# prc.vim

uses param-xml to convert prcs on the fly in vim.

config:

```lua
require("prc").setup {
    -- required
    labels = "/home/alex/ParamLabels.csv",
    -- optional
    param_path = "/home/alex/.local/bin/param-xml"
}
```
