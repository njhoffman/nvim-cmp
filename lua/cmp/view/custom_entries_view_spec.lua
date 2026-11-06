local config = require('cmp.config')
local entry = require('cmp.entry')
local spec = require('cmp.utils.spec')

local custom_entries_view = require('cmp.view.custom_entries_view')

describe('custom_entries_view', function()
  local view

  before_each(function()
    spec.before()
    view = custom_entries_view.new()
  end)

  after_each(function()
    view:close()
  end)

  local open = function(fields)
    config.set_global({
      formatting = {
        fields = fields,
        format = function(_, vim_item)
          vim_item.icon = 'XXXX'
          vim_item.kind = 'Kind'
          vim_item.menu = 'mm'
          return vim_item
        end,
      },
    })
    local state = spec.state('a', 1, 2)
    view:open(1, { entry.new(state.manual(), state.source(), { label = 'alpha' }) })
  end

  it('measures the icon column', function()
    open({ 'icon', 'abbr', 'menu' })
    assert.are.equal(4, view.column_width.icon)
  end)

  it('separates the icon from the next column', function()
    open({ 'icon', 'abbr', 'menu' })
    local line = vim.api.nvim_buf_get_lines(view.entries_win:get_buffer(), 0, 1, false)[1]
    assert.is.truthy(line:find('XXXX alpha mm', 1, true))
  end)

  it('does not reserve width for fields that are not displayed', function()
    open({ 'abbr' })
    assert.are.equal(0, view.column_width.icon)
    assert.are.equal(0, view.column_width.kind)
    assert.are.equal(0, view.column_width.menu)
    assert.are.equal(5, view.column_width.abbr)
  end)
end)
