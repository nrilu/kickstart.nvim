local colorscheme = 'gruvbox'
local ok, _ = pcall(vim.api.nvim_command, 'colorscheme ' .. colorscheme)
if not ok then
  print 'error setting colorscheme'
end
