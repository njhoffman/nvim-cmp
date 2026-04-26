if vim.g.loaded_cmp then
  return
end
vim.g.loaded_cmp = true

if not vim.api.nvim_create_autocmd then
  return print('[nvim-cmp] Your nvim does not has `nvim_create_autocmd` function. Please update to latest nvim.')
end

local api = require('cmp.utils.api')
local types = require('cmp.types')
local highlight = require('cmp.utils.highlight')
local autocmd = require('cmp.utils.autocmd')

vim.api.nvim_set_hl(0, 'CmpItemAbbr', { link = 'CmpItemAbbrDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemAbbrDeprecated', { link = 'CmpItemAbbrDeprecatedDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemAbbrMatch', { link = 'CmpItemAbbrMatchDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemAbbrMatchFuzzy', { link = 'CmpItemAbbrMatchFuzzyDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemKind', { link = 'CmpItemKindDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemKindIcon', { link = 'CmpItemKindIconDefault', default = true })
vim.api.nvim_set_hl(0, 'CmpItemMenu', { link = 'CmpItemMenuDefault', default = true })
for kind in pairs(types.lsp.CompletionItemKind) do
  if type(kind) == 'string' then
    local name = ('CmpItemKind%s'):format(kind)
    local icon_hl = name .. "Icon"
    vim.api.nvim_set_hl(0, name, { link = ('%sDefault'):format(name), default = true })
    vim.api.nvim_set_hl(0, icon_hl, { link = ('%sDefault'):format(icon_hl), default = true })
  end
end

autocmd.subscribe({'ColorScheme', 'UIEnter'},  function()
  highlight.inherit('CmpItemAbbrDefault', 'Pmenu', { bg = 'NONE', default = false })
  highlight.inherit('CmpItemAbbrDeprecatedDefault', 'Comment', { bg = 'NONE', default = false })
  highlight.inherit('CmpItemAbbrMatchDefault', 'Pmenu', { bg = 'NONE', default = false })
  highlight.inherit('CmpItemAbbrMatchFuzzyDefault', 'Pmenu', { bg = 'NONE', default = false })
  highlight.inherit('CmpItemKindDefault', 'Special', { bg = 'NONE', default = false })
  highlight.inherit('CmpItemKindIconDefault', 'Special', {bg = 'NONE', default = false })
  highlight.inherit('CmpItemMenuDefault', 'Pmenu', { bg = 'NONE', default = false })
  for name in pairs(types.lsp.CompletionItemKind) do
    if type(name) == 'string' then
      vim.api.nvim_set_hl(0, ('CmpItemKind%sDefault'):format(name), { link = 'CmpItemKind', default = false })
      vim.api.nvim_set_hl(0, ('CmpItemKind%sIconDefault'):format(name), {link = 'CmpItemKindIcon', default = false })
    end
  end
end)
autocmd.emit('ColorScheme')

if vim.on_key then
  local control_c_termcode = vim.api.nvim_replace_termcodes('<C-c>', true, true, true)
  vim.on_key(function(keys)
    if keys == control_c_termcode then
      vim.schedule(function()
        if not api.is_suitable_mode() then
          autocmd.emit('InsertLeave')
        end
      end)
    end
  end, vim.api.nvim_create_namespace('cmp.plugin'))
end

local cmp_status_contexts = { 'main', 'cmdline', 'filetype' }
vim.api.nvim_create_user_command('CmpStatus', function(opts)
  local context = opts.args ~= '' and opts.args or 'main'
  if not vim.tbl_contains(cmp_status_contexts, context) then
    vim.notify(("CmpStatus: unknown subcommand `%s` (expected main|cmdline|filetype)"):format(context), vim.log.levels.ERROR)
    return
  end
  require('cmp').status(context)
end, {
  desc = 'Check status of cmp sources for a context (main|cmdline|filetype)',
  nargs = '?',
  complete = function()
    return cmp_status_contexts
  end,
})

vim.api.nvim_create_user_command('CmpQuery', function(opts)
  local args = opts.fargs
  if #args < 2 then
    vim.notify('CmpQuery: usage `:CmpQuery <main|cmdline|filetype> <query...>`', vim.log.levels.ERROR)
    return
  end
  local context = args[1]
  if not vim.tbl_contains(cmp_status_contexts, context) then
    vim.notify(("CmpQuery: unknown context `%s` (expected main|cmdline|filetype)"):format(context), vim.log.levels.ERROR)
    return
  end
  local query = table.concat(vim.list_slice(args, 2), ' ')
  require('cmp').query({ context = context, query = query }, function(report)
    require('cmp.view.query_view').open(report)
  end)
end, {
  desc = 'Probe cmp sources with a query string and show timing/result data',
  nargs = '+',
  complete = function(arg_lead, cmd_line)
    -- Complete the first arg only.
    local before = cmd_line:sub(1, -#arg_lead - 1)
    local _, n = before:gsub('%s+', ' ')
    if n <= 1 then
      local out = {}
      for _, c in ipairs(cmp_status_contexts) do
        if c:sub(1, #arg_lead) == arg_lead then
          table.insert(out, c)
        end
      end
      return out
    end
    return {}
  end,
})

local function refresh_debug_command()
  local debug = require('cmp.utils.debug')
  pcall(vim.api.nvim_del_user_command, 'CmpDebugOn')
  pcall(vim.api.nvim_del_user_command, 'CmpDebugOff')
  if debug.flag then
    vim.api.nvim_create_user_command('CmpDebugOff', function()
      debug.disable()
      refresh_debug_command()
    end, { desc = 'Disable cmp debug logging' })
  else
    vim.api.nvim_create_user_command('CmpDebugOn', function()
      debug.enable()
      refresh_debug_command()
    end, { desc = 'Enable cmp debug logging' })
  end
end
refresh_debug_command()

vim.cmd([[doautocmd <nomodeline> User CmpReady]])
