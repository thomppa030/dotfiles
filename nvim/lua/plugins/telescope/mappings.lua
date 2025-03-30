-- Global Telescope keymappings
local M = {}

-- Register global mappings for Telescope
function M.setup_global_mappings()
  local builtin = require('telescope.builtin')

  -- Core functionality
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
  vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

  -- Extended functionality can be added by mode modules
end

-- Create a registry for mode-specific mappings
M.mode_mappings = {}

-- Function to register mode mappings
function M.register_mode_mappings(mode_name, mappings)
  M.mode_mappings[mode_name] = mappings

  -- Apply the mappings
  for key, mapping in pairs(mappings) do
    vim.keymap.set(
      mapping.mode or 'n',
      key,
      mapping.command,
      { desc = mapping.desc }
    )
  end
end

-- Set up global mappings
M.setup_global_mappings()

return M
