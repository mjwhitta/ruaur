Gem::Specification.new do |s|
    s.name = "ruaur"
    s.version = "0.2.7"
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
    s.add_development_dependency("rake", "~> 10.5", ">= 10.5.0")
    s.add_runtime_dependency(
        "archive-tar-minitar",
        "~> 0.5",
        ">= 0.5.2"
    )
    s.add_runtime_dependency("hilighter", "~> 0.1", ">= 0.1.0")
    s.add_runtime_dependency("scoobydoo", "~> 0.1", ">= 0.1.3")
    s.add_runtime_dependency("typhoeus", "~> 1.0", ">= 1.0.1")
end
