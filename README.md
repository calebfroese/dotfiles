## My Dotfiles

This repository contains my dotfiles. I use [Chezmoi](https://www.chezmoi.io/) to simplify keeping multiple devices in sync and making the dotfiles as transportable as possible.

## Installation

[Install Chezmoi](https://www.chezmoi.io/install/) for your OS.

```
chezmoi init calebfroese --apply --force
```

## Notes

- I don't like to manage `.zshrc` / `.zshenv` as various applications tend to write to it, or I need to put local device specific configuration in there.
Instead, the dotfile versions of these live in `~/.caleb`, and simply need to be soured by their home directory counterparts.
Chezmoi will do this automatically during the apply scripts.
- I usually kick off `tmux` when I first open a shell. I don't like to automatically enter a tmux session as it makes it annoying to iterate the config or debug (looking at you obscure nvim<>tmux over ssh bug).

## Development

The development loop typically looks like:

```
# make a bunch of edits to e.g. nvim config
chezmoi add ~/.config/nvim
chezmoi cd
# git add .. commit .. push .. etc
```

## Troubleshooting

### tmux

Installing tmux plugins should happen automatically. I've had odd behaviour where it doesn't, in that case, simply following the [TPM plugin installation flow](https://github.com/tmux-plugins/tpm).
