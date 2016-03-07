# RuAUR

## What is this?

RuAUR is a Ruby gem that allows searching and installing packages from
the Pacman sync database as well as the Arch User Repository (AUR).

## How to install

```bash
$ gem install ruaur
```

## Usage

```
$ ruaur --help
Usage: ruaur <operation> [OPTIONS] [pkgs]

OPTIONS
    -h, --help        Display this help message
        --nocolor     Disable colorized output
    -v, --verbose     Show backtrace when error occurs

OPERATIONS
    -R, --remove      Remove packages
    -S, --sync        Synchronize packages

SYNC_OPTIONS
    -c, --clean       Remove packages from the cache
        --names-only  Only show package names (useful for tab-completion)
        --noconfirm   Bypass any and all "Are you sure?" messages
    -s, --search      Search the sync database and AUR for packages
    -u, --sysupgrade  Upgrade all packages

REMOVE_OPTIONS
    -n, --nosave      Completely remove package
```

## Links

- [Homepage](https://mjwhitta.github.io/ruaur)
- [Source](https://gitlab.com/mjwhitta/ruaur)
- [Mirror](https://github.com/mjwhitta/ruaur)
- [RubyGems](https://rubygems.org/gems/ruaur)

## TODO

- Better README
- RDoc
