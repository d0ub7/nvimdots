vim.loader.enable()

-- Leader must be set before plugins are loaded
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.plugins")
require("config.keymaps")
require("config.autocmds")
