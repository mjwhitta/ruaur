class RuAUR::Error::FailedToDownload < RuAUR::Error
    def initialize(package = nil)
        super("Failed to download: #{package}") if (package)
        super("Failed to download") if (package.nil?)
    end
end
