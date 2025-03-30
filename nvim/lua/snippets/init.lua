-- ~/.config/nvim/lua/snippets/init.lua
local ls = require("luasnip")

-- Load snippets from separate files for better organization
local load_snippets = function()
  -- Load C++ snippets
  ls.add_snippets("cpp", require("snippets.cpp"))
  
  -- You can add more file types here in the future
  -- ls.add_snippets("python", require("snippets.python"))
  -- ls.add_snippets("lua", require("snippets.lua"))
  -- etc.
end

-- Configure LuaSnip
local setup = function()
  ls.config.set_config({
    history = true,
    updateevents = "TextChanged,TextChangedI",
    enable_autosnippets = true,
    ext_opts = {
      [require("luasnip.util.types").choiceNode] = {
        active = {
          virt_text = { { "●", "GruvboxOrange" } }
        }
      }
    }
  })
  
  -- Load all snippet files
  load_snippets()
end

return {
  setup = setup
}
