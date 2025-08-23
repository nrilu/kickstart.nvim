vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.foldmethod = 'expr'
    vim.opt_local.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.opt_local.foldtext = 'v:lua.markdown_fold_text()'

    -- Force treesitter to reparse and update folds
    vim.defer_fn(function()
      vim.cmd 'normal! zx' -- Update folds
    end, 100) -- Small delay to let treesitter finish parsing
  end,
})

local function markdown_fold_text()
  local line = vim.fn.getline(vim.v.foldstart)

  -- Extract heading text (remove # symbols)
  local title = line:match '^#+%s*(.+)'
  if title then
    return title:gsub('^%s*', ''):gsub('%s*$', '')
  end

  -- For code blocks or other content
  local first_line = line:gsub('^%s*', ''):gsub('%s*$', '')
  if first_line:match '^```' then
    local lang = first_line:match '^```(%S+)'
    return lang and (lang .. ' code block') or 'Code block'
  end

  return first_line ~= '' and first_line or 'Folded content'
end

-- Make it globally available
_G.markdown_fold_text = markdown_fold_text

-- Apply only to markdown files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.foldtext = 'v:lua.markdown_fold_text()'
  end,
})

return {}
