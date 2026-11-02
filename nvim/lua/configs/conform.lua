-- No LSP formatting on save for these: yaml/docker/markdown servers would
-- rewrite whole files (quotes, spacing) and make noisy diffs.
local no_lsp_format = {
  dockerfile = true,
  helm = true,
  markdown = true,
  yaml = true,
  ["yaml.docker-compose"] = true,
  ["yaml.helm-values"] = true,
}

-- sqlfluff fix can take seconds and touches the whole file, so SQL is fixed
-- only on <leader>fm, never on save.
local no_format_on_save = {
  dbt = true,
  sql = true,
}

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    -- ruff_fix is left out: on save it would delete imports you just added.
    python = { "ruff_organize_imports", "ruff_format" },
    go = { "goimports", "gofumpt" },
    -- rust-analyzer invokes rustfmt with the edition/config from Cargo.toml,
    -- which a bare `rustfmt` call on a single file cannot know.
    rust = { lsp_format = "prefer" },
    toml = { "taplo" },
    dbt = { "sqlfluff" },
    sql = { "sqlfluff" },
  },

  formatters = {
    sqlfluff = {
      command = function(_, ctx)
        return require("sqlfluff").cmd(ctx.buf)
      end,
      args = { "fix", "--stdin-filename", "$FILENAME", "-" },
      -- nil without a sqlfluff config, and require_cwd then skips it.
      cwd = function(_, ctx)
        return require("sqlfluff").cwd(ctx.buf)
      end,
      require_cwd = true,
      -- 1 means some violations could not be fixed; the output is still the fixed file.
      exit_codes = { 0, 1 },
    },
  },

  format_on_save = function(bufnr)
    if no_format_on_save[vim.bo[bufnr].filetype] then
      return nil
    end
    return {
      timeout_ms = 2000,
      lsp_format = no_lsp_format[vim.bo[bufnr].filetype] and "never" or "fallback",
    }
  end,
}

return options
