# Toggle

Q&D Neovim plugin for toggling booleans and temporary values in Python.

Install with your favourite plugin manager, for example Packer:
``````````````````
```
use 'emilel/toggle'
```

The plugin exposes one function, Toggle which takes in a boolean whether it
should save the old value in a comment.

Map this function, for example:

```
local python_group = vim.api.nvim_create_augroup(
    'python',
    { clear = true }
)
vim.api.nvim_create_autocmd(
    'BufEnter',
    {
        pattern = '*.py*',
        command = 'nnoremap <cr> <cmd>lua require("toggle").Toggle(false)<cr>',
        group = python_group
    }
)
vim.api.nvim_create_autocmd(
    'BufEnter',
    {
        pattern = '*.py*',
        command = 'nnoremap <space><cr> <cmd>lua require("toggle").Toggle(true)<cr>',
        group = python_group
    }
)
```

When calling Toggle(false), the current line is first forward searched for a boolean
value. If none is found, the line is searched from the back. If found, it will
be toggled to the other value.

If no boolean value is found, the assigned variable on the same line will be
deleted and the user will be put in insert mode.

Toggle(true) works the same way, but will save the old variable in a comment at
the end of the line. When calling Toggle() again, this original value will be
put in place and the comment deleted.
