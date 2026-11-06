local config = require('cmp.config')
local spec = require('cmp.utils.spec')

local source = require('cmp.source')

describe('source', function()
  before_each(spec.before)

  it('keeps item data unchanged for completionItem/resolve', function()
    local state = spec.state('', 1, 1)
    local data = { value = vim.NIL }
    local s = source.new('spec', {
      complete = function(_, _, callback)
        callback({ { label = 'spec', detail = vim.NIL, data = data } })
      end,
    })
    local done = false
    s:complete(state.manual(), function()
      done = true
    end)
    vim.wait(200, function()
      return done
    end, 5)
    assert.is_true(done)
    assert.is_nil(s.entries[1].completion_item.detail)
    assert.are.equal(vim.NIL, s.entries[1].completion_item.data.value)
  end)

  describe('vim.NIL response', function()
    for name, response in pairs({
      ['items = vim.NIL'] = { items = vim.NIL },
      ['response = vim.NIL'] = vim.NIL,
    }) do
      it('finishes when ' .. name, function()
        local state = spec.state('', 1, 1)
        local s = source.new('spec', {
          complete = function(_, _, callback)
            callback(response)
          end,
        })
        local done = false
        s:complete(state.manual(), function()
          done = true
        end)
        vim.wait(200, function()
          return done
        end, 5)
        assert.is_true(done)
        assert.are.equal(source.SourceStatus.WAITING, s.status)
        assert.are.equal(0, #s.entries)
      end)
    end
  end)

  describe('keyword length', function()
    it('not enough', function()
      config.set_buffer({
        completion = {
          keyword_length = 3,
        },
      }, vim.api.nvim_get_current_buf())

      local state = spec.state('', 1, 1)
      local s = source.new('spec', {
        complete = function(_, _, callback)
          callback({ { label = 'spec' } })
        end,
      })
      assert.is.truthy(not s:complete(state.input('a'), function() end))
    end)

    it('enough', function()
      config.set_buffer({
        completion = {
          keyword_length = 3,
        },
      }, vim.api.nvim_get_current_buf())

      local state = spec.state('', 1, 1)
      local s = source.new('spec', {
        complete = function(_, _, callback)
          callback({ { label = 'spec' } })
        end,
      })
      assert.is.truthy(s:complete(state.input('aiu'), function() end))
    end)

    it('enough -> not enough', function()
      config.set_buffer({
        completion = {
          keyword_length = 3,
        },
      }, vim.api.nvim_get_current_buf())

      local state = spec.state('', 1, 1)
      local s = source.new('spec', {
        complete = function(_, _, callback)
          callback({ { label = 'spec' } })
        end,
      })
      assert.is.truthy(s:complete(state.input('aiu'), function() end))
      assert.is.truthy(not s:complete(state.backspace(), function() end))
    end)

    it('continue', function()
      config.set_buffer({
        completion = {
          keyword_length = 3,
        },
      }, vim.api.nvim_get_current_buf())

      local state = spec.state('', 1, 1)
      local s = source.new('spec', {
        complete = function(_, _, callback)
          callback({ { label = 'spec' } })
        end,
      })
      assert.is.truthy(s:complete(state.input('aiu'), function() end))
      assert.is.truthy(not s:complete(state.input('eo'), function() end))
    end)
  end)

  describe('isIncomplete', function()
    it('isIncomplete=true', function()
      local state = spec.state('', 1, 1)
      local s = source.new('spec', {
        complete = function(_, _, callback)
          callback({
            items = { { label = 'spec' } },
            isIncomplete = true,
          })
        end,
      })
      vim.wait(100, function()
        return s.status == source.SourceStatus.COMPLETED
      end, 100, false)
      assert.is.truthy(s:complete(state.input('s'), function() end))
      vim.wait(100, function()
        return s.status == source.SourceStatus.COMPLETED
      end, 100, false)
      assert.is.truthy(s:complete(state.input('p'), function() end))
      vim.wait(100, function()
        return s.status == source.SourceStatus.COMPLETED
      end, 100, false)
      assert.is.truthy(s:complete(state.input('e'), function() end))
      vim.wait(100, function()
        return s.status == source.SourceStatus.COMPLETED
      end, 100, false)
      assert.is.truthy(s:complete(state.input('c'), function() end))
      vim.wait(100, function()
        return s.status == source.SourceStatus.COMPLETED
      end, 100, false)
    end)
  end)
end)
