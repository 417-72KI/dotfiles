#!/bin/zsh

REPO_ROOT="$(git rev-parse --show-toplevel)"
DIFF=("$@")

if [[ -n "${(M)DIFF[@]:#git-hooks/*}" ]]; then
    echo "\e[32m[INFO] git-hooks updated.\e[0m"
fi

if [[ -n "${(M)DIFF[@]:#src/.zshrc}" ]] || [[ -n "${(M)DIFF[@]:#src/.zprofile}" ]]; then
    echo "\e[32mShell configuration changed. Reload your shell to apply changes.\e[0m"
    RELOAD_COMMAND='exec /bin/zsh -l'
    echo "\e[32m  $ ${RELOAD_COMMAND}\e[0m"
    echo "$RELOAD_COMMAND" | pbcopy
    eval "$RELOAD_COMMAND"
fi

for dotfile in "${REPO_ROOT:a}"/src/.*; do
    if [ ! -e "$HOME/$(basename "$dotfile")" ]; then
        echo "\e[34mUnlinked dotfile '${dotfile}' detected. Linking to $HOME/$(basename "$dotfile")\e[m"
        ln -s "$dotfile" "$HOME/$(basename "$dotfile")"
    fi
done

if echo "${(M)DIFF[@]:#git-hooks/*}" | grep -qE '^src/\.homebrew\/Brewfile$'; then
    brew bundle install -g --no-upgrade
fi

echo "${(M)DIFF[@]:#git-hooks/*}" | grep -E '^src/\.homebrew\/Brewfile[._].+$' | while read -r brewfile; do
    echo "\e[32mInstalling packages from ${brewfile#src/}\e[0m"
    brew bundle install --file="$HOME/${brewfile#src/}" --no-upgrade
done
