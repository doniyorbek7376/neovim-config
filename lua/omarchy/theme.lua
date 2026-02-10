local M = {}

local theme_file = vim.fn.expand("~/.config/omarchy/current/theme.name")

local function read_theme()
    local f = io.open(theme_file, "r")
    if not f then
        return nil
    end
    local theme = f:read("*l")
    f:close()
    return theme
end

function M.apply()
    local theme = read_theme()
    if not theme or theme == "" then
        return
    end

    -- Full reset (this replaces all the Lazy magic)
    vim.cmd("highlight clear")
    if vim.fn.exists("syntax_on") == 1 then
        vim.cmd("syntax reset")
    end

    vim.o.background = "dark" -- let theme override if needed

    pcall(vim.cmd.colorscheme, theme)

    -- Force UI refresh
    vim.cmd("redraw!")
end

return M

