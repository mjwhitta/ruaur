class RuAUR::Error::MissingDependency < RuAUR::Error
    def initialize(dep = nil)
        super("Dependency not found: #{dep}") if (dep)
        super("Dependency not found") if (dep.nil?)
    end
end
