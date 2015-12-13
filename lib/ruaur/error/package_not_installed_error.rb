class RuAUR::Error::PackageNotInstalledError < RuAUR::Error
    def initialize(package = nil)
        super("Package not installed: #{package}") if (package)
        super("Package not installed") if (package.nil?)
    end
end
