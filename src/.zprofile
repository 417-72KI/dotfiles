# 履歴ファイルの保存先
export HISTFILE=${HOME}/.zhistory
export SAVEHIST=50
# 履歴をインクリメンタルに追加
setopt inc_append_history
# インクリメンタルからの検索
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# 環境変数
export PATH="$HOME/.mint/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=$PATH:~/.nodebrew/current/bin
export PATH="$HOME/.pyenv/shims:$PATH"
export PATH=$PATH:~/.local/bin
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
export GHQ_ROOT=~/.ghq

# Environments for Homebrew (with Apple Silicon)
if [[ -e /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Environments for SDKMAN!
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
export JAVA_HOME=${SDKMAN_DIR}/candidates/java/current

# Load local .zprofile if exists
if [ -f ~/.zprofile_local ]; then
    source ~/.zprofile_local
fi
