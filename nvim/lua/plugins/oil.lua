local M = {}

function M.toggle_oil_sidebar()
  local oil = require("oil")
  local win_id = vim.fn.bufwinid("oil://")

  if win_id ~= -1 then
    -- If Oil is already open, close it
    vim.api.nvim_win_close(win_id, true)
  else
    -- Open Oil as a floating window
    oil.open_float()
  end
end

function M.setup()
  require("oil").setup({
    default_file_explorer = true,
    -- Use floating windows by default
    default_view = "float",
    preview = {
      enabled = true,
      border = "rounded"
    },
    -- You can customize the appearance
    view_options = {
      -- Show hidden files
      show_hidden = false,
      -- Show file icon
      is_always_hidden = function(name, bufnr)
        return false
      end,
    },
    -- Customize the floating window
    float = {
      -- Set this to false for normal buffer behavior
      max_width = 60,
      max_height = 30,
      border = "rounded",
      win_options = {
        winblend = 10, -- slight transparency
      },
      override = function(conf)
        -- You can customize the floating window further here
        return conf
      end,
    },
    -- Customizing keymaps
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-s>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["<C-p>"] = "actions.preview",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["q"] = "actions.close", -- Add a quick way to close the floating window
    },
  })
end

return M
