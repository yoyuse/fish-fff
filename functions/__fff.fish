# 2022-03-01
# 2022-02-28
# 2022-02-27
# 2022-02-26
# 2022-02-24
# 2022-02-23

function __fff_set_usage
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
"
    end
end

function __fff_set_ls
    if test -z "$__fff_ls"
        which gls >/dev/null 2>&1 && set __fff_ls gls || set __fff_ls ls
        for opt in --color=always -G --color -F
            if [ "$opt" = -F ]
                set __fff_ls $__fff_ls
                set __fff_ls_F $__fff_ls $opt
                break
            end
            if $__fff_ls $opt / >/dev/null 2>&1
                set __fff_ls $__fff_ls $opt
                set __fff_ls_F $__fff_ls
                break
            end
        end
        set -gx __fff_ls $__fff_ls
        set -gx __fff_ls_F $__fff_ls_F
    end
    if test -z "$__fff_ls_F"
        set -gx __fff_ls_F $__fff_ls -F
    end
end

function __fff_set_fd
    if test -z "$__fff_fd" -a -z "$__fff_find"
        if which fdfind >/dev/null 2>&1
            set -gx __fff_fd fdfind --color=always --follow --no-ignore
        else if which fd >/dev/null 2>&1
            set -gx __fff_fd fd --color=always --follow --no-ignore
        else
            set -gx __fff_find find .
        end
    end
end

function __fff_set_pager
    if test -z "$__fff_pager"
        if which batcat >/dev/null 2>&1
            set -gx __fff_pager batcat -p --color=always --paging=always
        else if which bat >/dev/null 2>&1
            set -gx __fff_pager bat -p --color=always --paging=always
        else
            set -gx __fff_pager less -R
        end
    end
end

function __fff_set_editor
    if test -z "$__fff_editor"
        if which nvim >/dev/null 2>&1
            set -gx __fff_editor nvim
        else if which vim >/dev/null 2>&1
            set -gx __fff_editor vim
        else
            set -gx __fff_editor vi
        end
    end
end

function __fff_set_ttt
    if test -z "$__fff_ttt"
        for _ttt in go-ttt cli-ttt cli-ttt.rb
            if which $_ttt >/dev/null 2>&1
                set -gx __fff_ttt $_ttt
                break
            end
        end
    end
end

function __fff_shorten_path
    set -l dir $argv[1]
    set dir (echo "$dir" | sed -E -e 's:^'"$HOME"'($|/):~\1:')
    set dir (echo "$dir" | sed -E -e 's:(\.?[^/])[^/]*/:\1/:g')
    echo "$dir"
end

function __fff_dirslash
    while read path
        test -d "$path" && echo "$path/" || echo "$path"
    end
end

function __fff
    if test (count $argv) -eq 1 -a "$argv[1]" = --source
        __fff_source
        return
    end

    __fff_set_usage
    __fff_set_ls
    __fff_set_fd
    __fff_set_pager
    __fff_set_editor
    __fff_set_ttt

    set CLICOLOR_FORCE 1

    set -l mode ls
    set -l ls_opts
    set -l fd_opts
    set -l sed_opts -e '/\/\./d' # exclude hidden files

    set -l startdir (builtin cd .; pwd)
    set -l dir (commandline -t)
    set dir (string unescape $dir)
    test -z "$dir" && set dir .
    set dir (string replace -r '^~($|/)' "$HOME"'$1' $dir)
    set dir (string replace -r '^(.*)/$' '$1' $dir)

    set -l all
    set -l cmd

    while set out (
        test -d "$dir" && builtin cd "$dir"
        if test "$mode" = ls
            # $__fff_ls $ls_opts | __fff_dirslash
            set cmd $__fff_ls $ls_opts # | __fff_dirslash
        else if test -n "$__fff_fd"
            # $__fff_fd $fd_opts
            set cmd $__fff_fd $fd_opts
        else
            # $__fff_find | sed $sed_opts -e 's:^\./::' -e '/^\.$/d' | __fff_dirslash
            set cmd $__fff_find # | sed $sed_opts -e 's:^\./::' -e '/^\.$/d' | __fff_dirslash
        end
        $cmd | # sed $sed_opts -e 's:^\./::' -e '/^\.$/d' |
        fzf --ansi \
            --bind "?:execute-silent(echo -n '$__fff_usage' | less >/dev/tty)+clear-screen" \
            --bind "ctrl-k:kill-line" \
            --bind "ctrl-l:execute-silent(test -d {} && $__fff_ls -l $ls_opts {} | less -R >/dev/tty || $__fff_pager {} </dev/tty >/dev/tty)+clear-screen" \
            --bind "ctrl-v:execute($__fff_editor {} </dev/tty >/dev/tty)" \
            --expect=ctrl-j,ctrl-m,ctrl-o,ctrl-r,ctrl-s,ctrl-t,ctrl-x,ctrl-z \
            --expect=alt-j \
            --multi \
            --preview "[ -d {} ] && $__fff_ls_F $ls_opts {} || $__fff_pager {}" \
            --prompt (__fff_shorten_path "$dir")" > " \
            --query="$q" --print-query \
            | string collect; builtin cd "$startdir"); test -n "$q" -o -n "$out"
        set q   (echo "$out" | sed -n 1p)
        set k   (echo "$out" | sed -n 2p)
        set res (echo "$out" | sed -n '3,$p')
        # //path → /path
        [ "$dir" = . ] && set target $res || set target (string replace -r '/$' '' "$dir")"/"$res # XXX # ${dir%/}/$res
        switch "$k"
            case ctrl-j
                # commandline -rt "$target"
                commandline -rt (echo (string escape $target))
                break
            case ctrl-m
                if test -d "$target"
                    set dir "$target"
                    test "$dir" = "$startdir" && set dir .
                    set q
                else
                    # commandline -rt "$target"
                    commandline -rt (echo (string escape $target))
                    break
                end
            case ctrl-o
                test "$dir" = . -o "$dir" = "" && set dir (pwd)
                set -l parent (string replace -r '/[^/]+$' '' "$dir") # "${dir%/*}"
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
                set -l dirname (dirname "$target")
                if test -d "$dirname"
                    set dir $dirname
                end
            case ctrl-s
                test -n "$all" && set all || set all 1
                if test -n "$all"
                    set ls_opts -a
                    set fd_opts --hidden
                    set sed_opts
                else
                    set ls_opts
                    set fd_opts
                    set sed_opts '-e /\/\./d'
                end
            case ctrl-t
                # XXX: code copy
                set -l cwd "$PWD/"
                if test "$PWD" = (string replace -r '/$' '' "$dir")
                    set dir .
                else if test "$cwd" = (string sub -s 1 -l (string length "$cwd") "$dir") # "$cwd" = "${dir:0:${#cwd}}"
                    set dir (string replace "$cwd" '' "$dir") # set dir "${dir##$cwd}"
                else
                    set dir (builtin cd "$dir"; pwd)
                end
            case ctrl-x
                echo "cd $dir"
                cd "$dir"
                commandline -rt ""
                break
            case ctrl-z
                set target (z --list | fzf --bind "ctrl-z:abort" --nth 2.. --no-sort | sed 's/^[0-9,.]* *//')
                test -n "$target" && set dir $target
                # XXX: code copy
                set -l cwd "$PWD/"
                if test "$PWD" = (string replace -r '/$' '' "$dir")
                    set dir .
                else if test "$cwd" = (string sub -s 1 -l (string length "$cwd") "$dir") # "$cwd" = "${dir:0:${#cwd}}"
                    set dir (string replace "$cwd" '' "$dir") # set dir "${dir##$cwd}"
                else
                    set dir (builtin cd "$dir"; pwd)
                end
                #
                set q
            case alt-j
                test -n "$__fff_ttt" && set q (echo "$q" | "$__fff_ttt")
            case '*'
                break
        end
    end
    commandline -f repaint
end

function __fff_source
    set -l me (status --current-filename)
    echo source $me
    source $me
    commandline -f repaint
end
