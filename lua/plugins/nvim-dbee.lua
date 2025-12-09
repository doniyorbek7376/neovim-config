return {
  "kndndrj/nvim-dbee",
  dependencies = { "MunifTanjim/nui.nvim" },
  build = function()
    require("dbee").install()
  end,
  config = function()
    local dbee = require("dbee")
    dbee.setup()

    -- Keymap example
    vim.keymap.set("n", "<leader>bb", function()
      dbee.toggle()
    end, { desc = "Toggle DBee" })
  end,
}

