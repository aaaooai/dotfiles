#
#  _._     _,-'""`-._
# (,-.`._,'(       |\`-/|
#     `-.-' \ )-`( , o o)
#            `-   \`_`"'-
#

if (( DEBUG )); then
    set -x
fi

if (( $+commands[tmux] && $+SSH_CONNECTION && ! $+TMUX )); then
    tmux has -t ssh 2>/dev/null && exec tmux attach -t ssh
    exec tmux new -s ssh
fi

typeset -U path
path+=(~/bin(N-/) ~/.local/bin(N-/) ~/.local/share/bin(N-/))

typeset -U fpath
fpath+=(~/.local/share/zsh/site-functions(N-/))

typeset -U cdpath
cdpath+=(~ ~/src(N-/))

bindkey -e

setopt EXTENDED_GLOB
setopt NULL_GLOB

export HISTFILE=~/.zsh_history
export SAVEHIST=100000
export HISTSIZE=$((SAVEHIST + 1))

setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY

alias history='fc -dl -t "%Y-%m-%d %H:%M:%S"'

bindkey  history-incremental-pattern-search-backward
bindkey  history-incremental-pattern-search-forward
bindkey  history-beginning-search-backward
bindkey  history-beginning-search-forward

autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
else
        compinit -C
fi

autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

autoload -Uz select-word-style
select-word-style shell

zstyle ':zle:my-backward-word' word-style unspecified
zstyle ':zle:my-backward-word' word-chars ' /=;@:{}[]()<>,|.'
function my-backward-word() { zle backward-word }
zle -N my-backward-word
bindkey b my-backward-word

zstyle ':zle:my-forward-word' word-style unspecified
zstyle ':zle:my-forward-word' word-chars ' /=;@:{}[]()<>,|.'
function my-forward-word() { zle forward-word }
zle -N my-forward-word
bindkey f my-forward-word

zstyle ':zle:my-backward-kill-word' word-style unspecified
zstyle ':zle:my-backward-kill-word' word-chars ' /=;@:{}[]()<>,|.'
function my-backward-kill-word() { zle backward-kill-word }
zle -N my-backward-kill-word
bindkey w my-backward-kill-word

function clear_screen_and_scrollback() { printf '\x1Bc'; zle clear-screen }
zle -N clear_screen_and_scrollback
bindkey  clear_screen_and_scrollback

function reset_broken_terminal() { printf '%b' '\e[0m\e(B\e)0\017\e[?5l\e7\e[0;0r\e8' }
precmd_functions+=(reset_broken_terminal)

function zcompile-all() {
    local f
    for f; do [[ ! -f $f.zwc || $f -nt $f.zwc ]] && zcompile -U $f; done
}

function src-all() {
    local f
    for f; do source $f; done
}

function src-plug() {
    local r=https://github.com/$1 p=~/.local/share/zsh/plugins/$1; shift
    if [[ ! -e $p ]]; then
        git clone --depth=1 $r $p
        zcompile-all $p/*.zsh(N-) $p/**/*.zsh(N-)
    fi
    if (( $# )); then
        src-all ${@/#/$p/}(N-)
    else
        src-all $p/*.plugin.zsh(N-)
    fi
}

function eval-cache() {
    local cmd=$1 evalfile=~/.local/share/zsh/eval/${1%% *}.zsh
    if [[ ! -s $evalfile ]]; then
        install -Dm0644 /dev/null $evalfile
        eval $cmd > $evalfile
        zcompile $evalfile
    fi
    source $evalfile
}

function comp-cache() {
    local cmd=$1 compfile=~/.local/share/zsh/site-functions/_${1%% *}
    if [[ ! -s $compfile ]]; then
        install -Dm0644 /dev/null $compfile
        eval $cmd > $compfile
        zcompile $compfile
    fi
}

src-plug zsh-users/zsh-completions
src-plug zsh-users/zsh-autosuggestions
src-plug zsh-users/zsh-syntax-highlighting
src-plug zsh-users/zaw
src-plug sorin-ionescu/prezto modules/{command-not-found,completion}/init.zsh

PURE_PROMPT_SYMBOL='›'
PURE_PROMPT_VICMD_SYMBOL='‹'

zstyle ':prompt:pure:git:stash' show yes
zstyle ':prompt:pure:prompt:success' color green
zstyle ':prompt:pure:prompt:error' color red

src-plug sindresorhus/pure {async,pure}.zsh

alias relogin='exec zsh -l'
alias ls='ls -Xv --color=auto --group-directories-first'
alias grep='grep --color=auto'
alias mv='mv -vb'
alias cp='cp -vb'

function mkcd() { install -Dd "$1" && cd "$1" }

alias dotfiles='git --git-dir ~/.dotfiles --work-tree ~'
compdef dotfiles=git

if [[ ! -d ~/.dotfiles ]]; then
    git config --global init.defaultBranch main
    git config --global user.name $USER
    git config --global user.email $USER@$HOST
    dotfiles init
    dotfiles config pull.rebase false
    dotfiles config status.showUntrackedFiles no
    dotfiles remote add origin git@github.com:aaaooai/dotfiles.git
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
    bindkey g zaw-ghq-repos
fi

if (( $+commands[mise] )); then
    eval-cache 'mise activate zsh'
fi

if (( $+commands[niri] )); then
   comp-cache 'niri completions zsh'
fi

if (( $+commands[nnn] )); then
    export NNN_OPTS=acdo

    if (( $+commands[trash] )); then
        export NNN_TRASH=1
    fi

    typeset -TUx NNN_BMS nnn_bms \;
    typeset -TUx NNN_PLUG nnn_plug \;

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

() { zcompile-all $@; src-all $@ } ~/.zshrc.*~*.zwc~*~

unfunction zcompile-all src-all src-plug eval-cache comp-cache

if (( DEBUG )); then
    set +x
fi
