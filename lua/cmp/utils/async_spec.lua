local async = require('cmp.utils.async')

describe('utils.async', function()
  it('debounce reads a function delay on each call', function()
    local delay = 200
    local calls = 0
    local debounced = async.debounce(function()
      calls = calls + 1
    end, function()
      return delay
    end)

    debounced()
    vim.wait(30)
    assert.are.equal(0, calls)
    vim.wait(400, function()
      return calls == 1
    end, 5)
    assert.are.equal(1, calls)

    delay = 0
    debounced()
    vim.wait(50, function()
      return calls == 2
    end, 5)
    assert.are.equal(2, calls)
  end)

  it('throttle', function()
    local count = 0
    local now
    local f = async.throttle(function()
      count = count + 1
    end, 100)

    -- 1. delay for 100ms
    now = vim.uv.now()
    f.timeout = 100
    f()
    vim.wait(1000, function()
      return count == 1
    end)
    assert.is.truthy(math.abs(f.timeout - (vim.uv.now() - now)) < 10)

    -- 2. delay for 500ms
    now = vim.uv.now()
    f.timeout = 500
    f()
    vim.wait(1000, function()
      return count == 2
    end)
    assert.is.truthy(math.abs(f.timeout - (vim.uv.now() - now)) < 10)

    -- 4. delay for 500ms and wait 100ms (remain 400ms)
    f.timeout = 500
    f()
    vim.wait(100) -- remain 400ms

    -- 5. call immediately (100ms already elapsed from No.4)
    now = vim.uv.now()
    f.timeout = 100
    f()
    vim.wait(1000, function()
      return count == 3
    end)
    assert.is.truthy(math.abs(vim.uv.now() - now) < 10)
  end)
  it('step', function()
    local done = false
    local step = {}
    async.step(function(next)
      vim.defer_fn(function()
        table.insert(step, 1)
        next()
      end, 10)
    end, function(next)
      vim.defer_fn(function()
        table.insert(step, 2)
        next()
      end, 10)
    end, function(next)
      vim.defer_fn(function()
        table.insert(step, 3)
        next()
      end, 10)
    end, function()
      done = true
    end)
    vim.wait(1000, function()
      return done
    end)
    assert.are.same(step, { 1, 2, 3 })
  end)
end)
