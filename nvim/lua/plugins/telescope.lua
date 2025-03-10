return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
  },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            -- Add items to quickfix when pressing Ctrl+q
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,

            -- Add selected items to quickfix list without opening it
            ["<C-a>"] = actions.send_selected_to_qflist,

            -- This adds items to quickfix and opens it
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

            -- Toggle selection and move to next item
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,

            -- Toggle selection and move to previous item
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
          },
          n = {
            -- Same mappings for normal mode
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<C-a>"] = actions.send_selected_to_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_next,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_previous,
          }
        },
        -- Make sure the prompt is visible enough
        prompt_prefix = "❯ ",
        selection_caret = "❯ ",
        -- Show selection info (how many items are selected)
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
        -- Customizing file pickers to enable multi-select by default
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
    })

    -- Load extensions
    telescope.load_extension('fzf')

    -- Register custom function to add files to quickfix list
    local function add_to_quickfix()
      local picker = action_state.get_current_picker(vim.api.nvim_get_current_buf())
      local selections = picker:get_multi_selection()

      if #selections == 0 then
        -- If nothing is explicitly selected, select current item
        local selection = action_state.get_selected_entry()
        if selection then
          selections = { selection }
        end
      end

      if #selections > 0 then
        local qf_entries = {}
        for _, selection in ipairs(selections) do
          -- Handle different types of selections (files, grep results, etc.)
          if selection.filename then
            table.insert(qf_entries, {
              filename = selection.filename,
              lnum = selection.lnum or 1,
              col = selection.col or 1,
              text = selection.text or "",
            })
          end
        end

        if #qf_entries > 0 then
          -- Set the quickfix list
          vim.fn.setqflist(qf_entries)
          vim.cmd("copen")
          -- Return to previous window
          vim.cmd("wincmd p")
        end
      end
    end

    -- Setup keymaps
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help Tags' })

    -- Quick find references with LSP
    vim.keymap.set('n', '<leader>fr', builtin.lsp_references, { desc = 'Find references' })

    -- Add quickfix list integration keymaps
    vim.keymap.set('n', '<leader>fq', function()
      -- Find files and add to quickfix
      builtin.find_files({
        attach_mappings = function(_, map)
          map("i", "<C-q>", add_to_quickfix)
          map("n", "<C-q>", add_to_quickfix)
          return true
        end
      })
    end, { desc = 'Find files and add to quickfix' })
  end,
}
