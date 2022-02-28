# 2022-02-28

set -q FISH_FFF_DISABLE_KEYBINDINGS; or set -U FISH_FFF_DISABLE_KEYBINDINGS 0

if test "$FISH_FFF_DISABLE_KEYBINDINGS" -ne 1
    bind \cs __fff
    bind \es '__fff --source'

    if bind -M insert >/dev/null 2>/dev/null
        bind -M insert \cs __fff
        bind -M insert \es '__fff --source'
    end
end

function _fish_fff_uninstall -e fish_fff_uninstall
    bind --user \
        | string replace --filter --regex -- "bind (.+)( '?__fff.*)" 'bind -e $1' \
        | source

    set --names \
        | string replace --filter --regex '(^FISH_FFF.*)' 'set --erase $1' \
        | source

    set --names \
        | string replace --filter --regex '(^__fff.*)' 'set --erase $1' \
        | source

    functions --all \
        | string replace --filter --regex -- "(^__fff.*)" 'functions --erase $1' \
        | source
end
