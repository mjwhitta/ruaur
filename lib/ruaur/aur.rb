require "archive/tar/minitar"
require "fileutils"
require "io/wait"
require "json"
require "scoobydoo"
require "typhoeus"
require "zlib"

class RuAUR::AUR
    def clean
        puts "Cleaning AUR cache...".white
        Dir.chdir(@cache) do
            FileUtils.rm_rf(Dir["*"])
        end
    end

    def compile(package)
        puts "Compiling #{package.name}...".white
        if (Process.uid == 0)
            system("chown -R nobody:nobody .")
            system("su -s /bin/sh nobody -c \"makepkg -sr\"")
        else
            system("makepkg -sr")
        end

        compiled = Dir["#{package.name}*.pkg.tar.xz"]
        if (compiled.empty?)
            raise RuAUR::Error::FailedToCompileError.new(package.name)
        end

        return compiled
    end
    private :compile

    def download(package)
        FileUtils.rm_f(Dir["#{package.name}.tar.gz*"])

        puts "Downloading #{package.name}...".white
        tarball(package.name, package.url, "#{package.name}.tar.gz")

        tgz = Pathname.new("#{package.name}.tar.gz").expand_path
        if (!tgz.exist?)
            raise RuAUR::Error::FailedToDownloadError.new(
                package.name
            )
        end
    end
    private :download

    def edit_pkgbuild(package, noconfirm = false)
        return false if (noconfirm)

        print "Do you want to edit the PKGBUILD y/[n]/q?: "
        answer = nil
        while (answer.nil?)
            begin
                system("stty raw -echo")
                if ($stdin.ready?)
                    answer = $stdin.getc
                else
                    sleep 0.1
                end
            ensure
                system("stty -raw echo")
            end
        end
        puts

        case answer
        when "y", "Y"
            editor = ENV["EDITOR"]
            editor = ScoobyDoo.where_are_you("vim") if (editor.nil?)
            editor = ScoobyDoo.where_are_you("vi") if (editor.nil?)
            system("#{editor} PKGBUILD")
        when "q", "Q", "\x03"
            # Quit or ^C
            return true
        end
        return false
    end
    private :edit_pkgbuild

    def extract(package)
        FileUtils.rm_rf(package.name)

        puts "Extracting #{package.name}...".white
        File.open("#{package.name}.tar.gz", "rb") do |tgz|
            tar = Zlib::GzipReader.new(tgz)
            Archive::Tar::Minitar.unpack(tar, ".")
        end
        FileUtils.rm_f("pax_global_header")

        dir = Pathname.new(package.name).expand_path
        if (!dir.exist? || !dir.directory?)
            raise RuAUR::Error::FailedToExtractError.new(package.name)
        end
    end
    private :extract

    def find_upgrades
        puts "Checking for AUR updates...".white

        upgrades = Hash.new
        multiinfo(@installed.keys).each do |package|
            if (
                @installed.has_key?(package.name) &&
                package.newer?(@installed[package.name])
            )
                upgrades[package.name] = [
                    @installed[package.name],
                    package.version
                ]
            end
        end

        return upgrades
    end
    private :find_upgrades

    def info(package)
        return nil if (package.nil? || package.empty?)

        query = "type=info&arg=#{package}"
        body = JSON.parse(Typhoeus.get("#{@rpc_url}?#{query}").body)

        if (body["type"] == "error")
            raise RuAUR::Error::AURError.new(body["results"])
        end

        return nil if (body["results"].empty?)
        return RuAUR::Package.new(body["results"])
    end

    def initialize(pacman, cache = "/tmp/ruaur-#{ENV["USER"]}")
        @cache = Pathname.new(cache).expand_path
        FileUtils.mkdir_p(@cache)
        @installed = pacman.query_aur
        @pacman = pacman
        @rpc_url = "https://aur.archlinux.org/rpc.php"
    end

    def install(pkg_name, noconfirm = false)
        package = info(pkg_name)

        if (package.nil?)
            raise RuAUR::Error::PackageNotFoundError.new(pkg_name)
        end

        if (
            @installed.include?(pkg_name) &&
            !package.newer?(@installed[pkg_name])
        )
            puts "Already installed: #{pkg_name}".yellow
            return
        end

        Dir.chdir(@cache) do
            download(package)
            extract(package)
        end
        Dir.chdir("#{@cache}/#{package.name}") do
            return if (edit_pkgbuild(package, noconfirm))
            install_dependencies(package, noconfirm)
            compiled = compile(package)
            @pacman.install_local(compiled, noconfirm)
        end

        @installed.merge!(@pacman.query_aur(pkg_name))
    end

    def install_dependencies(package, noconfirm)
        pkgbuild = File.read("PKGBUILD")

        pkgbuild.match(/^depends\=\(([^\)]+)\)/m) do |match|
            match.captures.each do |cap|
                cap.gsub(/\n/, " ").scan(/[^' ]+/) do |scan|
                    dep = scan.gsub(/(\<|\=|\>).*$/, "")
                    if (!@installed.has_key?(dep))
                        puts "Installing dependency: #{dep}".purple
                        if (@pacman.exist?(dep))
                            @pacman.install(dep, noconfirm)
                        else
                            install(dep, noconfirm)
                        end
                    end
                end
            end
        end
    end
    private :install_dependencies

    def multiinfo(pkgs)
        results = Array.new
        return results if (pkgs.nil? || pkgs.empty?)

        query = "type=multiinfo&arg[]=#{pkgs.join("&arg[]=")}"
        body = JSON.parse(Typhoeus.get("#{@rpc_url}?#{query}").body)

        if (body["type"] == "error")
            raise RuAUR::Error::AURError.new(body["results"])
        end

        body["results"].each do |result|
            results.push(RuAUR::Package.new(result))
        end
        return results.sort
    end

    def search(string)
        results = Array.new
        return results if (string.nil? || string.empty?)

        query = "type=search&arg=#{string}"
        body = JSON.parse(Typhoeus.get("#{@rpc_url}?#{query}").body)

        if (body["type"] == "error")
            raise RuAUR::Error::AURError.new(body["results"])
        end

        body["results"].each do |result|
            results.push(RuAUR::Package.new(result))
        end

        results.each do |package|
            if (@installed.has_key?(package.name))
                package.installed(@installed[package.name])
            end
        end
        return results.sort
    end

    def tarball(name, url, file)
        if (url.nil? || url.empty? || file.nil? || file.empty?)
            return nil
        end

        tgz = File.open(file, "wb")
        request = Typhoeus::Request.new(url)
        request.on_headers do |response|
            if (response.code != 200)
                raise RuAUR::Error::FailedToDownloadError.new(name)
            end
        end
        request.on_body do |chunk|
            tgz.write(chunk)
        end
        request.on_complete do
            tgz.close
        end
        request.run
    end
    private :tarball

    def upgrade(noconfirm = false)
        find_upgrades.each do |pkg_name, versions|
            old, new = versions

            puts "Upgrading #{pkg_name}...".white
            puts  "#{old.red} -> #{new.green}"
            install(pkg_name, noconfirm)
        end
    end
end
