# fish-fff

Command-line Fuzzy File Finder for [Fish](https://fishshell.com/), inspired by [b4b4r07/cli-finder](https://github.com/b4b4r07/cli-finder).

## Usage

`C-s` - Invoke fish-fff

### Keybind

| Key      | Action                                     |
|----------|--------------------------------------------|
| `?`      | Show help                                  |
| `Return` | Print file path and exit / Enter directory |
| `C-g`    | Exit with CWD                              |
| `C-j`    | Print path and exit                        |
| `C-l`    | View file                                  |
| `C-o`    | Parent directory                           |
| `C-q`    | Exit                                       |
| `C-r`    | Toggle recursive search                    |
| `C-s`    | Toggle invisibles                          |
| `C-t`    | Toggle absolute path                       |
| `C-v`    | Edit file                                  |
| `C-x`    | Find path with `locate`                    |
| `C-z`    | Jump around with `z`                       |
| `C-SPC`  | Toggle preview                             |
| `A-H`    | `$HOME` directory                          |
| `A-I`    | Initial directory                          |

## Requirements

- [junegunn/fzf](https://github.com/junegunn/fzf) or [lotabout/skim](https://github.com/lotabout/skim)
- color `ls` (GNU ls or BSD ls)
- [sharkdp/bat](https://github.com/sharkdp/bat) and `less`
- [sharkdp/fd](https://github.com/sharkdp/fd) or `find`
- `locate`
- [jethrokuan/z](https://github.com/jethrokuan/z)
- (Optional) [yoyuse/cli-ttt](https://github.com/yoyuse/cli-ttt) or [yoyuse/go-ttt](https://github.com/yoyuse/go-ttt)

## Installation

Install with [Fisher](https://github.com/jorgebucaran/fisher):

``` shellsession
fisher install yoyuse/fish-fff
```

## Related

### cli-finder

- [GitHub - b4b4r07/cli-finder: A command-line finder with fzf](https://github.com/b4b4r07/cli-finder)
- [私の fzf 活用事例 | tellme.tokyo](https://tellme.tokyo/post/2015/11/08/013526/)

## License

MIT
