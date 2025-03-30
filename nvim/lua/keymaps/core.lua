-- lua/keymaps/core.lua
-- Core keymappings that don't depend on plugins

local M = {}

function M.setup(keymaps)
  -- Register window management keys
  keymaps.register("window", {
    n = {
      -- Navigation between windows
      ["<C-h>"] = { "<C-w>h", { desc = "Navigate to the left window" } },
      ["<C-j>"] = { "<C-w>j", { desc = "Navigate to the bottom window" } },
      ["<C-k>"] = { "<C-w>k", { desc = "Navigate to the top window" } },
      ["<C-l>"] = { "<C-w>l", { desc = "Navigate to the right window" } },

      -- Resize windows
      ["<C-Up>"] = { ":resize -2<CR>", { desc = "Decrease window height" } },
      ["<C-Down>"] = { ":resize +2<CR>", { desc = "Increase window height" } },
      ["<C-Left>"] = { ":vertical resize -2<CR>", { desc = "Decrease window width" } },
      ["<C-Right>"] = { ":vertical resize +2<CR>", { desc = "Increase window width" } },
    },
  })

  -- Register editing keys
  keymaps.register("editing", {
    v = {
      -- Stay in indent mode
      ["<"] = { "<gv", { desc = "Indent left and stay in visual mode" } },
      [">"] = { ">gv", { desc = "Indent right and stay in visual mode" } },
      -- Move selected lines
      ["<A-j>"] = { ":m '>+1<CR>gv=gv", { desc = "Move selection down" } },
      ["<A-k>"] = { ":m '<-2<CR>gv=gv", { desc = "Move selection up" } },
    },
    n = {
      -- Move lines
      ["<A-j>"] = { ":m .+1<CR>==", { desc = "Move line down" } },
      ["<A-k>"] = { ":m .-2<CR>==", { desc = "Move line up" } },
    },
  })

  -- Register file/buffer operations
  keymaps.register("file", {
    n = {
      -- Save and quit
      ["<leader>w"] = { ":w<CR>", { desc = "Save file" } },
      ["<leader>q"] = { ":q<CR>", { desc = "Quit" } },

      -- Clear search highlight
      ["<Esc>"] = { ":noh<CR>", { desc = "Clear search highlights" } },

      -- File browser (Oil)
      ["<C-n>"] = { ":Oil<CR>", { desc = "Open file browser" } },

      -- Change current directory to file path
      ["<leader>cd"] = { ":lcd %:p:h<CR>", { desc = "Change directory to current file" } },

      -- Reload configuration
      ["<leader>sc"] = { ":luafile $MYVIMRC<CR> :echo 'Neovim configuration reloaded!'<CR>",
        { desc = "Reload Neovim configuration" } },
    },
  })

  -- Disable arrow keys (for discipline)
  keymaps.register("discipline", {
    n = {
      ["<Up>"] = { "<Nop>", { desc = "Disabled - use k instead" } },
      ["<Down>"] = { "<Nop>", { desc = "Disabled - use j instead" } },
      ["<Left>"] = { "<Nop>", { desc = "Disabled - use h instead" } },
      ["<Right>"] = { "<Nop>", { desc = "Disabled - use l instead" } },
    },
    i = {
      ["<Up>"] = { "<Nop>", { desc = "Disabled - use Ctrl+p/k instead" } },
      ["<Down>"] = { "<Nop>", { desc = "Disabled - use Ctrl+n/j instead" } },
      ["<Left>"] = { "<Nop>", { desc = "Disabled - use Ctrl+b/h instead" } },
      ["<Right>"] = { "<Nop>", { desc = "Disabled - use Ctrl+f/l instead" } },
    },
    v = {
      ["<Up>"] = { "<Nop>", { desc = "Disabled - use k instead" } },
      ["<Down>"] = { "<Nop>", { desc = "Disabled - use j instead" } },
      ["<Left>"] = { "<Nop>", { desc = "Disabled - use h instead" } },
      ["<Right>"] = { "<Nop>", { desc = "Disabled - use l instead" } },
    },
    c = {
      ["<Up>"] = { "<Nop>", { desc = "Disabled - use Ctrl+p instead" } },
      ["<Down>"] = { "<Nop>", { desc = "Disabled - use Ctrl+n instead" } },
      ["<Left>"] = { "<Nop>", { desc = "Disabled - use Ctrl+b instead" } },
      ["<Right>"] = { "<Nop>", { desc = "Disabled - use Ctrl+f instead" } },
    },
  })

  -- Add C++ specific mappings
  keymaps.register("cpp", {
    n = {
      ["<A-o>"] = { ":ClangdSwitchSourceHeader<CR>", { desc = "Switch between header and source" } },
    },
  })
end

return M
