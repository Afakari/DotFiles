-- hadolint adds Dockerfile best-practice checks on top of
-- docker_language_server. sqlfluff lints SQL and dbt files, see lua/sqlfluff.lua.

local sql_fts = { dbt = true, sql = true }

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
      local lint = require "lint"
      local sqlfluff = require "sqlfluff"

      lint.linters_by_ft = {
        dbt = { "sqlfluff" },
        dockerfile = { "hadolint" },
        sql = { "sqlfluff" },
      }

      local linter = lint.linters.sqlfluff
      linter.cmd = function()
        return sqlfluff.cmd(0)
      end
      -- The file name lets sqlfluff find nested configs and the dbt model.
      linter.args = {
        "lint",
        "--format=json",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
        "-",
      }

      local function run(buf, event)
        if not sql_fts[vim.bo[buf].filetype] then
          return lint.try_lint()
        end
        -- sqlfluff is slow (the dbt templater compiles the model), so it runs on
        -- open and save only.
        if event ~= "InsertLeave" and sqlfluff.config_root(buf) then
          lint.try_lint(nil, { cwd = sqlfluff.cwd(buf) })
        end
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
        callback = function(ev)
          run(ev.buf, ev.event)
        end,
      })
      -- The plugin loads during the first BufReadPost, which can be before the
      -- filetype is set, so the first lint waits for the event to finish.
      vim.schedule(function()
        run(vim.api.nvim_get_current_buf(), "BufReadPost")
      end)
    end,
  },
}
