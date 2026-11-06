local types = require('cmp.types')

local compare = require('cmp.config.compare')

describe('config.compare', function()
  local entry = function(fields)
    return vim.tbl_extend('keep', fields, {
      completion_item = fields.completion_item or {},
      get_kind = function()
        return fields.kind
      end,
      get_offset = function()
        return fields.offset or 1
      end,
    })
  end

  it('offset prefers the smaller offset', function()
    assert.is_true(compare.offset(entry({ offset = 1 }), entry({ offset = 2 })))
    assert.is_false(compare.offset(entry({ offset = 2 }), entry({ offset = 1 })))
    assert.is_nil(compare.offset(entry({ offset = 1 }), entry({ offset = 1 })))
  end)

  it('exact prefers exact matches', function()
    assert.is_true(compare.exact(entry({ exact = true }), entry({ exact = false })))
    assert.is_false(compare.exact(entry({ exact = false }), entry({ exact = true })))
    assert.is_nil(compare.exact(entry({ exact = true }), entry({ exact = true })))
  end)

  it('score prefers the higher score', function()
    assert.is_true(compare.score(entry({ score = 2 }), entry({ score = 1 })))
    assert.is_false(compare.score(entry({ score = 1 }), entry({ score = 2 })))
    assert.is_nil(compare.score(entry({ score = 1 }), entry({ score = 1 })))
  end)

  it('kind ranks snippets first and text last', function()
    local kind = types.lsp.CompletionItemKind
    local item = function(k)
      return entry({ kind = k })
    end
    assert.is_true(compare.kind(item(kind.Snippet), item(kind.Method)))
    assert.is_true(compare.kind(item(kind.Method), item(kind.Text)))
    assert.is_true(compare.kind(item(kind.Method), item(kind.Field)))
    assert.is_nil(compare.kind(item(kind.Method), item(kind.Method)))
  end)

  it('sort_text orders by sortText', function()
    local item = function(text)
      return entry({ completion_item = { sortText = text } })
    end
    assert.is_true(compare.sort_text(item('a'), item('b')))
    assert.is_false(compare.sort_text(item('b'), item('a')))
    assert.is_nil(compare.sort_text(item('a'), item('a')))
    assert.is_nil(compare.sort_text(entry({}), item('a')))
  end)

  it('length prefers the shorter label', function()
    local item = function(label)
      return entry({ completion_item = { label = label } })
    end
    assert.is_true(compare.length(item('a'), item('ab')))
    assert.is_false(compare.length(item('ab'), item('a')))
    assert.is_nil(compare.length(item('ab'), item('cd')))
  end)

  it('order prefers the smaller id', function()
    assert.is_true(compare.order(entry({ id = 1 }), entry({ id = 2 })))
    assert.is_false(compare.order(entry({ id = 2 }), entry({ id = 1 })))
    assert.is_nil(compare.order(entry({ id = 1 }), entry({ id = 1 })))
  end)

  it('recently_used prefers the entry used last', function()
    local item = function(label)
      return entry({ completion_item = { label = label } })
    end
    compare.recently_used.records = {}
    assert.is_nil(compare.recently_used(item('a'), item('b')))
    compare.recently_used:add_entry(item('a'))
    assert.is_true(compare.recently_used(item('a'), item('b')))
    assert.is_false(compare.recently_used(item('b'), item('a')))
  end)
end)
