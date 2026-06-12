# Ubuntu Setup Notes

## Update & Prerequisites
```bash
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release \
  software-properties-common apt-transport-https
```

## Microsoft Repo (Azure CLI + PowerShell)
```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/microsoft.gpg
AZ_REPO="$(lsb_release -cs)"
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] \
https://packages.microsoft.com/repos/azure-cli $AZ_REPO main" \
  | sudo tee /etc/apt/sources.list.d/azure-cli.list
# PowerShell
curl -fsSL "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
  -o /tmp/packages-microsoft-prod.deb && sudo dpkg -i /tmp/packages-microsoft-prod.deb
sudo apt-get update
```

## Packages
```bash
sudo apt-get install -y \
    wget \
    openssl \
    zsh \
    git \
    neovim \
    p7zip-full \
    unzip \
    btop \
    jq \
    nmap \
    ripgrep \
    zoxide \
    kubectl \
    azure-cli \
    powershell
```

## Helm
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## k9s
```bash
TAG=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -fsSL "https://github.com/derailed/k9s/releases/download/$TAG/k9s_linux_amd64.deb" -o /tmp/k9s.deb
sudo dpkg -i /tmp/k9s.deb
```

## Zellij
```bash
TAG=$(curl -fsSL https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -fsSL "https://github.com/zellij-org/zellij/releases/download/$TAG/zellij-x86_64-unknown-linux-musl.tar.gz" \
  | sudo tar -xz -C /usr/local/bin zellij
sudo chmod +x /usr/local/bin/zellij
```

## lsd
```bash
TAG=$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -fsSL "https://github.com/lsd-rs/lsd/releases/download/$TAG/lsd_${TAG#v}_amd64.deb" -o /tmp/lsd.deb
sudo dpkg -i /tmp/lsd.deb
```

## HashiCorp (Terraform, Packer)
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y packer terraform
```

## Docker
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

## Non-Repo Tools

### GitHub Copilot CLI
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
npm install -g npm@11
npm install -g @github/copilot
```

### TalosCTL
```bash
curl -sL https://talos.dev/install | sh
```

### Azure AKS CLI
```bash
sudo az aks install-cli
```

# Zsh Setup
## Set Default Shell
```bash
chsh -s $(which zsh)
```

## Plugins

### powerlevel10k
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

### zsh-vi-mode
```bash
git clone https://github.com/jeffreytse/zsh-vi-mode.git ~/.zsh-vi-mode
```

# Git Config
`~/.gitconfig`
```
[url "ssh://git@github.com/"]
        insteadOf = http://github.com/
[url "git@github.com:"]
        insteadOf = https://github.com/
```

# SSH Config
`~/.ssh/config`
```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  AddKeysToAgent yes

Host ssh.github.com
  HostName ssh.github.com
  User git
  Port 443
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```
