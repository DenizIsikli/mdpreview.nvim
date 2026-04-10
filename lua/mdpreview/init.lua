local M = {}

local function send()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")

	vim.fn.jobstart({
		"curl",
		"-X",
		"POST",
		"http://localhost:3000/update",
		"--data-binary",
		content,
	}, { detach = true })
end

function M.setup()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		pattern = "*.md",
		callback = send,
	})
end
