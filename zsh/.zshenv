# See https://unix.stackexchange.com/a/487889/374985
# for the different ZSH config files.

# This file is for basic stuff intended for all sessions.

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

# =====================================================================================
# Other environment variables
# =====================================================================================

# Pyenv is a Python virtual environments management tool
local PYENV_ROOT="${HOME}/.pyenv"

if [ -d ${PYENV_ROOT} ]; then
    export PYENV_ROOT
    path+="${PYENV_ROOT}/bin"
    if command -v pyenv 1>/dev/null 2>&1; then
        # Manipulates PATH during initialization:
        eval "$(pyenv init -)"
    fi
fi

# Rust / Cargo setup
. "$HOME/.cargo/env"
