# fish-fff

Command-line Fuzzy File Finder for Fish, inspired by [b4b4r07/cli-finder](https://github.com/b4b4r07/cli-finder).

## Usage

`C-s` - invoke fish-fff

### Keybind

| Key      | Action                                     |
|----------|--------------------------------------------|
| `?`      | Show help                                  |
| `Return` | Print file path and exit / Enter directory |
| `C-j`    | Print path and exit                        |
| `C-l`    | View file                                  |
| `C-o`    | Parent directory                           |
| `C-q`    | Exit                                       |
| `C-r`    | Toggle recursive search                    |
| `C-s`    | Toggle absolute path                       |
| `C-t`    | Toggle preview                             |
| `C-v`    | Edit file                                  |
| `C-x`    | Chdir and exit                             |
| `C-z`    | Toggle invisibles                          |
| `A-z`    | Jump around with `z`                       |

## Requirements

- [junegunn/fzf](https://github.com/junegunn/fzf)
- color `ls` (GNU ls or BSD ls)
- [sharkdp/bat](https://github.com/sharkdp/bat) or `less`
- [sharkdp/fd](https://github.com/sharkdp/fd) or `find`
- [jethrokuan/z](https://github.com/jethrokuan/z)
- (Optional) [yoyuse/cli-ttt](https://github.com/yoyuse/cli-ttt) or [yoyuse/go-ttt](https://github.com/yoyuse/go-ttt)

## Related

### cli-finder

- [GitHub - b4b4r07/cli-finder: A command-line finder with fzf](https://github.com/b4b4r07/cli-finder)
- [私の fzf 活用事例 | tellme.tokyo](https://tellme.tokyo/post/2015/11/08/013526/)

