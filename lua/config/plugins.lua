-- Build Rust binaries after install/update
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if kind ~= "install" and kind ~= "update" then
      return
    end

    if name == "fff.nvim" then
      require("fff.download").download_or_build_binary()
    elseif name == "blink.cmp" then
      local dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/blink.cmp"
      vim.system({ "cargo", "build", "--release" }, { cwd = dir })
    end
  end,
})

vim.pack.add({
  -- Colorscheme
  { src = "https://github.com/catppuccin/nvim",                            name = "catppuccin" },

  -- Core utilities
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/echasnovski/mini.nvim" },

  -- Treesitter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
  { src = "https://github.com/windwp/nvim-ts-autotag" },
  { src = "https://github.com/folke/ts-comments.nvim" },

  -- LSP
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/williamboman/mason.nvim" },
  { src = "https://github.com/williamboman/mason-lspconfig.nvim" },
  { src = "https://github.com/folke/lazydev.nvim" },

  -- Completion
  { src = "https://github.com/Saghen/blink.cmp" },
  { src = "https://github.com/rafamadriz/friendly-snippets" },

  -- Formatting & Linting
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/mfussenegger/nvim-lint" },

  -- UI
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/folke/noice.nvim" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },

  -- Navigation
  { src = "https://github.com/dmtrKovalenko/fff.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/folke/flash.nvim" },
  { src = "https://github.com/MagicDuck/grug-far.nvim" },
  { src = "https://github.com/folke/todo-comments.nvim" },

  -- Git
  { src = "https://github.com/lewis6991/gitsigns.nvim" },

  -- File explorer
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" },

  -- Extras
  { src = "https://github.com/folke/trouble.nvim" },
  { src = "https://github.com/folke/persistence.nvim" },
})

vim.loader.reset()

-- ─── Colorscheme ──────────────────────────────────────────────────────────────

require("catppuccin").setup({})
vim.cmd.colorscheme("catppuccin")

-- ─── Mini ─────────────────────────────────────────────────────────────────────

require("mini.ai").setup({ n_lines = 500 })
require("mini.icons").setup({})
require("mini.icons").mock_nvim_web_devicons()
require("mini.pairs").setup({})

-- ─── Treesitter ───────────────────────────────────────────────────────────────
-- nvim-treesitter manages parser installation. Use :TSInstall <lang>.
-- Highlighting is built into Neovim; treesitter enables it per buffer.

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

require("nvim-ts-autotag").setup({})
require("ts-comments").setup({})

-- Treesitter text objects — select and move by syntax node
require("nvim-treesitter-textobjects").setup({})

local sel = require("nvim-treesitter-textobjects.select")
local mov = require("nvim-treesitter-textobjects.move")

vim.keymap.set({ "x", "o" }, "af", function()
  sel.select_textobject("@function.outer")
end, { desc = "Outer function" })
vim.keymap.set({ "x", "o" }, "if", function()
  sel.select_textobject("@function.inner")
end, { desc = "Inner function" })
vim.keymap.set({ "x", "o" }, "ac", function()
  sel.select_textobject("@class.outer")
end, { desc = "Outer class" })
vim.keymap.set({ "x", "o" }, "ic", function()
  sel.select_textobject("@class.inner")
end, { desc = "Inner class" })
vim.keymap.set({ "x", "o" }, "aa", function()
  sel.select_textobject("@parameter.outer")
end, { desc = "Outer argument" })
vim.keymap.set({ "x", "o" }, "ia", function()
  sel.select_textobject("@parameter.inner")
end, { desc = "Inner argument" })

vim.keymap.set("n", "]f", function()
  mov.goto_next_start("@function.outer")
end, { desc = "Next function" })
vim.keymap.set("n", "[f", function()
  mov.goto_previous_start("@function.outer")
end, { desc = "Prev function" })
vim.keymap.set("n", "]c", function()
  mov.goto_next_start("@class.outer")
end, { desc = "Next class" })
vim.keymap.set("n", "[c", function()
  mov.goto_previous_start("@class.outer")
end, { desc = "Prev class" })

-- ─── LSP ──────────────────────────────────────────────────────────────────────

require("lazydev").setup({
  library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
})

require("mason").setup({})

require("blink.cmp").setup({
  keymap = { preset = "default" },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
})

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

require("mason-lspconfig").setup({
  -- ensure_installed = { "lua_ls", "ts_ls", "pyright" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = ev.buf, desc = desc })
    end
    local tb = require("telescope.builtin")
    map("gd", tb.lsp_definitions, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", tb.lsp_references, "Find references")
    map("gi", tb.lsp_implementations, "Go to implementation")
    map("gy", tb.lsp_type_definitions, "Go to type definition")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>cs", tb.lsp_document_symbols, "Document symbols")
    map("[d", function()
      vim.diagnostic.jump({ count = -1 })
    end, "Prev diagnostic")
    map("]d", function()
      vim.diagnostic.jump({ count = 1 })
    end, "Next diagnostic")
  end,
})

-- ─── Formatting & Linting ─────────────────────────────────────────────────────

require("conform").setup({
  format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    require("lint").try_lint()
  end,
})

-- ─── UI ───────────────────────────────────────────────────────────────────────

require("lualine").setup({
  options = { theme = "catppuccin-mocha" },
})

require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
  },
  presets = {
    bottom_search = true,
    command_palette = true,
    long_message_to_split = true,
  },
})

vim.keymap.set("n", "<leader>fn", "<cmd>Noice history<cr>", { desc = "Notification history" })

require("bufferline").setup({
  options = { always_show_bufferline = false },
})

vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer" })

local snacks = require("snacks")
snacks.setup({
  bigfile = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  lazygit = { enabled = true },
  notifier = { enabled = true, timeout = 3000 },
  quickfile = { enabled = true },
  words = { enabled = true },
})

require("which-key").setup({})
require("which-key").add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>h", group = "hunks" },
  { "<leader>q", group = "session" },
  { "<leader>s", group = "search" },
  { "<leader>x", group = "diagnostics" },
})

-- ─── Navigation ───────────────────────────────────────────────────────────────

-- Flash: s for sneak-style jump, S for treesitter-aware jump
require("flash").setup({})
vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash jump" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash treesitter" })
vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Flash remote" })
vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Flash treesitter search" })
vim.keymap.set("c", "<c-s>", function()
  require("flash").toggle()
end, { desc = "Toggle flash search" })

-- fff: primary fuzzy finder
require("telescope").setup({})
vim.keymap.set("n", "<leader><leader>", function()
  require("fff").find_files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>/", function()
  require("fff").live_grep()
end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>ff", function()
  require("fff").find_files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function()
  require("fff").live_grep()
end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fz", function()
  require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
end, { desc = "Live grep (fuzzy+plain)" })
vim.keymap.set("n", "<leader>fc", function()
  require("fff").live_grep({ query = vim.fn.expand("<cword>") })
end, { desc = "Search current word" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Find help" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
vim.keymap.set("n", "<leader>fn", "<cmd>Noice history<cr>", { desc = "Notifications" })

-- Todo navigation
require("todo-comments").setup({})
vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo" })
vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Prev todo" })

-- Search & replace
vim.keymap.set("n", "<leader>fr", "<cmd>GrugFar<cr>", { desc = "Search & replace" })

-- ─── Git ──────────────────────────────────────────────────────────────────────

local gs = require("gitsigns")
gs.setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
})

vim.keymap.set("n", "]h", gs.next_hunk, { desc = "Next hunk" })
vim.keymap.set("n", "[h", gs.prev_hunk, { desc = "Prev hunk" })
vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>hb", gs.blame_line, { desc = "Blame line" })
vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
vim.keymap.set("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
vim.keymap.set("n", "<leader>g", function()
  snacks.lazygit()
end, { desc = "Lazygit" })

-- ─── File explorer ────────────────────────────────────────────────────────────

require("neo-tree").setup({
  filesystem = {
    follow_current_file = { enabled = true },
    hijack_netrw_behavior = "open_current",
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Toggle file explorer" })

-- ─── Diagnostics ──────────────────────────────────────────────────────────────

require("trouble").setup({})
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
vim.keymap.set("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols" })
vim.keymap.set("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix" })
vim.keymap.set("n", "<leader>xl", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })

-- ─── Sessions ─────────────────────────────────────────────────────────────────

require("persistence").setup({})
vim.keymap.set("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore session" })
vim.keymap.set("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore last session" })
vim.keymap.set("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Don't save session" })
