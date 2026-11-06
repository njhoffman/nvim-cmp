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

  describe('positioning', function()
    local lines = vim.o.lines

    after_each(function()
      vim.o.lines = lines
    end)

    ---Open a 3-entry menu with the cursor on a screen row.
    local open_at = function(row, positioning, top_padding)
      vim.o.lines = 40
      vim.cmd('silent! only')
      config.set_global({
        view = { entries = { name = 'custom', vertical_positioning = positioning } },
        window = { completion = { top_padding = top_padding or 0, border = 'none' } },
      })
      local text = {}
      for i = 1, 38 do
        text[i] = 'a'
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
      vim.cmd('normal! gg')
      vim.fn.winrestview({ topline = 1 })
      local state = spec.state('a', row, 2)
      assert.are.equal(row, vim.fn.screenpos(0, row, 2).row)
      local entries = {}
      for i = 1, 3 do
        entries[i] = entry.new(state.manual(), state.source(), { label = 'alpha' .. i })
      end
      view:open(1, entries)
      return vim.api.nvim_win_get_config(view.entries_win.win).row
    end

    it('below stays below the cursor', function()
      local row = open_at(20, 'below')
      assert.is_false(view.bottom_up)
      assert.is.truthy(row >= 20)
    end)

    it('below flips when there is no room', function()
      open_at(38, 'below')
      assert.is_true(view.bottom_up)
    end)

    it('above stays above the cursor', function()
      local row = open_at(20, 'above')
      assert.is_true(view.bottom_up)
      assert.is.truthy(row + 3 <= 20)
    end)

    it('above flips when there is no room', function()
      open_at(2, 'above')
      assert.is_false(view.bottom_up)
    end)

    it('auto opens above in the upper half', function()
      open_at(10, 'auto')
      assert.is_true(view.bottom_up)
    end)

    it('auto opens below in the lower half', function()
      open_at(25, 'auto')
      assert.is_false(view.bottom_up)
    end)

    it('top_padding moves the menu further below the cursor', function()
      local base = open_at(20, 'below', 0)
      view:close()
      assert.are.equal(base + 2, open_at(20, 'below', 2))
    end)

    it('top_padding moves the menu further above the cursor', function()
      local base = open_at(20, 'above', 0)
      view:close()
      assert.are.equal(base - 2, open_at(20, 'above', 2))
    end)
  end)

  it('marks expandable snippets when expandable_indicator is on', function()
    local state = spec.state('a', 1, 2)
    local item = { label = 'alpha', insertTextFormat = 2, insertText = 'alpha($1)' }
    config.set_global({ formatting = { expandable_indicator = true } })
    assert.are.equal('alpha~', entry.new(state.manual(), state.source(), item):get_view(1, view.entries_win:get_buffer()).abbr.text)
  end)

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
