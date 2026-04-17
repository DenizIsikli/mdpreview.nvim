local core = require("mdpreview.core")

local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			if vim.bo.filetype == "markdown" then
				if not core.running() then
					core.start()
				else
					vim.defer_fn(function()
						core.send()
					end, 100)
				end
			else
				core.stop()
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			core.stop()
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		pattern = "*.md",
		callback = function()
			if core.running() then
				core.send()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP", "BufWritePost" }, {
		pattern = "*.md",
		callback = function()
			if core.running() then
				core.send_debounced()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		pattern = "*.md",
		callback = function()
			if core.running() then
				core.send_cursor_debounced()
			end
		end,
	})
end

return M
