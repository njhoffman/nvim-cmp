local M = {}

-- Set window option without triggering the OptionSet event
---@param window number
---@param name string
---@param value any
M.win_set_option = function(window, name, value)
  local eventignore = vim.opt.eventignore:get()
  vim.opt.eventignore:append('OptionSet')
  vim.wo[window][name] = value
  vim.opt.eventignore = eventignore
end

-- Set buffer option without triggering the OptionSet event
---@param buffer number
---@param name string
---@param value any
M.buf_set_option = function(buffer, name, value)
  local eventignore = vim.opt.eventignore:get()
  vim.opt.eventignore:append('OptionSet')
  vim.bo[buffer][name] = value
  vim.opt.eventignore = eventignore
end

return M
