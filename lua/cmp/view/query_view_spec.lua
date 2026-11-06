local query_view = require('cmp.view.query_view')

describe('query_view', function()
  local report = {
    context = 'main',
    query = 'a',
    total_time_ms = 1,
    total_count = 2,
    timed_out = false,
    pending = 0,
    results = {
      {
        name = 'first',
        group_index = 1,
        registered = true,
        status = 'COMPLETED',
        time_ms = 1,
        count = 1,
        items = { { label = 'first_item', kind = 1 } },
      },
      {
        name = 'second',
        group_index = 2,
        registered = true,
        status = 'COMPLETED',
        time_ms = 1,
        count = 1,
        items = { { label = 'second_item', kind = 1 } },
      },
    },
  }

  local lines = function()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end

  local line_number = function(text)
    for i, line in ipairs(lines()) do
      if line:find(text, 1, true) then
        return i
      end
    end
  end

  local press = function(keys)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, true, true), 'x', false)
  end

  before_each(function()
    for _, r in ipairs(report.results) do
      r.expanded = nil
    end
    query_view.open(report)
  end)

  after_each(function()
    if vim.bo.filetype == 'cmp-query' then
      press('q')
    end
  end)

  it('parks the cursor on the first source line', function()
    assert.are.equal(line_number('first 1'), vim.api.nvim_win_get_cursor(0)[1])
  end)

  it('expands the source under the cursor', function()
    assert.is_nil(line_number('first_item'))
    press('<CR>')
    assert.is_not_nil(line_number('first_item'))
    assert.is_nil(line_number('second_item'))
  end)

  it('expands the second source from its own line', function()
    vim.api.nvim_win_set_cursor(0, { line_number('second 2'), 0 })
    press('<Tab>')
    assert.is_not_nil(line_number('second_item'))
    assert.is_nil(line_number('first_item'))
  end)

  it('collapses an expanded source', function()
    press('<CR>')
    press('<CR>')
    assert.is_nil(line_number('first_item'))
  end)

  it('closes with q', function()
    press('q')
    assert.is_not.equal('cmp-query', vim.bo.filetype)
  end)
end)
