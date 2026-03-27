local map = vim.keymap.set
local function opts(desc)
  return { noremap = true, silent = true, desc = desc }
end

-- Window navigation
map('n', '<C-h>', '<C-w>h', opts('Navigate to the left window'))
map('n', '<C-j>', '<C-w>j', opts('Navigate to the bottom window'))
map('n', '<C-k>', '<C-w>k', opts('Navigate to the top window'))
map('n', '<C-l>', '<C-w>l', opts('Navigate to the right window'))

-- Resize windows
map('n', '<C-Up>', ':resize -2<CR>', opts('Decrease window height'))
map('n', '<C-Down>', ':resize +2<CR>', opts('Increase window height'))
map('n', '<C-Left>', ':vertical resize -2<CR>', opts('Decrease window width'))
map('n', '<C-Right>', ':vertical resize +2<CR>', opts('Increase window width'))

-- Visual mode indenting
map('v', '<', '<gv', opts('Indent left and stay in visual mode'))
map('v', '>', '>gv', opts('Indent right and stay in visual mode'))

-- Move lines
map('v', '<A-j>', ":m '>+1<CR>gv=gv", opts('Move selection down'))
map('v', '<A-k>', ":m '<-2<CR>gv=gv", opts('Move selection up'))
map('n', '<A-j>', ':m .+1<CR>==', opts('Move line down'))
map('n', '<A-k>', ':m .-2<CR>==', opts('Move line up'))

-- File/buffer operations
map('n', '<leader>w', ':w<CR>', opts('Save file'))
map('n', '<leader>q', ':q<CR>', opts('Quit'))
map('n', '<Esc>', ':noh<CR>', opts('Clear search highlights'))
map('n', '<C-n>', ':Oil<CR>', opts('Open file browser'))
map('n', '<leader>cd', ':lcd %:p:h<CR>', opts('Change directory to current file'))
map('n', '<leader>sc', ':luafile $MYVIMRC<CR> :echo "Neovim configuration reloaded!"<CR>', opts('Reload Neovim configuration'))

-- Disable arrow keys (for discipline)
for _, mode in ipairs({ 'n', 'i', 'v', 'c' }) do
  map(mode, '<Up>', '<Nop>', opts('Disabled'))
  map(mode, '<Down>', '<Nop>', opts('Disabled'))
  map(mode, '<Left>', '<Nop>', opts('Disabled'))
  map(mode, '<Right>', '<Nop>', opts('Disabled'))
end

-- C++ specific
map('n', '<A-o>', ':ClangdSwitchSourceHeader<CR>', opts('Switch between header and source'))
