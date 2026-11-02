local M = {}

-- Per project root: models (name -> path) and sources (name -> {file, line, tables}).
-- Cleared when a file in the project is saved.
local cache = {}

local function notify(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "dbt" })
end

local function root(buf)
  return vim.fs.root(buf or 0, "dbt_project.yml")
end

local function project_lines(r)
  return vim.fn.readfile(r .. "/dbt_project.yml")
end

local function project_paths(r, key, default)
  for _, line in ipairs(project_lines(r)) do
    local list = line:match("^" .. key .. ":%s*%[(.-)%]")
    if list then
      local out = {}
      for p in list:gmatch "[\"']([^\"']+)[\"']" do
        table.insert(out, p)
      end
      return out
    end
  end
  return { default }
end

local function existing(r, dirs)
  return vim.tbl_filter(function(d)
    return vim.uv.fs_stat(r .. "/" .. d) ~= nil
  end, dirs)
end

local function rg(args, cwd)
  local cmd = { "rg", "--no-ignore", "--follow", "-g", "!**/target/**", "-g", "!**/logs/**", "-g", "!**/.venv/**" }
  local res = vim.system(vim.list_extend(cmd, args), { cwd = cwd, text = true }):wait()
  return vim.split(res.stdout or "", "\n", { trimempty = true })
end

local function models(r)
  cache[r] = cache[r] or {}
  if cache[r].models then
    return cache[r].models
  end
  local dirs = {}
  vim.list_extend(dirs, project_paths(r, "model%-paths", "models"))
  vim.list_extend(dirs, project_paths(r, "seed%-paths", "seeds"))
  vim.list_extend(dirs, project_paths(r, "snapshot%-paths", "snapshots"))
  local out = {}
  dirs = existing(r, dirs)
  if #dirs > 0 then
    for _, f in ipairs(rg(vim.list_extend({ "--files", "-g", "*.sql", "-g", "*.py", "-g", "*.csv" }, dirs), r)) do
      out[vim.fn.fnamemodify(f, ":t:r")] = r .. "/" .. f
    end
  end
  cache[r].models = out
  return out
end

-- Reads `sources:` blocks from the YAML files under the model paths.
local function sources(r)
  cache[r] = cache[r] or {}
  if cache[r].sources then
    return cache[r].sources
  end
  local out = {}
  local dirs = existing(r, project_paths(r, "model%-paths", "models"))
  local files = #dirs > 0 and rg(vim.list_extend({ "--files", "-g", "*.yml", "-g", "*.yaml" }, dirs), r) or {}
  for _, f in ipairs(files) do
    local path = r .. "/" .. f
    local in_sources, src = false, nil
    for i, line in ipairs(vim.fn.readfile(path)) do
      if line:match "^sources:" then
        in_sources, src = true, nil
      elseif line:match "^[%w_]+:" then
        in_sources = false
      elseif in_sources then
        local indent, name = line:match "^(%s*)%-%s*name:%s*[\"']?([%w_%.%-]+)"
        if name then
          if not src or #indent <= src.indent then
            src = { file = path, line = i, indent = #indent, tables = {} }
            out[name] = src
          elseif not src.table_indent or #indent == src.table_indent then
            src.table_indent = #indent
            src.tables[name] = src.tables[name] or i
          end
        end
      end
    end
  end
  cache[r].sources = out
  return out
end

-- String arguments of a `name(...)` call that spans the cursor, and whether
-- the cursor is inside the parentheses.
local function call_at_cursor(name)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  for s, a, args, e in line:gmatch("()%f[%w_]" .. name .. "%s*%(()(.-)%)()") do
    if col >= s and col < e then
      local out = {}
      for v in args:gmatch "[\"']([^\"']+)[\"']" do
        table.insert(out, v)
      end
      return out, col >= a
    end
  end
end

local function jump(file, line)
  vim.cmd "normal! m'"
  vim.cmd.edit(vim.fn.fnameescape(file))
  if line then
    vim.api.nvim_win_set_cursor(0, { line, 0 })
  end
end

function M.goto_definition()
  local r = root()
  if not r then
    return
  end

  local args = call_at_cursor "ref"
  if args and #args > 0 then
    local name = args[#args]
    local file = models(r)[name]
    if file then
      return jump(file)
    end
    return notify("model not found: " .. name)
  end

  -- Also wrappers such as normalized_source(); on the wrapper's own name the
  -- macro lookup below runs instead.
  local in_args
  args, in_args = call_at_cursor "[%w_]*source"
  if args and #args > 0 and in_args then
    local src = sources(r)[args[1]]
    if not src then
      return notify("source not found: " .. args[1])
    end
    return jump(src.file, args[2] and src.tables[args[2]] or src.line)
  end

  local word = vim.fn.expand "<cword>"
  local hits = rg({ "-n", "--no-heading", "--with-filename", "-g", "*.sql", "-e", "\\{%-?\\s*macro\\s+" .. word .. "\\s*\\(", "." }, r)
  table.sort(hits, function(a, b)
    return (a:find "dbt_packages" and 1 or 0) < (b:find "dbt_packages" and 1 or 0)
  end)
  local file, line = (hits[1] or ""):match "^(.-):(%d+):"
  if file then
    return jump(vim.fs.normalize(r .. "/" .. file), tonumber(line))
  end
  notify("no ref, source or macro under the cursor: " .. word)
end

-- Opens what `dbt compile` last wrote for this file, if anything.
function M.open_compiled()
  local r = root()
  if not r then
    return
  end
  local name
  for _, line in ipairs(project_lines(r)) do
    name = name or line:match "^name:%s*[\"']?([%w_]+)"
  end
  local rel = vim.fs.relpath(r, vim.api.nvim_buf_get_name(0))
  local file = string.format("%s/target/compiled/%s/%s", r, name or "", rel or "")
  if not vim.uv.fs_stat(file) then
    return notify "no compiled SQL for this file yet; it appears after dbt compile or dbt run"
  end
  vim.cmd.vsplit(vim.fn.fnameescape(file))
  vim.bo.readonly = true
  vim.bo.modifiable = false
end

local source = {}

function source:is_available()
  return vim.bo.filetype == "dbt"
end

function source:get_trigger_characters()
  return { "'", '"' }
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

function source:complete(params, callback)
  local r = root()
  if not r then
    return callback()
  end
  local kind = require("cmp").lsp.CompletionItemKind
  local before = params.context.cursor_before_line
  local items = {}

  if before:match "%f[%w_]ref%s*%(%s*[\"'][%w_]*$" then
    for name, path in pairs(models(r)) do
      table.insert(items, { label = name, kind = kind.File, detail = vim.fs.relpath(r, path) })
    end
  elseif before:match "%f[%w_][%w_]*source%s*%(%s*[\"'][%w_]*$" then
    for name in pairs(sources(r)) do
      table.insert(items, { label = name, kind = kind.Module })
    end
  else
    local src = before:match "%f[%w_][%w_]*source%s*%(%s*[\"']([%w_]+)[\"']%s*,%s*[\"'][%w_]*$"
    local s = src and sources(r)[src]
    for name in pairs(s and s.tables or {}) do
      table.insert(items, { label = name, kind = kind.Struct })
    end
  end
  callback(items)
end

local setup_done = false

local function setup()
  if setup_done then
    return
  end
  setup_done = true

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("DbtCache", { clear = true }),
    pattern = { "*.sql", "*.py", "*.csv", "*.yml", "*.yaml" },
    callback = function(ev)
      local r = root(ev.buf)
      if r then
        cache[r] = nil
      end
    end,
  })

  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.register_source("dbt", setmetatable({}, { __index = source }))
    cmp.setup.filetype("dbt", {
      sources = cmp.config.sources {
        { name = "dbt" },
        { name = "luasnip" },
        { name = "buffer" },
        { name = "async_path" },
      },
    })
  end

  local ok_ls, luasnip = pcall(require, "luasnip")
  if ok_ls then
    luasnip.filetype_extend("dbt", { "sql" })
  end
end

function M.attach(buf)
  setup()
  vim.bo[buf].commentstring = "-- %s"
  local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = "dbt " .. desc })
  end
  map("gd", M.goto_definition, "go to ref, source or macro")
  map("<leader>oc", M.open_compiled, "open compiled SQL")
end

return M
