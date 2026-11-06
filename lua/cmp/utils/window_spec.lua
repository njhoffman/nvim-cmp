local window = require('cmp.utils.window')

describe('utils.window', function()
  local win

  before_each(function()
    win = window.new()
  end)

  after_each(function()
    win:close()
  end)

  local style = function(extra)
    return vim.tbl_extend('force', { relative = 'editor', style = 'minimal', row = 1, col = 1, width = 10, height = 3 }, extra or {})
  end

  it('opens and closes', function()
    assert.is.falsy(win:visible())
    win:open(style())
    assert.is_true(win:visible())
    win:close()
    assert.is.falsy(win:visible())
  end)

  it('does not open with a size below 1', function()
    win:open(style({ height = 0 }))
    assert.is.falsy(win:visible())
    win:open(style({ width = -1 }))
    assert.is.falsy(win:visible())
  end)

  it('applies window options when it opens', function()
    win:option('wrap', true)
    win:open(style())
    assert.is_true(vim.wo[win.win].wrap)
  end)

  it('reports the border in its outer size', function()
    win:open(style({ border = 'single' }))
    local info = win:info()
    assert.are.equal(10, info.inner_width)
    assert.are.equal(3, info.inner_height)
    assert.are.equal(12, info.width)
    assert.are.equal(5, info.height)
    assert.is_true(info.border_info.visible)
  end)

  it('reads border sizes from the configured style', function()
    local border = window.get_border_info({ style = { border = 'single' } })
    assert.are.same({ 1, 1, 1, 1 }, { border.top, border.right, border.bottom, border.left })
    assert.are.equal(2, border.horiz)
    assert.are.equal(2, border.vert)

    border = window.get_border_info({ style = { border = 'none' } })
    assert.is_false(border.visible)
    assert.are.equal(0, border.horiz)
  end)

  it('counts content lines as its content height', function()
    win:open(style())
    vim.api.nvim_buf_set_lines(win:get_buffer(), 0, -1, false, { 'a', 'b' })
    assert.are.equal(2, win:get_content_height())
  end)
end)
