local cmp = require('cmp')
local config = require('cmp.config')
local source = require('cmp.source')

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

    local report
    cmp.query({ context = 'main', query = 'a', timeout = 1500 }, function(r)
      report = r
    end)

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

  it('flags configured sources that are not registered', function()
    register_source('lsp', { { label = 'foo' } })
    config.set_global({ sources = { { name = 'lsp' }, { name = 'ghost' } } })

    local report
    cmp.query({ context = 'main', query = 'f', timeout = 500 }, function(r)
      report = r
    end)

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

    local report
    cmp.query({ context = 'cmdline', query = 'h', timeout = 500 }, function(r)
      report = r
    end)

    assert.are.equal('cmdline', report.context)
    assert.are.equal(':', report.sub)
    assert.are.equal(1, #report.results)
    assert.are.equal('cmd', report.results[1].name)
    assert.are.equal(1, report.results[1].count)
  end)
end)
