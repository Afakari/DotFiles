# Apps

What I had on my Fedora 44 KDE desktop on 2026-11-02. A reminder, not a script: pick what a new
machine needs and install it with its package manager.

The name is the same in dnf, pacman, apt and brew unless the "other names" column says otherwise.
"—" means it is not in that manager's main repos; use the way in "how".

## Shell and terminal

| app | for | other names / how |
|---|---|---|
| zsh | shell | |
| oh-my-zsh | zsh framework | installer script; plugins in `README.md` |
| kitty | terminal (main) | brew: `--cask kitty` |
| ghostty | terminal (not installed now; config kept) | dnf: copr `scottames/ghostty`; brew: `--cask ghostty` |
| alacritty | terminal | brew: `--cask alacritty` |
| tmux | terminal multiplexer | |
| zellij | terminal multiplexer | I used the GitHub release binary in `/usr/local/bin`; pacman, brew: `zellij` |
| neovim | editor (NvChad) | |
| fzf | fuzzy finder | |
| ripgrep | `rg`, search in files | |
| fd | find files | dnf, apt: `fd-find` (apt binary is `fdfind`) |
| bat | `cat` with colours | apt binary is `batcat` |
| eza | `ls` replacement | apt: Debian 13+ / Ubuntu 24.04+ |
| zoxide | `z`, jump to folders | |
| atuin | shell history in SQLite | apt: — (`curl -sSf https://setup.atuin.sh \| sh`) |
| direnv | per-folder env from `.envrc` | |
| tealdeer | `tldr`, short command examples | |
| trash-cli | `trash-put`, delete to the trash | |
| btop | process and resource monitor | |
| jq | JSON on the command line | |
| yq | YAML on the command line | pacman: `go-yq` (the Go one, same as Fedora's) |
| tree | folder tree | |
| xclip | clipboard from the shell | Wayland: `wl-clipboard` |
| aria2 | `aria2c`, fast downloads | |
| rsync, wget, curl, unzip, unrar, zip | files and downloads | unrar: rpmfusion on Fedora |
| topydo | todo.txt CLI | pip/uv: `uv tool install topydo` |

## Development

| app | for | other names / how |
|---|---|---|
| git | | |
| git-delta | diff pager | brew, pacman, dnf: `git-delta`; apt: Debian 13+ |
| lazygit | git TUI | dnf: copr `atim/lazygit` or `go install github.com/jesseduffield/lazygit@latest` |
| gitui | git TUI | |
| uv | Python versions, venvs, tools | apt: — (`curl -LsSf https://astral.sh/uv/install.sh \| sh`) |
| ruff, ty | Python lint and type check | or `uv tool install ruff ty` |
| go | | dnf, apt: `golang` |
| rustup | Rust toolchains | then `rustup default stable` |
| Temurin JDK 17, 21, 25 | Java | dnf/apt: Adoptium repo, `temurin-21-jdk`; pacman: `jdk-openjdk`; brew: `--cask temurin` |
| maven | Java builds | |
| cmake, ninja, gcc-c++ | C/C++ builds | apt: `ninja-build`, `g++`; pacman: `ninja`, `gcc` |
| nvm + Node 22 | Node | nvm installer script; or `fnm` |
| VS Code | editor | dnf/apt: Microsoft repo, `code`; brew: `--cask visual-studio-code` |
| JetBrains IDEA, PyCharm, GoLand, DataGrip, Rider, RustRover | IDEs | JetBrains Toolbox; I had them in `/opt` |
| android-tools | `adb`, `fastboot` | |
| subversion, doxygen | | |
| Claude Code, opencode | coding agents | their own installers |

## Containers

| app | for | other names / how |
|---|---|---|
| podman | containers (aliased as `docker`) | |
| podman-compose | compose files | |
| podman-tui | containers TUI | |
| dive | look inside image layers | dnf: — (`go install github.com/wagoodman/dive@latest`) |
| toolbox | dev containers on Fedora | Fedora only; `distrobox` elsewhere |
| Podman Desktop | GUI | flatpak `io.podman_desktop.PodmanDesktop` |

## Data

| app | for | other names / how |
|---|---|---|
| dbt (dbt-core + dbt-trino) | dbt | per project with `uv`; `~/.local/bin/dbt` |
| Trino CLI | `trino` | executable jar from Maven Central (`io.trino:trino-cli`, newest there is 476); needs Java |
| MariaDB client | `mariadb`, also talks to StarRocks | dnf: `mariadb`; pacman: `mariadb-clients`; apt: `mariadb-client`; brew: `mariadb` |
| harlequin | SQL TUI | `uv tool install harlequin --with harlequin-trino --with harlequin-mysql` |
| Kafka CLI tools | `kafka-*.sh` | Apache tarball in `/opt/kafka` |
| DataGrip | SQL IDE | see JetBrains above |

## Network

| app | for | other names / how |
|---|---|---|
| mtr | ping + traceroute | apt: `mtr-tiny` (no GUI) |
| nmap, ncat | scans, `nc` | dnf: `nmap-ncat` for `nc`; apt: `ncat` |
| tcpdump, traceroute, whois, telnet | | |
| bind-utils | `dig`, `nslookup` | apt: `dnsutils`; pacman: `bind`; brew: `bind` |
| wireguard-tools | `wg` | |
| proxychains-ng | send a command through a proxy | apt: `proxychains4` |
| sshpass | ssh with a password from a script | |
| openconnect-saml | Cisco VPN with SAML login | `uv tool install openconnect-saml` |
| v2rayN | proxy client | GitHub release (in `/opt/v2rayN`) |

## Desktop

| app | for | other names / how |
|---|---|---|
| KDE Plasma | desktop | Fedora KDE spin |
| niri | scrolling tiling Wayland compositor | |
| DankMaterialShell | shell / bar for niri (`dms`) | dnf: in Fedora 44 |
| Firefox, Chromium, Google Chrome, Waterfox | browsers | Chrome: Google repo; Waterfox: OBS repo `isv:BrowserWorks` |
| Telegram | chat | flatpak `org.telegram.desktop` |
| NeoChat | Matrix chat | |
| LibreOffice | office | |
| Okular, Gwenview, KolourPaint, Spectacle | PDF, images, paint, screenshots | |
| Guitarix | guitar amp | |
| RustDesk | remote desktop | flatpak `com.rustdesk.RustDesk` |
| AnyDesk | remote desktop | AnyDesk repo |
| NoMachine | remote desktop | `nomachine-personal-edition`, from nomachine.com |
| Sunshine | game streaming host | dnf: copr `lizardbyte/stable` |
| KDE Connect | phone link | |

## Repos added on Fedora

rpmfusion (free, nonfree, nvidia driver, steam), Adoptium (Temurin), Google Chrome, VS Code,
copr `lizardbyte/stable` (Sunshine), copr `phracek/PyCharm`, OBS `isv:BrowserWorks` (Waterfox).
