# RuAUR

## What is this?

RuAUR is a Ruby gem that allows searching and installing packages from
the Pacman sync database as well as the Arch User Repository (AUR).

## How to install

```
$ gem install ruaur
```

## Usage

```
$ ruaur --help
Usage: ruaur <operation> [OPTIONS] [pkgs]

OPTIONS
    -h, --help          Display this help message
        --nocolor       Disable colorized output
    -v, --verbose       Show backtrace when error occurs
        --version       Show version

OPERATIONS
    -Q, --query         Query the package database
    -R, --remove        Remove package(s)
    -S, --sync          Synchronize package(s)

QUERY_OPTIONS
    -i, --info          Display information for given package(s)
    -o, --owns          Search for packages that own the specified file(s)

REMOVE_OPTIONS
    -n, --nosave        Completely remove package

SYNC_OPTIONS
    -c, --clean         Remove packages from the cache
        --names-only    Only show package names (useful for tab-completion)
        --noconfirm     Bypass any and all "Are you sure?" messages
    -s, --search        Search the sync database and AUR for package(s)
    -u, --sysupgrade    Upgrade all packages
    -w, --downloadonly  Retrieve packages from the server, but do not install
```

## Links

- [Source](https://gitlab.com/mjwhitta/ruaur)
- [RubyGems](https://rubygems.org/gems/ruaur)

## TODO

- Better README
- RDoc
