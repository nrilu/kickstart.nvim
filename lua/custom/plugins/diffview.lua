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
-- Inside either view (German-layout friendly, no bracket keys):
--   ö / Ö   next / previous hunk
--   ü / Ü   next / previous file
--   q       close
-- Unified view also has <CR> to fold/unfold the file under the cursor.
--
-- Two ways to look at a diff:
--   <leader>gd/gc/gr  side-by-side (diffview), old on the left, new on the right
--   <leader>gu/gU     unified -- one column of -/+ lines, like `git diff` in a
--                     terminal (see `unified_diff` below)
-- Both use the same colors: no backgrounds, green for added, red for removed.

--- Run git in the current file's directory, so this also works on a repo that
--- isn't nvim's cwd.
local function git(args)
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= '' and vim.fs.dirname(file) or vim.fn.getcwd()
  if vim.fn.isdirectory(dir) ~= 1 then
    dir = vim.fn.getcwd()
  end
  return vim.system(vim.list_extend({ 'git' }, args), { cwd = dir, text = true }):wait()
end

--- Pick a branch/remote ref, then hand it to `on_choice`.
local function pick_ref(prompt, on_choice)
  local res = git { 'for-each-ref', '--format=%(refname:short)', '--sort=-committerdate', 'refs/heads', 'refs/remotes' }
  if res.code ~= 0 then
    vim.notify('Not inside a git repository', vim.log.levels.WARN)
    return
  end

  local refs = vim.tbl_filter(function(ref)
    return ref ~= '' and not vim.endswith(ref, '/HEAD')
  end, vim.split(res.stdout, '\n', { trimempty = true }))

  vim.ui.select(refs, { prompt = prompt }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

--- Side-by-side diff of HEAD against a picked ref.
local function diff_against_ref()
  pick_ref('Diff HEAD against (merge-base):', function(ref)
    -- three-dot: changes on HEAD since it diverged from the chosen ref
    vim.cmd('DiffviewOpen ' .. vim.fn.fnameescape(ref) .. '...HEAD')
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
-- Unified diff: a single column with -/+ lines interleaved
-- ---------------------------------------------------------------------------
-- diffview is split-only -- its one single-window layout (`diff1_plain`) is for
-- merge conflicts and shows no diff at all -- so this is plain `git diff`
-- output dropped into a scratch buffer with `filetype=diff`. The treesitter
-- `diff` parser (already in your ensure_installed list) colors it, and it stays
-- an ordinary buffer: searchable, yankable, foldable per file.
local unified_nr = 0

--- @param range string|nil  e.g. "master...HEAD", "HEAD~3", "" for working tree
local function unified_diff(range)
  local args = vim.split(range or '', '%s+', { trimempty = true })
  local res = git(vim.list_extend({ 'diff' }, args))
  if res.code ~= 0 then
    vim.notify('git diff failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(res.stdout or '', '\n')
  if lines[#lines] == '' then
    table.remove(lines)
  end
  if #lines == 0 then
    vim.notify('No differences', vim.log.levels.INFO)
    return
  end

  vim.cmd 'tabnew'
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  unified_nr = unified_nr + 1
  local label = (range and range ~= '') and range or 'working tree'
  pcall(vim.api.nvim_buf_set_name, buf, string.format('git diff %s [%d]', label, unified_nr))

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'diff'
  vim.bo[buf].modifiable = false

  -- bare terminal look: no gutter, no line numbers, no wrapping
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  -- one fold per file, all open to start with
  vim.wo[win].foldmethod = 'expr'
  vim.wo[win].foldexpr = "getline(v:lnum) =~ '^diff --git' ? '>1' : '1'"
  vim.wo[win].foldlevel = 99

  -- Navigation on umlaut keys: [ and ] need AltGr on a German layout, and
  -- a/A is taken by the global ä -> / remap, so: ö/Ö hunks, ü/Ü files.
  local function map(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = buf, desc = desc })
  end
  map('q', '<cmd>tabclose<cr>', 'Close the diff')
  map('ö', function()
    vim.fn.search('^@@', 'W')
  end, 'Next hunk')
  map('Ö', function()
    vim.fn.search('^@@', 'bW')
  end, 'Previous hunk')
  map('ü', function()
    vim.fn.search('^diff --git', 'W')
  end, 'Next file')
  map('Ü', function()
    vim.fn.search('^diff --git', 'bW')
  end, 'Previous file')
  map('<CR>', 'za', 'Fold / unfold this file')
end

--- Unified diff of HEAD against a picked ref.
local function unified_against_ref()
  pick_ref('Unified diff of HEAD against (merge-base):', function(ref)
    unified_diff(ref .. '...HEAD')
  end)
end

--- Unified diff of a free-form range; empty input = working tree.
local function unified_range()
  vim.ui.input({ prompt = 'git diff ' }, function(input)
    if input then
      unified_diff(input)
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
  -- unified `git diff` buffers (filetype=diff): treesitter captures first,
  -- then the legacy vim-syntax groups as a fallback
  ['@diff.plus'] = { fg = palette.add },
  ['@diff.minus'] = { fg = palette.del },
  ['@diff.delta'] = { fg = '#e5c07b' },
  diffAdded = { fg = palette.add },
  diffRemoved = { fg = palette.del },
  diffChanged = { fg = '#e5c07b' },
  diffNewFile = { fg = palette.add },
  diffOldFile = { fg = palette.del },
  diffFile = { fg = '#61afef', bold = true }, -- "diff --git a/x b/x"
  diffLine = { fg = palette.dim }, -- "@@ -1,7 +1,9 @@"
  diffIndexLine = { fg = palette.dim },
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
      { '<leader>gu', unified_against_ref, desc = '[G]it [u]nified diff vs branch' },
      { '<leader>gU', unified_range, desc = '[G]it [U]nified diff, custom range' },
      { '<leader>gq', '<cmd>DiffviewClose<cr>', desc = '[G]it diff [q]uit' },
    },
    -- a function so `diffview.actions` can be required only once the plugin
    -- is actually on the runtimepath
    opts = function()
      local actions = require 'diffview.actions'

      -- Ergonomic navigation for a German layout: ] and [ sit behind AltGr,
      -- so hunks go on ö/Ö and files on ü/Ü. (ä is the global remap for /,
      -- b is flash, + is save -- all left alone.)
      local panel_nav = {
        { 'n', 'ü', actions.select_next_entry, { desc = 'Next file' } },
        { 'n', 'Ü', actions.select_prev_entry, { desc = 'Previous file' } },
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
      }
      -- hunk jumps only make sense in the diff windows themselves
      local view_nav = vim.list_extend({
        { 'n', 'ö', ']c', { desc = 'Next hunk' } },
        { 'n', 'Ö', '[c', { desc = 'Previous hunk' } },
      }, panel_nav)

      return {
        enhanced_diff_hl = true, -- clearer word-level highlighting
        view = {
          default = { layout = 'diff2_horizontal' }, -- old | new, side by side
          merge_tool = { layout = 'diff3_mixed' },
          file_history = { layout = 'diff2_horizontal' },
        },
        file_panel = {
          listing_style = 'tree',
          win_config = { position = 'left', width = 55 },
        },
        keymaps = {
          view = view_nav,
          file_panel = panel_nav,
          file_history_panel = panel_nav,
        },
        hooks = {
          -- Runs with the diff buffer/window current, after diffview applied
          -- its own window options -- so this remap wins.
          diff_buf_win_enter = function(bufnr, winid, ctx)
            strip_syntax(bufnr)
            vim.wo[winid].winhighlight = ctx.symbol == 'a' and winhl.old or winhl.new
          end,
        },
      }
    end,
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
