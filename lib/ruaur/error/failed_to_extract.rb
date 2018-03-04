class RuAUR::Error::FailedToExtract < RuAUR::Error
    def initialize(package = nil)
        super("Failed to extract: #{package}") if (package)
        super("Failed to extract") if (package.nil?)
    end
end
