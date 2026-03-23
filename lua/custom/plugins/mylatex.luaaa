return {
  {
    'lervag/vimtex',
    ft = { 'tex' },

    init = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_quickfix_mode = 0
      -- vim.g.maplocalleader = ',' //needs to be defined before the lazy plugin

      -- vim.o.foldmethod = 'expr'
      -- vim.o.foldexpr = 'vimtex#fold#level(v:lnum)'
      -- vim.o.foldtext = 'vimtex#fold#text()'
      -- vim.o.foldlevel = 4
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    opts = function(_, opts)
      local cmp = require 'cmp'

      opts.sources = cmp.config.sources {
        { name = 'nvim_lsp' },
        { name = 'buffer' },
      }

      opts.mapping = cmp.mapping.preset.insert {
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-l>'] = cmp.mapping.confirm { select = true },
      }
    end,
  },
}
