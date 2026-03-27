local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

return require("lazy").setup({
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },

  {
    "nvim-neotest/nvim-nio"
  },

  {
    "habamax/vim-godot",
    ft = "gdscript",
  },

  require('plugins.telescope'),
  require('plugins.dap'),

  {
    "thomppa030/unreal-tools.nvim",
    branch = "dev",
    ft = { "cpp", "h", "hpp" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      require("unreal-tools").setup({
        ft = { "cpp", "h", "hpp" },
      })
    end,
  },

  require('plugins.lsp'),
  require('plugins.conform'),
  require('plugins.completion'),
  require('plugins.statusline'),

  -- which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({})
      wk.add({
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>d", group = "Debug" },
        { "<leader>t", group = "Terminal" },
        { "<leader>w", group = "Window" },
        { "<leader>s", group = "Settings" },
        { "<leader>c", group = "Code" },
      })
    end,
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps (which-key)"
      },
    },
  },

  require('plugins.colorizer'),
  require('plugins.gitsigns'),

  {
    'nvim-treesitter/nvim-treesitter',
    event = { "BufReadPre", "BufNewFile" },
    build = ':TSUpdate',
    opts = {
      ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python" },
      sync_install = false,
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  {
    'tjdevries/present.nvim',
    cmd = "Present",
  },

  require('plugins.terminal'),

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")

      npairs.setup({
        check_ts = true,
        ts_config = {
          lua = { 'string' },
          javascript = { 'template-string' },
        },
        disable_filetype = { "TelescopePrompt", "vim" },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", "'", '"', "<" },
          pattern = [=[[%'%"%>%]%)%}%,]]=],
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "Search",
          highlight_grey = "Comment"
        }
      })

      local Rule = require('nvim-autopairs.rule')
      npairs.add_rules({
        Rule("<", ">", { "lua", "html", "xml", "tsx", "jsx", "typescript", "javascript", "svelte", "vue" })
      })
    end,
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {},
  },
  {
    'goolord/alpha-nvim',
    dependencies = { 'echasnovski/mini.icons' },
    config = function()
      require 'alpha'.setup(require 'alpha.themes.startify'.config)
    end
  },
  {
    'brianhuster/live-preview.nvim',
    cmd = "LivePreview",
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
  },
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      require('plugins.oil').setup()
    end
  },

  require('theme')
})
