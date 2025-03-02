local M = {}
function M.setup()
  require("oil").setup({
    -- Oil configuration options
    default_file_explorer = true,
    -- Use floating window for preview
    preview = {
      -- Set to false to disable the file preview
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
    -- Customize the window
    float = {
      -- Set this to false for normal buffer behavior
      max_width = 60,
      border = "rounded",
    },
    -- Customizing keymaps
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = function()
        local entry = require("oil").get_cursor_entry()

        if not entry then return end

        if entry.type == "directory" then
          require("oil.actions").select.callback()
        else
          -- Custom handler for CR to open files in the right buffer
          require("oil.actions").select.callback()
          -- If we're in the sidebar, focus the window to the right
          vim.cmd('wincmd l')
        end
      end,
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-s>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["-"] = "actions.parent",
      ["_"] = "actions.open_cwd",
      ["`"] = "actions.cd",
      ["~"] = "actions.tcd",
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
    },
  })
end

local oil_sidebar_open = false
local oil_sidebar_bufnr = 0
local oil_sidebar_width = 30 -- Adjust width as needed

function M.toggle_oil_sidebar()
  if oil_sidebar_open then
    -- Close the sidebar
    if vim.api.nvim_buf_is_valid(oil_sidebar_bufnr) then
      vim.api.nvim_buf_delete(oil_sidebar_bufnr, { force = true })
    end
    oil_sidebar_open = false
    oil_sidebar_bufnr = 0
  else
    local current_win = vim.api.nvim_get_current_win()

    vim.cmd('wincmd t')
    -- Open oil in a vertical split
    vim.cmd('leftabove ' .. oil_sidebar_width .. 'vsplit')

    -- Get the current directory or use vim's current working directory
    local path = vim.fn.getcwd()

    -- Open oil in the new split
    vim.cmd('Oil ' .. path)

    -- Store the buffer number for later
    oil_sidebar_bufnr = vim.api.nvim_get_current_buf()

    -- Set some buffer-local options to make it behave like a sidebar
    vim.bo[oil_sidebar_bufnr].buflisted = false
    vim.wo.winfixwidth = true

    -- Mark as open
    oil_sidebar_open = true
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "oil",
  callback = function(ev)
    -- If this is our sidebar buffer, set up additional configuration
    if oil_sidebar_open and vim.api.nvim_get_current_buf() == oil_sidebar_bufnr then
      -- Make sure there's a window to the right to receive the file
      local win_id = vim.fn.winnr('l')
      if win_id == 0 then
        -- If there's no window to the right, create one
        vim.cmd('rightbelow vsplit')
        vim.cmd('wincmd h') -- Go back to the oil buffer
      end
    end
  end,
})

return M
