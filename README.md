# vfinder-cmus

![Badge version](https://img.shields.io/badge/version-0.0.1-blue.svg?style=flat-square "Badge for version")
![License version](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square "Badge for license")

A [cmus](https://cmus.github.io/) source for [vfinder.vim](https://github.com/kabbamine/vfinder.vim).

![Demo of vfinder-cmus](.img/vfinder_demo.gif "Old demo of vFinder")

# Installation

e.g. with [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'kabbamine/vfinder.vim'
Plug 'kabbamine/vfinder-cmus.vim'
```

# Usage

```viml
call vfinder#i('cmus')
```

## Mappings

|  modes  | action         | default value |
| :-----: | -------------- | :-----------: |
| `i`/`n` | `play`         | `<CR>`/`<CR>` |
| `i`/`n` | `queue`        |  `<C-s>`/`s`  |
| `i`/`n` | `pre_queue`    |  `<C-v>`/`v`  |
| `i`/`n` | `show_current` |  `<C-o>`/`o`  |

# License

MIT
