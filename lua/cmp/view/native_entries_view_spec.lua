local config = require('cmp.config')
local entry = require('cmp.entry')
local spec = require('cmp.utils.spec')

local native_entries_view = require('cmp.view.native_entries_view')

describe('native_entries_view', function()
  local view

  before_each(function()
    spec.before()
    config.set_global({ view = { entries = 'native' } })
    view = native_entries_view.new()
  end)

  local entries = function(labels)
    local state = spec.state('a', 1, 2)
    local result = {}
    for i, label in ipairs(labels) do
      result[i] = entry.new(state.manual(), state.source(), vim.tbl_extend('keep', type(label) == 'table' and label or { label = label }, { dup = 0 }))
    end
    return result
  end

  ---complete() only works in Insert mode, so run the steps from there.
  local in_insert = function(fn)
    local ok, err
    _G.__cmp_native_spec = function()
      ok, err = pcall(fn)
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('A<Cmd>lua _G.__cmp_native_spec()<CR><Esc>', true, true, true), 'x', false)
    _G.__cmp_native_spec = nil
    assert(ok, err)
  end

  it('is ready and not visible before opening', function()
    assert.is_true(view:ready())
    assert.is_false(view:visible())
    assert.is_nil(view:get_selected_index())
    assert.is_nil(view:get_active_entry())
  end)

  it('removes duplicate entries', function()
    local items = entries({ 'alpha', 'alpha', 'beta' })
    in_insert(function()
      view:open(1, items)
      assert.are.equal(2, #view.entries)
      assert.are.equal(2, #view.items)
      assert.is_true(view:visible())
    end)
  end)

  it('remembers the first preselected entry', function()
    local items = entries({ 'alpha', { label = 'beta', preselect = true }, { label = 'gamma', preselect = true } })
    in_insert(function()
      view:open(1, items)
      assert.are.equal(2, view.preselect_index)
    end)
  end)

  it('clears its entries on close', function()
    local items = entries({ 'alpha' })
    in_insert(function()
      view:open(1, items)
      view:close()
      assert.are.equal(0, #view.entries)
    end)
  end)
end)
