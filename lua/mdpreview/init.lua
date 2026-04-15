local M = {}

local job_id = nil
local timer = nil

local function send()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")
	local file_dir = vim.fn.expand("%:p:h")

	vim.fn.jobstart({
		"curl",
		"-X",
		"POST",
		"http://localhost:3000/update",
		"-H",
		"X-Base-Dir: " .. file_dir,
		"--data-binary",
		content,
	}, { detach = true })
end

local function send_cursor()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local col = vim.api.nvim_win_get_cursor(0)[2]

	vim.fn.jobstart({
		"curl",
		"-X",
		"POST",
		"http://localhost:3000/cursor",
		"-H",
		"Content-Type: application/json",
		"-d",
		string.format('{"line": %d, "col": %d}', row, col),
	}, { detach = true })
end

local timer = vim.loop.new_timer()

local function send_debounced()
	timer:stop()
	timer:start(100, 0, vim.schedule_wrap(send))
end

local cursor_timer = vim.loop.new_timer()

local function send_cursor_debounced()
	cursor_timer:stop()
	cursor_timer:start(50, 0, vim.schedule_wrap(send_cursor))
end

function M.setup()
	vim.api.nvim_create_user_command("MarkdownPreview", function()
		if not job_id then
			local plugin_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
			plugin_path = plugin_path .. "../../"

			local bin = plugin_path .. "/bin/mdpreview"

			if vim.fn.filereadable(bin) == 0 then
				vim.notify("mdpreview binary not found.", vim.log.levels.ERROR)
				return
			end

			job_id = vim.fn.jobstart({ bin }, {
				detach = true,
				on_stderr = function(_, data)
					if data then
						print("ERR:", table.concat(data, "\n"))
					end
				end,
			})

			vim.defer_fn(function()
				send()
			end, 100)
		end

		vim.defer_fn(function()
			vim.fn.jobstart({ "xdg-open", "http://localhost:3000" }, { detach = true })
		end, 300)
	end, {})

	vim.api.nvim_create_user_command("MarkdownPreviewStop", function()
		if job_id then
			vim.fn.jobstop(job_id)
			job_id = nil
		end
	end, {})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			if vim.bo.filetype ~= "markdown" then
				if job_id then
					vim.fn.jobstop(job_id)
					job_id = nil
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = function()
			if job_id then
				vim.fn.jobstop(job_id)
				job_id = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			if vim.bo.filetype ~= "markdown" then
				if job_id then
					vim.fn.jobstop(job_id)
					job_id = nil
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		pattern = "*.md",
		callback = function()
			if job_id then
				send()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		pattern = "*.md",
		callback = function()
			if job_id then
				send_cursor_debounced()
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP", "BufWritePost" }, {
		pattern = "*.md",
		callback = function()
			if job_id then
				send_debounced()
			end
		end,
	})
end

return M
