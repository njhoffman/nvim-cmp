local types = require('cmp.types')

local ghost_text_view = require('cmp.view.ghost_text_view')

describe('ghost_text_view.text_gen', function()
  local gen = function(insert_text, line, cursor_col, text_format)
    return ghost_text_view.text_gen({
      entry = {
        offset = 1,
        get_insert_text = function()
          return insert_text
        end,
        get_completion_item = function()
          return { insertTextFormat = text_format }
        end,
      },
    }, line, cursor_col)
  end

  it('returns the characters still to be typed', function()
    assert.are.equal('llo', gen('hello', 'he', 2))
  end)

  it('returns nothing when the word is already typed', function()
    assert.are.equal('', gen('hello', 'hello', 5))
  end)

  it('counts characters, not bytes', function()
    assert.are.equal('うえ', gen('あいうえ', 'あい', 6))
  end)

  it('expands snippet syntax', function()
    assert.are.equal('llo()', gen('hello($1)', 'he', 2, types.lsp.InsertTextFormat.Snippet))
  end)
end)
