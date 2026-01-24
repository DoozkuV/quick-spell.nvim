--- TODO: Consider allowing user to set exact config levels (e.g. only WARN and up)
local config = require("quick-spell.config")

local M = {}

---Simple vim notify wrapper that checks for notification config
---@param msg string
---@param level integer | nil
function M.log(msg, level)
    if config.options.notify then
        vim.notify(msg, level)
    end
end

return M
