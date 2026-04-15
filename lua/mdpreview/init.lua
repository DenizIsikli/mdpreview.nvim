local M = {}

function M.setup()
	require("mdpreview.commands").setup()
	require("mdpreview.autocmds").setup()
end

return M
