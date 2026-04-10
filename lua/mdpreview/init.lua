local M = {}

local job_id = nil

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
	vim.api.nvim_create_user_command("MarkdownPreview", function()
		if not job_id then
			local plugin_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
			plugin_path = plugin_path .. "../../"
			if vim.fn.isdirectory(plugin_path) == 0 then
				plugin_path = vim.fn.getcwd()
			end

			local bin = plugin_path .. "/bin/mdpreview"
			if vim.fn.filereadable(bin) == 0 then
				vim.notify("mdpreview binary not found. Build it first.", vim.log.levels.ERROR)
				return
			end

			job_id = vim.fn.jobstart({ bin }, { detach = true })
		end

		vim.fn.jobstart({ "xdg-open", "http://localhost:3000" }, { detach = true })
	end, {})

	vim.api.nvim_create_user_command("MarkdownPreviewStop", function()
		if job_id then
			vim.fn.jobstop(job_id)
			job_id = nil
		end
	end, {})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		pattern = "*.md",
		callback = send,
	})
end

return M
