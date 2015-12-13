class RuAUR::Error < RuntimeError
end

require "ruaur/error/aur_error"
require "ruaur/error/failed_to_compile_error"
require "ruaur/error/failed_to_download_error"
require "ruaur/error/failed_to_extract_error"
require "ruaur/error/missing_dependency_error"
require "ruaur/error/package_not_found_error"
require "ruaur/error/package_not_installed_error"
require "ruaur/error/ruaur_already_running_error"
