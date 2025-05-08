-- This is a workaround to avoid the issue with mason.nvim
-- https://github.com/LazyVim/LazyVim/issues/6039
-- TODO: Remove this once the issue is fixed
return {
  { "mason-org/mason.nvim",           version = "^1.0.0" },
  { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
}
