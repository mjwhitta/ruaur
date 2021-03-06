require "hilighter"

class RuAUR::Package
    attr_accessor :description
    attr_accessor :installed
    attr_accessor :json
    attr_accessor :name
    attr_accessor :repo
    attr_accessor :url
    attr_accessor :version
    attr_accessor :votes

    def <=>(other)
        if (self.name.downcase == other.name.downcase)
            self_version = self.version.split(/\D+/).map(&:to_i)
            other_version = self.version.split(/\D+/).map(&:to_i)

            [self_version.size, other_version.size].max.times do |i|
                cmp = self_version[i] <=> other_version[i]
                return cmp if (cmp != 0)
            end
        end
        return (self.name.downcase <=> other.name.downcase)
    end

    def hilight_header(repo, name, installed, version, votes)
        header = Array.new

        if (!RuAUR.hilight?)
            header.push("#{repo}/#{name}")
            if (installed && newer?(installed))
                header.push(installed)
                header.push("->")
            end
            header.push(version)
            header.push(votes) if (votes)
            header.push("[installed]") if (installed)
        else
            header.push(
                [
                    repo.light_blue,
                    "/".light_blue,
                    name.light_cyan
                ].join
            )
            if (installed && newer?(installed))
                header.push(installed.light_red)
                header.push("->")
            end
            header.push(version.light_green)
            header.push(votes.light_white) if (votes)
            header.push("[installed]".light_magenta) if (installed)
        end

        return header.join(" ")
    end
    private :hilight_header

    def initialize(json, repo = "aur")
        @description = json["Description"]
        @description ||= ""
        @installed = nil
        @json = json
        @name = json["Name"]
        @repo = repo
        if (json["URLPath"])
            @url = "https://aur.archlinux.org#{json["URLPath"]}"
        else
            @url = nil
        end
        @version = json["Version"]
        @votes = nil
        @votes = "(#{json["NumVotes"]})" if (json["NumVotes"])
    end

    def installed(version = nil)
        @installed = version if (version)
        @installed = @version if (version.nil?)
    end

    def newer?(ver)
        pkg_version = @version.split(/\D+/).map(&:to_i)
        installed_version = ver.split(/\D+/).map(&:to_i)

        [pkg_version.size, installed_version.size].max.times do |i|
            return false if (pkg_version[i].nil?)
            return true if (installed_version[i].nil?)
            return true if (pkg_version[i] > installed_version[i])
            return false if (pkg_version[i] < installed_version[i])
        end
        return false
    end

    def older?(version)
        pkg_version = @version.split(/\D+/).map(&:to_i)
        installed_version = version.split(/\D+/).map(&:to_i)

        [pkg_version.size, installed_version.size].max.times do |i|
            return true if (pkg_version[i].nil?)
            return false if (installed_version[i].nil?)
            return true if (pkg_version[i] < installed_version[i])
            return false if (pkg_version[i] > installed_version[i])
        end
        return false
    end

    def tarball(file)
        return RuAUR::AUR.tarball(@url, file)
    end

    def to_s
        out = Array.new
        out.push(
            hilight_header(
                @repo,
                @name,
                @installed,
                @version,
                @votes
            )
        )

        # Wrap at default minus 4 spaces
        @description.scan(/\S.{0,76}\S(?=\s|$)|\S+/).each do |l|
            out.push("    #{l.strip}")
        end

        return out.join("\n")
    end
end
