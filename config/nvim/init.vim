" Set leader key to space
let mapleader = " "

" bootstrap lazy.nvim
lua << EOF
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
	print("Installing lazy.nvim...")
	vim.fn.system({
	  "git","clone","--filter=blob:none",
	  "https://github.com/folke/lazy.nvim.git",
	  "--branch=stable",
	  lazypath,
	})
	print("lazy.nvim installed. Please restart Neovim.")
end

vim.opt.rtp:prepend(lazypath)

local ok, lazy = pcall(require, "lazy")
if ok then
	lazy.setup("plugins")
end
EOF

" Use wl-clipboard explicitly
let g:clipboard = {
      \ 'name': 'wl-clipboard',
      \ 'copy': {
      \    '+': 'wl-copy',
      \    '*': 'wl-copy',
      \  },
      \ 'paste': {
      \    '+': 'wl-paste --no-newline',
      \    '*': 'wl-paste --no-newline',
      \  },
      \ 'cache_enabled': 0,
      \ }

" Use system clipboard
set clipboard+=unnamedplus

" Line numbers
set number

"     Enable Autoread
set autoread
autocmd FocusGained,BufEnter,CursorHold * checktime
