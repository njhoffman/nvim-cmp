local spec = require('cmp.utils.spec')
local lsp = require('cmp.types.lsp')

describe('types.lsp', function()
  before_each(spec.before)
  describe('Position.to_utf8', function()
    -- bytes: a=1 (byte 0), U+3042=3 (byte 1), b=1 (byte 4), U+10437=4 (byte 5), c=1 (byte 9)
    local text = 'a\227\129\130b\240\144\144\183c'

    local convert = function(character, encoding)
      return lsp.Position.to_utf8(text, { line = 0, character = character }, encoding).character
    end

    it('converts utf-16 positions', function()
      assert.are.equal(4, convert(2, 'utf-16'))
      assert.are.equal(9, convert(5, 'utf-16'))
    end)

    it('converts utf-32 positions', function()
      assert.are.equal(4, convert(2, 'utf-32'))
      assert.are.equal(9, convert(4, 'utf-32'))
    end)

    it('returns utf-8 positions unchanged', function()
      assert.are.equal(7, convert(7, 'utf-8'))
    end)

    it('clamps positions past the end of the line', function()
      assert.are.equal(#text, convert(20, 'utf-16'))
    end)

    it('does not use the deprecated signature', function()
      local deprecate = vim.deprecate
      local deprecated = false
      vim.deprecate = function()
        deprecated = true
      end
      convert(2, 'utf-16')
      vim.deprecate = deprecate
      assert.is_false(deprecated)
    end)
  end)

  describe('Position', function()
    vim.fn.setline('1', {
      'あいうえお',
      'かきくけこ',
      'さしすせそ',
    })
    local vim_position, lsp_position

    local bufnr = vim.api.nvim_get_current_buf()
    vim_position = lsp.Position.to_vim(bufnr, { line = 1, character = 3 })
    assert.are.equal(vim_position.row, 2)
    assert.are.equal(vim_position.col, 10)
    lsp_position = lsp.Position.to_lsp(bufnr, vim_position)
    assert.are.equal(lsp_position.line, 1)
    assert.are.equal(lsp_position.character, 3)

    vim_position = lsp.Position.to_vim(bufnr, { line = 1, character = 0 })
    assert.are.equal(vim_position.row, 2)
    assert.are.equal(vim_position.col, 1)
    lsp_position = lsp.Position.to_lsp(bufnr, vim_position)
    assert.are.equal(lsp_position.line, 1)
    assert.are.equal(lsp_position.character, 0)

    vim_position = lsp.Position.to_vim(bufnr, { line = 1, character = 5 })
    assert.are.equal(vim_position.row, 2)
    assert.are.equal(vim_position.col, 16)
    lsp_position = lsp.Position.to_lsp(bufnr, vim_position)
    assert.are.equal(lsp_position.line, 1)
    assert.are.equal(lsp_position.character, 5)

    -- overflow (lsp -> vim)
    vim_position = lsp.Position.to_vim(bufnr, { line = 1, character = 6 })
    assert.are.equal(vim_position.row, 2)
    assert.are.equal(vim_position.col, 16)

    -- overflow(vim -> lsp)
    vim_position.col = vim_position.col + 1
    lsp_position = lsp.Position.to_lsp(bufnr, vim_position)
    assert.are.equal(lsp_position.line, 1)
    assert.are.equal(lsp_position.character, 5)
  end)
end)
