-- Python stack:
--   ty + ruff (system binaries) -> LSP, see configs/lspconfig.lua
--   ruff                        -> format on save, see configs/conform.lua
--   nvim-dap-python + debugpy   -> debugging; the program runs with the
--                                  project's .venv python made by uv

local function uv(cmd)
  require("nvchad.term").runner { id = "uv", pos = "sp", cmd = "uv " .. cmd }
end

return {
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserPythonUv", { clear = true }),
        pattern = "python",
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "uv " .. desc })
          end
          map("<leader>pr", function()
            uv("run " .. vim.fn.shellescape(vim.fn.expand "%:p"))
          end, "run file")
          map("<leader>ps", function()
            uv "sync"
          end, "sync")
          map("<leader>pa", function()
            vim.ui.input({ prompt = "uv add: " }, function(pkg)
              if pkg and pkg ~= "" then
                uv("add " .. pkg)
              end
            end)
          end, "add package")
        end,
      })
    end,
    config = function()
      local dap_python = require "dap-python"
      -- debugpy's own venv runs the adapter; the debugged program uses the
      -- project's .venv (or $VIRTUAL_ENV) python.
      dap_python.setup(vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python")
      dap_python.test_runner = "pytest"
    end,
    keys = {
      {
        "<leader>dn",
        function()
          require("dap-python").test_method()
        end,
        ft = "python",
        desc = "dap debug nearest test",
      },
      {
        "<leader>dN",
        function()
          require("dap-python").test_class()
        end,
        ft = "python",
        desc = "dap debug test class",
      },
      {
        "<leader>dS",
        function()
          require("dap-python").debug_selection()
        end,
        mode = "v",
        ft = "python",
        desc = "dap debug selection",
      },
    },
  },
}
