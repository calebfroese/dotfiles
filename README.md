# Installation

Install [Chezmoi](https://www.chezmoi.io/install/) for your OS.

```
chezmoi init calebfroese
chezmoi apply --force
```

## Notes

I don't like to manage `.zshrc` / `.zshenv` with Chezmoi as various applications tend to write to it, or I need to put local device specific configuration in there.
Instead, the managed versions of these live in `~/.caleb`, and simply need to be soured by their home directory counterparts.
Chezmoi will do this automatically during the apply scripts.

