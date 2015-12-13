class RuAUR::Error::PackageNotFoundError < RuAUR::Error
    def initialize(package = nil)
        super("Package not found: #{package}") if (package)
        super("No package was specified") if (package.nil?)
    end
end
