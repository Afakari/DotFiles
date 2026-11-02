-- Shared debugger UI and keys. Language adapters live in rust.lua (codelldb),
-- python.lua (debugpy) and go.lua (delve). <leader>dn debugs the nearest test
-- or target in each of them.

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "nvim-neotest/nvim-nio" },
      {
        "rcarriga/nvim-dap-ui",
        opts = {},
        config = function(_, opts)
          local dap, dapui = require "dap", require "dapui"
          dapui.setup(opts)
          dap.listeners.before.attach.dapui_config = function() dapui.open() end
          dap.listeners.before.launch.dapui_config = function() dapui.open() end
          dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
          dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
        end,
      },
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = { virt_text_pos = "eol" },
      },
    },
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "dap toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ") end,
        desc = "dap conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "dap continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "dap step into" },
      { "<leader>dv", function() require("dap").step_over() end, desc = "dap step over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "dap step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "dap toggle repl" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "dap run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "dap terminate" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "dap toggle ui" },
      {
        "<leader>de",
        function() require("dapui").eval(nil, { enter = true }) end,
        mode = { "n", "v" },
        desc = "dap eval expression",
      },
    },
    config = function()
      -- A sign with empty text is dropped by Neovim 0.12, and the breakpoint
      -- with it, so every sign needs a visible character.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
      vim.fn.sign_define("DapLogPoint", { text = "◇", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticInfo", linehl = "Visual" })
    end,
  },
}
