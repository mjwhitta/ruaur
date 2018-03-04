class RuAUR::Error < RuntimeError
end

require "ruaur/error/aur"
require "ruaur/error/failed_to_compile"
require "ruaur/error/failed_to_download"
require "ruaur/error/failed_to_extract"
require "ruaur/error/missing_dependency"
require "ruaur/error/package_not_found"
require "ruaur/error/package_not_installed"
require "ruaur/error/ruaur_already_running"
