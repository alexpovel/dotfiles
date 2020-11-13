# Put this file somewhere you like, then:
# `ln --symbolic ~/path/to/this/file/.zshrc ~/.zshrc`
# and restart your shell.

# =====================================================================================
# General
# =====================================================================================

# "user@machine" prompt is hidden if $USER==$DEFAULT_USER, see prompt_context
DEFAULT_USER=alex

# =====================================================================================
# PATH
# Adds to `path` array, see https://stackoverflow.com/a/30792333/11477374
# =====================================================================================

path_candidates=(
    # Get e.g. Python tools installed via pip to work:
    "${HOME}/.local/bin"
    # Python dependency management tool:
    "${HOME}/.poetry/bin"
)

for path_candidate in "${path_candidates[@]}"; do
    if [ -d ${path_candidate} ]; then
        path+=${path_candidate}
    fi
done


# Add required by manually installing TeXLive via install-tl.
# That setup also has an option to adjust the PATHs manually, better use that.
THIS_YEAR=$(date +%Y)
TEX_LIVE_DIR="/usr/local/texlive/${THIS_YEAR}/bin/x86_64-linux"
if [ -d ${TEX_LIVE_DIR} ]; then
    path+=${TEX_LIVE_DIR}
    manpath+="/usr/local/texlive/${THIS_YEAR}/texmf-dist/doc/man"
    infopath+="/usr/local/texlive/${THIS_YEAR}/texmf-dist/doc/info"
    echo "Added TeXLive to (MAN/INFO)-PATH"
fi

# =====================================================================================
# Other environment variables
# =====================================================================================

# Pyenv is a Python virtual environments management tool
PYENV_ROOT="${HOME}/.pyenv"

if [ -d ${PYENV_ROOT} ]; then
    export PYENV_ROOT=${PYENV_ROOT}
    path+="${PYENV_ROOT}/bin"
    if command -v pyenv 1>/dev/null 2>&1; then
        # Manipulates PATH during initialization:
        eval "$(pyenv init -)"
    fi
fi

# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# =====================================================================================
# Theme
# =====================================================================================

ZSH_THEME="agnoster"

# =====================================================================================
# Plugin
# =====================================================================================

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# Plugins also here: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/
plugins=(
    # Colorize `man`:
    colored-man-pages
    # Provide ccat and cless for syntax highlighting:
    colorize
    # If command not found, suggests what package to install:
    command-not-found
    # Autocompletion:
    docker
    # Autocompletion and aliases:
    docker-compose
    # Aliases up the bazzoo as well as nice graphic displays:
    git
    # Suggests (previous) commands while typing, see
    # https://github.com/zsh-users/zsh-autosuggestions:
    zsh-autosuggestions
    # Syntax highlighting for the input prompt, see
    # https://github.com/zsh-users/zsh-syntax-highlighting:
    zsh-syntax-highlighting
)

# colorize plugin style picker for pygmentize.
# See available styles with:
# `python -c "from pygments.styles import STYLE_MAP; print(STYLE_MAP.keys())"`
ZSH_COLORIZE_STYLE="monokai"

# =====================================================================================
# Custom aliases
# =====================================================================================

# Colorize by default. Slow as heck but possibly worth the wait:
alias cat=ccat

# Debian has a distinction and still uses Python 2 for its main Python commands:
if command -v ipython3 1>/dev/null 2>&1; then
    alias pi=ipython3
else
    alias pi=ipython
fi

# A top-like overview for Docker containers.
# Makes sense to run via Docker because what are you gonna look at it Docker isn't
# available and running?
# https://github.com/bcicen/ctop
alias ctop="docker run --rm -ti --name=ctop --volume /var/run/docker.sock:/var/run/docker.sock:ro quay.io/vektorlab/ctop"

# =====================================================================================
# Apply
# =====================================================================================

source ${ZSH}/oh-my-zsh.sh

# =====================================================================================
# Other
# Left over from initial .zshrc template
# =====================================================================================

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder
