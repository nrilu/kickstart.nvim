-- railscasts.lua
-- Neovim port of the "Railscasts copy" CLion/IntelliJ .icls scheme,
-- tuned for C/C++ (Treesitter + clangd LSP semantic tokens).
--
-- Colors taken from Railscasts_copy.icls. The OC.* keys in that file are
-- CLion's C-family highlighter, so we mirror them onto Neovim's @lsp.* groups.
--
-- Use with:  vim.cmd.colorscheme 'railscasts'

vim.cmd 'highlight clear'
if vim.fn.exists 'syntax_on' then
  vim.cmd 'syntax reset'
end
vim.o.background = 'dark'
vim.o.termguicolors = true
vim.g.colors_name = 'railscasts'

-- Palette ------------------------------------------------------------------
local p = {
  bg = '#2b2b2b',
  fg = '#e6e1dc',
  white = '#ffffff',

  orange = '#cc7833', -- keywords, operators, storage qualifiers
  green = '#a5c261', -- strings, numbers
  comment = '#bc9458', -- comments (italic)
  yellow = '#ffc66d', -- function/method *definitions*, macros
  attr = '#e8bf6a', -- attributes, preprocessor
  blue = '#6d9cbe', -- constants, builtins, enum members
  fnblue = '#40a7d9', -- function/method *calls* (OC.FUNCTION)
  red = '#da4939', -- builtin function calls
  purple = '#d0d0ff', -- variables (local/global/this)
  param = '#ddba21', -- function parameters (OC.PARAMETER)
  field = '#2ab08c', -- struct/class members (OC.STRUCT_FIELD)
  type = '#b6d1de', -- struct/class type names (OC.STRUCT_LIKE)
  typedef = '#3c8795', -- typedefs / enums (OC.TYPEDEF)
  escape = '#519f50', -- string escape sequences

  cursorline = '#333435',
  selection = '#545c73',
  guide = '#404040',
  linenr = '#666656',
  matchbrace = '#3a6da0',
  search = '#4f4f82',
  incsearch = '#5f5f00',
  refbg = '#3c3c57', -- identifier under caret (document highlight)
  float = '#232323',
  errfg = '#ff6767',
  warnfg = '#f49810',
  warnbg = '#4a3f10',
  hint = '#80807f',
  todo = '#c7c7ff',
}

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- Editor / UI --------------------------------------------------------------
hi('Normal', { fg = p.fg, bg = p.bg })
hi('NormalNC', { fg = p.fg, bg = p.bg })
hi('NormalFloat', { fg = p.fg, bg = p.float })
hi('FloatBorder', { fg = p.guide, bg = p.float })
hi('FloatTitle', { fg = p.yellow, bg = p.float, bold = true })
hi('Cursor', { fg = p.bg, bg = p.white })
hi('lCursor', { fg = p.bg, bg = p.white })
hi('TermCursor', { fg = p.bg, bg = p.white })
hi('CursorLine', { bg = p.cursorline })
hi('CursorColumn', { bg = p.cursorline })
hi('ColorColumn', { bg = p.cursorline })
hi('CursorLineNr', { fg = p.fg, bold = true })
hi('LineNr', { fg = p.linenr })
hi('SignColumn', { bg = p.bg })
hi('FoldColumn', { fg = p.linenr, bg = p.bg })
hi('Folded', { fg = p.comment, bg = p.cursorline })
hi('Visual', { bg = p.selection })
hi('VisualNOS', { bg = p.selection })
hi('Search', { bg = p.search })
hi('CurSearch', { fg = p.bg, bg = p.incsearch })
hi('IncSearch', { fg = p.fg, bg = p.incsearch })
hi('MatchParen', { bg = p.matchbrace, bold = true })
hi('NonText', { fg = p.guide })
hi('Whitespace', { fg = p.guide })
hi('SpecialKey', { fg = p.guide })
hi('EndOfBuffer', { fg = p.bg })
hi('Conceal', { fg = p.linenr })
hi('Directory', { fg = p.blue })
hi('Title', { fg = p.yellow, bold = true })
hi('ErrorMsg', { fg = p.errfg })
hi('WarningMsg', { fg = p.warnfg })
hi('ModeMsg', { fg = p.fg })
hi('MoreMsg', { fg = p.green })
hi('Question', { fg = p.green })
hi('WinSeparator', { fg = p.guide })
hi('VertSplit', { fg = p.guide })

-- Statusline / tabline
hi('StatusLine', { fg = p.fg, bg = '#1f1f1f' })
hi('StatusLineNC', { fg = p.linenr, bg = '#1f1f1f' })
hi('TabLine', { fg = p.linenr, bg = '#1f1f1f' })
hi('TabLineSel', { fg = p.fg, bg = p.bg })
hi('TabLineFill', { bg = '#1f1f1f' })

-- Popup menu
hi('Pmenu', { fg = p.fg, bg = p.float })
hi('PmenuSel', { fg = p.white, bg = p.selection })
hi('PmenuSbar', { bg = p.float })
hi('PmenuThumb', { bg = p.selection })
hi('WildMenu', { fg = p.white, bg = p.selection })

-- Document highlight (your config calls vim.lsp.buf.document_highlight)
hi('LspReferenceText', { bg = p.refbg })
hi('LspReferenceRead', { bg = p.refbg })
hi('LspReferenceWrite', { bg = p.refbg })

-- Diagnostics
hi('DiagnosticError', { fg = p.errfg })
hi('DiagnosticWarn', { fg = p.warnfg })
hi('DiagnosticInfo', { fg = p.blue })
hi('DiagnosticHint', { fg = p.hint })
hi('DiagnosticOk', { fg = p.green })
hi('DiagnosticUnderlineError', { undercurl = true, sp = p.errfg })
hi('DiagnosticUnderlineWarn', { undercurl = true, sp = p.warnfg })
hi('DiagnosticUnderlineInfo', { undercurl = true, sp = p.blue })
hi('DiagnosticUnderlineHint', { undercurl = true, sp = p.hint })

-- Diff / git
hi('DiffAdd', { bg = '#264226' })
hi('DiffChange', { bg = '#2e2e1f' })
hi('DiffDelete', { fg = '#713f3f', bg = '#713f3f' })
hi('DiffText', { bg = '#4d5d3d' })
hi('Added', { fg = p.green })
hi('Changed', { fg = p.attr })
hi('Removed', { fg = p.red })

-- Legacy syntax groups (fallback for non-treesitter buffers) ----------------
hi('Comment', { fg = p.comment, italic = true })
hi('Constant', { fg = p.blue })
hi('String', { fg = p.green })
hi('Character', { fg = p.green })
hi('Number', { fg = p.green })
hi('Float', { fg = p.green })
hi('Boolean', { fg = p.blue })
hi('Identifier', { fg = p.fg })
hi('Function', { fg = p.yellow })
hi('Statement', { fg = p.orange })
hi('Conditional', { fg = p.orange })
hi('Repeat', { fg = p.orange })
hi('Label', { fg = p.orange })
hi('Operator', { fg = p.orange })
hi('Keyword', { fg = p.orange })
hi('Exception', { fg = p.orange })
hi('PreProc', { fg = p.attr })
hi('Include', { fg = p.orange })
hi('Define', { fg = p.yellow })
hi('Macro', { fg = p.yellow })
hi('PreCondit', { fg = p.attr })
hi('Type', { fg = p.type })
hi('StorageClass', { fg = p.orange })
hi('Structure', { fg = p.type })
hi('Typedef', { fg = p.typedef })
hi('Special', { fg = p.escape })
hi('SpecialChar', { fg = p.escape })
hi('Tag', { fg = p.attr })
hi('Delimiter', { fg = p.fg })
hi('SpecialComment', { fg = p.comment, italic = true })
hi('Debug', { fg = p.red })
hi('Underlined', { fg = p.blue, underline = true })
hi('Error', { fg = p.white, bg = '#990000' })
hi('Todo', { fg = p.todo, bg = 'NONE', bold = true })

-- Treesitter captures -------------------------------------------------------
hi('@comment', { fg = p.comment, italic = true })
hi('@comment.documentation', { fg = p.comment, italic = true })
hi('@comment.error', { fg = p.white, bg = '#990000' })
hi('@comment.warning', { fg = p.bg, bg = p.warnfg })
hi('@comment.todo', { fg = p.todo, bold = true })
hi('@comment.note', { fg = p.blue, bold = true })

hi('@keyword', { fg = p.orange })
hi('@keyword.function', { fg = p.orange })
hi('@keyword.operator', { fg = p.orange })
hi('@keyword.return', { fg = p.orange })
hi('@keyword.conditional', { fg = p.orange })
hi('@keyword.repeat', { fg = p.orange })
hi('@keyword.exception', { fg = p.orange })
hi('@keyword.import', { fg = p.orange })
hi('@keyword.directive', { fg = p.orange }) -- #include / #define / #pragma
hi('@keyword.directive.define', { fg = p.orange })
hi('@keyword.storage', { fg = p.orange }) -- static / extern / const ...
hi('@keyword.modifier', { fg = p.orange })

hi('@function', { fg = p.yellow }) -- definition name
hi('@function.call', { fg = p.fnblue }) -- call site
hi('@function.method', { fg = p.yellow })
hi('@function.method.call', { fg = p.fnblue })
hi('@function.builtin', { fg = p.red })
hi('@function.macro', { fg = p.yellow })
hi('@constructor', { fg = p.yellow })

hi('@type', { fg = p.type }) -- class / struct names
hi('@type.builtin', { fg = p.orange }) -- int, char, bool ... (keyword-colored, like CLion)
hi('@type.definition', { fg = p.typedef }) -- typedef / using
hi('@type.qualifier', { fg = p.orange }) -- const / volatile
hi('@storageclass', { fg = p.orange })
hi('@module', { fg = p.type }) -- namespaces
hi('@attribute', { fg = p.attr })
hi('@label', { fg = p.orange })

hi('@variable', { fg = p.purple })
hi('@variable.builtin', { fg = p.purple }) -- this
hi('@variable.parameter', { fg = p.param })
hi('@variable.member', { fg = p.field }) -- struct/class fields
hi('@property', { fg = p.field })
hi('@field', { fg = p.field })

hi('@constant', { fg = p.blue })
hi('@constant.builtin', { fg = p.blue }) -- nullptr, true, false
hi('@constant.macro', { fg = p.yellow })

hi('@string', { fg = p.green })
hi('@string.escape', { fg = p.escape })
hi('@string.special', { fg = p.green })
hi('@character', { fg = p.green })
hi('@character.special', { fg = p.escape })
hi('@number', { fg = p.green })
hi('@number.float', { fg = p.green })
hi('@boolean', { fg = p.blue })

hi('@operator', { fg = p.orange })
hi('@punctuation.delimiter', { fg = p.fg })
hi('@punctuation.bracket', { fg = p.fg })
hi('@punctuation.special', { fg = p.orange })
hi('@preproc', { fg = p.attr })

-- C/C++ specific treesitter tweaks
hi('@variable.member.cpp', { fg = p.field })
hi('@type.builtin.cpp', { fg = p.orange })
hi('@keyword.directive.cpp', { fg = p.orange })

-- LSP semantic tokens (clangd) ---------------------------------------------
-- These override treesitter when clangd is attached. The OC.* mapping lives
-- here: calls = blue, definitions = yellow, members = teal, params = gold.
hi('@lsp.type.keyword', { fg = p.orange })
hi('@lsp.type.comment', {})
hi('@lsp.type.string', { fg = p.green })
hi('@lsp.type.number', { fg = p.green })
hi('@lsp.type.operator', { fg = p.orange })
hi('@lsp.type.macro', { fg = p.yellow })

hi('@lsp.type.function', { fg = p.fnblue }) -- call/use by default
hi('@lsp.type.method', { fg = p.fnblue })
hi('@lsp.typemod.function.declaration', { fg = p.yellow })
hi('@lsp.typemod.function.definition', { fg = p.yellow })
hi('@lsp.typemod.method.declaration', { fg = p.yellow })
hi('@lsp.typemod.method.definition', { fg = p.yellow })

hi('@lsp.type.variable', { fg = p.purple })
hi('@lsp.type.parameter', { fg = p.param })
hi('@lsp.type.property', { fg = p.field })
hi('@lsp.type.field', { fg = p.field })
hi('@lsp.typemod.variable.globalScope', { fg = p.purple, italic = true })
hi('@lsp.typemod.variable.static', { fg = p.purple, italic = true })
hi('@lsp.typemod.variable.readonly', { fg = p.blue }) -- const locals look constant-ish

hi('@lsp.type.class', { fg = p.type })
hi('@lsp.type.struct', { fg = p.type })
hi('@lsp.type.type', { fg = p.type })
hi('@lsp.type.typeParameter', { fg = p.type })
hi('@lsp.type.namespace', { fg = p.type })
hi('@lsp.type.enum', { fg = p.typedef })
hi('@lsp.type.enumMember', { fg = p.blue })
hi('@lsp.type.concept', { fg = p.type })
hi('@lsp.type.unknown', {})
