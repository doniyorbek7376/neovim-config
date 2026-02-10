vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = function()
    require("omarchy.theme").apply()
  end,
})

