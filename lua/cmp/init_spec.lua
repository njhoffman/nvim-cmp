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

    assert.is_true(vim.tbl_contains(main.available, 'lsp'))
    assert.is_true(vim.tbl_contains(main.installed, 'buffer'))
    assert.is_true(vim.tbl_contains(main.invalid, 'ghost'))
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
    assert.is_true(vim.tbl_contains(colon.available, 'cmdline_only'))
    assert.is_true(vim.tbl_contains(colon.invalid, 'missing_cmd'))
    assert.is_false(vim.tbl_contains(colon.available, 'lsp'))

    local search = by_label['cmdline `/`']
    assert.is_not_nil(search)
    assert.is_true(vim.tbl_contains(search.available, 'buffer'))
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
    assert.is_true(vim.tbl_contains(lua.available, 'lua_only'))
    assert.is_false(vim.tbl_contains(lua.available, 'lsp'))

    local rust = by_label['filetype `rust`']
    assert.is_not_nil(rust)
    assert.is_true(vim.tbl_contains(rust.available, 'lsp'))
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
