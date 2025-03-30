-- Telescope extensions system
local M = {}

-- Registry for extensions
M.extensions = {}

-- Function to register a new extension
function M.register_extension(name, extension)
  M.extensions[name] = extension

  -- Initialize the extension if it has an init function
  if extension.init then
    extension.init()
  end

  return extension
end

-- Function to get a registered extension
function M.get_extension(name)
  return M.extensions[name]
end

-- Load all extension modules from the extensions directory
-- (This uses the same pattern as the modes loader)
function M.load_all()
  local extensions_dir = vim.fn.stdpath("config") .. "/lua/plugins/telescope/extensions"

  -- Find all Lua files in the extensions directory
  local extension_files = vim.fn.glob(extensions_dir .. "/*.lua", false, true)

  for _, file in ipairs(extension_files) do
    -- Skip the init.lua file
    if not file:match("init%.lua$") then
      local extension_name = vim.fn.fnamemodify(file, ":t:r")

      -- Only load if it's not already loaded
      if extension_name ~= "init" and not M.extensions[extension_name] then
        require("plugins.telescope.extensions." .. extension_name)
      end
    end
  end
end

return M
