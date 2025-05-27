local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local builtin = require 'telescope.builtin'

function OpenOldfileDirInTerminal()
  builtin.oldfiles {
    attach_mappings = function(prompt_bufnr, map)
      local function open_terminal()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        local filepath = selection.value
        local dir = vim.fn.fnamemodify(filepath, ':h')
        vim.fn.jobstart({ 'xfce4-terminal', '--working-directory', dir }, { detach = true })
      end

      -- bind Ctrl+t in BOTH insert and normal mode
      map('i', '<C-t>', open_terminal)
      map('n', '<C-t>', open_terminal)

      return true
    end,
  }
end

vim.keymap.set('n', '<leader>to', OpenOldfileDirInTerminal, { desc = 'Telescope oldfiles > xfce4-terminal' })
