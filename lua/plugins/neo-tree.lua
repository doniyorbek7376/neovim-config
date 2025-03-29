return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        require("neo-tree").setup({
            filesystem = {
                filtered_items = {
                    visible = true,
                    hide_dotfiles = false,
                    hide_gitignored = false,
                },
            },
        })

        vim.keymap.set("n", "<C-b>", ":Neotree filesystem reveal left<CR>", {})
        vim.keymap.set("n", "<C-l>", ":Neotree buffers reveal right<CR>", {})
        vim.keymap.set("n", "<leader>gt", ":Neotree git_status reveal right<CR>", {})
    end,
}
