local M = {}

local function path_of(buf)
  return vim.api.nvim_buf_get_name(buf)
end

-- Folder of the nearest sqlfluff config, or nil. Without a config sqlfluff
-- stops with "no dialect", so nothing runs then.
function M.config_root(buf)
  for dir in vim.fs.parents(path_of(buf)) do
    if vim.uv.fs_stat(dir .. "/.sqlfluff") then
      return dir
    end
    local pyproject = dir .. "/pyproject.toml"
    if vim.uv.fs_stat(pyproject) and vim.fn.match(vim.fn.readfile(pyproject), [[^\[tool\.sqlfluff]]) >= 0 then
      return dir
    end
  end
end

-- The repo's .venv sqlfluff when there is one, so the repo's version, plugins
-- and templater (dbt included) are used; else the mason one.
function M.cmd(buf)
  local venv = vim.fs.find(".venv", { path = vim.fs.dirname(path_of(buf)), upward = true, type = "directory" })[1]
  if venv and vim.fn.executable(venv .. "/bin/sqlfluff") == 1 then
    return venv .. "/bin/sqlfluff"
  end
  return "sqlfluff"
end

-- The dbt templater takes the project from the working folder.
function M.cwd(buf)
  if not M.config_root(buf) then
    return nil
  end
  return vim.fs.root(buf, "dbt_project.yml") or M.config_root(buf)
end

return M
