local core = require("mdpreview.core")

local M = {}

function M.setup()
	vim.api.nvim_create_user_command("MarkdownPreview", function()
		core.start()

		vim.defer_fn(function()
			vim.fn.jobstart({ "xdg-open", "http://localhost:3000" }, { detach = true })
		end, 300)
	end, {})

	vim.api.nvim_create_user_command("MarkdownPreviewStop", core.stop, {})
end

return M
