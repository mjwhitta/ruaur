class RuAUR::Error::FailedToCompileError < RuAUR::Error
    def initialize(package = nil)
        super("Failed to compile: #{package}") if (package)
        super("Failed to compile") if (package.nil?)
    end
end
