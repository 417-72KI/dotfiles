#!/bin/zsh

REPO_ROOT="$(git rev-parse --show-toplevel)"
DIFF=("$@")

if [[ -n "${(M)DIFF[@]:#git-hooks/*}" ]]; then
    echo "\e[32m[INFO] git-hooks updated.\e[0m"
fi

if [[ -n "${(M)DIFF[@]:#src/.zshrc}" ]] || [[ -n "${(M)DIFF[@]:#src/.zprofile}" ]]; then
    echo "\e[32m[INFO] Shell configuration changed. Reload your shell to apply changes.\e[0m"
    RELOAD_COMMAND='exec /bin/zsh -l'
    echo "\e[32m  $ ${RELOAD_COMMAND}\e[0m"
    echo "$RELOAD_COMMAND" | pbcopy
    eval "$RELOAD_COMMAND"
fi

for dotfile in "${REPO_ROOT:a}"/src/.*; do
    if [ ! -e "$HOME/$(basename "$dotfile")" ]; then
        echo "\e[34m[INFO] Unlinked dotfile '${dotfile}' detected. Linking to $HOME/$(basename "$dotfile")\e[m"
        ln -s "$dotfile" "$HOME/$(basename "$dotfile")"
    fi
done

if [[ -n "${(M)DIFF[@]:#src/.homebrew/Brewfile}" ]]; then
    echo "\e[32m[INFO] Brewfile changed. Installing packages...\e[0m"
    brew bundle install -g --no-upgrade
fi

for brewfile in "${(M)DIFF[@]:#src/.homebrew/Brewfile_*}"; do
    brewfile="${brewfile#src/}"
    echo "\e[32m[INFO] ${brewfile} changed. Installing packages...\e[0m"
    brew bundle install --file="$HOME/${brewfile}" --no-upgrade
done

# Untrack persona for Google Antigravity to prevent accidental commits
if [[ -z "$(git -C "$REPO_ROOT" ls-files -v | grep '^S src/.gemini/config/plugins/persona/rules/AGENTS.md$')" ]]; then
    git -C "$REPO_ROOT" update-index --skip-worktree src/.gemini/config/plugins/persona/rules/AGENTS.md
fi
