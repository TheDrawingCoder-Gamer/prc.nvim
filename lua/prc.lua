local M = {}

vim.filetype.add({
	prc = "prc"
})

local _label_location = nil
local _param_path = "param-xml"
function M.setup(config)
	if config then
		if config.labels then
			_label_location = vim.fs.normalize(config.labels)
		end
		if config.param_path then
			_param_path = vim.fs.normalize(config.param_path)
		end
	end
end

local function get_decomp_cmd(file_path)
	local tmp_dir = vim.fs.dirname(vim.fn.tempname()) .. "/prc"
	vim.fn.mkdir(tmp_dir, "p")
	local tmp_file = string.format("%s/%s", tmp_dir, string.gsub(vim.fn.fnamemodify(file_path, ":t"), ".prc", ".xml"))
	return {_param_path, 'disasm', file_path, '-o', tmp_file, '-l', _label_location }, tmp_file
end

local function get_comp_cmd(file_path)
	local tmp_dir = vim.fs.dirname(vim.fn.tempname()) .. "/prc"
	vim.fn.mkdir(tmp_dir, "p")
	local tmp_file = string.format("%s/%s", tmp_dir, string.gsub(vim.fn.fnamemodify(file_path, ":t"), ".prc", ".xml"))
	return {_param_path, 'asm', tmp_file, '-o', file_path, '-l', _label_location }, tmp_file
end

local prcgroup = vim.api.nvim_create_augroup("PRCEditor", {clear = true})

vim.api.nvim_create_autocmd({"BufReadPre","FileReadPre"}, {
	pattern = "*.prc",
	group = prcgroup,
	callback = function()
		vim.o.bin = true
	end
})
vim.api.nvim_create_autocmd({"BufReadPost","FileReadPost"}, {
	pattern = "*.prc",
	group = prcgroup,
	callback = function(evt)
		local cmd, tmp_file = get_decomp_cmd(evt.file)
		vim.fn.jobstart(cmd, {
			on_stderr = function (job_id, data)
				print(table.concat(data, "\n"))
			end,
			on_exit = function()
				vim.api.nvim_buf_set_lines(evt.buf, 0, -1, true, {})
				vim.cmd("1read " .. tmp_file)
				vim.bo.modified = false
			end
		})
		vim.bo.filetype = "xml"
		vim.o.bin = false

	end
})
-- Cmd because I don't want original to do anything
vim.api.nvim_create_autocmd({"BufWriteCmd", "FileWriteCmd"}, {
	pattern = "*.prc",
	group = prcgroup,
	callback = function(evt)
		local cmd, tmp_file = get_comp_cmd(evt.file)
		-- Ignore warning about writing to a file
		vim.cmd(":w! " .. tmp_file)
		vim.fn.jobstart(cmd, {
			on_stderr = function (job_id, data)
				print(table.concat(data, "\n"))
			end,
			on_exit = function (job_id, data)

			end
		})
		vim.bo.modified = false

	end
})

return M
