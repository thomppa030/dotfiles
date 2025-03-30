-- A lightweight project extension for telescope.nvim
local mappings = require('plugins.telescope.mappings')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')
local entry_display = require('telescope.pickers.entry_display')

-- Create the extension
local project = {}

-- Project data structure with defaults
project.data = {
  projects = {},
  recent = {},
}

-- File paths
local data_file = vim.fn.stdpath("data") .. "/telescope_simple_projects.lua"

-- Function to save project data
function project.save_data()
  local file = io.open(data_file, "w")
  if file then
    file:write("return " .. vim.inspect(project.data))
    file:close()
  end
end

-- Function to load project data
function project.load_data()
  -- Initialize data structure
  project.data = {
    projects = project.data.projects or {},
    recent = project.data.recent or {},
  }

  -- Try to load saved data
  local file = io.open(data_file, "r")
  if file then
    local content = file:read("*all")
    file:close()

    local success, compiled_fn = pcall(loadstring, content)
    if success and compiled_fn then
      local success2, loaded_data = pcall(compiled_fn)
      if success2 and loaded_data and type(loaded_data) == "table" then
        -- Make sure all required keys exist in loaded data
        loaded_data.projects = loaded_data.projects or {}
        loaded_data.recent = loaded_data.recent or {}

        project.data = loaded_data
      end
    end
  end
end

-- Function to add a project
function project.add_project(path, name, tags)
  if not path or path == "" then return end

  -- Create default name from path if not provided
  name = name or vim.fn.fnamemodify(path, ":t")
  tags = tags or {}

  -- Add to projects list
  project.data.projects[path] = {
    name = name,
    path = path,
    tags = tags,
    last_opened = os.time(),
  }

  -- Update recent list
  table.insert(project.data.recent, 1, path)

  -- Remove duplicates in recent list
  local seen = { [path] = true }
  local unique_recent = { path }

  for _, p in ipairs(project.data.recent) do
    if not seen[p] then
      seen[p] = true
      table.insert(unique_recent, p)
    end
  end

  -- Keep only the 15 most recent projects
  if #unique_recent > 15 then
    local trimmed = {}
    for i = 1, 15 do
      trimmed[i] = unique_recent[i]
    end
    unique_recent = trimmed
  end

  project.data.recent = unique_recent
  project.save_data()
end

-- Function to remove a project
function project.remove_project(path)
  -- Remove from projects list
  project.data.projects[path] = nil

  -- Remove from recent list
  local new_recent = {}
  for _, p in ipairs(project.data.recent) do
    if p ~= path then
      table.insert(new_recent, p)
    end
  end
  project.data.recent = new_recent

  project.save_data()
end

-- Function to get recent projects
function project.get_recent_projects()
  local results = {}
  for _, path in ipairs(project.data.recent) do
    -- Only include projects that still exist in projects table
    if project.data.projects[path] then
      table.insert(results, path)
    end
  end
  return results
end

-- Create a simple project previewer
local project_previewer = previewers.new_buffer_previewer({
  title = "Project Preview",
  define_preview = function(self, entry, status)
    if not entry or not entry.value then return end

    local path = entry.value
    local project_info = project.data.projects[path] or { name = vim.fn.fnamemodify(path, ":t"), path = path }

    local lines = {
      "# " .. project_info.name,
      "",
      "Path: " .. path,
      "",
    }

    -- Add tags if any
    if project_info.tags and #project_info.tags > 0 then
      table.insert(lines, "Tags: " .. table.concat(project_info.tags, ", "))
      table.insert(lines, "")
    end

    -- Add last opened time if available
    if project_info.last_opened then
      table.insert(lines, "Last opened: " .. os.date("%Y-%m-%d %H:%M:%S", project_info.last_opened))
      table.insert(lines, "")
    end

    -- Try to list some files in the project directory
    table.insert(lines, "## Files")
    table.insert(lines, "")

    local ok, result = pcall(function()
      local cmd = "find '" .. path .. "' -type f -not -path '*/\\.*' | head -10"
      local handle = io.popen(cmd)
      if handle then
        local output = handle:read("*a")
        handle:close()
        return output
      end
      return ""
    end)

    if ok and result and result ~= "" then
      for line in result:gmatch("[^\r\n]+") do
        local rel_path = line:gsub("^" .. vim.pesc(path) .. "/", "")
        table.insert(lines, "- " .. rel_path)
      end
    else
      table.insert(lines, "Unable to list files")
    end

    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
  end
})

-- Function to create entry_maker for projects
local function make_project_entry_maker()
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 30 },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local info = project.data.projects[entry.value] or { name = vim.fn.fnamemodify(entry.value, ":t") }

    return displayer({
      info.name,
      entry.value,
    })
  end

  return function(entry)
    return {
      value = entry,
      display = make_display,
      ordinal = project.data.projects[entry] and project.data.projects[entry].name or vim.fn.fnamemodify(entry, ":t"),
    }
  end
end

-- Function to browse all projects
function project.browse_projects()
  project.load_data()

  local projects = {}
  for path, _ in pairs(project.data.projects) do
    table.insert(projects, path)
  end

  -- Sort projects by name
  table.sort(projects, function(a, b)
    local name_a = project.data.projects[a].name
    local name_b = project.data.projects[b].name
    return name_a < name_b
  end)

  pickers.new({}, {
    prompt_title = "Projects",
    finder = finders.new_table({
      results = projects,
      entry_maker = make_project_entry_maker(),
    }),
    sorter = conf.generic_sorter({}),
    previewer = project_previewer,
    attach_mappings = function(prompt_bufnr, map)
      -- Default action when pressing Enter
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          -- Open the selected project
          local path = selection.value

          -- Update last opened time
          if project.data.projects[path] then
            project.data.projects[path].last_opened = os.time()

            -- Move to top of recent list
            local new_recent = { path }
            for _, p in ipairs(project.data.recent) do
              if p ~= path then
                table.insert(new_recent, p)
              end
            end
            project.data.recent = new_recent
            project.save_data()
          end

          -- Change to the directory
          vim.cmd("cd " .. path)

          -- Show file browser
          require("telescope.builtin").find_files()
        end
      end)

      -- Delete project mapping
      map("i", "<c-d>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local path = selection.value
        local name = project.data.projects[path] and project.data.projects[path].name or vim.fn.fnamemodify(path, ":t")

        vim.ui.input({
          prompt = "Delete project '" .. name .. "'? (y/N): ",
        }, function(input)
          if input and (input:lower() == "y" or input:lower() == "yes") then
            project.remove_project(path)

            -- Refresh the picker
            action_state.get_current_picker(prompt_bufnr):refresh(
              finders.new_table({
                results = vim.tbl_keys(project.data.projects),
                entry_maker = make_project_entry_maker(),
              }),
              { reset_prompt = true }
            )
          end
        end)
      end)

      -- Edit project details
      map("i", "<c-e>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end

        local path = selection.value
        local project_info = project.data.projects[path] or
            { name = vim.fn.fnamemodify(path, ":t"), path = path, tags = {} }

        vim.ui.input({
          prompt = "Project name: ",
          default = project_info.name,
        }, function(name)
          if name then
            vim.ui.input({
              prompt = "Tags (comma separated): ",
              default = table.concat(project_info.tags or {}, ", "),
            }, function(tags_str)
              local tags = {}
              if tags_str and tags_str ~= "" then
                for tag in string.gmatch(tags_str, "([^,]+)") do
                  tag = tag:match("^%s*(.-)%s*$") -- Trim whitespace
                  if tag ~= "" then
                    table.insert(tags, tag)
                  end
                end
              end

              project.data.projects[path] = {
                name = name,
                path = path,
                tags = tags,
                last_opened = project_info.last_opened or os.time(),
              }
              project.save_data()

              -- Refresh the picker
              action_state.get_current_picker(prompt_bufnr):refresh(
                finders.new_table({
                  results = vim.tbl_keys(project.data.projects),
                  entry_maker = make_project_entry_maker(),
                }),
                { reset_prompt = true }
              )
            end)
          end
        end)
      end)

      -- Add keymap help to title
      local help_text = " ⭐ Enter: Open | <C-e>: Edit | <C-d>: Delete"
      action_state.get_current_picker(prompt_bufnr).prompt_border:change_title("Projects" .. help_text)

      return true
    end,
  }):find()
end

-- Function to browse recent projects
function project.browse_recent_projects()
  project.load_data()

  local recent = project.get_recent_projects()

  pickers.new({}, {
    prompt_title = "Recent Projects",
    finder = finders.new_table({
      results = recent,
      entry_maker = make_project_entry_maker(),
    }),
    sorter = conf.generic_sorter({}),
    previewer = project_previewer,
    attach_mappings = function(prompt_bufnr, map)
      -- Default action when pressing Enter
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          -- Open the selected project
          local path = selection.value

          -- Update last opened time
          if project.data.projects[path] then
            project.data.projects[path].last_opened = os.time()

            -- Move to top of recent list
            local new_recent = { path }
            for _, p in ipairs(project.data.recent) do
              if p ~= path then
                table.insert(new_recent, p)
              end
            end
            project.data.recent = new_recent
            project.save_data()
          end

          -- Change to the directory
          vim.cmd("cd " .. path)

          -- Show file browser
          require("telescope.builtin").find_files()
        end
      end)

      -- Add keymap help to title
      local help_text = " ⭐ Enter: Open"
      action_state.get_current_picker(prompt_bufnr).prompt_border:change_title("Recent Projects" .. help_text)

      return true
    end,
  }):find()
end

-- Function to add current directory as project
function project.add_current_directory()
  project.load_data()

  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")

  vim.ui.input({
    prompt = "Project name: ",
    default = name,
  }, function(input_name)
    if input_name and input_name ~= "" then
      vim.ui.input({
        prompt = "Tags (comma separated): ",
      }, function(tags_str)
        local tags = {}
        if tags_str and tags_str ~= "" then
          for tag in string.gmatch(tags_str, "([^,]+)") do
            tag = tag:match("^%s*(.-)%s*$") -- Trim whitespace
            if tag ~= "" then
              table.insert(tags, tag)
            end
          end
        end

        project.add_project(cwd, input_name, tags)
        vim.notify("Added current directory as project: " .. input_name, vim.log.levels.INFO)
      end)
    end
  end)
end

-- Function to search projects by tags
function project.search_by_tags()
  project.load_data()

  -- First, collect all unique tags
  local all_tags = {}
  local tag_set = {}

  for _, info in pairs(project.data.projects) do
    if info.tags then
      for _, tag in ipairs(info.tags) do
        if not tag_set[tag] then
          tag_set[tag] = true
          table.insert(all_tags, tag)
        end
      end
    end
  end

  if #all_tags == 0 then
    vim.notify("No tags found in any projects", vim.log.levels.INFO)
    return
  end

  table.sort(all_tags)

  vim.ui.select(all_tags, {
    prompt = "Select tag to filter by:",
  }, function(selected_tag)
    if not selected_tag then return end

    -- Find projects with this tag
    local filtered_projects = {}
    for path, info in pairs(project.data.projects) do
      if info.tags then
        for _, tag in ipairs(info.tags) do
          if tag == selected_tag then
            table.insert(filtered_projects, path)
            break
          end
        end
      end
    end

    if #filtered_projects == 0 then
      vim.notify("No projects found with tag: " .. selected_tag, vim.log.levels.INFO)
      return
    end

    -- Show projects with this tag
    pickers.new({}, {
      prompt_title = "Projects with tag: " .. selected_tag,
      finder = finders.new_table({
        results = filtered_projects,
        entry_maker = make_project_entry_maker(),
      }),
      sorter = conf.generic_sorter({}),
      previewer = project_previewer,
      attach_mappings = function(prompt_bufnr, map)
        -- Default action when pressing Enter
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          if selection then
            -- Open the selected project
            local path = selection.value

            -- Update last opened time
            if project.data.projects[path] then
              project.data.projects[path].last_opened = os.time()

              -- Move to top of recent list
              local new_recent = { path }
              for _, p in ipairs(project.data.recent) do
                if p ~= path then
                  table.insert(new_recent, p)
                end
              end
              project.data.recent = new_recent
              project.save_data()
            end

            -- Change to the directory
            vim.cmd("cd " .. path)

            -- Show file browser
            require("telescope.builtin").find_files()
          end
        end)

        return true
      end,
    }):find()
  end)
end

-- Initialization function
function project.init()
  project.load_data()
end

-- Register the mappings
mappings.register_mode_mappings('project', {
  ['<leader>fp'] = {
    command = project.browse_projects,
    desc = 'Browse all projects'
  },
  ['<leader>fr'] = {
    command = project.browse_recent_projects,
    desc = 'Browse recent projects'
  },
  ['<leader>fa'] = {
    command = project.add_current_directory,
    desc = 'Add current directory as project'
  },
  ['<leader>ft'] = {
    command = project.search_by_tags,
    desc = 'Search projects by tag'
  },
})

-- Return the module
return project
