local entry = require('cmp.entry')
local spec = require('cmp.utils.spec')

local wildmenu_entries_view = require('cmp.view.wildmenu_entries_view')

describe('wildmenu_entries_view', function()
  local view

  before_each(function()
    spec.before()
    view = wildmenu_entries_view.new()
  end)

  after_each(function()
    view:close()
  end)

  local open = function(labels)
    local state = spec.state('a', 1, 2)
    local entries = {}
    for i, label in ipairs(labels) do
      entries[i] = entry.new(state.manual(), state.source(), { label = label, dup = 0 })
    end
    view:open(1, entries)
  end

  it('is not visible before opening', function()
    assert.is.falsy(view:visible())
    assert.is.falsy((view:get_selected_index()))
  end)

  it('draws entries on one line above the command line', function()
    open({ 'alpha', 'beta' })
    assert.is_true(view:visible())
    local win = vim.api.nvim_win_get_config(view.entries_win.win)
    assert.are.equal(1, win.height)
    assert.are.equal(vim.o.lines - 2, win.row)
    local lines = vim.api.nvim_buf_get_lines(view.entries_win:get_buffer(), 0, -1, false)
    assert.are.equal(1, #lines)
    assert.is.truthy(lines[1]:find('alpha', 1, true))
    assert.is.truthy(lines[1]:find('beta', 1, true))
  end)

  it('removes duplicate entries', function()
    open({ 'alpha', 'alpha', 'beta' })
    assert.are.equal(2, #view.entries)
  end)

  it('is not visible after closing', function()
    open({ 'alpha' })
    view:close()
    assert.is.falsy(view:visible())
  end)
end)
