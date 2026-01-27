local opt = vim.opt
opt.number = true          -- 行番号を表示
opt.relativenumber = true  -- 相対行番号（ジャンプに便利）
opt.tabstop = 4            -- タブ幅
opt.shiftwidth = 4         -- インデント幅
opt.expandtab = true       -- タブをスペースに変換
opt.smartindent = true     -- スマートインデント
opt.termguicolors = true   -- True Color対応
opt.clipboard = "unnamedplus" -- システムクリップボードと同期
opt.ignorecase = true      -- 検索時に大文字小文字を無視
opt.smartcase = true       -- 大文字を含んで検索したら区別する
opt.cursorline = true      -- カーソル行をハイライト

-- リーダーキーの設定（多くのプラグインの起点になるキー）
vim.g.mapleader = " "

-- キーマップの例
vim.keymap.set("n", "<Leader>e", ":Oil<CR>") -- Oilを開く
vim.keymap.set("n", "<Leader>ff", ":Telescope find_files<CR>") -- ファイル検索
