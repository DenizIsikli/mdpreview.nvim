local M = {}

M.job_id = nil

local timer = vim.loop.new_timer()
local cursor_timer = vim.loop.new_timer()

function M.send()
	print("SENDING:", vim.fn.expand("%:p"))
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

function M.send_cursor()
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

function M.send_debounced()
	timer:stop()
	timer:start(100, 0, vim.schedule_wrap(M.send))
end

function M.send_cursor_debounced()
	cursor_timer:stop()
	cursor_timer:start(50, 0, vim.schedule_wrap(M.send_cursor))
end

function M.start()
	if not M.job_id then
		local plugin_path = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
		plugin_path = plugin_path .. "../../"

		local bin = plugin_path .. "/bin/mdpreview"

		if vim.fn.filereadable(bin) == 0 then
			vim.notify("mdpreview binary not found.", vim.log.levels.ERROR)
			return
		end

		M.job_id = vim.fn.jobstart({ bin }, {
			detach = true,
			on_stderr = function(_, data)
				if data then
					print("ERR:", table.concat(data, "\n"))
				end
			end,
		})

		vim.defer_fn(function()
			M.send()
		end, 100)
	end
end

function M.stop()
	if M.job_id then
		vim.fn.jobstop(M.job_id)
		M.job_id = nil
	end
end

function M.running()
	return M.job_id ~= nil
end

return M
