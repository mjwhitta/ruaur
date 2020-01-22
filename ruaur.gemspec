Gem::Specification.new do |s|
    s.add_development_dependency("rake", "~> 13.0", ">= 13.0.0")
    s.add_runtime_dependency("hilighter", "~> 1.5", ">= 1.5.1")
    s.add_runtime_dependency("minitar", "~> 0.9", ">= 0.9.0")
    s.add_runtime_dependency("scoobydoo", "~> 1.0", ">= 1.0.1")
    s.add_runtime_dependency("typhoeus", "~> 1.3", ">= 1.3.1")
    s.authors = ["Miles Whittaker"]
    s.date = Time.new.strftime("%Y-%m-%d")
    s.description = [
        "RuAUR is a Ruby gem that allows searching and installing",
        "packages from the Pacman sync database as well as the Arch",
        "User Repository (AUR)."
    ].join(" ")
    s.email = "mj@whitta.dev"
    s.executables = Dir.chdir("bin") do
        Dir["*"]
    end
    s.files = Dir["lib/**/*.rb"]
    s.homepage = "https://gitlab.com/mjwhitta/ruaur"
    s.license = "GPL-3.0"
    s.metadata = {"source_code_uri" => s.homepage}
    s.name = "ruaur"
    s.summary = "Can search and install packages for Arch Linux"
    s.version = "1.2.0"
end
