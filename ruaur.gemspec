Gem::Specification.new do |s|
    s.name = "ruaur"
    s.version = "0.1.8"
    s.date = Time.new.strftime("%Y-%m-%d")
    s.summary = "Can search and install packages for Arch Linux"
    s.description =
        "RuAUR is a Ruby gem that allows searching and installing " \
        "packages from the Pacman sync database as well as the " \
        "Arch User Repository (AUR)."
    s.authors = [ "Miles Whittaker" ]
    s.email = "mjwhitta@gmail.com"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://mjwhitta.github.io/ruaur"
    s.license = "GPL-3.0"
    s.add_runtime_dependency(
        "archive-tar-minitar",
        "~> 0.5",
        ">= 0.5.2"
    )
    s.add_runtime_dependency("colorize", "~> 0.7", ">= 0.7.7")
    s.add_runtime_dependency("scoobydoo", "~> 0.1", ">= 0.1.1")
    s.add_runtime_dependency("typhoeus", "~> 0.8", ">= 0.8.0")
end
