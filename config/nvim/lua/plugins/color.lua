return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  { "catppuccin/nvim" },
  { "shatur/neovim-ayu" },
  { "projekt0n/github-nvim-theme" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
      -- colorscheme = "catppuccin",
      -- colorscheme = "github_dark_default",
      -- colorscheme = "ayu",
    },
  },
}
