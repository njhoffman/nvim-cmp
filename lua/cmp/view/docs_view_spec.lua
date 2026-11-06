local config = require('cmp.config')
local entry = require('cmp.entry')
local spec = require('cmp.utils.spec')

local docs_view = require('cmp.view.docs_view')

describe('docs_view', function()
  local view, columns

  before_each(function()
    spec.before()
    columns = vim.o.columns
    vim.o.columns = 120
    view = docs_view.new()
  end)

  after_each(function()
    view:close()
    vim.o.columns = columns
  end)

  local menu = { row = 10, col = 10, width = 20, height = 5 }

  ---Open the docs for an entry and return the window config.
  local open = function(documentation, item, bottom_up)
    config.set_global({ window = { documentation = vim.tbl_extend('force', { border = 'none', col_offset = 0, top_padding = 0, max_width = 0 }, documentation or {}) } })
    local state = spec.state('a', 1, 2)
    local e = entry.new(state.manual(), state.source(), item or { label = 'alpha', documentation = 'some docs' })
    view:open(e, menu, bottom_up)
    return view:visible() and vim.api.nvim_win_get_config(view.window.win) or nil
  end

  it('opens beside the menu', function()
    local win = open()
    assert.are.equal(menu.col + menu.width, win.col)
    assert.are.equal(menu.row, win.row)
  end)

  it('applies col_offset', function()
    assert.are.equal(menu.col + menu.width + 3, open({ col_offset = 3 }).col)
  end)

  it('moves down by top_padding', function()
    assert.are.equal(menu.row + 2, open({ top_padding = 2 }).row)
  end)

  it('moves up by top_padding when bottom_up', function()
    local base = open({}, nil, true).row
    view:close()
    assert.are.equal(base - 2, open({ top_padding = 2 }, nil, true).row)
  end)

  it('measures a wrapped line for its full height', function()
    assert.is.truthy(open({ max_width = 20 }, { label = 'alpha', documentation = string.rep('word ', 20) }).height > 1)
  end)

  it('stays closed when the entry has no documentation', function()
    assert.is_nil(open({}, { label = 'alpha' }))
  end)
end)
