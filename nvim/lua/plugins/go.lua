-- Go stack:
--   gopls + golangci_lint_ls -> LSP, see configs/lspconfig.lua
--   goimports + gofumpt      -> format on save, see configs/conform.lua
--   nvim-dap-go + delve      -> debugging (delve comes from mason)

return {
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    opts = {},
    keys = {
      {
        "<leader>dn",
        function()
          require("dap-go").debug_test()
        end,
        ft = "go",
        desc = "dap debug nearest test",
      },
      {
        "<leader>dN",
        function()
          require("dap-go").debug_last_test()
        end,
        ft = "go",
        desc = "dap debug last test",
      },
    },
  },
}
