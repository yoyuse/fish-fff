function __fff
    # __fff_usage
    if test -z "$__fff_usage"
        set -gx __fff_usage "\
Keybind:
    ?         Show help
    Return    Print file path and exit / Enter directory
    C-g       Exit with CWD
    C-h, BS   Parent directory (if query is empty)
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
    C-SPC     Toggle preview
    A-H       \$HOME directory
    A-I       Initial directory
"
    end

    # __fff_color_pl
    if test -z "$__fff_color_pl"
        set -gx __fff_color_pl 'if (-d s!\n!!r) {s!.*!\033[34m$&\033[m!;} else {s!.*/!\033[34m$&\033[m!;}'
    end

    # __fff_fzf
    if test -z "$__fff_fzf"
        for fzf in fzf sk
            if type -q $fzf
                set -gx __fff_fzf $fzf
                break
            end
        end
    end

    # __fff_ls, __fff_ls_F
    if test -z "$__fff_ls"
        type -q gls && set __fff_ls gls || set __fff_ls ls
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

    # __fff_fd, __fff_find
    if test -z "$__fff_fd" -a -z "$__fff_find"
        type -q fd && set -l _fd fd
        type -q fdfind && set -l _fd fdfind
        if test -n "$_fd"
            if $_fd --max-depth 0 --strip-cwd-prefix >/dev/null 2>&1
                set _fd $_fd --strip-cwd-prefix
            end
            set -gx __fff_fd $_fd --color=always --follow --no-ignore
        else
            set -gx __fff_find find -L .
            set -gx __fff_find_filter perl -ne '{chomp; next if m:/\.:; s:^\./::; next if /^\.$/; $_ .= "/" if $_ ne "/" && -d $_; print "$_\n";}'
            set -gx __fff_ls_filter perl -ne '{chomp; next if m:/\.:; $_ .= "/" if $_ ne "/" && -d $_; print "$_\n";}'
        end
    end

    # __fff_pager, __fff_bat
    if test -z "$__fff_pager" -o -z "$__fff_bat"
        if type -q batcat
            set -gx __fff_pager batcat --color=always --plain --paging=always
            set -gx __fff_bat batcat --color=always --plain
        else if type -q bat
            set -gx __fff_pager bat --color=always --plain --paging=always
            set -gx __fff_bat bat --color=always --plain
        else
            set -gx __fff_pager less -R
            set -gx __fff_bat cat
        end
    end

    # __fff_editor
    if test -z "$__fff_editor"
        if type -q nvim
            set -gx __fff_editor nvim
        else if type -q vim
            set -gx __fff_editor vim
        else
            set -gx __fff_editor vi
        end
    end

    # __fff_ttt
    if test -z "$__fff_ttt"
        for _ttt in go-ttt cli-ttt cli-ttt.rb
            if type -q $_ttt
                set -gx __fff_ttt $_ttt
                break
            end
        end
    end

    # CLICOLOR_FORCE
    set -lx CLICOLOR_FORCE 1

    # LESSOPEN
    set -l less_opts -iMR
    switch $SHELL
        case '*fish'
            # set -x LESSOPEN '|set t %s; test -d $t && '"$__fff_ls"' -l $ls_opts -- $t || '"$__fff_bat"' -- $t'
            set -x LESSOPEN '|set t %s; test -d $t && begin; '"$__fff_ls"' -dl $ls_opts -- $t; '"$__fff_ls"' -l $ls_opts -- $t; end || '"$__fff_bat"' -- $t'
        case '*'
            # set -x LESSOPEN '|t=%s; test -d $t && '"$__fff_ls"' -l $ls_opts -- $t || '"$__fff_bat"' -- $t'
            set -x LESSOPEN '|t=%s; test -d $t && ('"$__fff_ls"' -dl $ls_opts -- $t; '"$__fff_ls"' -l $ls_opts -- $t) || '"$__fff_bat"' -- $t'
    end

    set -l src
    set -l mode ls
    set -lx ls_opts -1 # XXX: 空の値であってはならない (LESSOPEN との兼ね合い)
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
    # preserve dir
    set -l prev_dir
    set -l row
    # /preserve dir
    set -l tmp (mktemp /tmp/fff.XXXXXXXXXX)
    rm -f $tmp                  # XXX: unsafe

    while true
        test -d "$dir" && builtin cd -- $dir
        set filter cat
        if test "$mode" = ls
            set cmd $__fff_ls $ls_opts
            test -z "$__fff_fd" && set filter $__fff_ls_filter
        else if test -n "$__fff_fd"
            set cmd $__fff_fd $fd_opts
        else
            set cmd $__fff_find
            set filter $__fff_find_filter
        end
        set prompt (string replace -a -r -- '(\.?[^/])[^/]*/' '$1/' (string replace -r -- '^'"$HOME"'($|/)' '~$1' $dir))" > "
        set fzf_opts --multi
        # preserve dir
        # pos(...) requires fzf >= 0.36.0
        if test -n "$row"
            set fzf_opts $fzf_opts --sync --bind "start:pos($row)"
        end
        # /preserve dir
        set color cat
        if test "$src" = locate
            set cmd locate /
            set prompt "LOCATE > "
            set fzf_opts --preview-window hidden
            set color perl -pe $__fff_color_pl
        else if test "$src" = z
            set cmd z --list
            set filter sed 's/^[0-9,.]* *//'
            set prompt "Z > "
            set fzf_opts --no-sort --preview-window hidden
            set color perl -pe $__fff_color_pl
        end
        rm -f $tmp
        set out ($cmd | $filter | $color |
        $__fff_fzf --ansi \
            --bind "?:execute(echo -n '$__fff_usage' | less >/dev/tty)+clear-screen" \
            --bind "ctrl-h:execute-silent(test -z {q} && echo {} > $tmp)+backward-delete-char/eof" \
            --bind "bspace:execute-silent(test -z {q} && echo {} > $tmp)+backward-delete-char/eof" \
            --bind "ctrl-k:kill-line" \
            --bind "ctrl-l:execute(less $less_opts -- {} </dev/tty >/dev/tty)+refresh-preview" \
            --bind "ctrl-q:abort" \
            --bind "ctrl-v:execute($__fff_editor -- {} </dev/tty >/dev/tty)+refresh-preview" \
            --bind "ctrl-w:backward-kill-word" \
            --bind "ctrl-space:toggle-preview" \
            --expect=ctrl-g,ctrl-j,ctrl-m,ctrl-o,ctrl-r,ctrl-s,ctrl-t,ctrl-x,ctrl-z \
            --expect=alt-H,alt-I \
            --expect=alt-j \
            --filepath-word \
            $fzf_opts \
            --keep-right \
            --preview "test -d {} && $__fff_ls_F $ls_opts -- {} || $__fff_pager -- {}" \
            --print-query \
            --prompt $prompt \
            --query=$q
        or begin test -f $tmp && begin echo; echo ctrl-h; cat $tmp; end; end)
        builtin cd -- $startdir
        test -z "$q" -a -z "$out" && break
        set q   $out[1]
        set k   $out[2]
        set res $out[3..-1]
        test "$dir" = . && set target $res || set target (string trim -r -c / -- $dir)"/"$res
        set res (string trim -r -c / -- $res)
        set dir (string trim -r -c / -- $dir)
        set target (string trim -r -c / -- $target)
        test "$src" = locate -o "$src" = z && set target $res
        switch $k
            case ctrl-j
                commandline -rt -- (string join -- ' ' (string escape -- $target))
                break
            case ctrl-m
                set src
                set row         # give up preserve dir
                if test -d "$target"
                    set dir $target
                    test "$dir" = "$startdir" && set dir .
                    set q
                else
                    commandline -rt -- (string join -- ' ' (string escape -- $target))
                    break
                end
            case ctrl-h ctrl-o
                if test "$src" = locate -o "$src" = z
                    set src
                    set row     # give up preserve dir
                    test -n "$target" && set dir (dirname $target)
                    set q
                    continue
                end
                set src
                test "$dir" = . -o "$dir" = "" && set dir (pwd)
                # preserve dir
                set prev_dir (basename $dir)
                # /preserve dir
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
                # preserve dir
                if test "$mode" = ls
                    # /bin/ls $ls_opts --color=never $dir | cat -nv 1>&2
                    # echo $prev_dir | cat -v 1>&2
                    set row ($__fff_ls $ls_opts --color=never $dir | awk '{i++; if ("'"$prev_dir"'" == $0) {print i;}}')
                    # echo $row 1>&2
                else
                    set row     # give up preserve dir
                end
                # /preserve dir
            case ctrl-r
                set src
                set row         # give up preserve dir
                test "$mode" = ls && set mode fd || set mode ls
                if test -n "$target"
                    set -l dirname (dirname $target)
                    test -d "$dirname" && set dir $dirname
                end
            case ctrl-s
                set src
                test -n "$all" && set all || set all 1
                # set row         # give up preserve dir
                if test -n "$all"
                    set ls_opts -1a
                    set fd_opts --hidden
                    set __fff_find_filter perl -ne '{chomp; s:^\./::; next if /^\.$/; $_ .= "/" if $_ ne "/" && -d $_; print "$_\n";}'
                else
                    set ls_opts -1
                    set fd_opts
                    set __fff_find_filter perl -ne '{chomp; next if m:/\.:; s:^\./::; next if /^\.$/; $_ .= "/" if $_ ne "/" && -d $_; print "$_\n";}'
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
                    set row         # give up preserve dir
                    if test -n "$target"
                        set dir $target
                        test -d "$dir" || set dir (dirname $target)
                    end
                    set q
                    continue
                end
                echo "cd $dir"
                cd -- $dir
                commandline -rt -- ""
                break
            case ctrl-z
                test "$src" = z && set src || set src z
                continue
            case alt-j
                test -n "$__fff_ttt" && set q (echo "$q" | $__fff_ttt)
            case ctrl-x
                test "$src" = locate && set src || set src locate
                continue
            case alt-H
                set src
                set row         # give up preserve dir
                set dir $HOME
                test "$dir" = "$startdir" && set dir .
                set q
            case alt-I
                set src
                set row         # give up preserve dir
                set dir .
                set q
            case '*'
                break
        end
    end
    commandline -f repaint
end
