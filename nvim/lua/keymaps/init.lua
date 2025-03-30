-- lua/keymaps/init.lua
-- Main keymapping management module
local M = {}

-- Store all registered keymaps for reference and which-key integration
M.mappings = {}

-- Helper function for consistent keymapping
function M.set(mode, lhs, rhs, opts)
  opts = opts or {}
  local options = { noremap = true, silent = true }
  options = vim.tbl_extend('force', options, opts)

  vim.keymap.set(mode, lhs, rhs, options)

  -- Store this mapping
  if not M.mappings[mode] then
    M.mappings[mode] = {}
  end
  M.mappings[mode][lhs] = {
    rhs = rhs,
    opts = options
  }

  return lhs
end

-- Register mappings by category
function M.register(category, mappings)
  if not M.mappings.categories then
    M.mappings.categories = {}
  end

  if not M.mappings.categories[category] then
    M.mappings.categories[category] = {}
  end

  for mode, mode_mappings in pairs(mappings) do
    for lhs, mapping in pairs(mode_mappings) do
      local rhs = mapping[1]
      local opts = mapping[2] or {}

      -- Add the category to the description if provided
      if opts.desc then
        opts.desc = string.format("[%s] %s", category, opts.desc)
      end

      -- Set the mapping
      M.set(mode, lhs, rhs, opts)

      -- Store in categories
      if not M.mappings.categories[category][mode] then
        M.mappings.categories[category][mode] = {}
      end
      M.mappings.categories[category][mode][lhs] = {
        rhs = rhs,
        opts = opts
      }
    end
  end
end

-- Collect Leader mappings for which-key
function M.get_leader_mappings()
  local leader_maps = {}

  -- Process all stored mappings
  for mode, mode_maps in pairs(M.mappings) do
    if mode ~= "categories" then -- Skip our metadata
      for lhs, mapping in pairs(mode_maps) do
        if type(lhs) == "string" and lhs:match("^<leader>") then
          -- Extract the key after leader (e.g., <leader>f -> f)
          local key = lhs:match("^<leader>(.)") or lhs:match("^<leader>(.+)$")
          if key then
            -- Initialize if not exists
            if not leader_maps[key] then leader_maps[key] = {} end

            -- Use description if available, otherwise use the command
            local desc = mapping.opts.desc or tostring(mapping.rhs)
            leader_maps[key] = {
              name = leader_maps[key].name, -- Preserve group name if exists
              [lhs:gsub("^<leader>", "")] = { mapping.rhs, desc }
            }
          end
        end
      end
    end
  end

  return leader_maps
end

-- Define leader key groups
function M.setup_which_key()
  local ok, which_key = pcall(require, "which-key")
  if not ok then return end

  -- Register groups
  which_key.register({
    ["<leader>f"] = { name = "File & Find" },
    ["<leader>g"] = { name = "Git" },
    ["<leader>l"] = { name = "LSP" },
    ["<leader>d"] = { name = "Debug" },
    ["<leader>t"] = { name = "Terminal" },
    ["<leader>w"] = { name = "Window" },
    ["<leader>s"] = { name = "Settings" },
    ["<leader>c"] = { name = "Code" },
  })

  -- Register all leader mappings from our structure
  local leader_mappings = M.get_leader_mappings()
  for key, mapping in pairs(leader_mappings) do
    if mapping.name then
      which_key.register({
        [key] = mapping
      }, { prefix = "<leader>" })
    end
  end
end

-- Main setup function
function M.setup()
  -- Set leader key
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "

  -- Load core mappings
  require("keymaps.core").setup(M)

  -- Feature-specific mappings (loaded only if the required plugins exist)
  local features = {
    "lsp", "telescope", "git", "debugging", "terminal", "editor"
  }

  for _, feature in ipairs(features) do
    local ok, module = pcall(require, "keymaps." .. feature)
    if ok and type(module) == "table" and type(module.setup) == "function" then
      pcall(module.setup, M)
    end
  end

  -- Setup which-key integration
  M.setup_which_key()
end

return M
