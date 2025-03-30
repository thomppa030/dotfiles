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
    else
      vim.notify("Mason not found, skipping automated LSP server installation", vim.log.levels.WARN)
    end

    require("mason-lspconfig").setup({
      ensure_installed = { "pylsp", "lua_ls", "cmake", "clangd", "ts_ls", "html", "svelte" },
      automatic_installation = true,
    })


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

      -- Buffer-local options for LSP
      vim.api.nvim_create_autocmd("BufWritePre", {
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            async = false,
            bufnr = bufnr,
          })
        end,
      })
    end

    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Add completion capabilities from cmp_nvim_lsp if available
    local has_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    if has_cmp then
      capabilities = cmp_lsp.default_capabilities(capabilities)
    end

    -- Add additional capabilities
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      }
    }

    local lspconfig = require('lspconfig')

    vim.diagnostic.config({
      virtual_text = {
        prefix = '■',
        spacing = 4,
      },
      signs = true,
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

    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    end

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
    lspconfig.denols.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.cmake.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.jsonls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    lspconfig.pylsp.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end
}
