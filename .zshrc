#
#  _._     _,-'""`-._
# (,-.`._,'(       |\`-/|
#     `-.-' \ )-`( , o o)
#            `-   \`_`"'-
#

if (( DEBUG )); then
    set -x
fi

# tmux
if (( $+commands[tmux] && ! $+TMUX && $+ALACRITTY_WINDOW_ID )); then
    s=alacritty-$$
    tmux has -t $s 2>/dev/null && exec tmux attach -t $s
    exec tmux new -s $s
fi

if (( $+commands[tmux] && ! $+TMUX && $+SSH_CONNECTION )); then
    s=ssh
    tmux has -t $s 2>/dev/null && exec tmux attach -t $s
    exec tmux new -s $s
fi

# path
typeset -U path
path+=(~/bin(N-/) ~/.local/bin(N-/) ~/.local/share/bin(N-/))

typeset -U fpath
fpath+=(~/.local/share/zsh/site-functions(N-/))

typeset -U cdpath
cdpath+=(~ ~/src(N-/))

# options
bindkey -e

setopt EXTENDED_GLOB
setopt NULL_GLOB

# history
export HISTFILE=~/.zsh_history
export SAVEHIST=100000
export HISTSIZE=$((SAVEHIST + 1))

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

alias history='fc -dl -t "%Y-%m-%d %H:%M:%S"'

# keybindings
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
autoload -Uz select-word-style
select-word-style shell
zstyle ':zle:my-backward-word' word-style unspecified
zstyle ':zle:my-backward-word' word-chars ' /=;@:{}[]()<>,|.'
function my-backward-word() { zle backward-word }
zle -N my-backward-word
bindkey 'b' my-backward-word

zstyle ':zle:my-forward-word' word-style unspecified
zstyle ':zle:my-forward-word' word-chars ' /=;@:{}[]()<>,|.'
function my-forward-word() { zle forward-word }
zle -N my-forward-word
bindkey 'f' my-forward-word

zstyle ':zle:my-backward-kill-word' word-style unspecified
zstyle ':zle:my-backward-kill-word' word-chars ' /=;@:{}[]()<>,|.'
function my-backward-kill-word() { zle backward-kill-word }
zle -N my-backward-kill-word
bindkey 'w' my-backward-kill-word

function clear_screen_and_scrollback() { printf '\x1Bc'; zle clear-screen }
zle -N clear_screen_and_scrollback
bindkey '' clear_screen_and_scrollback

# completion
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# terminal
function reset_broken_terminal() { printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8' }
precmd_functions+=(reset_broken_terminal)

# functions
function src-all() {
    local f
    for f; do [[ ! -f $f.zwc || $f -nt $f.zwc ]] && zcompile -U $f & done
    for f; do source $f; done
    wait
}

export ZSH_PLUGIN_DIR=${ZSH_PLUGIN_DIR:-~/.local/share/zsh/plugins}
typeset -ga PLUGIN_SRC_FILES

function get-plug() {
    local repo=$1 p=$ZSH_PLUGIN_DIR/$1; shift
    [[ -e $p ]] || git clone --depth=1 https://github.com/$repo $p || { print -u2 "get-plug: clone failed: $repo"; return 1 }
    if (( $# )); then
        PLUGIN_SRC_FILES+=(${@/#/$p/})
    else
        PLUGIN_SRC_FILES+=($p/**/*.plugin.zsh(N-))
    fi
}

function src-plug() {
    find $ZSH_PLUGIN_DIR -name FETCH_HEAD -mtime +7 | sed 's,/.git/FETCH_HEAD,,' | \
        xargs -I{} git -C {} pull --ff-only
    src-all $PLUGIN_SRC_FILES
}

function eval-cache() {
    local cmd=$1 evalfile=~/.local/share/zsh/eval/${1%% *}.zsh cmdfile=$evalfile.cmd
    mkdir -p ${evalfile:h}
    if [[ ! -f $cmdfile ]]; then
        eval $cmd 2>/dev/null > $evalfile && eval $cmd 2>/dev/null > $cmdfile
        zcompile $evalfile 2>/dev/null
    fi
    source $evalfile 2>/dev/null
}

function comp-cache() {
    local cmd=$1 compfile=~/.local/share/zsh/site-functions/_${1%% *} cmdfile=$compfile.cmd
    mkdir -p ${compfile:h}
    if [[ ! -f $cmdfile ]]; then
        eval $cmd 2>/dev/null > $compfile && eval $cmd 2>/dev/null > $cmdfile
        zcompile $compfile 2>/dev/null
    fi
}

# plugins
get-plug zsh-users/zsh-completions
get-plug zsh-users/zsh-autosuggestions
get-plug zsh-users/zsh-syntax-highlighting
get-plug zsh-users/zaw
get-plug sorin-ionescu/prezto modules/{command-not-found,completion}/init.zsh

# prompt
PURE_PROMPT_SYMBOL='›'
PURE_PROMPT_VICMD_SYMBOL='‹'

zstyle ':prompt:pure:git:stash' show yes

zstyle ':prompt:pure:git:aws' show yes
zstyle ':prompt:pure:aws' color 97

zstyle ':prompt:pure:git:gcp' show yes
zstyle ':prompt:pure:gcp' color 4

zstyle ':prompt:pure:git:kubernetes' show yes
zstyle ':prompt:pure:kubernetes' color 232

zstyle ':prompt:pure:prompt:success' color green
zstyle ':prompt:pure:prompt:error' color red

#get-plug sindresorhus/pure {async,pure}.zsh
get-plug aaaooai/pure {async,pure}.zsh

src-plug

# aliases
alias relogin='exec zsh -l'
alias ls='ls -Xv --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias mv='mv -vb'
alias cp='cp -vb'
export GPG_TTY=$(tty)

function mkcd() { install -Dd "$1" && cd "$1" }

# dotfiles
alias dotfiles='git --git-dir ~/.dotfiles --work-tree ~'
compdef dotfiles=git

if [[ ! -d ~/.dotfiles ]]; then
    git config --global init.defaultBranch main
    git config --global user.name $USER
    git config --global user.email $USER@$HOST
    dotfiles init
    dotfiles config pull.rebase false
    dotfiles config status.showUntrackedFiles no
    dotfiles remote add origin https://github.com/aaaooai/dotfiles.git
    dotfiles fetch
    dotfiles reset --hard origin/main
fi

if (( $+commands[cargo] )); then
    path+=(~/.cargo/bin(N-/))
fi

if (( $+commands[emacs] )); then
    alias emacs='emacsclient -a emacs -t'
fi

if (( $+commands[ghq] )); then
    cdpath+=(~/ghq(N-/))
    function zaw-src-ghq-repos() {
        candidates=(${(@)$(ghq list)})
        actions=("zaw-ghq-cd")
    }
    function zaw-ghq-cd() {
        BUFFER="cd '$1'"
        zle accept-line
    }
    zaw-register-src -n ghq-repos zaw-src-ghq-repos
    bindkey 'g' zaw-ghq-repos
fi

if (( $+commands[nnn] )); then
    export NNN_OPTS=acdo

    if (( $+commands[trash] )); then
        export NNN_TRASH=1
    fi

    typeset -TUx NNN_BMS nnn_bms \;
    nnn_bms=(m:/run/media/$USER)

    typeset -TUx NNN_PLUG nnn_plug \;
    nnn_plug=(a:recadd d:recdel s:recstopskip)

    if [[ ! -f ~/.config/nnn/plugins/.nnn-plugin-helper ]]; then
        curl -fsSL https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh
    fi
fi

if (( $+commands[pass] )); then
    export PASSWORD_STORE_ENABLE_EXTENSIONS=true
fi

if (( $+commands[vim] )); then
    export EDITOR=vim
fi

# local
() { src-all $@ } ~/.zshrc.*~*.zwc~*~

unfunction src-all get-plug src-plug eval-cache comp-cache

if (( DEBUG )); then
    set +x
fi
