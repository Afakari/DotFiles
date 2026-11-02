-- nvim-treesitter `main` only installs parsers and ignores `ensure_installed`.
-- Highlighting is started by NvChad's FileType autocmd (nvchad/autocmds.lua).

local parsers = {
  "bash",
  "diff",
  "dockerfile",
  "git_config",
  "gitcommit",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "helm",
  "html",
  "jinja",
  "jinja_inline",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "printf",
  "python",
  "query",
  "regex",
  "ron",
  "rust",
  "sql",
  "toml",
  "vim",
  "vimdoc",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    -- NvChad's build step runs TSInstallAll, which `main` does not have.
    build = ":TSUpdate",
    config = function()
      local ts = require "nvim-treesitter"
      ts.setup()
      ts.install(parsers)

      vim.treesitter.language.register("yaml", { "yaml.docker-compose" })

      -- dbt files are SQL inside Jinja. The jinja parser is loaded again under
      -- the name "dbt" so queries/dbt/ can mark the text as SQL without
      -- changing other Jinja files.
      local jinja = vim.api.nvim_get_runtime_file("parser/jinja.so", false)[1]
      if jinja then
        vim.treesitter.language.add("dbt", { path = jinja, symbol_name = "jinja" })
      end
    end,
  },
}
