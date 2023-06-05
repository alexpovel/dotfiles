#!/usr/bin/env bash

set -euo pipefail

# Install general base packages
sudo apt update && sudo apt install --yes \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    git-extras \
    gnupg \
    lsb-release \
    vim \
    wget \
    zsh

# Install build tools
sudo apt install --yes \
    build-essential \
    cmake \
    pkg-config

# Install Rust toolchain
curl https://sh.rustup.rs -sSf | sh -s -- -y # Pipe to `sh`, yes much spooky
source "$HOME/.cargo/env"  # Need to find `cargo`

# Install Rust tools
cargo install \
    fd-find \
    git-delta \
    ripgrep \
    starship \
    tokei \
    zoxide

# Install Go toolchain if none present yet
[ ! -d "/usr/local/go" ] && curl -sSL https://golang.org/dl/go1.20.4.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -

# Install shell tooling
sudo apt install --yes \
    file \
    fzf \
    htop \
    jq \
    ncdu \
    neofetch \
    tree

[ ! -d "$HOME/.oh-my-zsh" ] && (curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh)

[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ] && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ] && git force-clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Python tooling
sudo apt install --yes \
    python3 \
    python3-pip

curl -sSL https://install.python-poetry.org | python3 -

# Install ssh tooling
sudo apt install --yes \
    keychain \
    openssh-client

# If a key doesn't exist yet, generate a new ed25519 key pair
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating new ed25519 key pair, specify a comment (email) and passphrase..."
    read -p "Email: " email
    ssh-keygen -t ed25519 -C "$email"
fi

sudo apt install tldr && tldr --update || (cd "$HOME/.local/share/tldr/tldr" && git pull)

# Install Terraform; check with `https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli`
# on whether this is still the correct approach, especially for the GPG key.
sudo apt-get install --yes \
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

# Get latest versions of certain packages, e.g. `git` is too old on Debian 11 for ssh signing support (2.30 vs. 2.34 needed)
codename="$(lsb_release -cs)"
echo "deb http://deb.debian.org/debian $codename-backports main" | sudo tee "/etc/apt/sources.list.d/$codename-backports.list"

sudo apt update && sudo apt install --yes \
    "git/${codename}-backports"

cp --recursive home/. ~/

if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi
