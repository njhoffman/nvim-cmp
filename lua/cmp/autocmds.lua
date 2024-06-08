local config = require('cmp.config')
local autocmd = require('cmp.utils.autocmd')
local async = require('cmp.utils.async')

local setup = function(cmp)
  -- In InsertEnter autocmd, vim will detects mode=normal unexpectedly.
  local on_insert_enter = function()
    if config.enabled() then
      cmp.config.compare.scopes:update()
      cmp.config.compare.locality:update()
      cmp.core:prepare()
      cmp.core:on_change('InsertEnter')
    end
  end
  autocmd.subscribe({ 'CmdlineEnter', 'InsertEnter' }, async.debounce_next_tick(on_insert_enter))

  local on_text_changed = function()
    if config.enabled() then
      cmp.core:on_change('TextChanged')
    end
  end
  autocmd.subscribe(
    { 'TextChangedI', 'TextChangedP' },
    async.debounce(on_text_changed, config.get().performance.trigger_debounce)
  )
  autocmd.subscribe('CmdlineChanged', async.debounce_next_tick(on_text_changed))

  autocmd.subscribe('CursorMovedI', function()
    if config.enabled() then
      cmp.core:on_moved()
    else
      cmp.core:reset()
      cmp.core.view:close()
    end
  end)

  -- If make this asynchronous, the completion menu will not close when the command output is displayed.
  autocmd.subscribe({ 'InsertLeave', 'CmdlineLeave', 'CmdwinEnter' }, function()
    cmp.core:reset()
    cmp.core.view:close()
  end)

  cmp.event:on('complete_done', function(evt)
    if evt.entry then
      cmp.config.compare.recently_used:add_entry(evt.entry)
    end
    cmp.config.compare.scopes:update()
    cmp.config.compare.locality:update()
  end)

  cmp.event:on('confirm_done', function(evt)
    if evt.entry then
      cmp.config.compare.recently_used:add_entry(evt.entry)
    end
  end)

  return cmp
end
return { setup = setup }
