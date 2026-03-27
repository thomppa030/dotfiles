return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "p00f/clangd_extensions.nvim",
  },
  config = function()
    local has_mason, mason = pcall(require, "mason")
    if has_mason then
      mason.setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end

    require("mason-lspconfig").setup({
      ensure_installed = { "pylsp", "lua_ls", "cmake", "clangd", "ts_ls", "html", "svelte" },
      automatic_installation = true,
    })

    -- Diagnostics
    vim.diagnostic.config({
      virtual_text = {
        prefix = '■',
        spacing = 4,
      },
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = " ",
          [vim.diagnostic.severity.INFO] = " ",
        },
      },
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })

    -- Manual format keymap via LspAttach (format-on-save handled by conform.nvim)
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        vim.keymap.set('n', '<leader>lf', function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, { buffer = args.buf, desc = "Format file" })
      end,
    })

    -- Server configs via vim.lsp.config (Neovim 0.11+)
    local lspconfig = require('lspconfig')

    vim.lsp.config('lua_ls', {
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          telemetry = { enable = false },
        },
      },
    })

    vim.lsp.config('ts_ls', {
      root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json"),
      single_file_support = false,
    })

    vim.lsp.config('denols', {
      root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
      single_file_support = false,
    })

    vim.lsp.enable({
      "lua_ls", "ts_ls", "denols", "clangd", "html",
      "svelte", "cmake", "jsonls", "pylsp",
    })
  end
}
