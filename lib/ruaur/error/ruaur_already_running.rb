class RuAUR::Error::RuAURAlreadyRunning < RuAUR::Error
    def initialize
        super("RuAUR is already running")
    end
end
