# NoogleNvim

A Neovim plugin that lets you quickly search and explore types and methods in .NET libraries. It is used as a replacement for .NET LSPs.

## Installation

### lazy.nvim:
``` lua
{
    "Irdis/NoogleNvim",
    build = function ()
        require("noogle").build()
    end,
    config = function()
        require("noogle").setup()
        vim.keymap.set('n', '<Leader>nt', function()
            local cmd = 'Noogle -t ' .. vim.fn.expand('<cword>');
            vim.cmd(cmd)
        end, { noremap = true })
        vim.keymap.set('n', '<Leader>nT', function()
            local cmd = 'Noogle -i -a -t ' .. vim.fn.expand('<cword>');
            vim.cmd(cmd)
        end, { noremap = true })
        vim.keymap.set('n', '<Leader>nm', function()
            local cmd = 'Noogle -m ' .. vim.fn.expand('<cword>');
            vim.cmd(cmd)
        end, { noremap = true })
        vim.keymap.set('n', '<Leader>nM', function()
            local cmd = 'Noogle -i -a -m ' .. vim.fn.expand('<cword>');
            vim.cmd(cmd)
        end, { noremap = true })
    end
}
```


