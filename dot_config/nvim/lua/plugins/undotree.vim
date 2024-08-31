" Set up undo directory
let undo_dir = expand('~/.local/state/nvim/undo')
if !isdirectory(undo_dir)
  call mkdir(undo_dir, 'p')
endif

" Enable undofile and set undodir
set undofile
set undodir+=~/.local/state/nvim/undo

