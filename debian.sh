#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get directory of this script
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd )"

# If undefined, define but leave empty so `[ -z "$CI" ]` (or `-n`) works. Isn't bash a
# wonderful language?
CI="${CI:-}"

print_large() {
    printf "\n\n\e[32m"
    printf "================================================================================\n"
    printf "%s\n" "$1"
    printf "================================================================================\n"
    printf "\e[0m\n\n"
}

install_and_configure_shell() {
    print_large "Installing and configuring shell..."

    [ ! -d "$HOME/.oh-my-zsh" ] && (curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh)

    declare -A plugins
    plugins=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
    )

    for plugin in "${!plugins[@]}"; do
        local DEST=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin
        [ ! -d "$DEST" ] && git clone "${plugins[$plugin]}" "$DEST"
    done

    cargo binstall --no-confirm starship

    if [ "$SHELL" != "$(which zsh)" ] && [ -z "$CI" ]; then
        chsh -s "$(which zsh)"
    fi

    print_large "Shell installed and configured successfully."
}

install_cli_tools() {
    install_github_copilot_cli() {
        print_large "Installing GitHub Copilot CLI..."

        if ! command -v github-copilot-cli &> /dev/null
        then
            sudo npm install --global @githubnext/github-copilot-cli
        fi

        [ ! -f "$HOME/.copilot-cli-access-token" ] && github-copilot-cli auth

        print_large "GitHub Copilot CLI installed successfully."
    }

    install_github_cli() {
        print_large "Installing GitHub CLI..."

        if ! command -v gh &> /dev/null || [ -n "$CI" ]
        then
            # https://github.com/cli/cli/blob/bf7db84ca8b795a38ee47b5e54a8109a917a55bf/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
            && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
            && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

            sudo apt update && sudo apt install --yes gh
        fi

        print_large "GitHub CLI installed successfully."
    }

    install_terraform_cli() {
        print_large "Installing Terraform CLI..."

        # Check at
        # `https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli`
        # on whether this is still the correct approach, especially for the GPG key.

        if ! command -v terraform &> /dev/null || [ -n "$CI" ]
        then
            sudo apt update && sudo apt-get install --yes \
                gnupg \
                software-properties-common

            wget -O- https://apt.releases.hashicorp.com/gpg | \
                gpg --dearmor | \
                sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

            echo "HashiCorp GPG key fingerprint:"
            gpg --no-default-keyring \
                --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
                --fingerprint

            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
                sudo tee /etc/apt/sources.list.d/hashicorp.list

            sudo apt update && sudo apt install --yes terraform
        fi

        print_large "Terraform CLI installed successfully."
    }

    install_azure_cli() {
        print_large "Installing Azure CLI..."

        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

        print_large "Azure CLI installed successfully."
    }

    print_large "Installing CLI tools..."

    cargo binstall --no-confirm \
        bottom \
        erdtree \
        git-delta \
        just \
        tokei

    # On my system, the below directory was already part of the `fpath` array of zsh,
    # but didn't exist. Check if it's part of that array with: `echo $fpath | tr ' '
    # '\n'`. If it is, create if not exist, then put the completion file there.
    # Important: its name *must* start with an underscore, otherwise (like `just.zsh`)
    # it won't work. See for example: https://stackoverflow.com/a/73148583/11477374
    # https://github.com/casey/just/issues/618#issuecomment-601824467
    # https://github.com/casey/just/issues/617 (yes this is very complicated for some
    # reason) Note that `$ZSH_CUSTOM` and using regular files like `script.zsh` doesn't
    # work for completions, as far as I can see (like done here:
    # https://unix.stackexchange.com/a/587802/374985).
    local ZSH_COMPLETIONS_DIR="$HOME/.oh-my-zsh/completions"
    mkdir -p $ZSH_COMPLETIONS_DIR
    just --completions zsh > "${ZSH_COMPLETIONS_DIR}/_just"

    sudo apt update && sudo apt install --yes \
        direnv \
        dnsutils \
        fd-find \
        file \
        fzf \
        gron \
        heaptrack \
        heaptrack-gui \
        htop \
        jq \
        lsof \
        ncdu \
        neofetch \
        net-tools \
        nethogs \
        ripgrep \
        sysstat \
        tldr \
        zoxide

    # Can fail with `master` not found, their trunk is now `main`?
    tldr --update || (cd "$HOME/.local/share/tldr/tldr" && git pull)

    install_azure_cli

    [ -z "$CI" ] && install_github_copilot_cli

    install_terraform_cli

    pipx install --include-deps ansible

    print_large "CLI tools installed successfully."
}

install_ssh_tooling_and_configure_ssh() {
    print_large "Installing SSH tooling and configuring SSH..."

    sudo apt update && sudo apt install --yes \
        keychain \
        openssh-client

    if [ ! -f ~/.ssh/id_ed25519 ] && [ -z "$CI" ]; then
        print_large "Generating new ed25519 key pair, specify a comment (email) and passphrase..."
        read -p "Email: " email
        ssh-keygen -t ed25519 -C "$email"
    fi

    print_large "SSH tooling installed and configured successfully."
}

provision_config_files() {
    cp --recursive "${DIR}/home/." ~/

    # Overwrite:
    git config --global user.signingkey "$(cat ~/.ssh/id_ed25519.pub)"
}

install_language_toolchains() {
    install_base_build_packages() {
        print_large "Installing general base and build packages..."

        sudo apt update && sudo apt install --yes \
            apt-transport-https \
            build-essential \
            ca-certificates \
            cmake \
            curl \
            etckeeper \
            git \
            git-extras \
            gnupg \
            lsb-release \
            pkg-config \
            rsync \
            vim \
            wget \
            wireguard \
            zsh || exit 1 # Use explicit exit code in case `set -e` misbehaves

        sudo etckeeper init && { sudo etckeeper commit "Executed installation script" || true; }

        print_large "General base and build packages installed."
    }

    install_rust_toolchain() {
        print_large "Installing Rust toolchain..."

        if ! command -v cargo &> /dev/null || [ -n "$CI" ]
        then
            # Pipe to `sh`, yes much spooky
            curl https://sh.rustup.rs -sSf | sh -s -- -y || exit 1

            # Need to find `cargo` for later use
            source "$HOME/.cargo/env" || exit 1
        fi

        if ! command -v cargo-binstall &> /dev/null || [ -n "$CI" ]
        then
            # https://github.com/cargo-bins/cargo-binstall#installation
            curl -sSLf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
        fi

        print_large "Rust toolchain installed successfully."
    }

    install_go_toolchain() {
        print_large "Installing Go toolchain..."

        if ! command -v go &> /dev/null || [ -n "$CI" ]
        then
            curl -sSL https://golang.org/dl/go1.20.4.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
        fi

        print_large "Go toolchain installed successfully."
    }

    install_python_toolchain() {
        print_large "Installing Python toolchain..."

        if ! command -v python3 &> /dev/null || [ -n "$CI" ]
        then
            sudo apt update && sudo apt install --yes \
                python3 \
                python3-ipython \
                python3-pip \
                pipx

            pipx ensurepath
        fi

        if ! command -v poetry &> /dev/null || [ -n "$CI" ]
        then
            curl -sSL https://install.python-poetry.org | python3 -
        fi

        # https://github.com/pyenv/pyenv/issues/678
        sudo apt update && sudo apt install libsqlite3-dev
        if ! command -v pyenv &> /dev/null || [ -n "$CI" ]
        then
            # https://github.com/pyenv/pyenv/tree/96f93fd5531afa2fb5a826c92770293e500f9ab6#automatic-installer
            curl https://pyenv.run | bash
        fi

        for version in '3.9' '3.10' '3.11' '3.12'; do
            pyenv install --skip-existing "$version"
        done

        pipx install pdm

        print_large "Python toolchain installed successfully."
    }

    install_npm() {
        print_large "Installing npm..."

        if ! command -v npm &> /dev/null || [ -n "$CI" ]
        then
            sudo apt update && sudo apt install nodejs
        fi

        print_large "npm installed successfully."
    }

    install_base_build_packages

    install_rust_toolchain
    install_go_toolchain
    install_python_toolchain
    install_npm
}

main() {
    print_large "Provisioning system..."

    install_language_toolchains
    install_ssh_tooling_and_configure_ssh
    install_and_configure_shell
    install_cli_tools
    provision_config_files

    print_large "System provisioned successfully."
}

main
