# prompt
PROMPT='%F{6}%c%f $ '

# rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# aliases
alias ls='ls -G'
alias ll='ls -lha'
alias relogin='exec /bin/zsh -l'
alias rmderived='/bin/rm -rf ~/Library/Developer/Xcode/DerivedData/*; osascript -e '"'"'display notification "completed" with title "rmderived"'"'"''
alias rmdsstore="find . -name '.DS_Store' -type f -ls -delete"
alias rmconflicted="find . -name '*.orig' -type f -ls -delete"

# git alias
alias gb='git branch'
alias gba='git branch -a'
alias gca='git commit --amend --no-edit'
alias gcp='git cherry-pick'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grs='git rebase --skip'
alias gf='git fetch -pP --all'
alias gp='git pull --rebase -p --all'
alias ghead='git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@''

alias current_branch='gb | grep '"'"'*'"'"' | tr -d '"'"' '"'"' | tr -d '"'"'*'"'"''
alias merged_branch='git branch --merged | grep -v '"'"'*'"'"' | grep -v '"'"'+'"'"' | grep -v $(ghead)'
alias rmmerged_branch='merged_branch | xargs -I % git branch -d %'

alias gbm='current_branch > /tmp/.tmp_current_branch && vim /tmp/.tmp_current_branch && gb -m $(cat /tmp/.tmp_current_branch) && rm /tmp/.tmp_current_branch'

alias gdiffremote='git diff --name-only "origin/$(current_branch)"'

# ghq alias
alias gbpeco='gb | grep -v "HEAD" | peco | tr -d '"'"' '"'"' | tr -d '"'"'*'"'"' | tr -d '"'"'+'"'"''
alias gbapeco='gba | grep -v "HEAD" | peco | tr -d '"'"' '"'"' | tr -d '"'"'*'"'"' | tr -d '"'"'+'"'"''

function gclone() {
    RESULT="$(ghq get -s $@ 2>&1)"
    CLONE="$(echo "${RESULT}" | grep 'clone' | grep '\->' | sed -E 's/(.*) -> (.*)/\2/g')"
    EXISTS="$(echo "${RESULT}"| grep 'exists' | sed -E 's/.*exists.* (\/.*)/\1/g')"
    if [[ "${EXISTS}" != '' ]]; then
        echo "open ${EXISTS}"
        code "${EXISTS}"
    elif [[ "${CLONE}" != '' ]]; then
        echo "open ${CLONE}"
        code "${CLONE}"
    fi
}

alias gclones='gclone --shallow'
alias gout='gf && git checkout $(gbapeco)'
alias glook='ghq get -s --look $(ghq list | peco)'
alias gcode='code $(ghq root)/$(ghq list | peco)'
alias gcp='git cherry-pick'
alias grb='SKIP_POST_CHECKOUT=1 gf && git rebase $(gbapeco)'
alias grm='SKIP_POST_CHECKOUT=1 gf && git rebase origin/$(ghead)'
alias grd='SKIP_POST_CHECKOUT=1 gf && git rebase origin/develop'
alias gs='git switch $(gbpeco)'
alias gsr='gf && git switch $(gba | grep -v "HEAD" | grep "origin" | sed 's@remotes/origin/@@' | peco)'
alias gmb='gf && git merge --no-ff --no-edit $(gbapeco)'
alias gmm='gf && git merge --no-ff --no-edit origin/$(ghead)'
alias gmd='gf && git merge --no-ff --no-edit origin/develop'
alias ghr='git reset --hard'

# Docker alias
function drun() {
    local -A opthash
    zparseopts -D -a optarray -A opthash -- -debug d -bash b -platform: -entrypoint: -mount m -github g -environment+:: e+:: -image: i:

    if [[ -n "${opthash[(i)--debug]}" ]] || [[ -n "${opthash[(i)-d]}" ]]; then
        DEBUG=1
    else
        DEBUG=0
    fi

    OPTION='--rm'
    if [[ -n "${opthash[(i)--platform]}" ]]; then
        OPTION+=" --platform ${opthash[--platform]}"
    fi
    if [[ -n "${opthash[(i)--entrypoint]}" ]]; then
        OPTION+=" --entrypoint ${opthash[--entrypoint]}"
    fi
    if [[ -n "${opthash[(i)--mount]}" ]] || [[ -n "${opthash[(i)-m]}" ]]; then
        OPTION+=' -v $PWD:/work -w /work'
    fi
    if [[ -n "${opthash[(i)--github]}" ]] || [[ -n "${opthash[(i)-g]}" ]]; then
        OPTION+=' -e GITHUB_TOKEN=$GITHUB_TOKEN'
    fi
    if [[ -n "${opthash[(i)--environment]}" ]]; then
        for i in ${"${optarray[@]}"}; do
            if [[ $i =~ ^--environment ]]; then
                OPTION+=" -e ${i:13}"
            fi
        done
    fi
    if [[ -n "${opthash[(i)-e]}" ]]; then
        for i in ${"${optarray[@]}"}; do
            if [[ $i =~ ^-e ]]; then
                OPTION+=" -e ${i:2}"
            fi
        done
    fi
    if [[ -n "${opthash[(i)--bash]}" ]] || [[ -n "${opthash[(i)-b]}" ]]; then
        OPTION+=' --entrypoint /bin/bash'
    fi
    if [[ -n "${opthash[(i)--image]}" ]]; then
        IMAGE="${opthash[--image]}"
    elif [[ -n "${opthash[(i)-i]}" ]]; then
        IMAGE="${opthash[-i]}"
    else
        IMAGE="$(docker images --format "{{.Repository}}:{{.Tag}}" | peco)"
    fi

    if [[ DEBUG -eq 1 ]]; then
        echo "docker run $(eval echo $OPTION) -it $IMAGE $@"
    fi
    docker run $(eval echo $OPTION) -it $IMAGE $@
}

# Alias for Danger-Swift
function danger-pr() {
    if [ -f "Dangerfile.swift" ]; then
        DANGER_GITHUB_API_TOKEN=$(gh auth token) danger-swift pr --danger-js-path "$(dirname $(which danger-swift))/danger" $(gh pr view --json url --jq '.url')
    else # TODO: Support Danger-Ruby, Danger-JS or Danger-Kotlin
        echo "Dangerfile.swift not found in the current directory." 1>&2
    fi
}

# Other custom aliases or functions
alias readme='open $(find . -type d \( -name "Carthage" -o -name "Pods" -o -name "vendor" \) -prune -o -type f -name "README*" -print | peco)'
alias renovate-config-validator='drun -mg -e RENOVATE_TOKEN=$GITHUB_TOKEN -i renovate/renovate:slim renovate-config-validator'

alias coderc='code ~/.zshrc'
alias coderc_local='code ~/.zshrc_local'
alias codeprofile='code ~/.zprofile'
alias codeprofile_local='code ~/.zprofile_local'

function light() {
    if [ -z "$2" ]; then
        src="pbpaste"
    else
        src="cat $2"
    fi

    $src | highlight -O rtf --syntax $1 --font=Ricty --style=molokai --font-size 24 | pbcopy
}

function copy_current_branch() {
    git symbolic-ref --short HEAD | tr -d '\n' | pbcopy
}

function gbc() {
    if [ $# -ne 1 ]; then
        echo -e "\e[31mNo branch name specified.\e[m" 1>&2
        return
    fi
    gf && git switch --no-track -c $1 origin/$(ghead)
}

# Replace `origin` with forked repo
function fetchfork() {
    GITHUB_USER=$(gh api /user --jq .login | tr -d '"')
    UPSTREAM="$(git remote -v | grep origin | head -1 | awk '{ print $2 }')"
    if [[ "${UPSTREAM}" = *":${GITHUB_USER}/"* ]];then
        echo 'Already forked, or my own repo.'
        return
    fi
    git remote rename origin upstream
    FORKED="$(echo "${UPSTREAM}" | sed -E "s/^(.*)\/(.*)\/(.*)$/\1\/${GITHUB_USER}\/\3/g")"
    git remote add origin "${FORKED}"
    git fetch --all --prune
}

# Record iPhone simulator
function capsim() {
    trap '' 2 # Ignore Ctrl+C
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    xcrun simctl io booted recordVideo ~/Desktop/capture-$TIMESTAMP.mp4
    trap 2 # Restore Ctrl+C

    read yn\?"Convert to gif? (y/N): "
    case "$yn" in [yY]*) ;; *) echo "abort." ; return ;; esac

    ffmpeg -i ~/Desktop/capture-$TIMESTAMP.mp4 -r 24 ~/Desktop/capture-$TIMESTAMP.gif
}

# Record Android device via adb
function adbcap() {
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    echo "Recording: /sdcard/capture-$TIMESTAMP.mp4"

    trap "echo 'Press ^C again to stop recording.'" 2
    adb shell screenrecord /sdcard/capture-$TIMESTAMP.mp4
    sleep 5
    trap 2

    adb pull /sdcard/capture-$TIMESTAMP.mp4 ~/Desktop/capture-$TIMESTAMP.mp4
    adb shell rm /sdcard/capture-$TIMESTAMP.mp4
}

# Screenshot Android device via adb
function adbss() {
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    adb shell screencap -p /sdcard/screenshot-$TIMESTAMP.png
    adb pull /sdcard/screenshot-$TIMESTAMP.png ~/Desktop/screenshot-$TIMESTAMP.png
    adb shell rm /sdcard/screenshot-$TIMESTAMP.png
}

# Convert MOV to animated GIF
function mov2gif() {
    ffmpeg -i "$1" -r 24 "${1%.mov}.gif"
}

# Convert HEIC to JPG
function heic2jpg() {
    for BASE_FILE in $@; do
        OUTPUT_FILE=$(echo $BASE_FILE | sed -E 's/(.*)\.(heic|HEIC)/\1.jpg/g')
        sips --setProperty format jpeg "$BASE_FILE" --out "$OUTPUT_FILE"
    done
}

# Load local .zshrc if exists
if [ -f ~/.zshrc_local ]; then
    source ~/.zshrc_local
fi
