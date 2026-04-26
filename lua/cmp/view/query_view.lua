local query_view = {}

local function format_summary(report)
  local label = report.context
  if report.sub and report.sub ~= '' then
    label = ('%s `%s`'):format(label, report.sub)
  end
  local quoted_query = ('%q'):format(report.query)
  local lines = {
    ('Query: %s   context=%s   sources=%d'):format(quoted_query, label, #report.results),
    ('Total: %d items in %.1fms%s'):format(
      report.total_count,
      report.total_time_ms,
      report.timed_out and (' (timed out, %d source(s) still pending)'):format(report.pending) or ''
    ),
    '',
  }
  return lines
end

local function format_source_line(r)
  local marker = r.expanded and '▾' or '▸'
  local name = ('%s %d'):format(r.name, r.group_index)
  local status = r.status or '-'
  local count = r.registered and tostring(r.count) or '-'
  local time = r.registered and ('%.1fms'):format(r.time_ms) or '-'
  local trigger = r.trigger or (r.error and ('!' .. r.error) or '-')
  if r.trigger_character then
    trigger = ('%s(%q)'):format(trigger, r.trigger_character)
  end
  return ('%s %-32s  %-12s  %5s items  %8s  %s'):format(marker, name, status, count, time, trigger)
end

local function format_item_line(item, idx)
  local kind = item.kind and tostring(item.kind) or '-'
  local detail = item.detail or ''
  if #detail > 60 then
    detail = detail:sub(1, 57) .. '...'
  end
  return ('    %3d. %-40s  kind=%-4s  %s'):format(idx, item.label or '?', kind, detail)
end

---Render the report into the buffer. Returns a list mapping each line index
---to either { kind = 'source', source_index = N } or { kind = 'item', source_index = N, item_index = M }
---or nil (header / blank line — not interactive).
local function render(state)
  local lines = format_summary(state.report)
  local line_map = {}
  for _ = 1, #lines do
    table.insert(line_map, nil)
  end

  -- Column header above the source rows.
  table.insert(lines, ('  %-32s  %-12s  %5s        %8s  %s'):format('source group', 'status', 'count', 'time', 'trigger'))
  table.insert(line_map, nil)
  table.insert(lines, string.rep('-', 92))
  table.insert(line_map, nil)

  for i, r in ipairs(state.report.results) do
    table.insert(lines, format_source_line(r))
    table.insert(line_map, { kind = 'source', source_index = i })
    if r.expanded then
      if #r.items == 0 then
        table.insert(lines, '    (no items)')
        table.insert(line_map, nil)
      else
        for j, item in ipairs(r.items) do
          table.insert(lines, format_item_line(item, j))
          table.insert(line_map, { kind = 'item', source_index = i, item_index = j })
        end
      end
    end
  end

  table.insert(lines, '')
  table.insert(line_map, nil)
  table.insert(lines, '<CR> toggle expansion · q / <Esc> close')
  table.insert(line_map, nil)

  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', false)
  state.line_map = line_map
end

local function close(state)
  pcall(vim.api.nvim_win_close, state.win, true)
  pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
end

local function toggle_at_cursor(state)
  local row = vim.api.nvim_win_get_cursor(state.win)[1]
  local entry = state.line_map and state.line_map[row]
  if not entry then
    return
  end
  if entry.kind == 'source' then
    local r = state.report.results[entry.source_index]
    if r and r.registered and r.count > 0 then
      r.expanded = not r.expanded
      render(state)
    end
  elseif entry.kind == 'item' then
    -- jumping back to the source line could be added later; for now collapse
    -- the parent group on <CR> from inside.
    local r = state.report.results[entry.source_index]
    if r then
      r.expanded = false
      render(state)
    end
  end
end

---Open the floating popup for the given report.
---@param report cmp.QueryReport
function query_view.open(report)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'cmp-query')

  local width = math.min(vim.o.columns - 4, 110)
  local height = math.min(vim.o.lines - 4, math.max(8, 5 + #report.results + 4))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = 'rounded',
    style = 'minimal',
    title = ' CmpQuery ',
    title_pos = 'center',
  })
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  vim.api.nvim_win_set_option(win, 'wrap', false)

  local state = { buf = buf, win = win, report = report }
  render(state)

  local function map(lhs, rhs)
    vim.keymap.set('n', lhs, rhs, { buffer = buf, nowait = true, silent = true })
  end
  map('<CR>', function() toggle_at_cursor(state) end)
  map('<Tab>', function() toggle_at_cursor(state) end)
  map('q', function() close(state) end)
  map('<Esc>', function() close(state) end)

  -- Park the cursor on the first source line so <CR> works immediately.
  if state.line_map then
    for i, entry in ipairs(state.line_map) do
      if entry and entry.kind == 'source' then
        pcall(vim.api.nvim_win_set_cursor, win, { i, 0 })
        break
      end
    end
  end
end

return query_view
