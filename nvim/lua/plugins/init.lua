return {
  {
    "stevearc/conform.nvim",
    -- Without this the plugin never loads, so configs.conform's
    -- format_on_save was never registered (Go was affected too).
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
    "williamboman/mason.nvim",
    -- NvChad's spec only loads mason on :Mason*, so ensure_installed never
    -- ran. It must also be eager: mason.setup() is what prepends
    -- ~/.local/share/nvim/mason/bin to PATH, and vim.lsp.enable() below
    -- silently skips any server whose binary is not yet on PATH.
    lazy = false,
    priority = 100,
    config = function()
      require("mason").setup {
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      }

      -- Non-LSP tools (debug adapters, formatters, linters) that
      -- mason-lspconfig's ensure_installed does not cover.
      -- ruff, ty and uv come from the system package manager, not mason.
      local ensure_tools = {
        "codelldb",
        "debugpy",
        "delve",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "hadolint",
        "sqlfluff",
        "stylua",
      }

      vim.api.nvim_create_autocmd("User", {
        pattern = "MasonToolsBootstrap",
        once = true,
        callback = function()
          local registry = require "mason-registry"
          registry.refresh(function()
            for _, name in ipairs(ensure_tools) do
              local ok, pkg = pcall(registry.get_package, name)
              if ok and not pkg:is_installed() and not pkg:is_installing() then
                vim.notify("[mason] installing " .. name, vim.log.levels.INFO)
                pcall(function()
                  pkg:install()
                end)
              end
            end
          end)
        end,
      })

      vim.schedule(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "MasonToolsBootstrap" })
      end)
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = "User FilePost",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup {
        ensure_installed = {
          "docker_language_server",
          "golangci_lint_ls",
          "gopls",
          "helm_ls",
          "lua_ls",
          "marksman",
          "taplo",
          "yamlls",
        },
        -- rustaceanvim owns the rust-analyzer client; mason must not start a
        -- second one or the two clients fight over the same buffers.
        automatic_enable = { exclude = { "rust_analyzer" } },
      }
    end,
  },

  -- JSON/YAML schemas for yamlls (see configs/lspconfig.lua).
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
}
