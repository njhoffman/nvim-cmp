local core = require('cmp.core')
local source = require('cmp.source')
local autocmds = require('cmp.autocmds')
local config = require('cmp.config')
local context = require('cmp.context')
local feedkeys = require('cmp.utils.feedkeys')
local keymap = require('cmp.utils.keymap')
local misc = require('cmp.utils.misc')
local types = require('cmp.types')

local cmp = {}

cmp.core = core.new()

---Expose types
for k, v in pairs(require('cmp.types.cmp')) do
  cmp[k] = v
end
cmp.lsp = require('cmp.types.lsp')
cmp.vim = require('cmp.types.vim')

---Expose event
cmp.event = cmp.core.event

---Export mapping for special case
cmp.mapping = require('cmp.config.mapping')

---Export default config presets
cmp.config = {}
cmp.config.disable = misc.none
cmp.config.compare = require('cmp.config.compare')
cmp.config.sources = require('cmp.config.sources')
cmp.config.mapping = require('cmp.config.mapping')
cmp.config.window = require('cmp.config.window')

---Sync asynchronous process.
cmp.sync = function(callback)
  return function(...)
    cmp.core.filter:sync(1000)
    if callback then
      return callback(...)
    end
  end
end

---Suspend completion.
cmp.suspend = function()
  return cmp.core:suspend()
end

---Register completion sources
---@param name string
---@param s cmp.Source
---@return integer
cmp.register_source = function(name, s)
  local src = source.new(name, s)
  cmp.core:register_source(src)
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'CmpRegisterSource',
    data = {
      source_id = src.id,
    },
  })
  return src.id
end

---Unregister completion source
---@param id integer
cmp.unregister_source = function(id)
  cmp.core:unregister_source(id)
  local s = cmp.core:unregister_source(id)
  if s then
    vim.api.nvim_exec_autocmds('User', {
      pattern = 'CmpUnregisterSource',
      data = {
        source_id = id,
      },
    })
  end
end

---Get registered sources.
---@return cmp.Source[]
cmp.get_registered_sources = function()
  return cmp.core:get_registered_sources()
end

---Get current configuration.
---@return cmp.ConfigSchema
cmp.get_config = function()
  return require('cmp.config').get()
end

---Invoke completion manually
---@param option cmp.CompleteParams
cmp.complete = cmp.sync(function(option)
  option = option or {}
  config.set_onetime(option.config)
  cmp.core:complete(cmp.core:get_context({ reason = option.reason or cmp.ContextReason.Manual }))
  return true
end)

---Complete common string in current entries.
cmp.complete_common_string = cmp.sync(function()
  return cmp.core:complete_common_string()
end)

---Return view is visible or not.
cmp.visible = cmp.sync(function()
  return cmp.core.view:visible() or vim.fn.pumvisible() == 1
end)

---Get what number candidates are currently selected.
---If not selected, nil is returned.
cmp.get_selected_index = cmp.sync(function()
  return cmp.core.view:get_selected_index()
end)

---Get current selected entry or nil
cmp.get_selected_entry = cmp.sync(function()
  return cmp.core.view:get_selected_entry()
end)

---Get current active entry or nil
cmp.get_active_entry = cmp.sync(function()
  return cmp.core.view:get_active_entry()
end)

---Get current all entries
cmp.get_entries = cmp.sync(function()
  return cmp.core.view:get_entries()
end)

---Close current completion
cmp.close = cmp.sync(function()
  if cmp.core.view:visible() then
    local release = cmp.core:suspend()
    cmp.core.view:close()
    vim.schedule(release)
    return true
  else
    return false
  end
end)

---Abort current completion
cmp.abort = cmp.sync(function()
  if cmp.core.view:visible() then
    local release = cmp.core:suspend()
    cmp.core.view:abort()
    cmp.core:reset()
    vim.schedule(release)
    return true
  else
    return false
  end
end)

---Select next item if possible
cmp.select_next_item = cmp.sync(function(option)
  option = option or {}
  option.behavior = option.behavior or cmp.SelectBehavior.Insert
  option.count = option.count or 1

  if cmp.core.view:visible() then
    local release = cmp.core:suspend()
    cmp.core.view:select_next_item(option)
    vim.schedule(release)
    return true
  elseif vim.fn.pumvisible() == 1 then
    if option.behavior == cmp.SelectBehavior.Insert then
      feedkeys.call(keymap.t(string.rep('<C-n>', option.count)), 'in')
    else
      feedkeys.call(keymap.t(string.rep('<Down>', option.count)), 'in')
    end
    return true
  end
  return false
end)

---Select prev item if possible
cmp.select_prev_item = cmp.sync(function(option)
  option = option or {}
  option.behavior = option.behavior or cmp.SelectBehavior.Insert
  option.count = option.count or 1

  if cmp.core.view:visible() then
    local release = cmp.core:suspend()
    cmp.core.view:select_prev_item(option)
    vim.schedule(release)
    return true
  elseif vim.fn.pumvisible() == 1 then
    if option.behavior == cmp.SelectBehavior.Insert then
      feedkeys.call(keymap.t(string.rep('<C-p>', option.count)), 'in')
    else
      feedkeys.call(keymap.t(string.rep('<Up>', option.count)), 'in')
    end
    return true
  end
  return false
end)

---Scrolling documentation window if possible
cmp.scroll_docs = cmp.sync(function(delta)
  if cmp.core.view.docs_view:visible() then
    cmp.core.view:scroll_docs(delta)
    return true
  else
    return false
  end
end)

---Whether the documentation window is visible or not.
cmp.visible_docs = cmp.sync(function()
  return cmp.core.view.docs_view:visible()
end)

---Opens the documentation window.
cmp.open_docs = cmp.sync(function()
  if not cmp.visible_docs() then
    cmp.core.view:open_docs()
    return true
  else
    return false
  end
end)

---Closes the documentation window.
cmp.close_docs = cmp.sync(function()
  if cmp.visible_docs() then
    cmp.core.view:close_docs()
    return true
  else
    return false
  end
end)

---Confirm completion
cmp.confirm = cmp.sync(function(option, callback)
  option = option or {}
  option.select = option.select or false
  option.behavior = option.behavior or cmp.get_config().confirmation.default_behavior or cmp.ConfirmBehavior.Insert
  callback = callback or function() end

  if cmp.core.view:visible() then
    local e = cmp.core.view:get_selected_entry()
    if not e and option.select then
      e = cmp.core.view:get_first_entry()
    end
    if e then
      cmp.core:confirm(e, {
        behavior = option.behavior,
      }, function()
        callback()
        cmp.core:complete(cmp.core:get_context({ reason = cmp.ContextReason.TriggerOnly }))
      end)
      return true
    end
  elseif vim.fn.pumvisible() == 1 then
    local index = vim.fn.complete_info({ 'selected' }).selected
    if index == -1 and option.select then
      index = 0
    end
    if index ~= -1 then
      vim.api.nvim_select_popupmenu_item(index, true, true, {})
      return true
    end
  end
  return false
end)

---Build status buckets per scope for the given context.
---For `main`, returns one scope (the active insert-mode config) with the same
---buckets the original `cmp.status` produced. For `cmdline` / `filetype`,
---returns one scope per registered cmdtype / filetype, listing its configured
---sources and flagging any that aren't registered.
---@param context 'main'|'cmdline'|'filetype'|nil
---@return { label: string, available: string[], unavailable: string[], installed: string[], invalid: string[] }[]
cmp.gather_status = function(scope)
  scope = scope or 'main'

  local registered_by_name = {}
  for _, s in pairs(cmp.core.sources) do
    registered_by_name[s.name] = s
  end

  -- Walk a source list in priority order (groups first, then position within
  -- a group) and drop each entry into available / unavailable / invalid with
  -- a "name G.O" label, where G = group_index and O = the source's position
  -- inside that group. Sources without group_index default to group 1.
  -- check_availability is only used for the main context, where is_available()
  -- runs against the live config; cmdline / filetype configs aren't the live
  -- one when status is invoked outside that mode, so we just bucket as
  -- available if the source is registered.
  local function bucket_sources(entry, sources_list, check_availability)
    local group_positions = {}
    for _, src_config in ipairs(sources_list) do
      local g = src_config.group_index or 1
      group_positions[g] = (group_positions[g] or 0) + 1
      local o = group_positions[g]
      local s = registered_by_name[src_config.name]
      if s then
        local label = ('%s %d.%d'):format(s:get_debug_name(), g, o)
        if check_availability and not s:is_available() then
          table.insert(entry.unavailable, label)
        else
          table.insert(entry.available, label)
        end
      else
        table.insert(entry.invalid, src_config.name)
      end
    end
  end

  local scopes = {}

  if scope == 'main' then
    -- Sources referenced only in non-main contexts (cmdline / filetype /
    -- buffer) are owned by those scopes; surface them under their own
    -- :CmpStatus subcommand instead of cluttering main's "unused" bucket.
    local referenced_elsewhere = {}
    for _, c in pairs(config.cmdline) do
      for _, src in ipairs(c.sources or {}) do
        referenced_elsewhere[src.name] = true
      end
    end
    for _, c in pairs(config.filetypes) do
      for _, src in ipairs(c.sources or {}) do
        referenced_elsewhere[src.name] = true
      end
    end
    for _, c in pairs(config.buffers) do
      for _, src in ipairs(c.sources or {}) do
        referenced_elsewhere[src.name] = true
      end
    end

    local entry = { label = 'main', available = {}, unavailable = {}, installed = {}, invalid = {} }
    local main_sources = config.get().sources or {}

    bucket_sources(entry, main_sources, true)

    local in_main = {}
    for _, src_config in ipairs(main_sources) do
      in_main[src_config.name] = true
    end
    for _, s in pairs(cmp.core.sources) do
      if not in_main[s.name] and not referenced_elsewhere[s.name] then
        table.insert(entry.installed, s:get_debug_name())
      end
    end

    table.insert(scopes, entry)
  elseif scope == 'cmdline' or scope == 'filetype' then
    local table_ref = scope == 'cmdline' and config.cmdline or config.filetypes
    local label_fmt = scope == 'cmdline' and 'cmdline `%s`' or 'filetype `%s`'
    local keys = vim.tbl_keys(table_ref)
    table.sort(keys)
    for _, key in ipairs(keys) do
      local c = table_ref[key]
      local entry = { label = label_fmt:format(key), available = {}, unavailable = {}, installed = {}, invalid = {} }
      bucket_sources(entry, c.sources or {}, false)
      table.insert(scopes, entry)
    end
  else
    error(('cmp.status: unknown context `%s` (expected main|cmdline|filetype)'):format(tostring(scope)))
  end

  return scopes
end

---Show status
---@param scope 'main'|'cmdline'|'filetype'|nil
cmp.status = function(scope)
  local scopes = cmp.gather_status(scope)

  if #scopes == 0 then
    vim.api.nvim_echo({ { '\n', 'Normal' }, { ('# no %s configurations registered\n'):format(scope or 'main'), 'Comment' } }, false, {})
    return
  end

  for _, sc in ipairs(scopes) do
    if sc.label ~= 'main' then
      vim.api.nvim_echo({ { '\n', 'Normal' }, { ('## %s\n'):format(sc.label), 'Title' } }, false, {})
    end

    if #sc.available > 0 then
      vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
      vim.api.nvim_echo({ { '# ready source names\n', 'Special' } }, false, {})
      for _, name in ipairs(sc.available) do
        vim.api.nvim_echo({ { ('- %s\n'):format(name), 'Normal' } }, false, {})
      end
    end

    if #sc.unavailable > 0 then
      vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
      vim.api.nvim_echo({ { '# unavailable source names\n', 'Comment' } }, false, {})
      for _, name in ipairs(sc.unavailable) do
        vim.api.nvim_echo({ { ('- %s\n'):format(name), 'Normal' } }, false, {})
      end
    end

    if #sc.installed > 0 then
      vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
      vim.api.nvim_echo({ { '# unused source names\n', 'WarningMsg' } }, false, {})
      for _, name in ipairs(sc.installed) do
        vim.api.nvim_echo({ { ('- %s\n'):format(name), 'Normal' } }, false, {})
      end
    end

    if #sc.invalid > 0 then
      vim.api.nvim_echo({ { '\n', 'Normal' } }, false, {})
      vim.api.nvim_echo({ { '# unknown source names\n', 'ErrorMsg' } }, false, {})
      for _, name in ipairs(sc.invalid) do
        vim.api.nvim_echo({ { ('- %s\n'):format(name), 'Normal' } }, false, {})
      end
    end
  end
end

---Resolve the source list for a query context.
---@param ctx 'main'|'cmdline'|'filetype'
---@param sub string|nil cmdtype (for cmdline) or filetype (for filetype context)
---@return table[] sources_list, string|nil resolved_sub
local function resolve_query_sources(ctx, sub)
  if ctx == 'main' then
    return config.global.sources or {}, nil
  elseif ctx == 'cmdline' then
    sub = sub or ':'
    local cfg = config.cmdline[sub]
    if not cfg then
      local keys = vim.tbl_keys(config.cmdline)
      table.sort(keys)
      sub = keys[1]
      cfg = sub and config.cmdline[sub] or nil
    end
    return cfg and (cfg.sources or {}) or {}, sub
  elseif ctx == 'filetype' then
    sub = sub or vim.bo[0].filetype
    local cfg = config.filetypes[sub]
    return cfg and (cfg.sources or {}) or {}, sub
  end
  error(('cmp.query: unknown context `%s`'):format(tostring(ctx)))
end

---Build a synthetic cmp.Context for a query string. The context reports
---reason = Manual so source.complete always emits an Invoked completion
---request, regardless of trigger characters / keyword length.
---@param query string
---@param filetype string
---@return cmp.Context
local function build_query_context(query, filetype)
  local ctx = setmetatable({}, { __index = context })
  ctx.id = misc.id('cmp.query.context')
  ctx.cache = require('cmp.utils.cache').new()
  ctx.prev_context = context.empty()
  ctx.option = { reason = types.cmp.ContextReason.Manual }
  ctx.filetype = filetype or vim.bo[0].filetype
  ctx.time = vim.uv.now()
  ctx.bufnr = vim.api.nvim_get_current_buf()
  ctx.cursor_line = query
  ctx.cursor = {
    row = 1,
    col = #query + 1,
    line = 0,
  }
  ctx.cursor.character = misc.to_utfindex(query, ctx.cursor.col)
  ctx.cursor_before_line = query
  ctx.cursor_after_line = ''
  ctx.aborted = false
  return ctx
end

local STATUS_LABELS = {
  [source.SourceStatus.WAITING] = 'WAITING',
  [source.SourceStatus.FETCHING] = 'FETCHING',
  [source.SourceStatus.COMPLETED] = 'COMPLETED',
}

local TRIGGER_LABELS = {
  [1] = 'Invoked',
  [2] = 'TriggerCharacter',
  [3] = 'TriggerForIncompleteCompletions',
}

---Run each configured source against `query` in the requested context and
---collect timing + result data. The callback fires once all sources have
---responded or `opts.timeout` (default 2000ms) elapses.
---@param opts { context: 'main'|'cmdline'|'filetype', query: string, sub?: string, timeout?: integer, filetype?: string }
---@param callback fun(report: cmp.QueryReport)
cmp.query = function(opts, callback)
  opts = opts or {}
  local ctx_name = opts.context or 'main'
  local query = opts.query or ''
  local timeout = opts.timeout or 2000

  local sources_list, resolved_sub = resolve_query_sources(ctx_name, opts.sub)
  local filetype = opts.filetype
  if ctx_name == 'filetype' then
    filetype = filetype or resolved_sub
  end

  local registered_by_name = {}
  for _, s in pairs(cmp.core.sources) do
    registered_by_name[s.name] = s
  end

  local ctx = build_query_context(query, filetype)

  local results = {}
  local pending = 0
  local start = vim.uv.now()

  for _, src_config in ipairs(sources_list) do
    local g = src_config.group_index or 1
    local entry_result = {
      name = src_config.name,
      group_index = g,
      label = nil,
      registered = false,
      status = 'NOT_REGISTERED',
      trigger = nil,
      trigger_character = nil,
      offset = nil,
      keyword = nil,
      time_ms = 0,
      count = 0,
      items = {},
      error = nil,
    }
    local s = registered_by_name[src_config.name]
    if not s then
      entry_result.error = 'not registered'
      table.insert(results, entry_result)
    else
      entry_result.registered = true
      pending = pending + 1
      local s_start = vim.uv.now()
      local triggered_ok, triggered_err = pcall(function()
        s:reset()
        return s:complete(ctx, function()
          entry_result.time_ms = vim.uv.now() - s_start
          entry_result.status = STATUS_LABELS[s.status] or 'UNKNOWN'
          entry_result.offset = s.offset
          entry_result.keyword = string.sub(query, s.offset or 1)
          if s.completion_context then
            entry_result.trigger = TRIGGER_LABELS[s.completion_context.triggerKind]
            entry_result.trigger_character = s.completion_context.triggerCharacter
          end
          entry_result.items = vim.tbl_map(function(e)
            local item = e.completion_item or {}
            return {
              label = item.label,
              filter_text = item.filterText,
              insert_text = item.insertText,
              detail = item.detail,
              kind = item.kind,
              documentation = type(item.documentation) == 'table' and item.documentation.value or item.documentation,
            }
          end, s.entries or {})
          entry_result.count = #entry_result.items
          pending = pending - 1
        end)
      end)
      if not triggered_ok then
        entry_result.error = tostring(triggered_err)
        entry_result.status = 'ERROR'
        pending = pending - 1
      elseif triggered_err == nil then
        -- s:complete returned without invoking the source (no callback will fire).
        entry_result.status = 'NOT_TRIGGERED'
        entry_result.error = 'completion not triggered'
        pending = pending - 1
      end
      table.insert(results, entry_result)
    end
  end

  -- Wait for sources to respond or for the timeout.
  vim.wait(timeout, function()
    return pending == 0
  end, 25)

  local total_time = vim.uv.now() - start
  local total_count = 0
  for _, r in ipairs(results) do
    total_count = total_count + r.count
  end

  callback({
    context = ctx_name,
    sub = resolved_sub,
    query = query,
    total_time_ms = total_time,
    total_count = total_count,
    timed_out = pending > 0,
    pending = pending,
    results = results,
  })
end

---@type cmp.Setup
cmp.setup = setmetatable({
  global = function(c)
    config.set_global(c)
  end,
  filetype = function(filetype, c)
    config.set_filetype(c, filetype)
  end,
  buffer = function(c)
    config.set_buffer(c, vim.api.nvim_get_current_buf())
  end,
  cmdline = function(type, c)
    config.set_cmdline(c, type)
  end,
}, {
  __call = function(self, c)
    self.global(c)
    autocmds.setup(cmp)
  end,
})

return cmp
