# NoogleNvim

A Neovim plugin that lets you quickly search and explore types and methods in .NET libraries. Noogle scans `bin` folder with [ILSpy](https://github.com/icsharpcode/ILSpy) and outputs methods and properties signatures of matching classes.
<img width="1320" height="665" alt="image" src="https://github.com/user-attachments/assets/bace7a0e-aa44-43d9-b8fd-c7acca6bff76" />

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

        vim.keymap.set('n', '<Leader>nt', function() vim.cmd('NoogleType ' .. vim.fn.expand('<cword>')) end)
        vim.keymap.set('n', '<Leader>nT', function() vim.cmd('NoogleTypeExt ' .. vim.fn.expand('<cword>')) end)
        vim.keymap.set('n', '<Leader>nm', function() vim.cmd('NoogleMethod ' .. vim.fn.expand('<cword>')) end)
        vim.keymap.set('n', '<Leader>nM', function() vim.cmd('NoogleMethodExt ' .. vim.fn.expand('<cword>')) end)
    end
}
```

## Commands

User commands:
- `:NoogleType <query>` - Searches through public classes only
- `:NoogleTypeExt <query>` - Searches classes of all access levels (public, private, protected, etc.)
- `:NoogleMethod <query>` - Searches through public methods only
- `:NoogleMethodExt <query>` - Searches mehtods of all access levels (public, private, protected, etc.)

## Configuration

You can add extra folders to the search path. For example, by including the .NET directory, you’ll be able to query details about types in the standard library.
```lua
require("noogle").setup({
    additional_locations = {
        "C:\\Program Files\\dotnet\\shared\\Microsoft.NETCore.App\\9.0.8"
    }
})
```
