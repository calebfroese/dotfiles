```
chezmoi init calebfroese
chezmoi apply --force
```

I don't like to manage `.zshrc` / `.zshenv` with Chezmoi as various applications tend to write to it, or I need to put local device specific configuration in there.
Instead, the managed versions of these live in `~/.caleb`, and simply need to be soured by their home directory counterparts.

```
echo "source ~/.caleb/.zshenv" >> ~/.zshenv
echo "source ~/.caleb/.zshrc" >> ~/.zshrc
```

