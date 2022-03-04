function __fff_lite_set_usage
    if test -z "$__fff_usage"
        set -gx __fff_usage "\
Keybind:
    ?         Show help
    Return    Print file path and exit / Enter directory
    C-j       Print path and exit
    C-l       View file
    C-o       Parent directory
    C-q       Exit
    C-r       Toggle recursive search
    C-s       Toggle invisibles
    C-t       Toggle absolute path
    C-v       Edit file
    C-x       Chdir and exit
    C-z       Jump around with z
    M-l       Find path with locate
"
    end
end

function __fff_lite
    __fff_lite_set_usage

    set -l CLICOLOR_FORCE 1

    set -l mode ls
    set -l ls_opts
    set -l sed_opts -e '/\/\./d' # exclude hidden files

    set -l startdir (pwd -L)
    set -l dir (string unescape (commandline -t))
    test -z "$dir" && set dir .
    set dir (string replace -r '^~($|/)' "$HOME"'$1' $dir)
    set dir (string trim -r -c / $dir)

    set -l all
    set -l cmd

    while set out (
        test -d "$dir" && builtin cd "$dir"
        if test "$mode" = ls
            set cmd ls $ls_opts
        else if test "$mode" = locate
            set cmd locate -i (string split ' ' $q)[1]
        else
            set cmd find .
        end
        $cmd | sed $sed_opts -e 's:^\./::' -e '/^\.$/d' | perl -ne 'chomp; $_ .= "/" if -d; print "$_\n";' |
        fzf --ansi \
            --bind "?:execute-silent(echo -n '$__fff_usage' | less >/dev/tty)+clear-screen" \
            --bind "ctrl-k:kill-line" \
            --bind "ctrl-l:execute-silent(test -d {} && ls -l $ls_opts {} | less -R >/dev/tty || less -R {} </dev/tty >/dev/tty)+clear-screen" \
            --bind "ctrl-v:execute(vim {} </dev/tty >/dev/tty)+refresh-preview" \
            --expect=ctrl-j,ctrl-m,ctrl-o,ctrl-r,ctrl-s,ctrl-t,ctrl-x,ctrl-z \
            --expect=alt-j,alt-l \
            --multi \
            --preview "[ -d {} ] && ls -F $ls_opts {} || less -R {}" \
            --prompt (string replace -a -r '(\.?[^/])[^/]*/' '$1/' (string replace -r '^'"$HOME"'($|/)' '~$1' $dir))" > " \
            --query="$q" --print-query \
            | string collect; builtin cd "$startdir"); test -n "$q" -o -n "$out"
        set q   (echo "$out" | sed -n 1p)
        set k   (echo "$out" | sed -n 2p)
        set res (echo "$out" | sed -n '3,$p')
        [ "$dir" = . ] && set target $res || set target (string trim -r -c / "$dir")"/"$res
        test "$mode" = locate && set target $res
        switch "$k"
            case ctrl-j
                commandline -rt (string join ' ' (string escape $target))
                break
            case ctrl-m
                test "$mode" = locate && set mode ls
                if test -d "$target"
                    set dir "$target"
                    test "$dir" = "$startdir" && set dir .
                    set q
                else
                    commandline -rt (string join ' ' (string escape $target))
                    break
                end
            case ctrl-o
                test "$mode" = locate && set mode ls
                test "$dir" = . -o "$dir" = "" && set dir (pwd)
                set -l parent (string replace -r '/[^/]+$' '' "$dir")
                switch "$parent"
                    case ""
                        set dir /
                    case "$dir"
                        set dir .
                    case '*'
                        set dir "$parent"
                end
                set q
            case ctrl-r
                test "$mode" = ls && set mode fd || set mode ls
                # XXX: code copy
                set -l dirname (dirname "$target")
                if test -d "$dirname"
                    set dir $dirname
                end
                #
            case ctrl-s
                test "$mode" = locate && set mode ls
                test -n "$all" && set all || set all 1
                if test -n "$all"
                    set ls_opts -a
                    set sed_opts
                else
                    set ls_opts
                    set sed_opts '-e /\/\./d'
                end
            case ctrl-t
                test "$mode" = locate && set mode ls
                # XXX: code copy
                set -l cwd "$PWD/"
                if test "$PWD" = (string trim -r -c / "$dir")
                    set dir .
                else if test "$cwd" = (string sub -s 1 -l (string length "$cwd") "$dir")
                    set dir (string replace "$cwd" '' "$dir")
                else
                    set dir (builtin cd "$dir"; pwd)
                end
            case ctrl-x
                echo "cd $dir"
                cd "$dir"
                commandline -rt ""
                break
            case ctrl-z
                test "$mode" = locate && set mode ls
                #
                # set target (z --list | fzf --bind "ctrl-z:abort" --nth 2.. --no-sort | sed 's/^[0-9,.]* *//')
                #
                set out (z --list | \
                    fzf --nth 2.. --no-sort \
                    --bind "ctrl-z:abort" --expect=alt-l \
                    --print-query | \
                    sed 's/^[0-9,.]* *//' | string collect)
                set q   (echo "$out" | sed -n 1p)
                set k   (echo "$out" | sed -n 2p)
                set res (echo "$out" | sed -n '3,$p')
                set target $res
                switch "$k"
                    case alt-l
                        # AND search of locate
                        # set target (locate -Ai (string split ' ' $q) | fzf --bind "ctrl-z:abort" --query="$q")
                        # XXX: AND search is not available for macOS locate
                        set target (locate -i (string split ' ' $q)[1] | fzf --bind "ctrl-z:abort" --query="$q")
                end
                test -f "$target" && set target (dirname $target)
                #
                test -n "$target" && set dir $target
                # XXX: code copy
                set -l cwd "$PWD/"
                if test "$PWD" = (string trim -r -c / "$dir")
                    set dir .
                else if test "$cwd" = (string sub -s 1 -l (string length "$cwd") "$dir")
                    set dir (string replace "$cwd" '' "$dir")
                else
                    set dir (builtin cd "$dir"; pwd)
                end
                #
                set q
            case alt-j
                test -n "$__fff_ttt" && set q (echo "$q" | "$__fff_ttt")
            case alt-l
                test "$mode" = locate && set mode ls || set mode locate
                # XXX: code copy
                set -l dirname (dirname "$target")
                if test -d "$dirname"
                    set dir $dirname
                end
                #
            case '*'
                break
        end
    end
    commandline -f repaint
end
