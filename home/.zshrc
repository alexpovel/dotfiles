# =====================================================================================
# General
# =====================================================================================

export ZSH=$HOME/.oh-my-zsh

# =====================================================================================
# Plugins
# =====================================================================================

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)

plugins=(
    azure
    colored-man-pages
    docker
    git
    ripgrep
    rust
    terraform
    zsh-autosuggestions
    zsh-syntax-highlighting
)

export ZSH_COLORIZE_STYLE="dracula"

# =====================================================================================
# Custom functions
# =====================================================================================

# Gets current git repository's root directory, if possible. Use as `z `rr``, for
# example. Works with Tab completion.
alias rr='git rev-parse --show-toplevel 2>/dev/null || pwd'

pullall() {
    gh auth status 1>/dev/null 2>&1 || gh auth login

    local USER="$1"

    gh repo list "$USER" --limit 1000 | while read -r repo _; do
        gh repo clone "$repo" "$repo" || (
            cd "$repo"

            for branch in 'main' 'master' 'dev' 'devel'; do
                # Need to be on a branch to pull; first one found wins.
                git switch "$branch" && break
            done

            git pull --all || echo "Failed to pull $repo"
        )
    done
}

# =====================================================================================
# Custom aliases
# =====================================================================================

if command -v ipython3 1>/dev/null 2>&1; then
    alias pi=ipython3
else
    alias pi=ipython
fi

alias c=cargo

erd() {
    command erd --human "$@"
}
alias tree="erd"

# https://github.com/bcicen/ctop
alias ctop="docker run --rm -ti --name=ctop --volume /var/run/docker.sock:/var/run/docker.sock:ro quay.io/vektorlab/ctop"

# =====================================================================================
# Path adjustments
# =====================================================================================

GOPATH=~/go

# Needs to be lowercase. `path` is the array, `PATH` is the env var.
path+=("/usr/local/go/bin")

# Target location of `go install`:
path+=("$GOPATH/bin")

export PATH

# =====================================================================================
# Credentials
# =====================================================================================

export OPENAI_API_KEY="$(cat ${HOME}/.open-ai.api-key)"

# =====================================================================================
# pyenv
# =====================================================================================

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# =====================================================================================
# Apply
# =====================================================================================

source ${ZSH}/oh-my-zsh.sh

# =====================================================================================
# fzf tooling
# =====================================================================================

if command -v fzf 1>/dev/null 2>&1; then
    # https://github.com/junegunn/fzf/issues/1866#issuecomment-585176100
    source $(dpkg -L fzf | grep 'completion.*\.zsh')
    source $(dpkg -L fzf | grep 'bindings.*\.zsh')
fi

# =====================================================================================
# Other
# =====================================================================================

if [ -f /var/run/reboot-required ]; then
  echo "\e[31mOutstanding reboot detected.\e[0m"
fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(keychain --eval id_ed25519)"
eval "$(github-copilot-cli alias -- "$0")"
eval "$(erd --completions zsh)"
eval "$(direnv hook zsh)"
