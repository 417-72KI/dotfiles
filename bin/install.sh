#!/bin/zsh

set -eo pipefail

xcode-select --install || true

DEFAULT_REPO_URL="https://github.com/417-72KI/dotfiles.git"
DEFAULT_REPO_DESTINATION="$HOME/.dotfiles"

REPO_URL=${REPO_URL:-$DEFAULT_REPO_URL}
REPO_DESTINATION=${REPO_DESTINATION:-$DEFAULT_REPO_DESTINATION}

if [ ! -L ~/.zprofile ] && [ ! -L ~/.zshrc ]; then
    git clone "$REPO_URL" "$REPO_DESTINATION"
elif [ "$(dirname $(readlink -f ~/.zprofile))" = "$(dirname $(readlink -f ~/.zshrc))" ]; then
    REPO_DESTINATION="$(git -C "$(dirname $(readlink -f ~/.zprofile))" rev-parse --show-toplevel)"
else
    echo "\e[31mError: ~/.zprofile and ~/.zshrc are not symlinks to the same directory.\e[0m"
    echo "\e[31mPlease remove or fix the symlinks before running this script.\e[0m"
    exit 1
fi

zsh "${REPO_DESTINATION}/bin/setup.sh"
