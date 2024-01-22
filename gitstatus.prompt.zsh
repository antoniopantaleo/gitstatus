# Simple Zsh prompt with Git status.

# Source gitstatus.plugin.zsh from $GITSTATUS_DIR or from the same directory
# in which the current script resides if the variable isn't set.
source "${GITSTATUS_DIR:-${${(%):-%x}:h}}/gitstatus.plugin.zsh" || return

worktree_char() {
    if [[ $(pwd)  =~ "^$WORKTREE_PATH/.+" ]]; then
        echo "󰌹 "
    fi
}

function example_callback() {
  if [[ $VCS_STATUS_RESULT =~ 'norepo' ]]; then
    GITSTATUS_PROMPT=""
    return 0
  fi

  local      clean='%76F'   # green foreground
  local   modified='%178F'  # yellow foreground
  local  untracked='%39F'   # blue foreground
  local conflicted='%196F'  # red foreground

  local p
  local cleanOrDirty

  if [[ $VCS_STATUS_NUM_UNSTAGED -gt 0 || $VCS_STATUS_NUM_UNTRACKED -gt 0 ]]
  then
    cleanOrDirty="%{$fg_bold[red]%}✗"
  else
    cleanOrDirty="%{$fg_bold[green]%}✔"
  fi

  git_action=$([[ -n $VCS_STATUS_ACTION ]] && echo " ${FG[250]}| %{$fg_bold[red]%}$VCS_STATUS_ACTION" || echo "")

  local where  # branch name, tag or commit
  if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
    where=$VCS_STATUS_LOCAL_BRANCH
  elif [[ -n $VCS_STATUS_TAG ]]; then
    p+='%f#'
    where=$VCS_STATUS_TAG
  else
    p+='%f@'
    where=${VCS_STATUS_COMMIT[1,8]}
  fi

  p+="$(worktree_char)$fg[blue](${where//\%/%%} $cleanOrDirty$fg[blue]${git_action}$fg[blue])"             # escape %
  # ⇣42 if behind the remote.
  (( VCS_STATUS_COMMITS_BEHIND )) && p+=" ${FG[250]}↓"
  # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
  (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && p+=" "
  (( VCS_STATUS_COMMITS_AHEAD  )) && p+="${FG[250]}↑"
  # ⇠42 if behind the push remote.
  (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" ${FG[250]}⇠"
  (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && p+=" "
  # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
  (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && p+="${FG[250]}⇢"
  # *42 if have stashes.
  (( VCS_STATUS_STASHES        )) && p+=" ${FG[220]}✷"
  
  # ~42 if have merge conflicts.
  (( VCS_STATUS_NUM_CONFLICTED )) && p+=" ${FG[220]}⥂"
  # +42 if have staged changes.
  (( VCS_STATUS_NUM_STAGED     )) && p+=" ${FG[220]}⚑"
  # ?42 if have untracked files. It's really a question mark, your font isn't broken.
  (( VCS_STATUS_NUM_UNTRACKED  )) && p+=" ${FG[255]}?"

  GITSTATUS_PROMPT="${p}%f"
  # The length of GITSTATUS_PROMPT after removing %f and %F.
  GITSTATUS_PROMPT_LEN="${(m)#${${GITSTATUS_PROMPT//\%\%/x}//\%(f|<->F)}}"
  zle reset-prompt
}

function gitstatus_prompt_update() {
  emulate -L zsh
  typeset -g  GITSTATUS_PROMPT=''
  typeset -gi GITSTATUS_PROMPT_LEN=0

  gitstatus_query -t 0 -c example_callback 'MY'                  || return 1  # error
}

gitstatus_stop 'MY' && gitstatus_start -s -1 -u -1 -c -1 -d -1 'MY'

# On every prompt, fetch git status and set GITSTATUS_PROMPT.
autoload -Uz add-zsh-hook
add-zsh-hook precmd gitstatus_prompt_update

# Enable/disable the right prompt options.
setopt no_prompt_bang prompt_percent prompt_subst
