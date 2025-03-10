return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "folke/neodev.nvim",
    "p00f/clangd_extensions.nvim"
  },
  config = function()
    require('neodev').setup()

    require("mason").setup({
      ui = {
        border = "rounded",
      },
    })

    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "cmake","clangd", "ts_ls", "html", "svelte" },
      automatic_installation = true,
    })

    local lspconfig = require("lspconfig")

    local on_attach = function(_, bufnr)
      local opts = { noremap = true, silent = true, buffer = bufnr }
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
      vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
      vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
    end

    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    local lspconfig = require('lspconfig')

    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkthirdparty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })

    --More LSP Server configuration here
    lspconfig.clangd.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.html.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.ts_ls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.svelte.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.cmake.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
