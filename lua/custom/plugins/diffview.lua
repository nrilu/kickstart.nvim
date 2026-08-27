-- diffview.nvim: side-by-side diffs for whole branches / revision ranges.
--
-- gitsigns can only compare a buffer against a base revision. diffview gives a
-- file panel listing *every* changed file between two revisions, with a
-- side-by-side diff per file, and a commit history browser.
--
--   :DiffviewOpen                  working tree vs. index/HEAD
--   :DiffviewOpen master           working tree vs. master
--   :DiffviewOpen master..feature  two-dot: plain diff between the two tips
--   :DiffviewOpen master...feature three-dot: only what feature added since it
--                                  branched off master (the "PR view")
--   :DiffviewFileHistory %         history of the current file
--
-- Inside the view: <tab>/<s-tab> next/prev file, ]c/[c next/prev hunk,
-- <leader>e focus file panel, <leader>b toggle it, q or :DiffviewClose to quit.

--- Pick a branch/remote ref and diff the current branch against it.
local function diff_against_ref()
  local refs = vim.fn.systemlist { 'git', 'for-each-ref', '--format=%(refname:short)', '--sort=-committerdate', 'refs/heads', 'refs/remotes' }
  if vim.v.shell_error ~= 0 then
    vim.notify('Not inside a git repository', vim.log.levels.WARN)
    return
  end

  refs = vim.tbl_filter(function(ref)
    return not vim.endswith(ref, '/HEAD')
  end, refs)

  vim.ui.select(refs, { prompt = 'Diff HEAD against (merge-base):' }, function(choice)
    if choice then
      -- three-dot: changes on HEAD since it diverged from the chosen ref
      vim.cmd('DiffviewOpen ' .. vim.fn.fnameescape(choice) .. '...HEAD')
    end
  end)
end

--- Free-form revision range, e.g. `master..feature` or `HEAD~3`.
local function diff_range()
  vim.ui.input({ prompt = 'DiffviewOpen ' }, function(input)
    if input and input ~= '' then
      vim.cmd('DiffviewOpen ' .. input)
    end
  end)
end

-- ---------------------------------------------------------------------------
-- Bare-bones `git diff` look
-- ---------------------------------------------------------------------------
-- Inside a diff, syntax highlighting is turned off entirely, so unchanged code
-- is plain `Normal` text. The only color in the buffer is the diff itself:
-- added code green, removed code red -- foreground only, no background blocks.
-- Syntax is restored on `:DiffviewClose` (side "b" of a working-tree diff is
-- your real file buffer, so this has to be put back).
local palette = {
  add = '#3fbf60', -- added / new line
  add_text = '#7bf59b', -- the characters that actually differ, new side
  del = '#e0474b', -- removed / old line
  del_text = '#ff8f93', -- the characters that actually differ, old side
  dim = '#4b5263', -- "-----" filler lines
}

-- `enhanced_diff_hl` makes diffview remap the diff groups per window: in the
-- left (old) window `DiffAdd` becomes `DiffviewDiffAddAsDelete`, which inherits
-- its colors from `DiffDelete`. `DiffChange`/`DiffText` are *not* per-side by
-- default, so the CustomDiff* groups below get wired up per window in the
-- `diff_buf_win_enter` hook -- that is what makes a modified line read as red
-- on the left and green on the right, like a terminal diff.
local diff_hl = {
  DiffAdd = { fg = palette.add },
  DiffDelete = { fg = palette.del }, -- source for DiffviewDiffAddAsDelete
  DiffviewDiffAddAsDelete = { fg = palette.del },
  DiffviewDiffDeleteDim = { fg = palette.dim },
  DiffChange = { fg = palette.add }, -- fallback; the hook overrides per side
  DiffText = { fg = palette.add_text, bold = true },
  CustomDiffOldLine = { fg = palette.del },
  CustomDiffOldText = { fg = palette.del_text, bold = true },
  CustomDiffNewLine = { fg = palette.add },
  CustomDiffNewText = { fg = palette.add_text, bold = true },
  -- file panel
  DiffviewStatusAdded = { fg = palette.add },
  DiffviewStatusUntracked = { fg = palette.add },
  DiffviewStatusModified = { fg = '#e5c07b' },
  DiffviewStatusDeleted = { fg = palette.del },
  DiffviewFilePanelInsertions = { fg = palette.add },
  DiffviewFilePanelDeletions = { fg = palette.del },
}

local function apply_diff_hl()
  for group, val in pairs(diff_hl) do
    vim.api.nvim_set_hl(0, group, val)
  end
end

-- Per-window group remaps: "a" is the old side, anything else the new side.
local winhl = {
  old = table.concat({
    'DiffAdd:DiffviewDiffAddAsDelete', -- lines present only in the old file
    'DiffChange:CustomDiffOldLine',
    'DiffText:CustomDiffOldText',
    'DiffDelete:DiffviewDiffDeleteDim', -- filler
  }, ','),
  new = table.concat({
    'DiffAdd:DiffviewDiffAdd',
    'DiffChange:CustomDiffNewLine',
    'DiffText:CustomDiffNewText',
    'DiffDelete:DiffviewDiffDeleteDim',
  }, ','),
}

-- Buffers whose syntax we switched off, and what to put back afterwards.
local stripped = {}

local function strip_syntax(bufnr)
  if stripped[bufnr] or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  stripped[bufnr] = {
    syntax = vim.bo[bufnr].syntax,
    treesitter = vim.treesitter.highlighter.active[bufnr] ~= nil,
    lsp = #vim.lsp.get_clients { bufnr = bufnr } > 0,
  }

  if stripped[bufnr].treesitter then
    pcall(vim.treesitter.stop, bufnr)
  end
  if stripped[bufnr].lsp then
    pcall(vim.lsp.semantic_tokens.enable, false, { bufnr = bufnr })
  end
  vim.bo[bufnr].syntax = 'off'
end

local function restore_syntax()
  for bufnr, prev in pairs(stripped) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.bo[bufnr].syntax = prev.syntax
      if prev.treesitter then
        pcall(vim.treesitter.start, bufnr)
      end
      if prev.lsp then
        pcall(vim.lsp.semantic_tokens.enable, true, { bufnr = bufnr })
      end
    end
  end
  stripped = {}
end

return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = {
      'DiffviewOpen',
      'DiffviewClose',
      'DiffviewFileHistory',
      'DiffviewFocusFiles',
      'DiffviewToggleFiles',
      'DiffviewRefresh',
    },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', desc = '[G]it [d]iff working tree' },
      { '<leader>gc', diff_against_ref, desc = '[G]it diff vs [c]hosen branch' },
      { '<leader>gr', diff_range, desc = '[G]it diff [r]evision range' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = '[G]it file [h]istory (current file)' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<cr>', desc = '[G]it [H]istory (whole repo)' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>', desc = '[G]it diff [q]uit' },
    },
    opts = {
      enhanced_diff_hl = true, -- clearer word-level highlighting
      view = {
        default = { layout = 'diff2_vertical' }, -- old | new, side by side
        merge_tool = { layout = 'diff3_mixed' },
        file_history = { layout = 'diff2_horizontal' },
      },
      file_panel = {
        listing_style = 'tree',
        win_config = { position = 'left', width = 55 },
      },
      keymaps = {
        view = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
        file_panel = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
        file_history_panel = {
          { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        },
      },
      hooks = {
        -- Runs with the diff buffer/window current, after diffview applied its
        -- own window options -- so this remap wins.
        diff_buf_win_enter = function(bufnr, winid, ctx)
          strip_syntax(bufnr)
          vim.wo[winid].winhighlight = ctx.symbol == 'a' and winhl.old or winhl.new
        end,
      },
    },
    config = function(_, opts)
      require('diffview').setup(opts)
      apply_diff_hl()

      local group = vim.api.nvim_create_augroup('custom-diffview-hl', { clear = true })
      -- init.lua swaps colorschemes per filetype, and every switch wipes these
      -- groups -- diffview reinstalls its defaults on ColorScheme, so reapply
      -- afterwards (this autocmd is registered last, so it wins).
      vim.api.nvim_create_autocmd('ColorScheme', {
        group = group,
        desc = 'Reapply the git-diff style highlights',
        callback = apply_diff_hl,
      })
      vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'DiffviewViewClosed',
        desc = 'Give the real file buffers their syntax highlighting back',
        callback = function()
          -- deferred: the closing view is still listed when the event fires
          vim.schedule(function()
            -- keep the diff style while another diffview tab is still open
            if #require('diffview.lib').views == 0 then
              restore_syntax()
            end
          end)
        end,
      })
    end,
  },
}
