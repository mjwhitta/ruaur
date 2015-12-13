class RuAUR::Error::RuAURAlreadyRunningError < RuAUR::Error
    def initialize
        super("RuAUR is already running")
    end
end
