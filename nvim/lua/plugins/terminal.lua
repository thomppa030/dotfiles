return {
  'akinsho/toggleterm.nvim',
  version = "*",
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "Open terminal split" },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Open terminal float" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "Open terminal vertical" },
  },
  opts = {},
}
