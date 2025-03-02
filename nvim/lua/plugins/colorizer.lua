return {
  "norcalli/nvim-colorizer.lua",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("colorizer").setup({
      -- Filetypes to enable colorizer for
      'css',
      'javascript',
      'typescript',
      'html',
      'lua',
      'cpp', -- Enabling for C++
      'vim',
      'scss',
      -- You can enable it for all files (but might impact performance)
      -- '*',
    }, {
      -- Default options
      RGB = true,         -- #RGB hex codes
      RRGGBB = true,      -- #RRGGBB hex codes
      names = true,       -- Named colors like "Red" or "Blue"
      RRGGBBAA = true,    -- #RRGGBBAA hex codes
      rgb_fn = true,      -- CSS rgb() and rgba() functions
      hsl_fn = true,      -- CSS hsl() and hsla() functions
      css = true,         -- Enable all CSS features
      css_fn = true,      -- CSS functions
      mode = 'background', -- 'background' or 'foreground'
      -- You can add custom patterns too, though this is advanced
      -- See the documentation for details
    })
  end,
}
