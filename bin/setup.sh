#!/bin/zsh

set -eo pipefail

# For macOS
if [[ $OSTYPE == darwin* && $CPUTYPE == arm64 ]]; then
    # ネットワークドライブで.DS_Storeを作成しないようにする
    if [ "$(defaults read com.apple.desktopservices DSDontWriteNetworkStores)" != 1 ]; then
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool YES
    fi

    # Xcode13.2~でビルドを高速化する
    if [ "$(defaults read com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration)" != 1 ]; then
        defaults write com.apple.dt.XCBuild EnableSwiftBuildSystemIntegration -bool YES
    fi

    # 隠しファイルを表示するようにする
    if [ "$(defaults read com.apple.finder AppleShowAllFiles)" != 1 ]; then
        defaults write com.apple.finder AppleShowAllFiles -bool YES
        echo 'Reboot Finder...'
        killall Finder
    fi

    # Xcodeでビルド時間を表示する
    if [ "$(defaults read com.apple.dt.Xcode ShowBuildOperationDuration)" != 1 ]; then
        defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES
    fi
fi

# Homebrewインストール
if which brew > /dev/null; then
    echo '\033[33mHomebrew already exists\033[m'
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# rbenvインストール
if which rbenv > /dev/null; then
    echo '\033[33mrbenv already exists\033[m'
else
    brew install rbenv rbenv-communal-gems
fi

# Rubyを最新版に
RUBY_LATEST_VERSION=$(rbenv install -l | grep -v - | tail -1)
if [ "$(rbenv versions | grep "$RUBY_LATEST_VERSION")" = '' ]; then
    rbenv install $RUBY_LATEST_VERSION
    rbenv global $RUBY_LATEST_VERSION
    rbenv rehash
fi

# Node.jsインストール
if which nodebrew > /dev/null; then
    echo '\033[33mnodebrew already exists\033[m'
else
    brew install nodebrew
    mkdir -p ~/.nodebrew/src
    nodebrew install-binary latest
fi

# ssh公開鍵作成
if [[ ! -e ~/.ssh/id_rsa ]]; then
    ssh-keygen
fi

# .ssh/config作成
if [ -f ~/.ssh/config ]; then
    echo '\033[33m~/.ssh/config already exists\033[m'
else
    cat << EOS > ~/.ssh/config
Host github.com
    HostName github.com
    User git
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/id_rsa

Host *
    UseKeychain yes
EOS
fi

# jqインストール
if which jq > /dev/null; then
    echo '\033[33mjq already installed\033[m'
else
    brew install jq
fi

# ghインストール
if which gh > /dev/null; then
    echo '\033[33mgh already installed\033[m'
else
    brew install gh
fi

# ghq & pecoインストール
if which ghq > /dev/null; then
    echo '\033[33mghq already installed\033[m'
else
    brew install ghq
fi
if which peco > /dev/null; then
    echo '\033[33mpeco already installed\033[m'
else
    brew install peco
fi

local_files=(~/.zprofile_local ~/.zshrc_local ~/.gitconfig_local ~/.stCommitMsg)
for local_file in "${local_files[@]}"; do
    if [ ! -f "$local_file" ]; then
        echo "\033[33m$local_file does not exist, creating...\033[m"
        touch "$local_file"
    fi
done

# Link dotfiles from src directory
link_dotfile() {
    local src_file=$1
    local dest_file="$HOME/$(basename "$src_file")"
    
    if [ -f "$dest_file" ]; then
        if [[ ! -L "$dest_file" ]]; then
            mv "$dest_file" "$dest_file.bak"
        else 
            rm "$dest_file"
        fi
    fi
    ln -s "$src_file" "$dest_file"
}

# Process all dotfiles in src directory
SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR}/.."
for dotfile in "${REPO_ROOT:a}"/src/.*; do
    echo "\033[34mProcessing $dotfile...\033[m"
    if [ -f "$dotfile" ] && [ "$(basename "$dotfile")" != "." ] && [ "$(basename "$dotfile")" != ".." ]; then
        link_dotfile "$dotfile"
    fi
done

# link git hooks
GIT_DIR="${REPO_ROOT}/.git"
HOOKS_DIR="${GIT_DIR}/hooks"
if [ -d "$HOOKS_DIR" ] && [ ! -L "$HOOKS_DIR" ]; then
    echo "\033[33mRemoving existing hooks directory...\033[m"
    rm -rf "$HOOKS_DIR"
    cd "$GIT_DIR"
    ln -s "../git-hooks" hooks
    cd "${REPO_ROOT}"
fi

exec /bin/zsh -l
