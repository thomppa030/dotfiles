-- plugins/dap.lua
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-telescope/telescope-dap.nvim",
    "jbyuki/one-small-step-for-vimkind", -- Lua debugging
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- DAP UI setup
    dapui.setup({
      icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
      mappings = {
        -- Use a table to apply multiple mappings
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        edit = "e",
        repl = "r",
        toggle = "t",
      },
      -- Expand lines larger than the window
      expand_lines = vim.fn.has("nvim-0.7") == 1,
      layouts = {
        {
          elements = {
            -- Elements can be strings or table with id and size keys.
            { id = "scopes", size = 0.25 },
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 40, -- 40 columns
          position = "left",
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 0.25, -- 25% of total lines
          position = "bottom",
        },
      },
      controls = {
        -- Requires Neovim nightly (or 0.8 when released)
        enabled = true,
        -- Display controls in this element
        element = "repl",
        icons = {
          pause = "",
          play = "",
          step_into = "",
          step_over = "",
          step_out = "",
          step_back = "",
          run_last = "",
          terminate = "",
        },
      },
      floating = {
        max_height = nil,  -- These can be integers or a float between 0 and 1.
        max_width = nil,   -- Floats will be treated as percentage of your screen.
        border = "single", -- Border style. Can be "single", "double" or "rounded"
        mappings = {
          close = { "q", "<Esc>" },
        },
      },
      windows = { indent = 1 },
      render = {
        max_type_length = nil, -- Can be integer or nil.
        max_value_lines = 100, -- Can be integer or nil.
      }
    })

    -- Virtual text setup
    require("nvim-dap-virtual-text").setup({
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = false,
      show_stop_reason = true,
      commented = false,
      virt_text_pos = 'eol',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil
    })

    -- Configure C/C++ adapter with LLDB for better C++ and Unreal support
    dap.adapters.lldb = {
      type = 'executable',
      command = vim.fn.stdpath("data") .. '/mason/bin/codelldb',
      name = 'lldb'
    }

    -- Helper function to find CMake build directory and executable
    local function get_cmake_targets()
      -- Discover build directories (common patterns)
      local build_dirs = {
        "./build",
        "./build/Debug",
        "./build/Release",
        "./out/build",
        "./cmake-build-debug",
        "./cmake-build-release",
      }

      -- Try to find compile_commands.json to identify build dir
      local compile_commands_dirs = vim.fn.glob("**/compile_commands.json", true, true)
      for _, file in ipairs(compile_commands_dirs) do
        table.insert(build_dirs, 1, vim.fn.fnamemodify(file, ":h"))
      end

      -- Look for executables in build directories
      local executables = {}
      for _, dir in ipairs(build_dirs) do
        if vim.fn.isdirectory(dir) == 1 then
          -- Find executables in the build directory (excluding .dll, .so files)
          local files = vim.fn.glob(dir .. "/**", false, true)
          for _, file in ipairs(files) do
            if vim.fn.executable(file) == 1 and
                not file:match("%.dll$") and
                not file:match("%.so$") and
                not file:match("%.cmake$") and
                not file:match("CMakeFiles") then
              table.insert(executables, file)
            end
          end
        end
      end

      return executables
    end

    local function select_cmake_target()
      local targets = get_cmake_targets()

      if #targets == 0 then
        -- Fallback to manual input if no targets found
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      elseif #targets == 1 then
        -- Use the only target without prompting
        return targets[1]
      else
        -- Show selection if multiple targets found
        local choice = nil
        vim.ui.select(targets, {
          prompt = "Select executable",
          format_item = function(item)
            return vim.fn.fnamemodify(item, ":t") .. " (" .. item .. ")"
          end,
        }, function(selected)
          choice = selected
        end)
        return choice
      end
    end

    dap.configurations.cpp = {
      {
        name = "Launch CMake target",
        type = "lldb",
        request = "launch",
        program = select_cmake_target,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        -- LLDB specific options for better C++ display
        initCommands = {
          "settings set target.inline-breakpoint-strategy always",
          "settings set target.process.thread.step-avoid-regexp \"\"",
        },
        -- For Unreal Engine projects - enable if needed
        -- env = function()
        --   local variables = {}
        --   for k, v in pairs(vim.fn.environ()) do
        --     table.insert(variables, {name = k, value = v})
        --   end
        --   return variables
        -- end,
      },
      {
        name = "Attach to process",
        type = "lldb",
        request = "attach",
        pid = require('dap.utils').pick_process,
        args = {},
        cwd = "${workspaceFolder}",
        initCommands = {
          "settings set target.inline-breakpoint-strategy always",
          "settings set target.process.thread.step-avoid-regexp \"\"",
        },
      },
      {
        name = "Launch file (custom)",
        type = "lldb",
        request = "launch",
        program = function()
          return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
        initCommands = {
          "settings set target.inline-breakpoint-strategy always",
          "settings set target.process.thread.step-avoid-regexp \"\"",
        },
      },
    }
    dap.configurations.c = dap.configurations.cpp

    -- Configure Lua adapter (for your Neovim plugin development)
    dap.adapters.nlua = function(callback, config)
      callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
    end
    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = "Attach to running Neovim instance",
      }
    }

    -- Autocommands
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dap-repl",
      callback = function()
        require("dap.ext.autocompl").attach()
      end
    })

    -- Auto open/close UI
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    -- Keymaps
    vim.keymap.set("n", "<leader>db", function() dap.toggle_breakpoint() end, { desc = "Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
      { desc = "Set conditional breakpoint" })
    vim.keymap.set("n", "<leader>dl", function() dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end,
      { desc = "Set log point" })
    vim.keymap.set("n", "<leader>dc", function() dap.continue() end, { desc = "Continue" })
    vim.keymap.set("n", "<leader>di", function() dap.step_into() end, { desc = "Step into" })
    vim.keymap.set("n", "<leader>do", function() dap.step_over() end, { desc = "Step over" })
    vim.keymap.set("n", "<leader>dO", function() dap.step_out() end, { desc = "Step out" })
    vim.keymap.set("n", "<leader>dr", function() dap.repl.open() end, { desc = "Open REPL" })
    vim.keymap.set("n", "<leader>du", function() dapui.toggle() end, { desc = "Toggle UI" })
    vim.keymap.set("n", "<leader>dx", function() dap.terminate() end, { desc = "Terminate" })

    -- Enable telescope integration
    require('telescope').load_extension('dap')
    vim.keymap.set("n", "<leader>dcc", function() require('telescope').extensions.dap.commands {} end,
      { desc = "Commands" })
    vim.keymap.set("n", "<leader>dco", function() require('telescope').extensions.dap.configurations {} end,
      { desc = "Configurations" })
    vim.keymap.set("n", "<leader>dlb", function() require('telescope').extensions.dap.list_breakpoints {} end,
      { desc = "List breakpoints" })
    vim.keymap.set("n", "<leader>dv", function() require('telescope').extensions.dap.variables {} end,
      { desc = "Variables" })
    vim.keymap.set("n", "<leader>df", function() require('telescope').extensions.dap.frames {} end, { desc = "Frames" })
  end
}

