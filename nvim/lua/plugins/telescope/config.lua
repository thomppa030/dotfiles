-- Update your config.lua with these new mappings
local actions = require('telescope.actions')

return {
  defaults = {
    mappings = {
      i = {
        -- Add <C-j> and <C-k> for navigation
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,

        -- Keep your existing mappings
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<C-a>"] = actions.send_selected_to_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
      },
      n = {
        -- Add <C-j> and <C-k> for navigation in normal mode too
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,

        -- Keep your existing normal mode mappings
        ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
        ["<C-a>"] = actions.send_selected_to_qflist,
        ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
        ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
      }
    },
    -- Keep all your other existing settings
    prompt_prefix = "❯ ",
    selection_caret = "❯ ",
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    layout_strategy = "horizontal",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
        results_width = 0.8,
      },
      vertical = {
        mirror = false,
      },
      width = 0.87,
      height = 0.80,
      preview_cutoff = 120,
    },
  },
  pickers = {
    -- Default configurations for pickers
    find_files = {
      theme = "dropdown",
      previewer = false,
      multi_select = true,
    },
    live_grep = {
      multi_select = true,
    },
    buffers = {
      multi_select = true,
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  }
}
