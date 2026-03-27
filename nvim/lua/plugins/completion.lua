return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  dependencies = {
    "L3MON4D3/LuaSnip",
  },
  config = function()
    require("snippets").setup()

    require("blink.cmp").setup({
      snippets = { preset = "luasnip" },

      sources = {
        default = { "lsp", "snippets", "buffer", "path" },
      },

      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show" },
        ["<C-e>"] = { "cancel" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up" },
        ["<C-f>"] = { "scroll_documentation_down" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },

      completion = {
        ghost_text = { enabled = true },
        menu = {
          border = "rounded",
          draw = {
            columns = { { "kind_icon" }, { "label", gap = 1 }, { "source_name" } },
          },
        },
        documentation = {
          auto_show = true,
          window = { border = "rounded" },
        },
        list = {
          selection = { preselect = true, auto_insert = false },
        },
      },

      appearance = {
        kind_icons = {
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",
          Field = "󰜢",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "",
        },
      },
    })
  end,
}
