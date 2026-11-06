local cmp = require('cmp')
local config = require('cmp.config')
local source = require('cmp.source')
local spec = require('cmp.utils.spec')

describe('cmp.setup', function()
  it('subscribes autocmds on load, once', function()
    local autocmd = require('cmp.utils.autocmd')
    local before = #autocmd.events.CursorMovedI
    assert.is.truthy(before > 0)
    cmp.setup({})
    cmp.setup({})
    assert.are.equal(before, #autocmd.events.CursorMovedI)
  end)

  it('does not stack event handlers', function()
    local before = #cmp.event.events.confirm_done
    cmp.setup({})
    assert.are.equal(before, #cmp.event.events.confirm_done)
  end)
end)

describe('text changes', function()
  local autocmd = require('cmp.utils.autocmd')
  local enabled, on_change
  local calls

  before_each(function()
    enabled, on_change = config.enabled, cmp.core.on_change
    config.enabled = function()
      return true
    end
    calls = 0
    cmp.core.on_change = function()
      calls = calls + 1
    end
    config.set_global({ performance = { trigger_debounce = 0 } })
  end)

  after_each(function()
    config.enabled, cmp.core.on_change = enabled, on_change
    config.global = require('cmp.config.default')()
    config.cache:clear()
  end)

  ---Emit TextChangedI and return whether it reached cmp.core.on_change.
  local changed = function()
    calls = 0
    autocmd.emit('TextChangedI')
    vim.wait(50, function()
      return calls > 0
    end, 2)
    return calls > 0
  end

  it('does not update completion when lines were removed', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
    changed()
    vim.api.nvim_buf_set_lines(0, 2, 3, false, {})
    assert.is_false(changed())
  end)

  it('updates completion for edits, added lines and the next change after a removal', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
    changed()
    vim.api.nvim_buf_set_lines(0, 2, 3, false, {})
    changed()

    vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'one more' })
    assert.is_true(changed())
    vim.api.nvim_buf_set_lines(0, 2, 2, false, { 'pasted' })
    assert.is_true(changed())
  end)

  it('does not compare line counts across buffers', function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three' })
    changed()
    vim.cmd('enew!')
    assert.is_true(changed())
  end)
end)

describe('cmp.resubscribe', function()
  it('makes cmp the last receiver of the event', function()
    local group = vim.api.nvim_create_augroup('cmp_resubscribe_spec', { clear = true })
    vim.api.nvim_create_autocmd('TextChangedI', { group = group, callback = function() end })

    local last_group = function()
      local found = vim.api.nvim_get_autocmds({ event = 'TextChangedI' })
      return found[#found].group
    end
    assert.are.equal(group, last_group())

    local autocmd = require('cmp.utils.autocmd')
    local subscribers = #autocmd.events.TextChangedI
    cmp.resubscribe({ 'TextChangedI' })
    assert.are.equal(autocmd.group, last_group())
    assert.are.equal(subscribers, #autocmd.events.TextChangedI)

    vim.api.nvim_del_augroup_by_id(group)
  end)

  it('ignores events cmp does not subscribe to', function()
    local before = #vim.api.nvim_get_autocmds({ group = require('cmp.utils.autocmd').group, event = 'BufWritePost' })
    cmp.resubscribe({ 'BufWritePost' })
    assert.are.equal(before, #vim.api.nvim_get_autocmds({ group = require('cmp.utils.autocmd').group, event = 'BufWritePost' }))
  end)
end)

describe('cmp.gather_status', function()
  before_each(function()
    config.global = require('cmp.config.default')()
    config.cmdline = {}
    config.filetypes = {}
    config.buffers = {}
    config.onetime = {}
    config.cache:clear()

    cmp.core.sources = {}
    for _, name in ipairs({ 'lsp', 'buffer', 'cmdline_only', 'lua_only' }) do
      local s = source.new(name, { complete = function() end })
      cmp.core.sources[s.id] = s
    end
  end)

  after_each(function()
    cmp.core.sources = {}
    config.global = require('cmp.config.default')()
    config.cmdline = {}
    config.filetypes = {}
    config.cache:clear()
  end)

  it('main scope reflects the active config sources', function()
    config.set_global({ sources = { { name = 'lsp' }, { name = 'ghost' } } })

    local scopes = cmp.gather_status('main')
    assert.are.equal(1, #scopes)

    local main = scopes[1]
    assert.are.equal('main', main.label)

    assert.is_true(vim.tbl_contains(main.available, 'lsp 1.1'))
    assert.is_true(vim.tbl_contains(main.installed, 'buffer'))
    assert.is_true(vim.tbl_contains(main.invalid, 'ghost'))
  end)

  it('main scope hides sources that are only configured for cmdline/filetype/buffer', function()
    config.set_global({ sources = { { name = 'lsp' } } })
    config.set_cmdline({ sources = { { name = 'cmdline_only' } } }, ':')
    config.set_filetype({ sources = { { name = 'lua_only' } } }, 'lua')

    local main = cmp.gather_status('main')[1]

    assert.is_true(vim.tbl_contains(main.available, 'lsp 1.1'))
    assert.is_false(vim.tbl_contains(main.installed, 'cmdline_only'))
    assert.is_false(vim.tbl_contains(main.installed, 'lua_only'))
    -- `buffer` is registered but not referenced anywhere, so it stays in `installed`.
    assert.is_true(vim.tbl_contains(main.installed, 'buffer'))
  end)

  it('main available bucket is sorted by group and labelled with group.order', function()
    -- Mirror cmp.config.sources(group1, group2): group_index tags + flat list.
    config.set_global({
      sources = {
        { name = 'lsp', group_index = 1 },
        { name = 'lua_only', group_index = 2 },
        { name = 'buffer', group_index = 2 },
        { name = 'cmdline_only', group_index = 2 },
      },
    })

    local main = cmp.gather_status('main')[1]

    assert.are.same({
      'lsp 1.1',
      'lua_only 2.1',
      'buffer 2.2',
      'cmdline_only 2.3',
    }, main.available)
  end)

  it('cmdline scope only shows sources for cmdtypes', function()
    config.set_cmdline({ sources = { { name = 'cmdline_only' }, { name = 'missing_cmd' } } }, ':')
    config.set_cmdline({ sources = { { name = 'buffer' } } }, '/')

    local scopes = cmp.gather_status('cmdline')
    assert.are.equal(2, #scopes)

    local by_label = {}
    for _, s in ipairs(scopes) do
      by_label[s.label] = s
    end

    local colon = by_label['cmdline `:`']
    assert.is_not_nil(colon)
    assert.is_true(vim.tbl_contains(colon.available, 'cmdline_only 1.1'))
    assert.is_true(vim.tbl_contains(colon.invalid, 'missing_cmd'))
    assert.is_false(vim.tbl_contains(colon.available, 'lsp 1.1'))

    local search = by_label['cmdline `/`']
    assert.is_not_nil(search)
    assert.is_true(vim.tbl_contains(search.available, 'buffer 1.1'))
    assert.are.equal(0, #search.invalid)
  end)

  it('filetype scope only shows sources for that filetype', function()
    config.set_filetype({ sources = { { name = 'lua_only' } } }, 'lua')
    config.set_filetype({ sources = { { name = 'lsp' }, { name = 'ghost' } } }, { 'rust' })

    local scopes = cmp.gather_status('filetype')
    assert.are.equal(2, #scopes)

    local by_label = {}
    for _, s in ipairs(scopes) do
      by_label[s.label] = s
    end

    local lua = by_label['filetype `lua`']
    assert.is_not_nil(lua)
    assert.is_true(vim.tbl_contains(lua.available, 'lua_only 1.1'))
    assert.is_false(vim.tbl_contains(lua.available, 'lsp 1.1'))

    local rust = by_label['filetype `rust`']
    assert.is_not_nil(rust)
    assert.is_true(vim.tbl_contains(rust.available, 'lsp 1.1'))
    assert.is_true(vim.tbl_contains(rust.invalid, 'ghost'))
  end)

  it('returns no scopes when context has no configured contexts', function()
    assert.are.equal(0, #cmp.gather_status('cmdline'))
    assert.are.equal(0, #cmp.gather_status('filetype'))
  end)

  it('rejects unknown contexts', function()
    assert.has_error(function()
      cmp.gather_status('bogus')
    end)
  end)
end)

describe('cmp.query', function()
  before_each(function()
    config.global = require('cmp.config.default')()
    config.cmdline = {}
    config.filetypes = {}
    config.buffers = {}
    config.onetime = {}
    config.cache:clear()
    cmp.core.sources = {}
  end)

  after_each(function()
    cmp.core.sources = {}
    config.global = require('cmp.config.default')()
    config.cmdline = {}
    config.filetypes = {}
    config.cache:clear()
  end)

  ---Run cmp.query and wait for its report.
  local function query(opts)
    local report
    cmp.query(opts, function(r)
      report = r
    end)
    vim.wait(opts.timeout + 200, function()
      return report ~= nil
    end, 5)
    return report
  end

  ---Register a fake source that synchronously returns the given items.
  local function register_source(name, items)
    local s = source.new(name, {
      complete = function(_, _, callback)
        callback(items)
      end,
    })
    cmp.core.sources[s.id] = s
    return s
  end

  it('returns one result per configured source with timing and counts', function()
    register_source('fast', {
      { label = 'apple', kind = 1 },
      { label = 'apricot', kind = 1 },
    })
    register_source('slow', {
      { label = 'avocado', kind = 6 },
    })

    config.set_global({
      sources = {
        { name = 'fast', group_index = 1 },
        { name = 'slow', group_index = 2 },
      },
    })

    local report = query({ context = 'main', query = 'a', timeout = 1500 })

    assert.is_not_nil(report)
    assert.are.equal('main', report.context)
    assert.are.equal('a', report.query)
    assert.are.equal(2, #report.results)
    assert.is_false(report.timed_out)

    local by_name = {}
    for _, r in ipairs(report.results) do
      by_name[r.name] = r
    end

    assert.is_true(by_name.fast.registered)
    assert.are.equal(2, by_name.fast.count)
    assert.are.equal('apple', by_name.fast.items[1].label)
    assert.are.equal('Invoked', by_name.fast.trigger)
    assert.are.equal('COMPLETED', by_name.fast.status)

    assert.is_true(by_name.slow.registered)
    assert.are.equal(1, by_name.slow.count)
    assert.are.equal(2, by_name.slow.group_index)

    assert.are.equal(3, report.total_count)
    assert.is_true(report.total_time_ms >= 0)
  end)

  it('does not change the state of registered sources', function()
    spec.before()
    local calls = 0
    local live = source.new('live', {
      complete = function(_, _, callback)
        calls = calls + 1
        callback({ { label = 'prior_item' } })
      end,
    })
    cmp.core.sources[live.id] = live
    config.set_global({ sources = { { name = 'live' } } })

    local revision = live.revision
    local report = query({ context = 'main', query = 'pri', timeout = 500 })

    assert.are.equal(1, report.results[1].count)
    assert.are.equal(1, calls)
    assert.are.equal(source.SourceStatus.WAITING, live.status)
    assert.are.equal(0, #live.entries)
    assert.are.equal(-1, live.request_offset)
    assert.are.equal(revision, live.revision)

    -- A real completion at the same offset still reaches the source.
    assert.is.truthy(live:complete(spec.state('', 1, 1).input('x'), function() end))
    assert.are.equal(2, calls)
  end)

  it('keeps the entries of a menu that is already open', function()
    local live = source.new('live', {
      complete = function(_, _, callback)
        callback({ { label = 'query_item' } })
      end,
    })
    cmp.core.sources[live.id] = live
    config.set_global({ sources = { { name = 'live' } } })
    local shown = { 'shown' }
    live.entries = shown

    query({ context = 'main', query = 'q', timeout = 500 })

    assert.are.equal(shown, live.entries)
  end)

  it('uses the active config for main', function()
    register_source('global_only', { { label = 'g' } })
    register_source('buffer_only', { { label = 'b' } })
    config.set_global({ sources = { { name = 'global_only' } } })
    config.set_buffer({ sources = { { name = 'buffer_only' } } }, vim.api.nvim_get_current_buf())

    local report = query({ context = 'main', query = 'b', timeout = 500 })
    config.buffers = {}
    config.cache:clear()

    assert.are.equal(1, #report.results)
    assert.are.equal('buffer_only', report.results[1].name)
  end)

  it('does not block and reports a timeout when a source never responds', function()
    local s = source.new('silent', { complete = function() end })
    cmp.core.sources[s.id] = s
    config.set_global({ sources = { { name = 'silent' } } })

    local report
    cmp.query({ context = 'main', query = 'a', timeout = 50 }, function(r)
      report = r
    end)
    assert.is_nil(report)

    vim.wait(500, function()
      return report ~= nil
    end, 5)
    assert.is_true(report.timed_out)
    assert.are.equal(1, report.pending)
  end)

  it('queries the requested cmdtype', function()
    register_source('search', { { label = 'help' } })
    register_source('cmd', { { label = 'help' } })
    config.set_cmdline({ sources = { { name = 'cmd' } } }, ':')
    config.set_cmdline({ sources = { { name = 'search' } } }, '/')

    local report = query({ context = 'cmdline', sub = '/', query = 'h', timeout = 500 })

    assert.are.equal('/', report.sub)
    assert.are.equal('search', report.results[1].name)
  end)

  it('flags configured sources that are not registered', function()
    register_source('lsp', { { label = 'foo' } })
    config.set_global({ sources = { { name = 'lsp' }, { name = 'ghost' } } })

    local report = query({ context = 'main', query = 'f', timeout = 500 })

    local by_name = {}
    for _, r in ipairs(report.results) do
      by_name[r.name] = r
    end

    assert.is_true(by_name.lsp.registered)
    assert.is_false(by_name.ghost.registered)
    assert.are.equal('NOT_REGISTERED', by_name.ghost.status)
    assert.are.equal('not registered', by_name.ghost.error)
  end)

  it('queries a configured cmdtype when context = cmdline', function()
    register_source('cmd', { { label = 'help' } })
    config.set_cmdline({ sources = { { name = 'cmd' } } }, ':')

    local report = query({ context = 'cmdline', query = 'h', timeout = 500 })

    assert.are.equal('cmdline', report.context)
    assert.are.equal(':', report.sub)
    assert.are.equal(1, #report.results)
    assert.are.equal('cmd', report.results[1].name)
    assert.are.equal(1, report.results[1].count)
  end)
end)
