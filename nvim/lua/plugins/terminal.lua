return{
  'akinsho/toggleterm.nvim',
  version = "*",
  opts = function()
    vim.api.nvim_set_keymap('n', '<leader>tt', ':ToggleTerm <CR>',
      { noremap = true, silent = true, desc = "Opens a terminal in a split!" })
    vim.api.nvim_set_keymap('n', '<leader>tf', ':ToggleTerm direction=float<CR>',
      { noremap = true, silent = true, desc = "Opens a terminal in a split!" })
    vim.api.nvim_set_keymap('n', '<leader>tv', ':ToggleTerm direction=vertical<CR>',
      { noremap = true, silent = true, desc = "Opens a terminal in a split!" })
  end
}
