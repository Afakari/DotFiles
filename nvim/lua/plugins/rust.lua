-- Rust development stack:
--   rustaceanvim  -> rust-analyzer client, runnables/testables/debuggables, macro expansion
--   crates.nvim   -> Cargo.toml dependency versions + completion
--   nvim-dap      -> debugging via codelldb, see plugins/dap.lua

return {
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false, -- rustaceanvim sets up its own FileType autocmd
    init = function()
      vim.g.rustaceanvim = {
        tools = {
          float_win_config = { border = "rounded" },
          test_executor = "background",
        },

        server = {
          on_attach = function(client, bufnr)
            -- NvChad installs its LSP keymaps via a global LspAttach autocmd,
            -- so gd/gD/<leader>ra are already present here.

            if client:supports_method "textDocument/inlayHint" then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end

            if client:supports_method "textDocument/codeLens" then
              -- 0.12's codelens.enable owns its own refresh cycle; the old
              -- refresh()+autocmd dance is deprecated.
              vim.lsp.codelens.enable(true, { bufnr = bufnr })
            end

            local map = function(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "rust " .. desc })
            end

            map("<leader>rr", function() vim.cmd.RustLsp "runnables" end, "runnables")
            map("<leader>rl", function() vim.cmd.RustLsp { "runnables", bang = true } end, "run last")
            map("<leader>rt", function() vim.cmd.RustLsp "testables" end, "testables")
            map("<leader>rd", function() vim.cmd.RustLsp "debuggables" end, "debuggables")
            map("<leader>rm", function() vim.cmd.RustLsp "expandMacro" end, "expand macro")
            map("<leader>rc", function() vim.cmd.RustLsp "openCargo" end, "open Cargo.toml")
            map("<leader>rD", function() vim.cmd.RustLsp "openDocs" end, "open docs.rs")
            map("<leader>rp", function() vim.cmd.RustLsp "parentModule" end, "parent module")
            map("<leader>rj", function() vim.cmd.RustLsp "joinLines" end, "join lines")
            map("<leader>re", function() vim.cmd.RustLsp "explainError" end, "explain error")
            map("<leader>rE", function() vim.cmd.RustLsp "renderDiagnostic" end, "render diagnostic")
            map("<leader>rg", function() vim.cmd.RustLsp { "crateGraph", "x11" } end, "crate graph")
            map("<leader>rs", function() vim.cmd.RustLsp "ssr" end, "structural search replace")
            map("<leader>rH", function() vim.cmd.RustLsp { "view", "hir" } end, "view HIR")
            map("<leader>rM", function() vim.cmd.RustLsp { "view", "mir" } end, "view MIR")

            vim.keymap.set("n", "<leader>dn", function()
              vim.cmd.RustLsp "debug"
            end, { buffer = bufnr, desc = "dap debug target at cursor" })

            map("<leader>rL", vim.lsp.codelens.run, "run code lens")
            map("<leader>ri", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
            end, "toggle inlay hints")

            -- hover actions replace plain hover in Rust buffers
            map("K", function() vim.cmd.RustLsp { "hover", "actions" } end, "hover actions")
            map("<leader>ca", function() vim.cmd.RustLsp "codeAction" end, "grouped code action")
          end,

          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              files = {
                excludeDirs = { ".direnv", ".git", "target", "node_modules" },
              },
              inlayHints = {
                bindingModeHints = { enable = false },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 25 },
                closureReturnTypeHints = { enable = "never" },
                lifetimeElisionHints = { enable = "never", useParameterNames = false },
                maxLength = 25,
                parameterHints = { enable = true },
                reborrowHints = { enable = "never" },
                renderColons = true,
                typeHints = { enable = true, hideClosureInitialization = false, hideNamedConstructor = false },
              },
              lens = {
                enable = true,
                implementations = { enable = true },
                references = {
                  adt = { enable = true },
                  enumVariant = { enable = true },
                  method = { enable = true },
                  trait = { enable = true },
                },
              },
              completion = {
                callable = { snippets = "fill_arguments" },
                fullFunctionSignatures = { enable = true },
              },
              imports = {
                granularity = { group = "module" },
                prefix = "self",
              },
              diagnostics = {
                enable = true,
                experimental = { enable = false },
              },
            },
          },
        },

        dap = {
          -- rustaceanvim auto-discovers codelldb from mason when available
          autoload_configurations = true,
        },
      }
    end,
  },

  {
    "saecki/crates.nvim",
    tag = "stable",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
    config = function(_, opts)
      local crates = require "crates"
      crates.setup(opts)

      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("CratesKeymaps", { clear = true }),
        pattern = "Cargo.toml",
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = "crates " .. desc })
          end

          map("<leader>ct", crates.toggle, "toggle ui")
          map("<leader>cR", crates.reload, "reload")
          map("<leader>cv", crates.show_versions_popup, "show versions")
          map("<leader>cf", crates.show_features_popup, "show features")
          map("<leader>cd", crates.show_dependencies_popup, "show dependencies")
          map("<leader>cu", crates.update_crate, "update crate")
          map("<leader>ca", crates.update_all_crates, "update all crates")
          map("<leader>cU", crates.upgrade_crate, "upgrade crate")
          map("<leader>cA", crates.upgrade_all_crates, "upgrade all crates")
          map("<leader>cH", crates.open_homepage, "open homepage")
          map("<leader>cr", crates.open_repository, "open repository")
          map("<leader>cD", crates.open_documentation, "open documentation")
          map("<leader>cC", crates.open_crates_io, "open crates.io")
        end,
      })
    end,
  },
}
