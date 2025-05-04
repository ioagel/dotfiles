return {
  -- add colorschemes
  { "ellisonleao/gruvbox.nvim" },
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  { "shatur/neovim-ayu" },
  { "projekt0n/github-nvim-theme" },

  -- Configure LazyVim with a default colorscheme
  -- (the auto-theme plugin will override this dynamically)
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
