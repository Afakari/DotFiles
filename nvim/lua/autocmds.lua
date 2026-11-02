require "nvchad.autocmds"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbt",
  callback = function(ev)
    require("dbt").attach(ev.buf)
  end,
})
