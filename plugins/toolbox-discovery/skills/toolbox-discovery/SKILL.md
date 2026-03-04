---
name: toolbox-discovery
description: Use when wanting to discover what tools are installed on the system, identify misconfigured or underutilized tools, activate dormant capabilities, optimize the development environment, or find missing tools for a project. Also use when mentioning 'what tools do I have', 'system inventory', 'tool discovery', 'setup my environment', 'missing tools', 'optimize dev setup', 'activate tools', or wanting a comprehensive overview of available system capabilities.
---

# Toolbox Discovery & Activation

A comprehensive system inventory and smart configuration skill. Scans the system for ALL installed tools — CLI utilities, language runtimes, servers, package managers, dev tools, AI coding agents, and more — then assesses their health, identifies what is misconfigured or underutilized, and proposes activations, configurations, or new installations.

## Philosophy

**"You can't use what you don't know you have."**

Most developers have dozens, sometimes hundreds, of tools installed on their systems but actively use only a fraction of them. Tools get installed for one project and forgotten. Package managers pull in utilities as dependencies that never get used directly. Default configurations leave powerful features dormant. Integrations between tools that would multiply productivity remain unconnected.

The Toolbox Discovery process follows four phases:

1. **Discovery** — What is actually installed on this system right now?
2. **Assessment** — Is each tool healthy, configured, integrated, up-to-date?
3. **Activation** — What dormant capabilities can be enabled right now?
4. **Optimization** — What is missing that would complement the existing stack?

This skill is **system-aware**: it adapts to what is actually available on the machine, not what theoretically should be there. It detects the OS, package manager, shell, and existing configurations, then tailors every recommendation to the real environment.

---

## The Discovery Process

### Phase 1: SCAN (System Inventory)

Use `command -v` (not `which`) for speed and POSIX compliance. Scan every tool in each category below. For each tool found, capture the binary path and version string.

Run the discovery script for a fast automated scan:
```bash
bash skills/toolbox-discovery/scripts/discover-tools.sh
# or for JSON output:
bash skills/toolbox-discovery/scripts/discover-tools.sh --json
```

#### Languages & Runtimes

| Category | Tools to Scan |
|----------|--------------|
| Go | `go`, `gofmt`, `gopls`, `golangci-lint`, `air`, `templ`, `buf`, `protoc`, `dlv`, `staticcheck` |
| Node.js | `node`, `npm`, `npx`, `yarn`, `pnpm`, `bun`, `deno`, `tsx`, `ts-node` |
| Python | `python3`, `python`, `pip`, `pip3`, `pipx`, `uv`, `poetry`, `conda`, `pyenv`, `virtualenv`, `ruff`, `mypy`, `pyright`, `black`, `isort` |
| Rust | `rustc`, `cargo`, `rustup`, `rust-analyzer`, `cargo-watch`, `cargo-edit`, `cargo-expand`, `miri` |
| Java | `java`, `javac`, `gradle`, `mvn`, `kotlin`, `kotlinc`, `ant`, `jshell` |
| Ruby | `ruby`, `gem`, `bundler`, `rails`, `rspec`, `rubocop`, `irb` |
| PHP | `php`, `composer`, `artisan`, `phpunit`, `phpstan`, `psalm` |
| Zig | `zig` |
| Nim | `nim`, `nimble` |
| Elixir | `elixir`, `mix`, `iex`, `erlc` |
| Haskell | `ghc`, `ghci`, `cabal`, `stack`, `hlint` |
| C/C++ | `gcc`, `g++`, `clang`, `clang++`, `cmake`, `make`, `meson`, `ninja`, `ccache`, `gdb`, `lldb`, `valgrind` |
| Lua | `lua`, `luajit`, `luarocks` |
| Perl | `perl`, `cpan` |

For each runtime found, also check:
- Version: `<tool> --version` or `<tool> version`
- Active version manager: check for `asdf`, `mise`, `proto`, `nvm`, `pyenv`, `rbenv`, `rustup`

#### Package Managers

| Category | Tools to Scan |
|----------|--------------|
| System (Arch/Manjaro) | `pacman`, `yay`, `paru`, `pamac`, `pikaur`, `trizen` |
| System (Debian/Ubuntu) | `apt`, `apt-get`, `dpkg`, `snap` |
| System (Fedora/RHEL) | `dnf`, `rpm`, `yum` |
| System (macOS) | `brew` |
| Universal | `flatpak`, `snap`, `nix`, `guix`, `appimage` |
| Version managers | `asdf`, `mise`, `proto`, `nvm`, `fnm`, `pyenv`, `rbenv`, `goenv` |
| Language-specific | `npm`, `pip`, `cargo`, `go install`, `gem`, `composer`, `mix`, `cabal`, `luarocks` |

#### Containers & Orchestration

| Category | Tools to Scan |
|----------|--------------|
| Containers | `docker`, `docker-compose`, `podman`, `podman-compose`, `buildah`, `skopeo`, `nerdctl`, `containerd`, `cri-o` |
| Kubernetes | `kubectl`, `helm`, `k9s`, `minikube`, `kind`, `k3s`, `k3d`, `kustomize`, `kubectx`, `kubens`, `stern`, `lens` |
| IaC | `terraform`, `tofu`, `pulumi`, `ansible`, `ansible-playbook`, `vagrant`, `packer` |
| Cloud CLI | `aws`, `gcloud`, `az`, `doctl`, `flyctl`, `railway`, `vercel`, `netlify`, `wrangler` |

#### Version Control & Git Tools

| Category | Tools to Scan |
|----------|--------------|
| Core | `git`, `git-lfs` |
| GitHub/GitLab | `gh`, `glab` |
| UI/TUI | `lazygit`, `tig`, `gitui`, `gitk` |
| Diff tools | `delta`, `difftastic`, `diff-so-fancy`, `colordiff` |
| Utilities | `pre-commit`, `commitizen`, `cz`, `conventional-commits`, `git-flow`, `git-crypt` |

#### AI & Coding Agents

| Category | Tools to Scan |
|----------|--------------|
| Agents | `claude`, `codex`, `gemini`, `aider`, `goose`, `amp`, `opencode`, `cody` |
| GitHub AI | `gh copilot` (check `gh extension list`) |
| Local AI | `ollama`, `llama-server`, `whisper`, `tts`, `vllm` |
| Utilities | `sgpt`, `mods`, `fabric`, `glow` |

#### Editors & IDEs

| Category | Tools to Scan |
|----------|--------------|
| Terminal editors | `nvim`, `vim`, `vi`, `emacs`, `helix`, `hx`, `kakoune`, `kak`, `nano`, `micro`, `ne`, `joe` |
| GUI editors | `code`, `cursor`, `windsurf`, `zed`, `subl`, `atom` |
| JetBrains | `idea`, `goland`, `pycharm`, `webstorm`, `clion`, `rider`, `phpstorm`, `rubymine` |

#### Terminal & Shell

| Category | Tools to Scan |
|----------|--------------|
| Shells | `bash`, `zsh`, `fish`, `nu`, `nushell`, `elvish`, `xonsh`, `dash`, `ksh` |
| Multiplexers | `tmux`, `zellij`, `screen`, `byobu` |
| Emulators | `ghostty`, `alacritty`, `kitty`, `wezterm`, `foot`, `konsole`, `gnome-terminal`, `xterm` |
| Prompts | `starship` (also check `~/.oh-my-zsh`, `~/.oh-my-posh`, `~/.config/powerlevel10k`) |
| Utilities | `zoxide`, `direnv`, `atuin`, `mcfly` |

#### Networking

| Category | Tools to Scan |
|----------|--------------|
| HTTP clients | `curl`, `wget`, `httpie`, `http`, `xh`, `grpcurl`, `evans` |
| Scanners | `nmap`, `masscan`, `zmap` |
| Tunneling | `ssh`, `mosh`, `et` (eternal-terminal), `socat`, `netcat`, `nc`, `ncat` |
| VPN | `tailscale`, `wg` (wireguard), `openvpn` |
| Servers | `caddy`, `nginx`, `apache2`, `httpd`, `traefik` |
| DNS | `dig`, `nslookup`, `host`, `dog`, `drill` |
| Monitoring | `tcpdump`, `wireshark`, `tshark`, `iftop`, `nethogs`, `bandwhich`, `trippy` |

#### Databases

| Category | Tools to Scan |
|----------|--------------|
| Clients | `sqlite3`, `psql`, `mysql`, `mongosh`, `mongo`, `redis-cli`, `clickhouse-client`, `cqlsh` |
| Enhanced clients | `pgcli`, `mycli`, `litecli`, `usql`, `iredis` |
| GUI | `dbeaver`, `beekeeper-studio` |
| Migration | `flyway`, `liquibase`, `goose`, `migrate`, `atlas` |

#### Monitoring & Debugging

| Category | Tools to Scan |
|----------|--------------|
| System monitors | `htop`, `btop`, `glances`, `gotop`, `bottom`, `zenith`, `nmon` |
| Process | `ps`, `pgrep`, `pidof`, `lsof`, `fuser` |
| Debuggers | `gdb`, `lldb`, `dlv`, `strace`, `ltrace`, `dtrace` |
| Profiling | `perf`, `valgrind`, `flamegraph`, `pprof`, `heaptrack` |
| Logs | `journalctl`, `dmesg`, `lnav`, `multitail`, `goaccess` |

#### File & Disk Utilities

| Category | Tools to Scan |
|----------|--------------|
| Search | `fd`, `rg` (ripgrep), `fzf`, `ag` (silver-searcher), `ack`, `plocate`, `locate`, `mlocate` |
| View | `bat`, `eza`, `exa`, `lsd`, `broot`, `tree` |
| Navigate | `ranger`, `yazi`, `nnn`, `lf`, `vifm`, `mc` |
| Data | `jq`, `yq`, `xsv`, `csvtool`, `fx`, `gron`, `dasel`, `htmlq` |
| Disk | `ncdu`, `dust`, `duf`, `gdu` |
| Transfer | `rsync`, `rclone`, `scp`, `sftp` |
| Backup | `borgbackup`, `borg`, `restic`, `timeshift`, `snapper` |
| Archive | `tar`, `zip`, `unzip`, `7z`, `zstd`, `xz`, `gzip`, `bzip2` |

#### Media & Graphics

| Category | Tools to Scan |
|----------|--------------|
| Video/Audio | `ffmpeg`, `ffprobe`, `mpv`, `vlc`, `yt-dlp`, `youtube-dl`, `sox` |
| Images | `imagemagick`, `convert`, `gimp`, `inkscape`, `optipng`, `pngquant`, `jpegoptim` |
| Recording | `obs-studio`, `obs`, `wf-recorder`, `arecord`, `pactl` |
| Docs | `pandoc`, `typst`, `latex`, `pdflatex`, `wkhtmltopdf`, `weasyprint` |

#### System Utilities

| Category | Tools to Scan |
|----------|--------------|
| Services | `systemctl`, `loginctl`, `journalctl`, `timedatectl`, `hostnamectl` |
| Hardware | `lsblk`, `blkid`, `fdisk`, `parted`, `smartctl`, `hdparm` |
| Info | `dmidecode`, `lscpu`, `lspci`, `lsusb`, `inxi`, `neofetch`, `fastfetch` |
| Network config | `ip`, `ss`, `nmcli`, `iwctl`, `networkctl` |
| Firewall | `ufw`, `firewalld`, `firewall-cmd`, `iptables`, `nftables` |
| Cron/Timers | `crontab`, `systemctl list-timers`, `at`, `anacron` |

---

### Phase 2: ASSESS (Health Check)

For each discovered tool, evaluate:

1. **Version & Currency**
   - Run `<tool> --version` or `<tool> version`
   - Compare against latest known version where feasible
   - Flag tools that are significantly outdated (2+ major versions behind)

2. **Configuration Status**
   - Check for config files in standard locations (`~/.config/<tool>/`, `~/.<tool>rc`, etc.)
   - Determine if config is default or customized
   - Flag tools with no config that benefit from one (e.g., git without delta, tmux without config)

3. **Integration Health**
   - Check if tools that work together are actually connected
   - Examples: Is delta set as git's pager? Is fzf integrated with zsh? Is bat used as MANPAGER?
   - List potential integrations that are not active

4. **Binary Health**
   - Verify the binary actually runs (not just exists)
   - Check for common errors: missing libraries, broken symlinks, permission issues
   - Flag tools that exist but fail to execute

5. **Service Status** (for daemons)
   - Check `systemctl --user status <service>` and `systemctl status <service>`
   - Flag services that should be running but are not (e.g., ollama, docker)

---

### Phase 3: ACTIVATE (Enable & Configure)

For each underutilized tool, provide actionable activation steps. Reference the activation recipes file for ready-to-apply configurations:

```
Read: skills/toolbox-discovery/references/activation-recipes.md
```

**Categories of activation:**

1. **Shell Integrations**
   - Add completions for tools (gh, docker, kubectl, etc.)
   - Enable keybindings (fzf ctrl-R, ctrl-T, alt-C)
   - Install shell plugins (zsh-autosuggestions, zsh-syntax-highlighting)
   - Configure prompt (starship, powerlevel10k)

2. **Tool Configurations**
   - Create/improve config files (`.gitconfig`, `tmux.conf`, `starship.toml`)
   - Set environment variables (`EDITOR`, `VISUAL`, `PAGER`, `MANPAGER`, `BROWSER`)
   - Configure aliases and functions for daily workflows

3. **Integration Chains**
   - fzf + zsh + bat: fuzzy search with syntax-highlighted preview
   - delta + git + bat: beautiful diffs and logs
   - eza + bat: modern ls and cat replacements
   - ripgrep + fzf: fuzzy code search across projects
   - zoxide + fzf: smart directory navigation
   - direnv + shell: automatic environment per project
   - tmux + zsh: persistent session management
   - starship: universal prompt across all shells

4. **Service Enablement**
   - Start and enable systemd services (docker, ollama, tailscale)
   - Create user services for project daemons
   - Configure socket activation where appropriate

**Always back up existing configuration before modifying anything.** The activation script handles this:
```bash
bash skills/toolbox-discovery/scripts/activate-tools.sh <tool-or-category>
```

---

### Phase 4: RECOMMEND (Missing Tools)

Based on what is installed, recommend complementary tools. The logic follows patterns:

**Modern Replacements:**
| Old Tool | Modern Alternative | Why |
|----------|--------------------|-----|
| `grep` | `ripgrep` (rg) | 10-100x faster, respects .gitignore |
| `find` | `fd` | Simpler syntax, faster, respects .gitignore |
| `cat` | `bat` | Syntax highlighting, git integration, paging |
| `ls` | `eza` | Colors, icons, git status, tree view |
| `du` | `dust` | Visual, sorted, colored disk usage |
| `df` | `duf` | Tabular, colored, grouped disk free |
| `top` | `btop` | Beautiful, mouse support, detailed |
| `cd` | `zoxide` | Learns frequent directories, fuzzy matching |
| `ctrl-r` | `atuin` | Full shell history search with sync |
| `diff` | `delta` | Syntax highlighting, side-by-side, git integration |
| `man` | `tldr`, `cheat` | Practical examples instead of full manpages |

**Stack Completers:**
- Have `go` but no `golangci-lint`? -> Recommend it for linting
- Have `docker` but no `lazydocker`? -> Recommend it for TUI management
- Have `kubectl` but no `k9s`? -> Recommend it for cluster TUI
- Have `git` but no `lazygit`? -> Recommend it for TUI git
- Have `python` but no `ruff`? -> Recommend it for fast linting
- Have `node` but no `pnpm`? -> Recommend it for fast package management
- Have `zsh` but no `starship`? -> Recommend it for universal prompt
- Have `tmux` but no config? -> Recommend sensible defaults
- Have any shell but no `fzf`? -> Recommend it for everything

**Security Gap Analysis:**
- No `git-crypt` or `sops`? -> Recommend for secrets management
- No `age` or `gpg`? -> Recommend for encryption
- No firewall active? -> Recommend `ufw` setup
- No `fail2ban`? -> Recommend for SSH protection
- No `lynis`? -> Recommend for security auditing

**Refer to the full tool catalog for install commands and descriptions:**
```
Read: skills/toolbox-discovery/references/tool-catalog.md
```

---

## Output Format

Present the discovery report in this structured format:

```
TOOLBOX DISCOVERY REPORT
========================
System: <os> <version> | Shell: <shell> | Package Manager: <pm>
Scan date: <date>

LANGUAGES & RUNTIMES:
  [checkmark] go 1.24.1        [configured] gopls, golangci-lint, air, templ
  [checkmark] node 22.4.0      [configured] npm, pnpm, bun
  [checkmark] python 3.12.3    [partial]    pip, uv -- missing: pyright, ruff
  [x] rust                     [not installed]

PACKAGE MANAGERS:
  [checkmark] pacman           [configured]
  [checkmark] yay              [configured]
  [checkmark] flatpak          [configured]

CONTAINERS:
  [checkmark] docker 27.1.0    [running]    compose, buildx
  [x] podman                   [not installed]

VERSION CONTROL:
  [checkmark] git 2.47.0       [configured] gh, lazygit, delta
  [!] git-lfs                  [installed but not configured]

AI TOOLS:
  [checkmark] claude           [configured]
  [checkmark] ollama           [running]    models: llama3, nomic-embed-text
  [checkmark] aider            [configured]
  [x] codex                    [not installed]

EDITORS:
  [checkmark] nvim 0.10.0      [configured] lazy.nvim, LSP, treesitter
  [checkmark] code             [configured]

TERMINAL:
  [checkmark] zsh 5.9          [configured] oh-my-zsh, fzf, zoxide
  [checkmark] tmux 3.4         [configured]
  [checkmark] starship         [configured]

FILE UTILITIES:
  [checkmark] fd               [configured]
  [checkmark] rg               [configured]
  [checkmark] fzf              [configured] zsh integration active
  [checkmark] bat              [configured] MANPAGER set
  [checkmark] eza              [configured]

NETWORKING:
  [checkmark] curl             [configured]
  [checkmark] tailscale        [running]
  [checkmark] ssh              [configured] agent running

HEALTH ISSUES:
  [!] git-lfs: installed but hooks not configured
  [!] docker: user not in docker group (requires sudo)
  [!] conda: found but not in PATH

QUICK WINS (activate now):
  1. Set bat as MANPAGER: export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  2. Enable fzf alt-C keybinding in zsh
  3. Install zsh completions for docker and kubectl
  4. Set delta as git diff pager

MISSING (recommended for your stack):
  - ruff        -- fast Python linter    -- pacman -S ruff
  - lazydocker  -- Docker TUI            -- pacman -S lazydocker
  - dust        -- better du             -- pacman -S dust
  - atuin       -- shell history search  -- pacman -S atuin
```

Adapt the checkmark/x/! symbols to the terminal's capability. Use color if the output supports it.

---

## Quick Reference Commands

Scan everything:
```bash
bash skills/toolbox-discovery/scripts/discover-tools.sh
```

Scan and output JSON:
```bash
bash skills/toolbox-discovery/scripts/discover-tools.sh --json
```

Activate a specific tool or category:
```bash
bash skills/toolbox-discovery/scripts/activate-tools.sh fzf
bash skills/toolbox-discovery/scripts/activate-tools.sh git
bash skills/toolbox-discovery/scripts/activate-tools.sh shell
```

---

## Progressive Disclosure

- For the full catalog of tools with install commands: read `references/tool-catalog.md`
- For ready-to-apply activation recipes: read `references/activation-recipes.md`
- For the automated discovery script: run `scripts/discover-tools.sh`
- For the automated activation script: run `scripts/activate-tools.sh`
