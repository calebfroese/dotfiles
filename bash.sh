ZSHRC=$HOME/.zshrc
ZSHENV=$HOME/.zshenv
ZSHRC_LINE="source ~/.caleb/.zshrc"
ZSHENV_LINE="source ~/.caleb/.zshenv"

if [ ! -f "$ZSHENV" ]; then
  touch "$ZSHENV"
fi
if [ ! -f "$ZSHRC" ]; then
  touch "$ZSHRC"
fi

grep -qxF "$ZSHRC_LINE" "$ZSHRC" || echo "$ZSHRC_LINE" >> "$ZSHRC"
grep -qxF "$ZSHENV_LINE" "$ZSHENV" || echo "$ZSHENV_LINE" >> "$ZSHENV"
