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

" Clipboard provider: prefer OSC52 over SSH, otherwise wl-clipboard when available
if exists('$SSH_TTY')
  lua << EOF
local ok, osc52 = pcall(require, 'vim.ui.clipboard.osc52')
if ok then
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = osc52.paste('+'),
      ['*'] = osc52.paste('*'),
    },
  }
  vim.opt.clipboard:append('unnamedplus')
end
EOF
elseif executable('wl-copy') && executable('wl-paste')
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
  set clipboard+=unnamedplus
endif

" Line numbers
set number

"     Enable Autoread
set autoread
autocmd FocusGained,BufEnter,CursorHold * checktime
