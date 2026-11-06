local async = require('cmp.utils.async')

describe('utils.async', function()
  it('debounced functions do not cancel each other', function()
    local calls = { a = 0, b = 0 }
    local a = async.debounce(function()
      calls.a = calls.a + 1
    end, 10)
    local b = async.debounce(function()
      calls.b = calls.b + 1
    end, 10)
    a()
    b()
    vim.wait(200, function()
      return calls.a == 1 and calls.b == 1
    end, 5)
    assert.are.same({ a = 1, b = 1 }, calls)
  end)

  it('debounce collapses repeated calls and passes the last arguments', function()
    local received = {}
    local debounced = async.debounce(function(v)
      table.insert(received, v)
    end, 10)
    debounced(1)
    debounced(2)
    vim.wait(200, function()
      return #received > 0
    end, 5)
    assert.are.same({ 2 }, received)
  end)

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
