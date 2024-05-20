local debug = {}

debug.flag = false

debug.enable = function()
  debug.flag = true
end

debug.disable = function()
  debug.flag = false
end

debug.name_max = function()
  local name_max = 0
  local sources = require('cmp.config').get().sources or {}
  if type(sources[1][1]) == 'table' then
    for _, group in ipairs(sources) do
      for _, src in ipairs(group) do
        name_max = math.max(name_max, #src.name)
      end
    end
  else
    for _, src in ipairs(sources) do
      name_max = math.max(name_max, #src.name)
    end
  end
  return name_max
end

---Print log
---@vararg any
debug.log = function(...)
  if debug.flag == true then
    local data = {}
    for _, v in ipairs({ ... }) do
      if not vim.tbl_contains({ 'string', 'number', 'boolean' }, type(v)) then
        v = vim.inspect(v)
      end
      table.insert(data, v)
    end
    vim.dbglog(table.concat(data, ' '))
  end
end

debug.right_align = function(name, width)
  name = name or ''
  width = width or debug.name_max()
  return name .. string.rep(' ', width - #tostring(name))
end

debug.source_summary = function()
  local kinds = { available = {}, unavailable = {}, installed = {}, invalid = {} }
  local config = require('cmp.config')
  local cmp = require('cmp')
  for _, s in pairs(cmp.core.sources) do
    if config.get_source_config(s.name) then
      if s:is_available() then
        table.insert(kinds.available, s:get_debug_name())
      else
        table.insert(kinds.unavailable, s:get_debug_name())
      end
    else
      table.insert(kinds.installed, s:get_debug_name())
    end
  end
  return kinds
end

debug.log_retrieval = function(self, res)
  if debug.flag == true then
    debug.log(debug.right_align(self:get_debug_name()), 'retrieve', debug.right_align(res, 4))
  end
end

debug.log_request = function(self, offset, completion_context)
  if debug.flag == true then
    local name = self:get_debug_name()
    local kind, char = completion_context.triggerKind, completion_context.triggerCharacter
    debug.log(
      debug.right_align(name),
      'request  ',
      debug.right_align(offset, 3),
      kind and ' kind:' .. kind or '',
      char and ' char:' .. char or ''
    )
  end
end

-- ---Get current all entries
-- cmp.get_entries = cmp.sync(function()
--   return cmp.core.view:get_entries()
-- end)
return debug
