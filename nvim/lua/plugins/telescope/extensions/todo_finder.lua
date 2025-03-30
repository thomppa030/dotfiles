-- plugins/telescope/extensions/todo_finder.lua
local extensions = require('plugins.telescope.extensions')
local mappings = require('plugins.telescope.mappings')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local previewers = require('telescope.previewers')

local todo_finder = {}

-- Configuration
local config = {
  -- Patterns to search for
  patterns = {
    "TODO", "FIXME", "HACK", "NOTE", "BUG", "WARN", "PERF", "XXX"
  },
  -- File extensions to include (empty means all)
  include_extensions = {},
  -- File/directory patterns to exclude
  exclude_patterns = {
    "%.git/",
    "node_modules/",
    "%.cache/",
    "build/",
    "%.o$",
    "%.d$",
    "%.meta$",
    "%.DS_Store$"
  },
  -- Maximum file size to parse (in kilobytes)
  max_file_size = 1024,
  -- Max depth for directory traversal (nil for unlimited)
  max_depth = nil,
  -- Ignore file settings
  ignore_file = {
    name = ".todoignore",    -- Name of the ignore file
    fallback = ".gitignore", -- Fallback to this file if the primary doesn't exist
    enabled = true,          -- Whether to use ignore files
  },
  -- Display style options
  display = {
    show_count_in_filename = true, -- Show count of TODOs in filename
    todo_icon = " ",               -- Icon for TODO markers
    group_by_file = true,          -- Group TODOs by file in the preview
    path_display = "smart",        -- Options: "full", "relative", "smart", "filename"
    max_path_length = 40           -- Maximum length of displayed path
  }
}

-- Cache to store TODO counts and details per file
local todo_cache = {
  files = {},
  last_update = 0
}

-- Cache for ignore patterns
local ignore_cache = {
  patterns = {},
  loaded = false,
  ignore_files = {}
}

-- Parse gitignore-style file and build patterns
local function parse_ignore_file(filepath)
  if not vim.fn.filereadable(filepath) then
    return {}
  end

  local file = io.open(filepath, "r")
  if not file then return {} end

  local patterns = {}
  for line in file:lines() do
    -- Remove comments and trim whitespace
    line = line:gsub("#.*$", ""):match("^%s*(.-)%s*$")

    -- Skip empty lines
    if line ~= "" then
      -- Handle negation (we only support exclusions for now)
      if line:sub(1, 1) ~= "!" then
        -- Convert gitignore pattern to Lua pattern
        local pattern = line
        -- Escape Lua pattern special characters
        pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")

        -- Handle gitignore-style wildcards (convert to Lua patterns)
        pattern = pattern:gsub("%%%*%%%*", ".*") -- ** means any characters including /
        pattern = pattern:gsub("%%%*", "[^/]*")  -- * means any characters except /

        -- Handle directory marker / at the end
        if pattern:sub(-1) == "/" then
          pattern = pattern:sub(1, -2) -- Remove trailing /
          pattern = pattern .. ".*"    -- Match all files inside this directory
        end

        -- Anchoring: patterns without / at start match anywhere
        if pattern:sub(1, 1) ~= "/" then
          pattern = ".*" .. pattern
        else
          pattern = "^" .. pattern:sub(2) -- Remove leading / and anchor to start
        end

        -- Final cleanup
        pattern = pattern:gsub("//+", "/") -- Replace multiple / with single /

        table.insert(patterns, pattern)
      end
    end
  end

  file:close()
  return patterns
end

-- Load ignore patterns from .todoignore or .gitignore
local function load_ignore_patterns()
  if ignore_cache.loaded then
    return ignore_cache.patterns
  end

  local root_dir = vim.fn.getcwd()
  local patterns = {}
  local found_files = {}

  -- Find all ignore files recursively in the project
  if config.ignore_file.enabled then
    -- Try primary ignore file first
    local primary_path = root_dir .. "/" .. config.ignore_file.name
    if vim.fn.filereadable(primary_path) == 1 then
      local file_patterns = parse_ignore_file(primary_path)
      vim.list_extend(patterns, file_patterns)
      table.insert(found_files, primary_path)
    elseif config.ignore_file.fallback then
      -- Try fallback ignore file
      local fallback_path = root_dir .. "/" .. config.ignore_file.fallback
      if vim.fn.filereadable(fallback_path) == 1 then
        local file_patterns = parse_ignore_file(fallback_path)
        vim.list_extend(patterns, file_patterns)
        table.insert(found_files, fallback_path)
      end
    end

    -- Also look for nested ignore files (limited to reasonable depth)
    local function scan_for_ignore_files(dir, depth)
      if depth > 5 then return end -- Prevent excessive recursion

      local handle = vim.loop.fs_scandir(dir)
      if not handle then return end

      while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end

        local path = dir .. "/" .. name

        if type == "directory" then
          scan_for_ignore_files(path, depth + 1)
        elseif type == "file" and (name == config.ignore_file.name or name == config.ignore_file.fallback) then
          -- Skip if we've already processed this file
          if not vim.tbl_contains(found_files, path) then
            local file_patterns = parse_ignore_file(path)
            -- These patterns are relative to the directory containing the ignore file
            local dir_prefix = path:match("(.*)/[^/]*$") or ""
            for i, pattern in ipairs(file_patterns) do
              -- Make the pattern relative to the directory containing the ignore file
              local adjusted_pattern = pattern:gsub("^%^",
                "^" .. dir_prefix:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "/")
              table.insert(patterns, adjusted_pattern)
            end
            table.insert(found_files, path)
          end
        end
      end
    end

    scan_for_ignore_files(root_dir, 1)
  end

  -- Cache the results
  ignore_cache.patterns = patterns
  ignore_cache.loaded = true
  ignore_cache.ignore_files = found_files

  if #found_files > 0 then
    vim.notify("TODO Finder: Loaded " .. #found_files .. " ignore files", vim.log.levels.INFO)
  end

  return patterns
end

-- Check if path should be ignored based on patterns
local function should_ignore_path(path)
  -- First check built-in exclude patterns
  for _, pattern in ipairs(config.exclude_patterns) do
    if path:match(pattern) then
      return true
    end
  end

  -- Then check patterns from ignore files
  local ignore_patterns = load_ignore_patterns()
  for _, pattern in ipairs(ignore_patterns) do
    if path:match(pattern) then
      return true
    end
  end

  return false
end

-- Parse a file for TODOs
local function parse_file_for_todos(filepath)
  -- Skip if file is too large
  local stats = vim.loop.fs_stat(filepath)
  if not stats or stats.type ~= "file" or stats.size > config.max_file_size * 1024 then
    return nil
  end

  -- Check if we should include this file based on extension
  if #config.include_extensions > 0 then
    local ext = filepath:match("%.([^./]+)$")
    if not ext or not vim.tbl_contains(config.include_extensions, ext) then
      return nil
    end
  end

  -- Check if path should be ignored
  if should_ignore_path(filepath) then
    return nil
  end

  -- Try to read the file
  local file, err = io.open(filepath, "r")
  if not file then
    -- print("Error opening " .. filepath .. ": " .. (err or "unknown error"))
    return nil
  end

  local todos = {}
  local line_num = 0

  -- Create pattern for matching TODOs
  local todo_pattern = "("
  for i, pattern in ipairs(config.patterns) do
    todo_pattern = todo_pattern .. pattern
    if i < #config.patterns then
      todo_pattern = todo_pattern .. "|"
    end
  end
  todo_pattern = todo_pattern .. ")"

  -- Match TODOs in comments based on file type
  local comment_patterns = {
    -- Single line patterns
    "%s*//.*" .. todo_pattern .. "(.*)$",             -- C/C++/JS style
    "%s*#.*" .. todo_pattern .. "(.*)$",              -- Python/Ruby style
    "%s*%-%-.*" .. todo_pattern .. "(.*)$",           -- Lua style
    "%s*%%.*" .. todo_pattern .. "(.*)$",             -- MATLAB/Octave style
    "%s*;.*" .. todo_pattern .. "(.*)$",              -- Assembly style
    "%s*<!%-%-.*" .. todo_pattern .. "(.*)%s*%-%-?>", -- HTML style

    -- General pattern (will catch most cases)
    ".*" .. todo_pattern .. "[:%- ]%s*(.*)$"
  }

  for line in file:lines() do
    line_num = line_num + 1
    local matched = false

    -- Try each pattern to find TODOs
    for _, pattern in ipairs(comment_patterns) do
      local todo_type, todo_text = line:match(pattern)
      if todo_type and todo_text then
        matched = true
        -- Remove leading/trailing whitespace
        todo_text = todo_text:match("^%s*(.-)%s*$")

        -- Skip empty TODOs
        if todo_text and todo_text ~= "" then
          table.insert(todos, {
            type = todo_type,
            text = todo_text,
            line = line_num,
            line_content = line
          })
        end

        break -- Found a match, no need to try more patterns
      end
    end

    -- If no match was found with specific patterns, try a more general approach
    if not matched then
      for _, todo_type in ipairs(config.patterns) do
        if line:match(todo_type) then
          local todo_text = line:match(todo_type .. "[:%- ]%s*(.*)$")
          if todo_text then
            todo_text = todo_text:match("^%s*(.-)%s*$")
            if todo_text and todo_text ~= "" then
              table.insert(todos, {
                type = todo_type,
                text = todo_text,
                line = line_num,
                line_content = line
              })
            end
          end
        end
      end
    end
  end

  file:close()

  -- Cache the results
  todo_cache.files[filepath] = {
    count = #todos,
    todos = todos,
    mtime = stats.mtime.sec
  }

  return todos
end

-- Scan directory recursively for TODOs
local function scan_directory_for_todos(dir_path, callback, depth)
  depth = depth or 1

  -- Check max depth
  if config.max_depth and depth > config.max_depth then
    return
  end

  local handle = vim.loop.fs_scandir(dir_path)
  if not handle then return end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then break end

    local path = dir_path .. "/" .. name

    -- Check if this path should be ignored
    if should_ignore_path(path) then
      goto continue
    end

    if type == "directory" then
      scan_directory_for_todos(path, callback, depth + 1)
    elseif type == "file" then
      local stats = vim.loop.fs_stat(path)

      -- Check cached entry or modified time
      local cached = todo_cache.files[path]
      if not cached or cached.mtime ~= stats.mtime.sec then
        local todos = parse_file_for_todos(path)
        if todos and #todos > 0 then
          callback(path, todos)
        end
      elseif cached and cached.count > 0 then
        callback(path, cached.todos)
      end
    end

    ::continue::
  end
end

-- Create file entry with TODO count
local function make_entry_with_todo_count(entry)
  local path = entry[1]
  local todos = entry[2]

  -- Format path based on config
  local display_path
  local max_length = config.display.max_path_length or 40

  if config.display.path_display == "full" then
    display_path = path
  elseif config.display.path_display == "filename" then
    display_path = vim.fn.fnamemodify(path, ":t")
  elseif config.display.path_display == "relative" then
    display_path = vim.fn.fnamemodify(path, ":.")
  else -- "smart" (default)
    -- Get relative path from current directory
    local relative_path = vim.fn.fnamemodify(path, ":.")

    -- If path is too long, use a more compact format
    if #relative_path > max_length then
      -- Show only filename with parent directory for context
      display_path = vim.fn.fnamemodify(path, ":h:t") .. "/" .. vim.fn.fnamemodify(path, ":t")

      -- If the file is deeply nested, add some context
      if vim.fn.fnamemodify(path, ":h:h:t") ~= "" then
        display_path = ".../" .. display_path
      end
    else
      display_path = relative_path
    end
  end

  -- Add TODO count to display with more prominent formatting
  local display
  if config.display.show_count_in_filename then
    -- Format: filename │ 5 TODOs
    display = string.format("%s │ %d %s",
      display_path,
      #todos,
      #todos == 1 and "TODO" or "TODOs")
  else
    display = display_path
  end

  return {
    value = entry,
    ordinal = path,
    display = display,
    filename = path,
    todos = todos,
    todo_count = #todos
  }
end

-- Preview TODOs in a file
local todo_previewer = previewers.new_buffer_previewer({
  title = "TODOs Preview",

  get_buffer_by_name = function(_, entry)
    return entry.filename
  end,

  define_preview = function(self, entry, status)
    if not entry or not entry.todos then
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No TODOs found" })
      return
    end

    local lines = {}
    local todos = entry.todos

    -- Sort TODOs by line number
    table.sort(todos, function(a, b) return a.line < b.line end)

    -- Display header
    table.insert(lines, string.format("# %s - %d TODOs",
      vim.fn.fnamemodify(entry.filename, ":t"),
      #todos))
    table.insert(lines, "")

    -- Display TODOs with context
    for i, todo in ipairs(todos) do
      local line_display = string.format("%d: [%s] %s",
        todo.line,
        todo.type,
        todo.text)

      table.insert(lines, line_display)

      -- Add the actual line content
      if todo.line_content then
        local content = "    " .. todo.line_content:gsub("^%s+", "")
        content = content:gsub("\t", "    ") -- Replace tabs with spaces
        table.insert(lines, content)
      end

      -- Add separator between TODOs
      if i < #todos then
        table.insert(lines, "")
      end
    end

    -- Set lines in preview buffer
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

    -- Set filetype for syntax highlighting
    vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
  end
})

-- Find TODOs in the current project
function todo_finder.find_project_todos()
  local results = {}
  local root_dir = vim.fn.getcwd()

  -- Reset cache if it's older than 5 minutes
  local current_time = os.time()
  if current_time - todo_cache.last_update > 300 then
    todo_cache.files = {}
  end
  todo_cache.last_update = current_time

  -- Load ignore patterns first
  local ignore_patterns = load_ignore_patterns()
  local ignore_files = ignore_cache.ignore_files

  -- Notify user that scanning is in progress
  if #ignore_files > 0 then
    vim.notify(string.format("Scanning for TODOs... (Using %d ignore patterns from %d files)",
      #ignore_patterns, #ignore_files), vim.log.levels.INFO)
  else
    vim.notify("Scanning for TODOs...", vim.log.levels.INFO)
  end

  -- Collect files with TODOs
  scan_directory_for_todos(root_dir, function(filepath, todos)
    if #todos > 0 then
      table.insert(results, { filepath, todos })
    end
  end)

  -- Sort by number of TODOs (descending)
  table.sort(results, function(a, b)
    return #a[2] > #b[2]
  end)

  -- Count total TODOs
  local total_todos = 0
  for _, result in ipairs(results) do
    total_todos = total_todos + #result[2]
  end

  -- Format the results title with counts
  local results_title = string.format("⭐ %d TODOs in %d files | <C-t> Copy | <C-g> Jump | <C-r> Reload",
    total_todos, #results)

  -- Create the picker
  pickers.new({}, {
    prompt_title = "TODOs in Project",
    finder = finders.new_table({
      results = results,
      entry_maker = make_entry_with_todo_count
    }),
    sorter = conf.generic_sorter({}),
    previewer = todo_previewer,
    results_title = results_title,
    layout_config = {
      width = 0.9,
      height = 0.8,
      preview_width = 0.6 -- Give more space to the preview panel
    },
    attach_mappings = function(prompt_bufnr, map)
      -- Jump to the file and line of the TODO
      map("i", "<C-g>", function()
        -- Get selected entry
        local entry = action_state.get_selected_entry()
        if not entry or not entry.todos or #entry.todos == 0 then
          return
        end

        actions.close(prompt_bufnr)

        -- Open the file
        vim.cmd("edit " .. entry.filename)

        -- Jump to the first TODO
        vim.api.nvim_win_set_cursor(0, { entry.todos[1].line, 0 })
        vim.cmd("normal! zz") -- Center the screen
      end)

      -- Copy the TODO text to clipboard
      map("i", "<C-t>", function()
        local entry = action_state.get_selected_entry()
        if not entry or not entry.todos or #entry.todos == 0 then
          return
        end

        local todo_texts = {}
        for _, todo in ipairs(entry.todos) do
          table.insert(todo_texts, string.format("[%s] %s", todo.type, todo.text))
        end

        local text = table.concat(todo_texts, "\n")
        vim.fn.setreg("+", text)
        vim.notify("Copied " .. #entry.todos .. " TODOs to clipboard", vim.log.levels.INFO)
      end)

      -- Add mapping to reload ignore files
      map("i", "<C-r>", function()
        actions.close(prompt_bufnr)
        todo_finder.reload_ignore_files()
        todo_finder.find_project_todos()
      end)

      -- Default action to open file at first TODO
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if not entry then
          return
        end

        actions.close(prompt_bufnr)

        -- Open the file
        vim.cmd("edit " .. entry.filename)

        -- Jump to the first TODO if available
        if entry.todos and #entry.todos > 0 then
          vim.api.nvim_win_set_cursor(0, { entry.todos[1].line, 0 })
          vim.cmd("normal! zz") -- Center the screen
        end
      end)

      return true
    end
  }):find()
end

-- Find TODOs in the current file
function todo_finder.find_file_todos()
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No file open", vim.log.levels.WARN)
    return
  end

  local todos = parse_file_for_todos(current_file)
  if not todos or #todos == 0 then
    vim.notify("No TODOs found in current file", vim.log.levels.INFO)
    return
  end

  -- Create entries for picker
  local results = {}
  for _, todo in ipairs(todos) do
    table.insert(results, {
      line = todo.line,
      type = todo.type,
      text = todo.text,
      content = todo.line_content
    })
  end

  -- Sort by line number
  table.sort(results, function(a, b)
    return a.line < b.line
  end)

  -- Create the picker
  pickers.new({}, {
    prompt_title = "TODOs in Current File",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local display = string.format("%4d: [%s] %s",
          entry.line,
          entry.type,
          entry.text)

        return {
          value = entry,
          ordinal = tostring(entry.line) .. entry.text,
          display = display,
          filename = current_file,
          lnum = entry.line,
          col = 1,
          text = entry.text
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    results_title = "⭐ Enter=Jump to TODO | <C-t> Copy TODO",
    attach_mappings = function(prompt_bufnr, map)
      -- Copy TODO text
      map("i", "<C-t>", function()
        local entry = action_state.get_selected_entry()
        if not entry then
          return
        end

        vim.fn.setreg("+", entry.text)
        vim.notify("TODO copied to clipboard", vim.log.levels.INFO)
      end)

      -- Default action to jump to TODO
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        if not entry then
          return
        end

        actions.close(prompt_bufnr)

        -- Jump to the TODO line
        vim.api.nvim_win_set_cursor(0, { entry.lnum, 0 })
        vim.cmd("normal! zz") -- Center the screen
      end)

      return true
    end
  }):find()
end

-- Configuration function
function todo_finder.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

-- Register mappings
mappings.register_mode_mappings('todo_finder', {
  ['<leader>ft'] = {
    command = todo_finder.find_project_todos,
    desc = 'Find TODOs in project'
  },
  ['<leader>fT'] = {
    command = todo_finder.find_file_todos,
    desc = 'Find TODOs in current file'
  },
})

-- Register the extension
return extensions.register_extension('todo_finder', todo_finder)
