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
    # Colorize `man`:
    colored-man-pages
    # Autocompletion:
    docker
    # Aliases etc.:
    git
    # Suggests (previous) commands while typing, see
    # https://github.com/zsh-users/zsh-autosuggestions:
    zsh-autosuggestions
    # Syntax highlighting for the input prompt, see
    # https://github.com/zsh-users/zsh-syntax-highlighting:
    zsh-syntax-highlighting
)

export ZSH_COLORIZE_STYLE="dracula"

# =====================================================================================
# Custom aliases
# =====================================================================================

if command -v ipython3 1>/dev/null 2>&1; then
    alias pi=ipython3
else
    alias pi=ipython
fi

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
# Apply
# =====================================================================================

source ${ZSH}/oh-my-zsh.sh

# =====================================================================================
# Other
# =====================================================================================

if [ -f /var/run/reboot-required ]; then
  echo "\e[31mOutstanding reboot detected.\e[0m"
fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval $(keychain --eval id_ed25519)
