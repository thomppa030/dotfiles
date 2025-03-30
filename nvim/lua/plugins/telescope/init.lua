-- Main entry point for Telescope configuration
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
  },
  config = function()
    -- Load core configuration
    local config = require('plugins.telescope.config')

    -- Set up telescope with our configuration
    local telescope = require('telescope')
    telescope.setup(config)

    -- Load extensions
    telescope.load_extension('fzf')

    -- Set up keymappings
    require('plugins.telescope.mappings')

    -- Load all extensions
    require('plugins.telescope.extensions').load_all()
  end,
}
