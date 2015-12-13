class RuAUR::Pacman
    def clean(noconfirm = false)
        puts "Cleaning pacman cache...".white
        system("sudo #{@pac_clr} -Sc") if (!noconfirm)
        system("sudo #{@pac_clr} -Sc --noconfirm") if (noconfirm)
    end

    def exist?(pkg_name)
        return !%x(#{@pac_noclr} -Ss "^#{pkg_name}$").empty?
    end

    def initialize
        @pac_noclr = "pacman --color=never"
        @pac_clr = "pacman --color=always"
        @installed = query
    end

    def install(pkg_name, noconfirm = false)
        if (@installed.include?(pkg_name))
            puts "Already installed: #{pkg_name}".yellow
            return
        end

        puts "Installing #{pkg_name}...".white
        if (!noconfirm)
            system("sudo #{@pac_clr} -S #{pkg_name} --needed")
        else
            system(
                "sudo #{@pac_clr} -S #{pkg_name} --needed --noconfirm"
            )
        end

        @installed.merge!(query(pkg_name))
    end

    def install_local(pkgs, noconfirm = false)
        pkgs.each do |pkg|
            puts "Installing #{pkg}...".white
            if (!noconfirm)
                system("sudo #{@pac_clr} -U #{pkg}") if (!noconfirm)
            else
                system("sudo #{@pac_clr} -U #{pkg} --noconfirm")
            end
        end
    end

    def query(pkg_name = "")
        results = Hash.new
        %x(#{@pac_noclr} -Q #{pkg_name}).split("\n").map do |line|
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
        %x(#{@pac_noclr} -Qm #{pkg_name}).split("\n").delete_if do |p|
            # Skip packages in community
            Dir["#{community}/#{p.split.join("-")}"].any?
        end.map do |line|
            line = line.split
            results[line[0]] = line[1]
        end
        return results
    end

    def remove(pkg_names, nosave = false)
        puts "Removing #{pkg_names.join(" ")}...".white
        if (!nosave)
            system("sudo #{@pac_clr} -R #{pkg_names.join(" ")}")
        else
            system("sudo #{@pac_clr} -Rn #{pkg_names.join(" ")}")
        end
    end

    def search(pkg_names)
        results = Array.new
        return results if (pkg_names.nil? || pkg_names.empty?)

        %x(#{@pac_noclr} -Ss #{pkg_names}).each_line do |line|
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
        puts "Updating...".white
        system("sudo #{@pac_clr} -Syyu") if (!noconfirm)
        system("sudo #{@pac_clr} -Syyu --noconfirm") if (noconfirm)
    end
end
