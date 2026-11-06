local compare = require('cmp.config.compare')
local default = require('cmp.config.default')

describe('config.default', function()
  it('sorts by sort_text between kind and length', function()
    local comparators = default().sorting.comparators
    local index = function(fn)
      for i, comparator in ipairs(comparators) do
        if comparator == fn then
          return i
        end
      end
    end
    assert.is_not_nil(index(compare.sort_text))
    assert.are.equal(index(compare.kind) + 1, index(compare.sort_text))
    assert.are.equal(index(compare.sort_text) + 1, index(compare.length))
  end)

  it('expands snippets with vim.snippet', function()
    local expand = vim.snippet.expand
    local body
    vim.snippet.expand = function(b)
      body = b
    end
    default().snippet.expand({ body = 'foo($1)' })
    vim.snippet.expand = expand
    assert.are.equal('foo($1)', body)
  end)
end)
