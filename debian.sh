#!/usr/bin/env bash

set -euo pipefail

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

    cargo install starship

    if [ "$SHELL" != "$(which zsh)" ]; then
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

    install_git() {
        print_large "Installing git..."
        # Get latest version, git is too old on Debian 11 for ssh signing support (2.30 vs. 2.34 needed)

        local CODENAME
        CODENAME="$(lsb_release -cs)"

        echo "deb http://deb.debian.org/debian $CODENAME-backports main" | sudo tee "/etc/apt/sources.list.d/$CODENAME-backports.list"

        sudo apt update && sudo apt install --yes \
            "git/${CODENAME}-backports"

        print_large "git installed successfully."
    }

    install_terraform_cli() {
        print_large "Installing Terraform CLI..."

        # Check at
        # `https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli`
        # on whether this is still the correct approach, especially for the GPG key.

        if ! command -v terraform &> /dev/null
        then
            sudo apt update && sudo apt-get install --yes \
                gnupg \
                software-properties-common

            wget -O- https://apt.releases.hashicorp.com/gpg | \
                gpg --dearmor | \
                sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

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

    install_git

    cargo install \
        fd-find \
        git-delta \
        just \
        ripgrep \
        tokei \
        zoxide

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
        file \
        fzf \
        htop \
        jq \
        lsof \
        ncdu \
        neofetch \
        tldr \
        tree

    # Can fail with `master` not found, their trunk is now `main`?
    tldr --update || (cd "$HOME/.local/share/tldr/tldr" && git pull)

    install_azure_cli

    install_github_copilot_cli

    install_terraform_cli

    print_large "CLI tools installed successfully."
}

install_ssh_tooling_and_configure_ssh() {
    print_large "Installing SSH tooling and configuring SSH..."

    sudo apt update && sudo apt install --yes \
        keychain \
        openssh-client

    # If a key doesn't exist yet, generate a new pair
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        print_large "Generating new ed25519 key pair, specify a comment (email) and passphrase..."
        read -p "Email: " email
        ssh-keygen -t ed25519 -C "$email"
    fi

    print_large "SSH tooling installed and configured successfully."
}

provision_config_files() {
    cp --recursive home/. ~/

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
            git \
            git-extras \
            gnupg \
            lsb-release \
            pkg-config \
            vim \
            wget \
            zsh || exit 1 # Use explicit exit code in case `set -e` misbehaves

        print_large "General base and build packages installed."
    }

    install_rust_toolchain() {
        print_large "Installing Rust toolchain..."

        if ! command -v cargo &> /dev/null
        then
            # Pipe to `sh`, yes much spooky
            curl https://sh.rustup.rs -sSf | sh -s -- -y || exit 1

            # Need to find `cargo` for later use
            source "$HOME/.cargo/env" || exit 1
        fi

        print_large "Rust toolchain installed successfully."
    }

    install_go_toolchain() {
        print_large "Installing Go toolchain..."

        if ! command -v go &> /dev/null
        then
            curl -sSL https://golang.org/dl/go1.20.4.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
        fi

        print_large "Go toolchain installed successfully."
    }

    install_python_toolchain() {
        print_large "Installing Python toolchain..."

        if ! command -v python3 &> /dev/null
        then
            sudo apt update && sudo apt install --yes \
                python3 \
                python3-pip
        fi

        if ! command -v poetry &> /dev/null
        then
            curl -sSL https://install.python-poetry.org | python3 -
        fi

        print_large "Python toolchain installed successfully."
    }

    install_npm() {
        print_large "Installing npm..."

        if ! command -v npm &> /dev/null
        then
            # Debian repo versions are too old
            curl -sL https://deb.nodesource.com/setup_19.x | sudo bash -

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
