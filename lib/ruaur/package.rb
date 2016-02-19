require "colorize"
require "string"

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
        self_version = @version.split(/\D+/).map(&:to_i)
        other_version = ver.split(/\D+/).map(&:to_i)

        [self_version.size, other_version.size].max.times do |i|
            if (self_version[i] > other_version[i])
                return true
            end
        end
        return false
    end

    def older?(version)
        self_version = @version.split(/\D+/).map(&:to_i)
        other_version = version.split(/\D+/).map(&:to_i)

        [self_version.size, other_version.size].max.times do |i|
            if (self_version[i] < other_version[i])
                return true
            end
        end
        return false
    end

    def tarball(file)
        return RuAUR::AUR.tarball(@url, file)
    end

    def to_s
        out = Array.new
        header = Array.new

        header.push("#{@repo.blue}#{"/".blue}#{@name.cyan}")
        if (@installed && newer?(@installed))
            header.push(@installed.red)
            header.push("->")
        end
        header.push(@version.green)
        header.push(@votes.white) if (@votes)
        header.push("[installed]".magenta) if (@installed)
        out.push(header.join(" "))

        @description.word_wrap.each_line do |line|
            out.push("    #{line.rstrip}")
        end

        return out.join("\n")
    end
end
