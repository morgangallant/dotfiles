```bash
$ stow -v <group> -t $HOME/
```

`-n` shows what it _would_ install.

Vim plugins are git submodules, so clone with `--recurse-submodules` (or run
`git submodule update --init` after cloning). Update them with
`git submodule update --remote`.
