function __fff_set_usage
    if test -z "$__fff_usage"
        set -gx __fff_usage "\
Keybind:
    ?         Show help
    Return    Print file path and exit / Enter directory
    C-g       Exit with CWD
    C-j       Print path and exit
    C-l       View file
    C-o       Parent directory
    C-q       Exit
    C-r       Toggle recursive search
    C-s       Toggle invisibles
    C-t       Toggle absolute path
    C-v       Edit file
    C-x       Find path with locate
    C-z       Jump around with z
    M-t       Toggle preview
"
    end
end

function __fff_set_ls
    if test -z "$__fff_ls"
        which gls >/dev/null 2>&1 && set __fff_ls gls || set __fff_ls ls
        for opt in --color=always -G --color -F
            if test "$opt" = -F
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

function __fff
    __fff_set_usage
    __fff_set_ls
    __fff_set_fd
    __fff_set_pager
    __fff_set_editor
    __fff_set_ttt

    if test -z "$__fff_fd" # -o "$__fff_pager" = "less -R"
        # __fff_lite
        # return
        echo "fd: not found" >/dev/tty
        exit 1
    end

    set -l CLICOLOR_FORCE 1

    set -l src
    set -l mode ls
    set -l ls_opts
    set -l fd_opts

    set -l startdir (pwd -L)
    set -l dir (string unescape -- (commandline -t))
    test -z "$dir" && set dir .
    set dir (string replace -r -- '^~($|/)' "$HOME"'$1' $dir)
    set dir (string trim -r -c / -- $dir)

    set -l all
    set -l cmd
    set -l filter
    set -l prompt
    set -l fzf_opts

    while set out (
        test -d "$dir" && builtin cd -- $dir
        if test "$mode" = ls
            set cmd $__fff_ls $ls_opts
        else if test -n "$__fff_fd"
            set cmd $__fff_fd $fd_opts
        else
            set cmd $__fff_find
        end
        set filter cat
        set prompt (string replace -a -r -- '(\.?[^/])[^/]*/' '$1/' (string replace -r -- '^'"$HOME"'($|/)' '~$1' $dir))" > "
        set fzf_opts --multi
        if test "$src" = locate
            set cmd locate -i -- (string split -- ' ' $q)[1]
            set prompt "LOCATE > "
        else if test "$src" = z
            set cmd z --list
            set filter sed 's/^[0-9,.]* *//'
            set prompt "Z > "
            set fzf_opts --no-sort
        end
        $cmd | $filter |
        fzf --ansi \
            --bind "?:execute-silent(echo -n '$__fff_usage' | less >/dev/tty)+clear-screen" \
            --bind "ctrl-k:kill-line" \
            --bind "ctrl-l:execute-silent(test -d {} && $__fff_ls -l $ls_opts -- {} | less -R >/dev/tty || $__fff_pager -- {} </dev/tty >/dev/tty)+clear-screen" \
            --bind "ctrl-v:execute($__fff_editor -- {} </dev/tty >/dev/tty)+refresh-preview" \
            --bind "alt-t:toggle-preview" \
            --expect=ctrl-g,ctrl-j,ctrl-m,ctrl-o,ctrl-r,ctrl-s,ctrl-t,ctrl-x,ctrl-z \
            --expect=alt-j \
            $fzf_opts \
            --preview "test -d {} && $__fff_ls_F $ls_opts -- {} || $__fff_pager -- {}" \
            --prompt $prompt \
            --query=$q --print-query \
            | string collect; builtin cd -- $startdir); test -n "$q" -o -n "$out"
        set q   (echo "$out" | sed -n 1p)
        set k   (echo "$out" | sed -n 2p)
        set res (echo "$out" | sed -n '3,$p')
        test "$dir" = . && set target $res || set target (string trim -r -c / -- $dir)"/"$res
        test "$src" = locate -o "$src" = z && set target $res
        switch $k
            case ctrl-j
                commandline -rt -- (string join -- ' ' (string escape -- $target))
                break
            case ctrl-m
                set src
                if test -d "$target"
                    set dir $target
                    test "$dir" = "$startdir" && set dir .
                    set q
                else
                    commandline -rt -- (string join -- ' ' (string escape -- $target))
                    break
                end
            case ctrl-o
                if test "$src" = locate -o "$src" = z
                    set src
                    set dir (dirname $target)
                    set q
                    continue
                end
                set src
                test "$dir" = . -o "$dir" = "" && set dir (pwd)
                set -l parent (string replace -r -- '/[^/]+$' '' $dir)
                switch $parent
                    case ""
                        set dir /
                    case $dir
                        set dir .
                    case '*'
                        set dir $parent
                end
                set q
            case ctrl-r
                set src
                test "$mode" = ls && set mode fd || set mode ls
                if test -n "$target"
                    set -l dirname (dirname $target)
                    test -d "$dirname" && set dir $dirname
                end
            case ctrl-s
                set src
                test -n "$all" && set all || set all 1
                if test -n "$all"
                    set ls_opts -a
                    set fd_opts --hidden
                else
                    set ls_opts
                    set fd_opts
                end
            case ctrl-t
                set src
                # XXX: code copy
                set -l cwd $PWD/
                if test "$PWD" = (string trim -r -c / -- $dir)
                    set dir .
                else if test "$cwd" = (string sub -s 1 -l (string length -- $cwd) -- $dir)
                    set dir (string replace -- $cwd '' $dir)
                else
                    set dir (builtin cd -- $dir; pwd)
                end
            case ctrl-g
                if test "$src" = locate -o "$src" = z
                    set src
                    set dir $target
                    test -d "$dir" || set dir (dirname $target)
                    set q
                    continue
                end
                echo "cd $dir"
                cd -- $dir
                commandline -rt -- ""
                break
            case ctrl-z
                # set src z
                test "$src" = z && set src || set src z
                continue
                # set q
            case alt-j
                test -n "$__fff_ttt" && set q (echo "$q" | $__fff_ttt)
            case ctrl-x
                # set src locate
                test "$src" = locate && set src || set src locate
                continue
            case '*'
                break
        end
    end
    commandline -f repaint
end
