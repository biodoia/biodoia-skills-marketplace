# Tool Catalog

Exhaustive catalog of development tools organized by category. Each entry includes detection, installation, configuration, and integration information.

Legend:
- **Detect**: Command to check if installed
- **Install**: Install command(s) by package manager
- **Config**: Standard configuration file location
- **Integrates with**: Tools that work together with this one

---

## Languages & Runtimes

### Go

| Tool | Description | Detect | Install (pacman) | Install (brew) | Install (other) | Config | Integrates with |
|------|-------------|--------|-----------------|----------------|-----------------|--------|----------------|
| go | Go compiler and toolchain | `command -v go` | `pacman -S go` | `brew install go` | golang.org/dl | `~/.config/go/env`, `GOPATH` | gopls, air, templ, dlv |
| gopls | Go language server | `command -v gopls` | `pacman -S gopls` | `brew install gopls` | `go install golang.org/x/tools/gopls@latest` | `~/.config/gopls/` | nvim, code, any LSP editor |
| golangci-lint | Go meta-linter | `command -v golangci-lint` | `pacman -S golangci-lint` | `brew install golangci-lint` | `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest` | `.golangci.yml` | git pre-commit, CI |
| air | Go live reload | `command -v air` | -- | -- | `go install github.com/air-verse/air@latest` | `.air.toml` | go |
| templ | Go HTML templating | `command -v templ` | -- | -- | `go install github.com/a-h/templ/cmd/templ@latest` | -- | go, HTMX |
| dlv | Go debugger (Delve) | `command -v dlv` | `pacman -S delve` | `brew install delve` | `go install github.com/go-delve/delve/cmd/dlv@latest` | -- | nvim, code |
| buf | Protobuf toolchain | `command -v buf` | -- | `brew install buf` | `go install github.com/bufbuild/buf/cmd/buf@latest` | `buf.yaml` | protoc, gRPC |
| protoc | Protocol Buffers compiler | `command -v protoc` | `pacman -S protobuf` | `brew install protobuf` | -- | -- | buf, gRPC |
| staticcheck | Go static analyzer | `command -v staticcheck` | -- | -- | `go install honnef.co/go/tools/cmd/staticcheck@latest` | -- | golangci-lint |
| gofumpt | Strict gofmt | `command -v gofumpt` | -- | -- | `go install mvdan.cc/gofumpt@latest` | -- | gopls, editor |

### Node.js

| Tool | Description | Detect | Install (pacman) | Install (brew) | Install (other) | Config | Integrates with |
|------|-------------|--------|-----------------|----------------|-----------------|--------|----------------|
| node | Node.js runtime | `command -v node` | `pacman -S nodejs` | `brew install node` | nvm, fnm | -- | npm, all JS tooling |
| npm | Node package manager | `command -v npm` | (with nodejs) | (with node) | -- | `~/.npmrc` | node |
| npx | npm package runner | `command -v npx` | (with nodejs) | (with node) | -- | -- | npm |
| yarn | Yarn package manager | `command -v yarn` | `pacman -S yarn` | `brew install yarn` | `npm i -g yarn` | `~/.yarnrc.yml` | node |
| pnpm | Fast package manager | `command -v pnpm` | -- | `brew install pnpm` | `npm i -g pnpm` | `~/.npmrc` | node |
| bun | Fast JS runtime + bundler | `command -v bun` | -- | `brew install oven-sh/bun/bun` | `curl -fsSL https://bun.sh/install \| bash` | `bunfig.toml` | node ecosystem |
| deno | Secure JS/TS runtime | `command -v deno` | `pacman -S deno` | `brew install deno` | `curl -fsSL https://deno.land/install.sh \| sh` | `deno.json` | -- |
| tsx | TypeScript execute | `command -v tsx` | -- | -- | `npm i -g tsx` | -- | node, typescript |
| ts-node | TypeScript for Node | `command -v ts-node` | -- | -- | `npm i -g ts-node` | `tsconfig.json` | node, typescript |

### Python

| Tool | Description | Detect | Install (pacman) | Install (brew) | Install (other) | Config | Integrates with |
|------|-------------|--------|-----------------|----------------|-----------------|--------|----------------|
| python3 | Python interpreter | `command -v python3` | `pacman -S python` | `brew install python` | pyenv | -- | pip, uv, all Python tooling |
| pip | Python package installer | `command -v pip3` | (with python) | (with python) | -- | `~/.config/pip/pip.conf` | python3 |
| pipx | Install Python CLI apps | `command -v pipx` | `pacman -S python-pipx` | `brew install pipx` | `pip install pipx` | -- | pip |
| uv | Fast Python package manager | `command -v uv` | -- | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `pyproject.toml` | python3, pip replacement |
| poetry | Python dependency manager | `command -v poetry` | -- | `brew install poetry` | `pipx install poetry` | `pyproject.toml` | python3 |
| pyenv | Python version manager | `command -v pyenv` | `pacman -S pyenv` | `brew install pyenv` | `curl https://pyenv.run \| bash` | `~/.pyenv/` | python3 |
| ruff | Fast Python linter+formatter | `command -v ruff` | `pacman -S ruff` | `brew install ruff` | `pipx install ruff` | `pyproject.toml`, `ruff.toml` | python3, editor |
| mypy | Python type checker | `command -v mypy` | `pacman -S mypy` | `brew install mypy` | `pipx install mypy` | `mypy.ini`, `pyproject.toml` | python3 |
| pyright | Python type checker (fast) | `command -v pyright` | -- | `brew install pyright` | `npm i -g pyright` | `pyrightconfig.json` | node, python3 |
| black | Python code formatter | `command -v black` | `pacman -S python-black` | `brew install black` | `pipx install black` | `pyproject.toml` | python3, editor |

### Rust

| Tool | Description | Detect | Install (pacman) | Install (brew) | Install (other) | Config | Integrates with |
|------|-------------|--------|-----------------|----------------|-----------------|--------|----------------|
| rustc | Rust compiler | `command -v rustc` | `pacman -S rust` | `brew install rust` | `rustup` | -- | cargo |
| cargo | Rust package manager | `command -v cargo` | (with rust) | (with rust) | `rustup` | `~/.cargo/config.toml` | rustc |
| rustup | Rust toolchain manager | `command -v rustup` | `pacman -S rustup` | `brew install rustup` | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | `~/.rustup/` | rustc, cargo |
| rust-analyzer | Rust language server | `command -v rust-analyzer` | `pacman -S rust-analyzer` | `brew install rust-analyzer` | `rustup component add rust-analyzer` | -- | editor, LSP |
| cargo-watch | File watcher for cargo | `command -v cargo-watch` | -- | -- | `cargo install cargo-watch` | -- | cargo |

### C/C++

| Tool | Description | Detect | Install (pacman) | Install (brew) | Install (other) | Config | Integrates with |
|------|-------------|--------|-----------------|----------------|-----------------|--------|----------------|
| gcc | GNU C Compiler | `command -v gcc` | `pacman -S gcc` | `brew install gcc` | -- | -- | make, cmake |
| g++ | GNU C++ Compiler | `command -v g++` | (with gcc) | (with gcc) | -- | -- | make, cmake |
| clang | LLVM C/C++ compiler | `command -v clang` | `pacman -S clang` | `brew install llvm` | -- | -- | cmake, make |
| cmake | Build system generator | `command -v cmake` | `pacman -S cmake` | `brew install cmake` | -- | `CMakeLists.txt` | gcc, clang, ninja |
| make | Build automation | `command -v make` | `pacman -S make` | `brew install make` | -- | `Makefile` | gcc, clang |
| meson | Modern build system | `command -v meson` | `pacman -S meson` | `brew install meson` | `pip install meson` | `meson.build` | ninja |
| ninja | Fast build system | `command -v ninja` | `pacman -S ninja` | `brew install ninja` | -- | -- | cmake, meson |
| ccache | Compiler cache | `command -v ccache` | `pacman -S ccache` | `brew install ccache` | -- | `~/.config/ccache/ccache.conf` | gcc, clang |

---

## Package Managers

| Tool | Description | Detect | Config | Notes |
|------|-------------|--------|--------|-------|
| pacman | Arch/Manjaro system PM | `command -v pacman` | `/etc/pacman.conf` | Core system PM |
| yay | AUR helper (Go) | `command -v yay` | `~/.config/yay/config.json` | Most popular AUR helper |
| paru | AUR helper (Rust) | `command -v paru` | `~/.config/paru/paru.conf` | Fast AUR helper |
| pamac | Manjaro package manager | `command -v pamac` | `/etc/pamac.conf` | GUI + CLI |
| apt | Debian/Ubuntu PM | `command -v apt` | `/etc/apt/sources.list` | Debian family |
| dnf | Fedora PM | `command -v dnf` | `/etc/dnf/dnf.conf` | Fedora/RHEL |
| brew | Homebrew | `command -v brew` | `~/.config/homebrew/` | macOS + Linux |
| flatpak | Universal packages | `command -v flatpak` | -- | Sandboxed apps |
| snap | Canonical universal PM | `command -v snap` | -- | Ubuntu ecosystem |
| nix | Nix package manager | `command -v nix` | `~/.config/nix/nix.conf` | Reproducible builds |
| asdf | Universal version manager | `command -v asdf` | `~/.tool-versions` | Multi-language |
| mise | Modern asdf alternative | `command -v mise` | `~/.config/mise/config.toml` | Faster asdf replacement |
| proto | Moonrepo version manager | `command -v proto` | `~/.proto/config.toml` | Rust-based, fast |

---

## Containers & Orchestration

| Tool | Description | Detect | Install (pacman) | Config | Integrates with |
|------|-------------|--------|-----------------|--------|----------------|
| docker | Container runtime | `command -v docker` | `pacman -S docker` | `~/.docker/config.json` | compose, buildx |
| docker-compose | Multi-container orchestration | `command -v docker-compose` | `pacman -S docker-compose` | `docker-compose.yml` | docker |
| podman | Rootless containers | `command -v podman` | `pacman -S podman` | `~/.config/containers/` | buildah, skopeo |
| buildah | OCI image builder | `command -v buildah` | `pacman -S buildah` | -- | podman |
| skopeo | Container image tool | `command -v skopeo` | `pacman -S skopeo` | -- | podman, docker |
| kubectl | Kubernetes CLI | `command -v kubectl` | `pacman -S kubectl` | `~/.kube/config` | helm, k9s |
| helm | Kubernetes package manager | `command -v helm` | `pacman -S helm` | `~/.config/helm/` | kubectl |
| k9s | Kubernetes TUI | `command -v k9s` | `pacman -S k9s` | `~/.config/k9s/` | kubectl |
| minikube | Local Kubernetes | `command -v minikube` | `pacman -S minikube` | `~/.minikube/` | kubectl, docker |
| kind | K8s in Docker | `command -v kind` | -- | -- | kubectl, docker |
| terraform | Infrastructure as Code | `command -v terraform` | `pacman -S terraform` | `*.tf` files | cloud providers |
| ansible | Configuration management | `command -v ansible` | `pacman -S ansible` | `ansible.cfg` | ssh |

---

## Version Control

| Tool | Description | Detect | Install (pacman) | Config | Integrates with |
|------|-------------|--------|-----------------|--------|----------------|
| git | Version control | `command -v git` | `pacman -S git` | `~/.gitconfig` | delta, gh, lazygit |
| gh | GitHub CLI | `command -v gh` | `pacman -S github-cli` | `~/.config/gh/` | git |
| glab | GitLab CLI | `command -v glab` | -- | `~/.config/glab-cli/` | git |
| git-lfs | Git Large File Storage | `command -v git-lfs` | `pacman -S git-lfs` | `.gitattributes` | git |
| lazygit | Git TUI | `command -v lazygit` | `pacman -S lazygit` | `~/.config/lazygit/` | git, delta |
| tig | Git TUI viewer | `command -v tig` | `pacman -S tig` | `~/.tigrc` | git |
| gitui | Rust Git TUI | `command -v gitui` | `pacman -S gitui` | `~/.config/gitui/` | git |
| delta | Git diff highlighter | `command -v delta` | `pacman -S git-delta` | `~/.gitconfig` | git, bat |
| difftastic | Structural diff | `command -v difft` | `pacman -S difftastic` | -- | git |
| pre-commit | Git hook framework | `command -v pre-commit` | `pacman -S python-pre-commit` | `.pre-commit-config.yaml` | git |

---

## AI & Coding Agents

| Tool | Description | Detect | Install | Config | Notes |
|------|-------------|--------|---------|--------|-------|
| claude | Claude Code CLI | `command -v claude` | `npm i -g @anthropic-ai/claude-code` | `~/.claude/` | Anthropic |
| codex | Codex CLI | `command -v codex` | `npm i -g @openai/codex` | `~/.codex/` | OpenAI |
| gemini | Gemini CLI | `command -v gemini` | `npm i -g @google/gemini-cli` | `~/.gemini/` | Google |
| aider | AI pair programming | `command -v aider` | `pipx install aider-chat` | `.aider.conf.yml` | Open source |
| goose | AI coding agent | `command -v goose` | `brew install block/tap/goose` | `~/.config/goose/` | Block |
| amp | Sourcegraph agent | `command -v amp` | ampcode.com | `~/.amp/` | Sourcegraph |
| opencode | Go-based AI agent | `command -v opencode` | `go install github.com/opencode-ai/opencode@latest` | `opencode.json` | Open source |
| ollama | Local LLM runner | `command -v ollama` | `pacman -S ollama` | `~/.ollama/` | Local AI |
| llama-server | llama.cpp server | `command -v llama-server` | build from source | -- | Local AI |

---

## Editors & IDEs

| Tool | Description | Detect | Install (pacman) | Config | Notes |
|------|-------------|--------|-----------------|--------|-------|
| nvim | Neovim | `command -v nvim` | `pacman -S neovim` | `~/.config/nvim/` | Extensible, LSP |
| vim | Vim | `command -v vim` | `pacman -S vim` | `~/.vimrc` | Classic |
| emacs | GNU Emacs | `command -v emacs` | `pacman -S emacs` | `~/.emacs.d/` | Extensible |
| helix | Helix editor | `command -v hx` | `pacman -S helix` | `~/.config/helix/` | Modern, Rust |
| kakoune | Kakoune editor | `command -v kak` | `pacman -S kakoune` | `~/.config/kak/` | Modal |
| micro | Modern terminal editor | `command -v micro` | `pacman -S micro` | `~/.config/micro/` | Easy to use |
| nano | GNU nano | `command -v nano` | `pacman -S nano` | `~/.nanorc` | Simple |
| code | VS Code | `command -v code` | `pacman -S code` | `~/.config/Code/` | Extensions |
| cursor | Cursor IDE | `command -v cursor` | AUR/download | `~/.config/Cursor/` | AI-native |
| zed | Zed editor | `command -v zed` | AUR/download | `~/.config/zed/` | Fast, Rust |

---

## Terminal & Shell

| Tool | Description | Detect | Install (pacman) | Config | Integrates with |
|------|-------------|--------|-----------------|--------|----------------|
| bash | Bourne Again Shell | `command -v bash` | (preinstalled) | `~/.bashrc` | fzf, starship |
| zsh | Z Shell | `command -v zsh` | `pacman -S zsh` | `~/.zshrc` | oh-my-zsh, fzf, starship |
| fish | Friendly shell | `command -v fish` | `pacman -S fish` | `~/.config/fish/` | starship |
| nushell | Structured data shell | `command -v nu` | `pacman -S nushell` | `~/.config/nushell/` | starship |
| tmux | Terminal multiplexer | `command -v tmux` | `pacman -S tmux` | `~/.tmux.conf` | zsh, tpm |
| zellij | Modern multiplexer | `command -v zellij` | `pacman -S zellij` | `~/.config/zellij/` | any shell |
| starship | Cross-shell prompt | `command -v starship` | `pacman -S starship` | `~/.config/starship.toml` | any shell |
| fzf | Fuzzy finder | `command -v fzf` | `pacman -S fzf` | `~/.fzf.zsh` | zsh, bash, bat, fd |
| zoxide | Smart cd | `command -v zoxide` | `pacman -S zoxide` | -- | zsh, bash, fish |
| direnv | Per-directory envs | `command -v direnv` | `pacman -S direnv` | `.envrc` | any shell |
| atuin | Shell history search | `command -v atuin` | `pacman -S atuin` | `~/.config/atuin/` | zsh, bash, fish |

---

## File & Disk Utilities

| Tool | Description | Detect | Install (pacman) | Replaces | Integrates with |
|------|-------------|--------|-----------------|----------|----------------|
| fd | Fast find | `command -v fd` | `pacman -S fd` | find | fzf |
| ripgrep | Fast grep | `command -v rg` | `pacman -S ripgrep` | grep | fzf |
| fzf | Fuzzy finder | `command -v fzf` | `pacman -S fzf` | -- | fd, rg, bat, zsh |
| bat | Cat with wings | `command -v bat` | `pacman -S bat` | cat | fzf, delta, MANPAGER |
| eza | Modern ls | `command -v eza` | `pacman -S eza` | ls | -- |
| lsd | LSDeluxe | `command -v lsd` | `pacman -S lsd` | ls | -- |
| broot | Tree navigator | `command -v broot` | `pacman -S broot` | tree | -- |
| tree | Directory tree | `command -v tree` | `pacman -S tree` | -- | -- |
| ranger | File manager TUI | `command -v ranger` | `pacman -S ranger` | -- | bat, fzf |
| yazi | Fast file manager | `command -v yazi` | `pacman -S yazi` | ranger | bat, fd, rg |
| jq | JSON processor | `command -v jq` | `pacman -S jq` | -- | curl, API tools |
| yq | YAML processor | `command -v yq` | `pacman -S yq` | -- | jq |
| ncdu | Disk usage TUI | `command -v ncdu` | `pacman -S ncdu` | du | -- |
| dust | Visual disk usage | `command -v dust` | `pacman -S dust` | du | -- |
| duf | Disk free TUI | `command -v duf` | `pacman -S duf` | df | -- |
| rsync | File sync | `command -v rsync` | `pacman -S rsync` | cp | ssh |
| rclone | Cloud file sync | `command -v rclone` | `pacman -S rclone` | -- | cloud storage |

---

## Networking

| Tool | Description | Detect | Install (pacman) | Config | Notes |
|------|-------------|--------|-----------------|--------|-------|
| curl | HTTP client | `command -v curl` | `pacman -S curl` | `~/.curlrc` | Universal |
| wget | HTTP downloader | `command -v wget` | `pacman -S wget` | `~/.wgetrc` | Recursive downloads |
| xh | Friendly HTTP client | `command -v xh` | `pacman -S xh` | -- | httpie compatible |
| nmap | Network scanner | `command -v nmap` | `pacman -S nmap` | -- | Security |
| ssh | Secure shell | `command -v ssh` | `pacman -S openssh` | `~/.ssh/config` | Core networking |
| mosh | Mobile shell | `command -v mosh` | `pacman -S mosh` | -- | ssh alternative |
| tailscale | Mesh VPN | `command -v tailscale` | `pacman -S tailscale` | -- | Zero-config VPN |
| caddy | HTTP server | `command -v caddy` | `pacman -S caddy` | `Caddyfile` | Auto HTTPS |
| nginx | HTTP server | `command -v nginx` | `pacman -S nginx` | `/etc/nginx/` | Reverse proxy |
| socat | Socket relay | `command -v socat` | `pacman -S socat` | -- | Networking Swiss knife |

---

## Databases

| Tool | Description | Detect | Install (pacman) | Config | Notes |
|------|-------------|--------|-----------------|--------|-------|
| sqlite3 | SQLite CLI | `command -v sqlite3` | `pacman -S sqlite` | -- | Embedded DB |
| psql | PostgreSQL CLI | `command -v psql` | `pacman -S postgresql` | `~/.pgpass` | PostgreSQL |
| mysql | MySQL CLI | `command -v mysql` | `pacman -S mariadb-clients` | `~/.my.cnf` | MySQL/MariaDB |
| redis-cli | Redis CLI | `command -v redis-cli` | `pacman -S redis` | -- | Redis |
| mongosh | MongoDB shell | `command -v mongosh` | AUR | -- | MongoDB |
| pgcli | Enhanced psql | `command -v pgcli` | `pacman -S pgcli` | `~/.config/pgcli/` | psql alternative |
| mycli | Enhanced mysql | `command -v mycli` | `pip install mycli` | `~/.myclirc` | mysql alternative |
| litecli | Enhanced sqlite3 | `command -v litecli` | `pip install litecli` | -- | sqlite3 alternative |
| usql | Universal SQL CLI | `command -v usql` | `go install github.com/xo/usql@latest` | -- | Any database |

---

## Monitoring & Debugging

| Tool | Description | Detect | Install (pacman) | Notes |
|------|-------------|--------|-----------------|-------|
| htop | Process viewer | `command -v htop` | `pacman -S htop` | Classic |
| btop | Resource monitor | `command -v btop` | `pacman -S btop` | Beautiful |
| glances | System monitor | `command -v glances` | `pacman -S glances` | Python, web UI |
| gotop | Go system monitor | `command -v gotop` | AUR | Minimal |
| bottom | Rust system monitor | `command -v btm` | `pacman -S bottom` | Cross-platform |
| strace | Syscall tracer | `command -v strace` | `pacman -S strace` | Linux debugging |
| gdb | GNU debugger | `command -v gdb` | `pacman -S gdb` | C/C++ debugging |
| dlv | Go debugger | `command -v dlv` | `pacman -S delve` | Go debugging |
| lnav | Log navigator | `command -v lnav` | `pacman -S lnav` | Log analysis |
| perf | Linux profiler | `command -v perf` | `pacman -S perf` | Performance |

---

## Media & Documents

| Tool | Description | Detect | Install (pacman) | Notes |
|------|-------------|--------|-----------------|-------|
| ffmpeg | Media transcoder | `command -v ffmpeg` | `pacman -S ffmpeg` | Universal media tool |
| imagemagick | Image processor | `command -v convert` | `pacman -S imagemagick` | Batch image ops |
| mpv | Media player | `command -v mpv` | `pacman -S mpv` | Minimal, scriptable |
| yt-dlp | Video downloader | `command -v yt-dlp` | `pacman -S yt-dlp` | YouTube + more |
| pandoc | Document converter | `command -v pandoc` | `pacman -S pandoc` | Markdown, LaTeX, etc. |
| typst | Modern typesetting | `command -v typst` | `pacman -S typst` | LaTeX alternative |

---

## System Utilities

| Tool | Description | Detect | Install (pacman) | Notes |
|------|-------------|--------|-----------------|-------|
| inxi | System info | `command -v inxi` | `pacman -S inxi` | Hardware report |
| fastfetch | System info display | `command -v fastfetch` | `pacman -S fastfetch` | Fast neofetch |
| neofetch | System info display | `command -v neofetch` | `pacman -S neofetch` | Classic (archived) |
| lsblk | Block devices | `command -v lsblk` | (preinstalled) | Disk layout |
| smartctl | Disk health | `command -v smartctl` | `pacman -S smartmontools` | SMART data |
| ufw | Uncomplicated firewall | `command -v ufw` | `pacman -S ufw` | Simple firewall |
| lynis | Security auditing | `command -v lynis` | `pacman -S lynis` | System hardening |
