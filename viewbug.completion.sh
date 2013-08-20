_viewbug(){
    local cur=${COMP_WORDS[COMP_CWORD]}
    local prev=${COMP_WORDS[COMP_CWORD-1]}
    if [[ ${#COMP_WORDS[@]} -eq 1 || $cur =~ -* ]]; then
        COMP_REPLY=( $(compgen -W '-A -c -h -k -n -o -p -v -x' -- $cur) )
        return
    fi
}
complete -F _viewbug viewbug
