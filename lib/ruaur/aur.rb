require "fileutils"
require "hilighter"
require "io/wait"
require "json"
require "minitar"
require "scoobydoo"
require "typhoeus"
require "zlib"

class RuAUR::AUR
    def clean
        puts(hilight_status("Cleaning AUR cache..."))
        Dir.chdir(@cache) do
            FileUtils.rm_rf(Dir["*"])
        end
    end

    def compile(package, noconfirm = false)
        puts(hilight_status("Compiling #{package.name}..."))

        cmd = "makepkg -rs"
        cmd = "makepkg --noconfirm -rs" if (noconfirm)

        if (Process.uid == 0)
            system("chown -R nobody:nobody .")
            system("su -s /bin/sh nobody -c \"#{cmd}\"")
        else
            system(cmd)
        end

        tar = "#{package.name}*.pkg.tar"
        compiled = Dir["#{tar}.zst"]
        compiled = Dir["#{tar}.xz"] if (compiled.empty?)

        if (compiled.empty?)
            raise RuAUR::Error::FailedToCompile.new(package.name)
        end

        return compiled
    end
    private :compile

    def download(package, status = true)
        FileUtils.rm_f(Dir["#{package.name}.tar.gz*"])

        if (status)
            puts(hilight_status("Downloading #{package.name}..."))
        end

        tarball(package.name, package.url, "#{package.name}.tar.gz")

        tgz = Pathname.new("#{package.name}.tar.gz").expand_path
        if (!tgz.exist?)
            raise RuAUR::Error::FailedToDownload.new(
                package.name
            )
        end
    end

    def edit_pkgbuild(package, noconfirm = false)
        return false if (noconfirm)

        loop do
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
            when "n", "N", "\r"
                return false
            when "q", "Q", "\x03"
                # Quit or ^C
                return true
            when "y", "Y"
                editor = ENV["EDITOR"]
                editor = ScoobyDoo.where_are_you("vim") if (editor.nil?)
                editor = ScoobyDoo.where_are_you("vi") if (editor.nil?)
                system("#{editor} PKGBUILD")
            end
        end
    end
    private :edit_pkgbuild

    def extract(package, status = true)
        FileUtils.rm_rf(package.name)

        if (status)
            puts(hilight_status("Extracting #{package.name}..."))
        end

        File.open("#{package.name}.tar.gz", "rb") do |tgz|
            tar = Zlib::GzipReader.new(tgz)
            Minitar.unpack(tar, ".")
        end
        FileUtils.rm_f("pax_global_header")

        dir = Pathname.new(package.name).expand_path
        if (!dir.exist? || !dir.directory?)
            raise RuAUR::Error::FailedToExtract.new(package.name)
        end
    end
    private :extract

    def find_upgrades
        puts(hilight_status("Checking for AUR updates..."))

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

    def get_dependencies(package)
        deps = Array.new
        keep = false
        Dir.chdir("#{@cache}/#{package.name}") do
            system("chown -R nobody:nobody .") if (Process.uid == 0)
            cmd = "su -s /bin/sh nobody -c \"makepkg --printsrcinfo\""
            cmd = "makepkg --printsrcinfo" if (Process.uid != 0)
            %x(#{cmd}).each_line do |line|
                line.match(/^\s*pkg(base|name)\s*\=\s*(.+)/) do |m|
                    keep = (m[2] == package.name)
                end
                line.match(
                    /^\s*depends(_i686|_x86_64)?\s*\=\s*([^>=:]+)/
                ) do |m|
                    deps.push(m[2].strip) if (keep)
                end
            end
        end
        return deps
    end

    def hilight_dependency(dependency)
        return dependency if (!RuAUR.hilight?)
        return dependency.light_magenta
    end
    private :hilight_dependency

    def hilight_installed(installed)
        return installed if (!RuAUR.hilight?)
        return installed.light_yellow
    end
    private :hilight_installed

    def hilight_status(status)
        return status if (!RuAUR.hilight?)
        return status.light_white
    end
    private :hilight_status

    def hilight_upgrade(old, new)
        return "#{old} -> #{new}" if (!RuAUR.hilight?)
        return "#{old.light_red} -> #{new.light_green}"
    end
    private :hilight_upgrade

    def info(pkg_name)
        return nil if (pkg_name.nil? || pkg_name.empty?)

        query = "type=info&arg=#{pkg_name}"
        response = Typhoeus.get("#{@rpc_url}?#{query}", timeout: 5)

        if (response.timed_out?)
            raise RuAUR::Error::AUR.new(
                "Check your internet connection!"
            )
        end

        return nil if (response.body.empty?)
        body = JSON.parse(response.body)

        if (body["type"] == "error")
            raise RuAUR::Error::AUR.new(body["results"])
        end

        return nil if (body["results"].empty?)
        return RuAUR::Package.new(body["results"], "aur")
    end

    def initialize(pacman, cache = "/tmp/ruaur-#{ENV["USER"]}")
        cache = "/tmp/ruaur-#{ENV["USER"]}" if (cache.nil?)
        @cache = Pathname.new(cache).expand_path
        FileUtils.mkdir_p(@cache)
        @installed = pacman.query_aur
        @pacman = pacman
        @rpc_url = "https://aur.archlinux.org/rpc.php"
    end

    def install(pkg_name, noconfirm = false)
        package = info(pkg_name)
        if (package.nil?)
            raise RuAUR::Error::PackageNotFound.new(pkg_name)
        end

        if (
            @installed.include?(pkg_name) &&
            !package.newer?(@installed[pkg_name])
        )
            puts(hilight_installed("Already installed: #{pkg_name}"))
            return
        end

        Dir.chdir(@cache) do
            download(package)
            extract(package)
        end

        Dir.chdir("#{@cache}/#{package.name}") do
            return if (edit_pkgbuild(package, noconfirm))
            install_dependencies(package, noconfirm)
            compiled = compile(package, noconfirm)
            @pacman.install_local(compiled, noconfirm)
        end

        @installed.merge!(@pacman.query_aur(pkg_name))
    end

    def install_dependencies(package, noconfirm)
        get_dependencies(package).each do |dep|
            if (!@installed.has_key?(dep))
                puts(
                    hilight_dependency(
                        "Installing dependency: #{dep}"
                    )
                )
                if (@pacman.exist?(dep))
                    @pacman.install(dep, noconfirm)
                else
                    install(dep, noconfirm)
                end
            end
        end
    end
    private :install_dependencies

    def multiinfo(pkgs)
        results = Array.new
        return results if (pkgs.nil? || pkgs.empty?)

        query = "type=multiinfo&arg[]=#{pkgs.join("&arg[]=")}"
        response = Typhoeus.get("#{@rpc_url}?#{query}", timeout: 5)

        if (response.timed_out?)
            raise RuAUR::Error::AUR.new(
                "Check your internet connection!"
            )
        end

        return results if (response.body.empty?)
        body = JSON.parse(response.body)

        if (body["type"] == "error")
            raise RuAUR::Error::AUR.new(body["results"])
        end

        body["results"].each do |result|
            results.push(RuAUR::Package.new(result, "aur"))
        end

        return results.sort
    end

    def query(pkg_name, info = false)
        package = info(pkg_name)
        return Hash.new if (package.nil?)

        results = Hash.new
        json = package.json

        if (!json.empty?)
            results[pkg_name] = json["Version"]
            if (info)
                max = 12 # Length of "Dependencies"
                json.each do |k, v|
                    max = k.length if (max < k.length)
                end

                out = Array.new
                json.each do |k, v|
                    filler = Array.new(max - k.length + 2, " ").join
                    out.push("#{k}#{filler}: #{v}")
                end

                Dir.chdir(@cache) do
                    download(package, false)
                    extract(package, false)
                end

                deps = get_dependencies(package)
                filler = Array.new(max - 10, " ").join
                out.push("Dependencies#{filler}: #{deps.join("  ")}")

                results[pkg_name] = out.join("\n")
            end
        end

        # Clean up
        Dir.chdir(@cache) do
            FileUtils.rm_rf(Dir["#{package.name}*"])
        end

        return results
    end

    def search(string)
        results = Array.new
        return results if (string.nil? || string.empty?)

        query = "type=search&arg=#{string}"
        response = Typhoeus.get("#{@rpc_url}?#{query}", timeout: 5)

        if (response.timed_out?)
            raise RuAUR::Error::AUR.new(
                "Check your internet connection!"
            )
        end

        return results if (response.body.empty?)
        body = JSON.parse(response.body)

        if (body["type"] == "error")
            raise RuAUR::Error::AUR.new(body["results"])
        end

        body["results"].each do |result|
            results.push(RuAUR::Package.new(result, "aur"))
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
        request = Typhoeus::Request.new(url, timeout: 5)

        request.on_headers do |response|
            if (response.code != 200)
                raise RuAUR::Error::FailedToDownload.new(name)
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

            puts(hilight_status("Upgrading #{pkg_name}..."))
            puts(hilight_upgrade(old, new))
            install(pkg_name, noconfirm)
        end
    end
end
