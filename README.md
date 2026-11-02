# DotFiles

My config files, and a list of the apps I use (`APPS.md`). No install scripts: on a new machine,
pick what is needed from `APPS.md`, install it with that system's package manager, then copy the
configs below into place.

Copied from my Fedora 44 desktop on 2026-11-02.

## What goes where

| in this repo | goes to | for |
|---|---|---|
| `zsh/.zshrc` | `~/.zshrc` | zsh with oh-my-zsh |
| `git/.gitconfig` | `~/.gitconfig` | git, with delta as the pager |
| `nvim/` | `~/.config/nvim/` | Neovim (NvChad v2.5) |
| `kitty/` | `~/.config/kitty/` | kitty |
| `tmux/.tmux.conf` | `~/.tmux.conf` | tmux |
| `zellij/config.kdl` | `~/.config/zellij/config.kdl` | zellij |
| `ghostty/config` | `~/.config/ghostty/config` | ghostty |
| `alacritty/dank-theme.toml` | `~/.config/alacritty/dank-theme.toml` | alacritty theme |

Copy one:

```bash
cp zsh/.zshrc ~/.zshrc
mkdir -p ~/.config/nvim && cp -r nvim/. ~/.config/nvim/
```

Or link it, so edits land in the repo:

```bash
ln -sf "$PWD/zsh/.zshrc" ~/.zshrc
ln -sfn "$PWD/nvim" ~/.config/nvim
```

## zsh

`.zshrc` needs oh-my-zsh and three plugins that are not part of it, cloned into
`~/.oh-my-zsh/custom/plugins/`:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting
git clone https://github.com/Aloxaf/fzf-tab ~/.oh-my-zsh/custom/plugins/fzf-tab
```

It also calls `zoxide`, `direnv`, `atuin`, `fzf`, `eza`, `bat` and `trash-cli`; see `APPS.md`.
Settings for one machine only (work paths, hosts, aliases like `hqt`) go in `~/.zshrc.local`,
which `.zshrc` sources if it exists. It is not in this repo.

After `atuin` is installed, `atuin import zsh` loads the old `~/.zsh_history` into it.
After `tealdeer` is installed, `tldr --update` downloads the pages.

### Keys

| key | does |
|---|---|
| Ctrl-R | search history (atuin; Ctrl-R again inside it switches global / this folder / this session) |
| Ctrl-T | pick a file with fzf and paste its path |
| Alt-C | pick a folder with fzf and cd into it |
| Tab | completions in an fzf list (fzf-tab) |
| Ctrl-X Ctrl-E | edit the current command in nvim |

### Aliases

| alias | runs |
|---|---|
| `dc`, `cd..`, `sl`, `gti`, `exti` | typos of `cd`, `cd ..`, `ls`, `git`, `exit` |
| `ls`, `ll`, `lt` | eza: list, long list with git status, tree two levels deep |
| `cat` | `bat -pp` (colours, no pager) |
| `del` | `trash-put` (to the trash; `trash-list`, `trash-restore` bring it back) |
| `z <part>`, `j <part>` | jump to the most used folder that matches |
| `zi`, `ji` | pick the folder from a list |
| `lg` | lazygit |
| `docker` | podman |
| `ptui` | podman-tui |
| `port <host> <port>` | `nc -vz`: is the port open |
| `hq` | harlequin (SQL TUI) |
| `nv` | nvim |
| `copy` | xclip to the clipboard |
| `dl` | aria2c with 16 connections |
| `todo` | topydo |

## git

`.gitconfig` has no `[user]`: it includes `~/.gitconfig.local`, which holds the name and email
for that machine:

```ini
[user]
	email = you@example.com
	name = you
```

`delta` shows diffs with syntax colours and line numbers in `git diff`, `git show` and `git log -p`.
`n` and `N` jump between files. Merge conflicts use the `zdiff3` style (shows the common base).
