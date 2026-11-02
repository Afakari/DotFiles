export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
ZSH_DISABLE_COMPFIX="true"

# Machine-only settings (work paths, hosts, aliases): not in the dotfiles repo.
# Sourced before oh-my-zsh, so fpath entries there reach its compinit.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# nvm loads on the first node/npm/nvm call instead of at startup.
zstyle ':omz:plugins:nvm' lazy yes

# fzf-tab must come before the plugins that wrap widgets (autosuggestions, highlighting).
plugins=(git nvm fzf fzf-tab zsh-autosuggestions fast-syntax-highlighting colored-man-pages)

zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'

source $ZSH/oh-my-zsh.sh

HISTSIZE=1000000
SAVEHIST=1000000

git_prompt_info() {
if git rev-parse --is-inside-work-tree &>/dev/null; then
local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
echo "%B%F{cyan}(git%B%F{cyan}::%B%F{red}${branch}%F{cyan})%F{reset}"
fi
}

PS1='%F{%(#.cyan.green)}┌──${debian_chroot:+($debian_chroot)─}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))─}(%B%F{%(#.magenta.yellow)}%n㉿%m%b%F{%(#.cyan.green)})-[%B%F{blue}%(6~.%-1~/…/%4~.%5~)%b%F{%(#.cyan.green)}]%F{reset} $(git_prompt_info)
%F{green}└─%B%(#.%F{magenta}#.%F{purple}$)%b%F{reset}%F{yellow}'

export PATH=$HOME/.opencode/bin:$PATH:$HOME/.local/bin:$HOME/go/bin:/opt/kafka/bin:$HOME/.cargo/bin
export CLASSPATH=".:/usr/local/lib/antlr-4.9.2-complete.jar:$CLASSPATH"

# Ctrl-X Ctrl-E: edit the current command in $EDITOR.
export EDITOR=nvim
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
# After oh-my-zsh, so atuin owns Ctrl-R. The up arrow stays plain history.
eval "$(atuin init zsh --disable-up-arrow)"

# --- aliases ---

# typos
alias dc='cd'
alias cd..='cd ..'
alias sl='ls'
alias gti='git'
alias exti='exit'

# files
alias ls='eza --group-directories-first'
alias ll='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'
alias cat='bat -pp'
alias del='trash-put'
alias grep='grep --color=auto'

# jump (zoxide): z <part of a path>, zi to pick from a list
alias j='z'
alias ji='zi'

# git and containers
alias lg='lazygit'
alias docker='podman'
alias ptui='podman-tui'

# network: port <host> <port>
port() { nc -vz -w 3 "$1" "$2"; }

# databases
alias hq='harlequin'

# other
alias d='date'
alias nv='nvim'
alias copy='xclip -selection clipboard'
alias dl='aria2c -x 16 -j 1 -c -s 16 -k 1M'
alias todo='topydo'
alias dbtf="$HOME/.local/bin/dbt"
alias antlr4='java-temurin -Xmx500M -cp "/usr/local/lib/antlr-4.9.2-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
alias grun='java-temurin -Xmx500M -cp "/usr/local/lib/antlr-4.9.2-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'
