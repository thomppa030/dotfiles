local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend('force', options, opts)
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- better window navigation
map('n', '<C-h>', '<C-w>h', {desc = 'Navigate to the left window'})
map('n', '<C-j>', '<C-w>j', {desc = 'Navigate to the bottom window'})
map('n', '<C-k>', '<C-w>k', {desc = 'Navigate to the top window'})
map('n', '<C-l>', '<C-w>l', {desc = 'Navigate to the right window'})

-- Resize with arrows
map('n', '<C-Up>', ':resize -2<CR>', {desc = 'Decrease window height'})
map('n', '<C-Down>', ':resize +2<CR>', {desc = 'Increase window height'})
map('n', '<C-Left>', ':vertical resize -2<CR>', {desc = 'Decrease window width'})
map('n', '<C-Right>', ':vertical resize +2<CR>', {desc = 'Increase window width'})

-- Stay in indent mode when indenting in visual mode
map('v', '<', '<gv', {desc = 'Indent left and keep selection'})
map('v', '>', '>gv', {desc = 'Indent right and keep selection'})

-- Move text up and down
map('n', '<A-j>', ':m .+1<CR>==', {desc = 'Move line down'})
map('n', '<A-k>', ':m .-2<CR>==', {desc = 'Move line up'})
map('v', '<A-j>', ":m '>+1<CR>gv=gv", {desc = 'Move selection down'})
map('v', '<A-k>', ":m '>-2<CR>gv=gv", {desc = 'Move selection down'})

map('n', '<C-n>', ':lua require("plugins/oil").toggle_oil_sidebar()<CR>')

map('n', '<leader>gg', ':tabnew<CR>:terminal lazygit<CR>i', {desc = 'Open a terminal with lazygit in a new tab'})

-- Change cwd
map('n', '<leader>cd', ':lcd %:p:h<CR>', {noremap = true, silent = true, desc = "Changes the current working directory to current path"})

map('n', '<leader>sc', ':luafile $MYVIMRC<CR> :echo "Neovim configuration reloaded!"<CR>', {noremap = true, silent = true, desc = "Reloads Vim Configuration"})

-- Other
map('n', '<leader>w', ':w<CR>', {desc = "Save file"})
map('n', '<leader>q', ':q<CR>', {desc = "Quit"})
map('n', '<Esc>', ':noh<CR>', {desc = "Clear search highlights"})
