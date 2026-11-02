require("nvchad.configs.lspconfig").defaults()

-- NOTE: rust_analyzer is deliberately absent — rustaceanvim starts and owns
-- that client itself (see lua/plugins/rust.lua). Enabling it here too would
-- attach two rust-analyzer clients to every Rust buffer.

-- Python: ty does types, hover and go-to; ruff does lint and quick fixes.
vim.lsp.config("ty", {})
vim.lsp.config("ruff", {})

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      completeUnimported = true,
      usePlaceholders = false,
      analyses = {
        nilness = true,
        shadow = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      codelenses = {
        generate = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

-- Kubernetes manifests have no fixed file name, so they are matched by folder.
-- Any other YAML file can opt in with a first line of
--   # yaml-language-server: $schema=kubernetes
local k8s_globs = {
  "*.k8s.yaml",
  "*.k8s.yml",
  "**/k8s/**/*.yaml",
  "**/k8s/**/*.yml",
  "**/kubernetes/**/*.yaml",
  "**/kubernetes/**/*.yml",
  "**/manifests/**/*.yaml",
  "**/manifests/**/*.yml",
  "**/deploy/**/*.yaml",
  "**/deploy/**/*.yml",
}

vim.lsp.config("yamlls", {
  -- Helm templates belong to helm_ls. Compose files get both: yamlls checks
  -- them against the Compose schema, which docker_language_server does not.
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  before_init = function(_, config)
    local schemas = require("schemastore").yaml.schemas()
    schemas.kubernetes = k8s_globs
    -- SchemaStore only knows dbt folders named *dbt*; projects/<name>/models
    -- below a dbt/ folder needs these too.
    for _, globs in pairs(schemas) do
      if type(globs) == "table" and vim.tbl_contains(globs, "**/*dbt*/models/**/*.yml") then
        for _, dir in ipairs { "models", "macros", "seeds", "snapshots" } do
          table.insert(globs, "**/dbt/**/" .. dir .. "/**/*.yml")
          table.insert(globs, "**/dbt/**/" .. dir .. "/**/*.yaml")
        end
      end
    end
    config.settings.yaml.schemas = schemas
  end,
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      -- SchemaStore.nvim supplies the catalog; the built-in download would
      -- clash with it.
      schemaStore = { enable = false, url = "" },
      keyOrdering = false,
      validate = true,
      format = { enable = false },
    },
  },
})

vim.lsp.config("helm_ls", {
  settings = {
    ["helm-ls"] = {
      yamlls = { path = "yaml-language-server" },
    },
  },
})

vim.lsp.enable {
  "docker_language_server",
  "golangci_lint_ls",
  "gopls",
  "helm_ls",
  "marksman",
  "ruff",
  "taplo",
  "ty",
  "yamlls",
}

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- ty answers hover for Python; two hover popups would stack.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    if client.name ~= "rust-analyzer" and client:supports_method "textDocument/inlayHint" then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      vim.keymap.set("n", "<leader>ih", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = ev.buf }, { bufnr = ev.buf })
      end, { buffer = ev.buf, desc = "LSP toggle inlay hints" })
    end
  end,
})
