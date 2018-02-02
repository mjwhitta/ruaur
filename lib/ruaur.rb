require "fileutils"
require "scoobydoo"

class RuAUR
    def check_and_lock
        if (@lock.exist?)
            raise RuAUR::Error::RuAURAlreadyRunningError.new
        end

        FileUtils.touch(@lock)
    end
    private :check_and_lock

    def clean(noconfirm)
        check_and_lock
        @pacman.clean(noconfirm)
        @aur.clean
    ensure
        unlock
    end

    def download(pkg_names, noconfirm = false)
        pkg_names.each do |pkg_name|
            if (@pacman.exist?(pkg_name))
                @pacman.download(pkg_name, noconfirm)
                system(
                    "cp /var/cache/pacman/pkg/#{pkg_name}-[0-9]*.xz ."
                )
            else
                package = @aur.info(pkg_name)
                @aur.download(package)
            end
        end
    end

    def self.hilight?
        @@hilight ||= false
        return @@hilight
    end

    def initialize(hilight = false)
        [
            "makepkg",
            "pacman",
            "su",
            "sudo"
        ].each do |dep|
            if (ScoobyDoo.where_are_you(dep).nil?)
                raise RuAUR::Error::MissingDependencyError.new(dep)
            end
        end

        @@hilight = hilight
        @pacman = RuAUR::Pacman.new
        @aur = RuAUR::AUR.new(@pacman, nil)
        @lock = Pathname.new("/tmp/ruaur.lock").expand_path
    end

    def install(pkg_names, noconfirm = false)
        if (pkg_names.nil? || pkg_names.empty?)
            raise RuAUR::Error::PackageNotFoundError.new
        end

        check_and_lock

        pkg_names.each do |pkg_name|
            if (@pacman.exist?(pkg_name))
                @pacman.install(pkg_name, noconfirm)
            else
                @aur.install(pkg_name, noconfirm)
            end
        end
    ensure
        unlock
    end

    def query(pkg_names, options = [])
        info = options.include?(RuAUR::Options::Info)
        owns = options.include?(RuAUR::Options::Owns)

        if (owns)
            puts @pacman.query_owns(pkg_names.join(" "))
        else
            pkg_names.each do |pkg_name|
                results = @pacman.query(pkg_name, info)
                results.each do |name, details|
                    print "#{name} " if (!info)
                    puts details
                    puts if (info)
                end
                results = @aur.query(pkg_name, info)
                results.each do |name, details|
                    print "#{name} " if (!info)
                    puts details
                    puts if (info)
                end
            end
        end
    end

    def remove(pkg_names, options = [])
        check_and_lock
        nosave = options.include?(RuAUR::Options::NoSave)
        @pacman.remove(pkg_names, nosave)
    ensure
        unlock
    end

    def search(string, names_only = false)
        found = @pacman.search(string).concat(@aur.search(string))
        return found if (!names_only)
        names = Array.new
        found.each do |pkg|
            names.push(pkg.name) if (!names.include?(pkg.name))
        end
        return names
    end

    def sync(packages = [], options = [])
        if (options.include?(RuAUR::Options::Clean))
            clean(options.include?(RuAUR::Options::NoConfirm))
        elsif (options.include?(RuAUR::Options::Download))
            download(
                packages,
                options.include?(RuAUR::Options::NoConfirm)
            )
        elsif (options.include?(RuAUR::Options::Search))
            return search(
                packages.join(" "),
                options.include?(RuAUR::Options::NamesOnly)
            )
        elsif (options.include?(RuAUR::Options::Upgrade))
            upgrade(options.include?(RuAUR::Options::NoConfirm))
        else
            install(
                packages,
                options.include?(RuAUR::Options::NoConfirm)
            )
        end
        return nil
    end

    def unlock
        FileUtils.rm_f(@lock)
    end
    private :unlock

    def upgrade(noconfirm = false)
        check_and_lock
        @pacman.upgrade(noconfirm)
        @aur.upgrade(noconfirm)
    ensure
        unlock
    end

    def self.validate_options(options)
        valid = {
            RuAUR::Operation::Query => {
                "valid" => [
                    RuAUR::Options::Info,
                    RuAUR::Options::Owns
                ]
            },
            RuAUR::Operation::Remove => {
                "valid" => [
                    RuAUR::Options::NoSave
                ]
            },
            RuAUR::Operation::Sync => {
                "valid" => [
                    RuAUR::Options::Clean,
                    RuAUR::Options::Download,
                    RuAUR::Options::NamesOnly,
                    RuAUR::Options::NoConfirm,
                    RuAUR::Options::Search,
                    RuAUR::Options::Upgrade
                ],
                RuAUR::Options::Clean => [
                    RuAUR::Options::Clean,
                    RuAUR::Options::NoConfirm
                ],
                RuAUR::Options::Download => [
                    RuAUR::Options::Download,
                    RuAUR::Options::NoConfirm
                ],
                RuAUR::Options::Search => [
                    RuAUR::Options::NamesOnly,
                    RuAUR::Options::NoConfirm,
                    RuAUR::Options::Search
                ],
                RuAUR::Options::Upgrade => [
                    RuAUR::Options::NoConfirm,
                    RuAUR::Options::Upgrade
                ]
            }
        }

        return false if (valid[options["operation"]].nil?)

        valid[options["operation"]].each do |k, v|
            if ((k == "valid") || options["options"].include?(k))
                options["options"].each do |o|
                    return false if (!v.include?(o))
                end
            end
        end

        return true
    end
end

require "ruaur/aur"
require "ruaur/error"
require "ruaur/operation"
require "ruaur/options"
require "ruaur/package"
require "ruaur/pacman"
