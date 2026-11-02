return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- lazy = true is the default here, so without `ft` it never loaded.
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      completions = { lsp = { enabled = true } },
      -- Math needs the latex parser and utftex/latex2text; none are installed.
      latex = { enabled = false },
    },
    keys = {
      { "<leader>mt", "<cmd>RenderMarkdown toggle<cr>", ft = "markdown", desc = "markdown toggle render" },
    },
  },
}
