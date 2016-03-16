require "colorize"
require "pathname"

class RuAUR::Pacman
    def clean(noconfirm = false)
        puts colorize_status("Cleaning pacman cache...")
        system("sudo #{@pac_cmd} -Sc") if (!noconfirm)
        system("sudo #{@pac_cmd} -Sc --noconfirm") if (noconfirm)
    end

    def colorize_installed(installed)
        return installed if (!RuAUR.colorize?)
        return installed.light_yellow
    end
    private :colorize_installed

    def colorize_status(status)
        return status if (!RuAUR.colorize?)
        return status.light_white
    end
    private :colorize_status

    def exist?(pkg_name)
        return !%x(#{@pac_nocolor} -Ss "^#{pkg_name}$").empty?
    end

    def initialize
        if (ScoobyDoo.where_are_you("pacman").nil?)
            raise RuAUR::Error::MissingDependencyError.new("pacman")
        end

        @pac_nocolor = "pacman --color=never"
        @pac_color = "pacman --color=always"
        @pac_cmd = @pac_color
        @pac_cmd = @pac_nocolor if (!RuAUR.colorize?)
        @installed = query
    end

    def install(pkg_name, noconfirm = false)
        if (@installed.include?(pkg_name))
            puts colorize_installed("Already installed: #{pkg_name}")
            return
        end

        puts colorize_status("Installing #{pkg_name}...")
        if (!noconfirm)
            system("sudo #{@pac_cmd} -S #{pkg_name} --needed")
        else
            system(
                "sudo #{@pac_cmd} -S #{pkg_name} --needed --noconfirm"
            )
        end

        @installed.merge!(query(pkg_name))
    end

    def install_local(pkgs, noconfirm = false)
        puts colorize_status("Installing compiled packages...")
        xzs = pkgs.join(" ")
        if (!noconfirm)
            system("sudo #{@pac_cmd} -U #{xzs}")
        else
            system("sudo #{@pac_cmd} -U #{xzs} --noconfirm")
        end
    end

    def query(pkg_name = "")
        results = Hash.new
        %x(#{@pac_nocolor} -Q #{pkg_name}).split("\n").each do |line|
            line = line.split
            results[line[0]] = line[1]
        end
        return results
    end

    def query_aur(pkg_name = "")
        community = Pathname.new(
            "/var/lib/pacman/sync/community"
        ).expand_path

        results = Hash.new
        %x(
            #{@pac_nocolor} -Qm #{pkg_name}
        ).split("\n").delete_if do |p|
            # Skip packages in community
            Dir["#{community}/#{p.split.join("-")}"].any?
        end.each do |line|
            line = line.split
            results[line[0]] = line[1]
        end
        return results
    end

    def remove(pkg_names, nosave = false)
        puts colorize_status("Removing #{pkg_names.join(" ")}...")
        if (!nosave)
            system("sudo #{@pac_cmd} -R #{pkg_names.join(" ")}")
        else
            system("sudo #{@pac_cmd} -Rn #{pkg_names.join(" ")}")
        end
    end

    def search(pkg_names)
        results = Array.new
        return results if (pkg_names.nil? || pkg_names.empty?)

        %x(
            #{@pac_nocolor} -Ss #{pkg_names}
        ).split("\n").each do |line|
            reg = "^([^\/ ]+)\/([^ ]+) ([^ ]+)( .*)?$"
            match = line.match(/#{reg}/)
            if (match)
                repo, name, version, trailing = match.captures
                repo.strip!
                name.strip!
                version.strip!
                trailing = "" if (trailing.nil?)
                trailing.strip!

                results.push(
                    RuAUR::Package.new(
                        {
                            "Description" => "",
                            "Name" => name,
                            "NumVotes" => nil,
                            "URLPath" => nil,
                            "Version" => version
                        },
                        repo
                    )
                )
                if (trailing.include?("[installed]"))
                    results.last.installed
                end
            elsif (results.any?)
                results.last.description += " #{line.strip}"
            end
        end

        return results
    end

    def upgrade(noconfirm = false)
        puts colorize_status("Updating...")
        system("sudo #{@pac_cmd} -Syyu") if (!noconfirm)
        system("sudo #{@pac_cmd} -Syyu --noconfirm") if (noconfirm)
    end
end
