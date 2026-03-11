local set_layout = function()
	require("dapui").setup({
		layouts = {
			{
				elements = {
					{ id = "breakpoints", size = 0.1 },
					{ id = "watches", size = 0.2 },
					{ id = "scopes", size = 0.7 },
				},
				position = "right",
				size = 80,
			},
			{
				elements = {
					{ id = "repl", size = 1 },
				},
				position = "bottom",
				size = 10,
			},
		},
	})
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"leoluz/nvim-dap-go",
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"mfussenegger/nvim-dap-python",
	},
	config = function()
		set_layout()

		vim.keymap.set("n", "<leader>dR", function()
			set_layout()
			require("dapui").open()
		end, { desc = "Debug: Reload UI layout" })

		require("dap-go").setup()
		require("dap-python").setup("venv/bin/python")

		local dap, dapui = require("dap"), require("dapui")
		local Menu = require("nui.menu")
		local Input = require("nui.input")

		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end

		-- Configs Go

		local function get_free_port()
			return math.random(30000, 40000)
		end

		dap.adapters.go = function(callback, _)
			local port = get_free_port()

			local stdout = vim.loop.new_pipe(false)
			local stderr = vim.loop.new_pipe(false)
			local handle

			local opts = {
				stdio = { nil, stdout, stderr },
				args = { "dap", "-l", "127.0.0.1:" .. port },
				detached = true,
			}

			handle = vim.loop.spawn("dlv", opts, function(code)
				stdout:close()
				stderr:close()
				handle:close()
				if code ~= 0 then
					print("dlv exited with code", code)
				end
			end)

			local function forward_output(pipe)
				pipe:read_start(function(err, chunk)
					assert(not err, err)
					if chunk then
						vim.schedule(function()
							require("dap.repl").append(chunk)
						end)
					end
				end)
			end

			forward_output(stdout)
			forward_output(stderr)

			vim.defer_fn(function()
				callback({ type = "server", host = "127.0.0.1", port = port })
			end, 100)
		end

		local function load_vscode_env()
			local env_path = vim.fn.getcwd() .. "/.vscode/settings.json"
			local ok, content = pcall(vim.fn.readfile, env_path)
			if not ok then
				return {}
			end

			local json = table.concat(content, "\n")
			local ok2, parsed = pcall(vim.fn.json_decode, json)
			if not ok2 or not parsed["go.testEnvVars"] then
				return {}
			end

			return parsed["go.testEnvVars"]
		end

		dap.configurations.go = {
			{
				type = "go",
				name = "Debug workspace",
				request = "launch",
				program = vim.fn.getcwd() .. "/cmd/app",
				cwd = vim.fn.getcwd(),
				mode = "debug",
			},
			{
				type = "go",
				name = "Debug cmd/*",
				request = "launch",
				mode = "debug",
				cwd = vim.fn.getcwd(),
				args = function()
					return coroutine.create(function(co)
						local input
						input = Input({
							position = "50%",
							size = { width = 60 },
							border = {
								style = "rounded",
								text = {
									top = " Program arguments ",
									top_align = "center",
								},
							},
						}, {
							prompt = "> ",
							on_submit = function(value)
								coroutine.resume(co, vim.fn.split(value, " "))
							end,
							on_close = function()
								coroutine.resume(co, {})
							end,
						})

						input:mount()
					end)
				end,

				program = function()
					return coroutine.create(function(co)
						local cmd_dir = vim.fn.getcwd() .. "/cmd"

						local items = {}
						for _, dir in ipairs(vim.fn.glob(cmd_dir .. "/*", 1, 1)) do
							if vim.fn.isdirectory(dir) == 1 then
								table.insert(items, Menu.item(vim.fn.fnamemodify(dir, ":t"), { value = dir }))
							end
						end

						if #items == 0 then
							vim.notify("No cmd directories found", vim.log.levels.ERROR)
							coroutine.resume(co, nil)
							return
						end

						local menu

						menu = Menu({
							position = "50%",
							size = {
								width = 40,
								height = math.min(#items + 2, 10),
							},
							border = {
								style = "rounded",
								text = {
									top = " Choose command to debug ",
									top_align = "center",
								},
							},
						}, {
							lines = items,
							keymap = {
								focus_next = { "j", "<Down>" },
								focus_prev = { "k", "<Up>" },
								close = { "<Esc>", "<C-c>" },
								submit = { "<CR>" },
							},
							on_submit = function(item)
								menu:unmount()
								coroutine.resume(co, item.value)
							end,
							on_close = function()
								menu:unmount()
								coroutine.resume(co, nil)
							end,
						})

						menu:mount()
					end)
				end,
			},
			{
				type = "go",
				name = "Debug file",
				request = "launch",
				program = "${file}",
				mode = "debug",
			},
			{
				type = "go",
				name = "Debug package tests",
				request = "launch",
				mode = "test",
				program = "${fileDirname}",
				env = load_vscode_env(),
			},
		}

		-- Configs Python

		dap.configurations.python = {
			{
				type = "python",
				name = "Debug file",
				request = "launch",
				program = "${file}",
				mode = "debug",
			},
			{
				type = "python",
				request = "launch",
				name = "Launch FastAPI (uvicorn)",
				module = "uvicorn",
				args = { "app.main:app", "--host", "127.0.0.1", "--port", "8000", "--reload" },
				cwd = vim.fn.getcwd(),
			},
		}

		-- 🔴 Custom breakpoint icons
		vim.fn.sign_define("DapBreakpoint", {
			text = "🔴",
			texthl = "DiagnosticSignError",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapBreakpointCondition", {
			text = "🟡",
			texthl = "DiagnosticSignWarn",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapLogPoint", {
			text = "🔵",
			texthl = "DiagnosticSignInfo",
			linehl = "",
			numhl = "",
		})
		vim.fn.sign_define("DapStopped", {
			text = "➡️",
			texthl = "DiagnosticSignHint",
			linehl = "Visual",
			numhl = "",
		})

		-- Core actions
		vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue" })
		vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "Debug: Next (Step Over)" })
		vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
		vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Debug: Step Out" })
		vim.keymap.set("n", "<leader>dx", dap.terminate, { desc = "Debug: Terminate" })
		vim.keymap.set("n", "<leader>dr", dap.run_last, { desc = "Debug: Run Last (Restart)" })

		-- Breakpoints
		vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
		vim.keymap.set("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "Debug: Set Conditional Breakpoint" })

		-- DAP UI
		vim.keymap.set("n", "<leader>du", function()
			require("dapui").toggle()
		end, { desc = "Debug: Toggle UI" })

		-- Debug test at cursor
		vim.keymap.set("n", "<leader>dt", function()
			require("dap-go").debug_test()
		end, { desc = "Debug Go Test at Cursor" })
	end,
}
