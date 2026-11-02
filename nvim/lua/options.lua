require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
vim.opt.clipboard:append("unnamedplus")

-- Helm files only count when a Chart.yaml sits above them, so plain
-- `templates/` folders in other projects stay yaml.
local function in_helm_chart(path)
  return vim.fs.root(path, "Chart.yaml") ~= nil
end

vim.g.snipmate_snippets_path = vim.fn.stdpath "config" .. "/snippets"

vim.filetype.add {
  filename = {
    ["compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["docker-compose.yml"] = "yaml.docker-compose",
  },
  pattern = {
    ["compose%..+%.ya?ml"] = "yaml.docker-compose",
    ["docker%-compose%..+%.ya?ml"] = "yaml.docker-compose",
    ["helmfile.*%.ya?ml"] = "helm",
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.ya?ml"] = function(path)
      if in_helm_chart(path) then
        return "helm"
      end
    end,
    [".*%.sql"] = function(path)
      if vim.fs.root(path, "dbt_project.yml") then
        return "dbt"
      end
    end,
    [".*/values.*%.ya?ml"] = function(path)
      if vim.uv.fs_stat(vim.fs.joinpath(vim.fs.dirname(path), "Chart.yaml")) then
        return "yaml.helm-values"
      end
    end,
  },
}
