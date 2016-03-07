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
        @pacman.clean(noconfirm)
        @aur.clean
    end

    def initialize(colorize = false)
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

        @colorize = colorize
        @pacman = RuAUR::Pacman.new(@colorize)
        @aur = RuAUR::AUR.new(@pacman, nil, @colorize)
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

    def remove(pkg_names, nosave = false)
        check_and_lock
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
end

require "ruaur/aur"
require "ruaur/error"
require "ruaur/package"
require "ruaur/pacman"
