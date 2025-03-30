-- lua/keymaps/telescope.lua
-- Telescope-specific keybindings without direct module loading

local M = {}

function M.setup(keymaps)
  -- Register core Telescope mappings using commands
  -- This avoids requiring the telescope module during initialization
  keymaps.register("telescope", {
    n = {
      -- File pickers
      ["<leader>ff"] = { "<cmd>Telescope find_files<cr>", { desc = "Find files in project" } },
      ["<leader>fa"] = { "<cmd>Telescope find_files hidden=true<cr>", { desc = "Find all files (including hidden)" } },
      ["<leader>fg"] = { "<cmd>Telescope live_grep<cr>", { desc = "Live grep" } },
      ["<leader>fb"] = { "<cmd>Telescope buffers<cr>", { desc = "Find buffers" } },
      ["<leader>fh"] = { "<cmd>Telescope help_tags<cr>", { desc = "Find help tags" } },
      ["<leader>fm"] = { "<cmd>Telescope man_pages<cr>", { desc = "Find man pages" } },
      ["<leader>fr"] = { "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" } },
      ["<leader>fc"] = { "<cmd>Telescope command_history<cr>", { desc = "Command history" } },
      ["<leader>fs"] = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Search in current buffer" } },

      -- Special pickers
      ["<leader>fw"] = { "<cmd>Telescope grep_string<cr>", { desc = "Find word under cursor" } },
      ["<leader>fp"] = { "<cmd>Telescope projects<cr>", { desc = "Projects" } },
      ["<leader>ft"] = { "<cmd>Telescope todo_finder<cr>", { desc = "Find TODOs" } },

      -- Vim pickers
      ["<leader>fk"] = { "<cmd>Telescope keymaps<cr>", { desc = "Find keymaps" } },
      ["<leader>fo"] = { "<cmd>Telescope vim_options<cr>", { desc = "Find vim options" } },
      ["<leader>fj"] = { "<cmd>Telescope jumplist<cr>", { desc = "Jumplist" } },
      ["<leader>fn"] = { "<cmd>Telescope registers<cr>", { desc = "Registers" } },
      ["<leader>fu"] = { "<cmd>Telescope colorscheme<cr>", { desc = "Colorschemes" } },
      ["<leader>fC"] = { "<cmd>Telescope commands<cr>", { desc = "Commands" } },
      ["<leader>fA"] = { "<cmd>Telescope autocommands<cr>", { desc = "Autocommands" } },
    },
  })

  -- Register Git Telescope mappings
  keymaps.register("git_telescope", {
    n = {
      ["<leader>gc"] = { "<cmd>Telescope git_commits<cr>", { desc = "Git commits" } },
      ["<leader>gC"] = { "<cmd>Telescope git_bcommits<cr>", { desc = "Git buffer commits" } },
      ["<leader>gb"] = { "<cmd>Telescope git_branches<cr>", { desc = "Git branches" } },
      ["<leader>gs"] = { "<cmd>Telescope git_status<cr>", { desc = "Git status" } },
      ["<leader>gS"] = { "<cmd>Telescope git_stash<cr>", { desc = "Git stash" } },
      ["<leader>gg"] = { "<cmd>ToggleTerm direction=float<cr>lazygit<cr>", { desc = "Open Lazygit in floating terminal" } },
    },
  })

  -- Register LSP Telescope mappings
  keymaps.register("lsp_telescope", {
    n = {
      ["<leader>ls"] = { "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document symbols" } },
      ["<leader>lS"] = { "<cmd>Telescope lsp_workspace_symbols<cr>", { desc = "Workspace symbols" } },
      ["<leader>lr"] = { "<cmd>Telescope lsp_references<cr>", { desc = "References" } },
      ["<leader>li"] = { "<cmd>Telescope lsp_implementations<cr>", { desc = "Implementations" } },
      ["<leader>ld"] = { "<cmd>Telescope lsp_definitions<cr>", { desc = "Definitions" } },
      ["<leader>lt"] = { "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Type definitions" } },
      ["<leader>la"] = { "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" } },
    },
  })

  -- Register DAP Telescope mappings
  keymaps.register("dap_telescope", {
    n = {
      ["<leader>dc"] = { "<cmd>Telescope dap commands<cr>", { desc = "DAP commands" } },
      ["<leader>dC"] = { "<cmd>Telescope dap configurations<cr>", { desc = "DAP configurations" } },
      ["<leader>db"] = { "<cmd>Telescope dap list_breakpoints<cr>", { desc = "DAP breakpoints" } },
      ["<leader>dv"] = { "<cmd>Telescope dap variables<cr>", { desc = "DAP variables" } },
      ["<leader>df"] = { "<cmd>Telescope dap frames<cr>", { desc = "DAP frames" } },
    },
  })

  -- Add special file browser mappings
  keymaps.register("file_browser", {
    n = {
      ["<leader>fd"] = { "<cmd>Telescope file_browser<cr>", { desc = "File browser" } },
    },
  })

  -- Register the C++ documentation finder
  keymaps.register("cpp_docs", {
    n = {
      ["<leader>dc"] = { "<cmd>Telescope cpp_docs lookup_by_category<cr>", { desc = "C++ docs by category" } },
      ["<leader>ds"] = { "<cmd>Telescope cpp_docs search_all_docs<cr>", { desc = "Search all C++ docs" } },
    },
  })
end

return M
