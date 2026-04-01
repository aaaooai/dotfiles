(setq debug-on-error t)

(load-theme 'anticolor t)

(add-hook
 'after-save-hook
 (lambda ()
   (let ((file-name (buffer-file-name (current-buffer))))
     (when (and (file-exists-p file-name)
                (eq (point-min) (point-max)))
       (delete-file file-name)))))

(add-hook
 'after-save-hook
 'executable-make-buffer-file-executable-if-script-p)

(setq custom-file (locate-user-emacs-file (format "custom-%d.el" (emacs-pid))))

(add-hook
 'kill-emacs-hook
 (lambda ()
   (when (and (boundp 'custom-file)
              (file-exists-p custom-file))
     (delete-file custom-file))))

(setq inhibit-startup-screen t)
(setq initial-scratch-mesasge nil)

(setq scratch-buffer-file
      (locate-user-emacs-file "scratch"))

(add-hook
 'after-init-hook
 (lambda ()
   (when (file-exists-p scratch-buffer-file)
     (with-current-buffer (get-buffer-create "*scratch*")
       (erase-buffer)
       (insert-file-contents scratch-buffer-file)))))

(add-hook
 'kill-emacs-hook
 (lambda ()
   (with-current-buffer (get-buffer-create "*scratch*")
     (write-region (point-min) (point-max) scratch-buffer-file nil t))))

(add-hook
 'buffer-kill-hook
 (lambda ()
   (when (eq (current-buffer) (get-buffer "*scratch*"))
     (rename-buffer "*scratch~*")
     (clone-buffer "*scratch*"))))

(setq exec-path
      '("~/bin"
        "~/.local/share/mise/shims"
        "/usr/local/bin"
        "/sur/local/sbin"
        "/usr/bin"
        "/usr/sbin"))

(setq find-file-visit-truename t)

(setq global-auto-revert-mode t)

(setq-default indent-tabs-mode nil)

(setq make-backup-files nil)

(add-hook
 'prog-mode-hook
 (setq-local make-backup-files t))

(setq pop-up-windows nil)

(setq require-final-newline 'visit-save)

(setq scroll-step 1)

(setq set-file-name-coding-system 'utf-8)
(setq set-keyboard-coding-system 'utf-8)
(setq set-terminal-coding-system 'utf-8)

(setq set-mark-command-repeat-pop t)

(setq show-paren-mode t)

(setq sqplit-width-threshold 0)

(setq system-time-locale "C")

(let ((display-table (or buffer-display-table standard-display-table)))
  (when display-table
    ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Display-Tables.html
    (set-display-table-slot display-table 1 ? )
    (set-display-table-slot display-table 5 ?│)
    (set-window-display-table (selected-window) display-table)))

(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)

(use-package eshell
  :ensure nil
  :commands eshell
  :bind ("C-#" . eshell)
  :custom
  (eshell-path-env `,(string-join exec-path ":"))
  :config
  (defun eshell/hello ()
    (message "hello world")))

(use-package ido
  :ensure nil
  :hook ((after-init . ido-mode)
         (after-init . ido-everywhere))
  :custom
  (ido-enable-flex-matching t)
  (ido-use-faces t))

(use-package imenu-anywhere
  :bind ("M-." . ido-imenu-anywhere))

(use-package smex
  :bind (("M-x" . smex)
         ("M-X" . smex-major-mode-commands)))

(use-package ido-vertical-mode
  :hook (after-init . ido-vertical-mode)
  :custom
  (ido-vertical-define-keys 'C-n-C-p-up-and-down))

(use-package org
  :ensure nil
  :init
  (let ((org-config-file (expand-file-name "~/org/org-config.el")))
    (when (file-exists-p org-config-file)
      (load-file org-config-file))))

(use-package whitespace
  :ensure nil
  :hook ((after-init . global-whitespace-mode)
         (before-save . whitespace-cleanup))
  :custom
  (whitespace-space-regexp "\\(\u3000+\\)")
  (whitespace-style '(face trailing spaces empty space-mark tab-mark))
  (whitespace-display-mappings '((space-mark ?\u3000 [?\u25a1]) (tab-mark ?\t [?\u00bb ?\t] [?\\ ?\t])))
  (whitespace-action '(auto-cleanup)))

;; (use-package lsp-mode
;;   :hook (((python-mode js-mode typescript-mode rust-mode go-mode c-mode c++-mode) .
;;           lsp-deferred)
;;          (lsp-mode . lsp-enable-which-key-integration))
;;   :commands (lsp lsp-deferred)
;;   :custom
;;   (lsp-completion-provider :capf)
;;   (lsp-idle-delay 0.5)
;;   (lsp-keymap-prefix "C-c l"))

(defun my-add-company-backends (backends)
  (require 'company)
  (setq-local company-backends (append backends company-backends)))

(use-package company
  :commands company-complete
  :bind ("C-c i" . company-complete)
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay nil)
  (company-section-wrap-around t)
  (company-backends
   '((company-capf
      company-files
      company-keywords)
     (company-dabbrev-code
      company-dabbrev))))

(use-package company-shell
  :after company
  :hook ((sh-mode eshell-mode shell-mode shell-script-mode) .
         (lambda () (my-add-company-backends '(company-shell company-shell-env)))))

(use-package terraform-mode
  :if (executable-find "terraform")
  :mode "\\.tf\\'"
  :hook (terraform-mode . terraform-format-on-save-mode)
  :config (use-package terraform-doc))

(use-package company-terraform
  :if (executable-find "terraform")
  :after (company terraform-mode)
  :hook (terraform-mode . company-terraform-init))

(use-package ddskk
  :custom
  (default-input-method "japanese-skk")
  (skk-status-indicator 'minor-mode)
  (skk-egg-like-newline t)
  (skk-latin-mode-string "a")
  (skk-hiragana-mode-string "あ")
  (skk-katakana-mode-string "ア")
  (skk-jisx0208-latin-mode-string "Ａ")
  :config
  (let ((jisyo (locate-user-emacs-file "jisyo")))
    (unless (file-directory-p jisyo)
      (skk-get jisyo))))

(use-package macrostep
  :commands macrostep-expand
  :bind ("C-c e" . macrostep-expand))

(use-package popwin
  :hook (after-init . popwin-mode)
  :config
  ;;(push '() popwin:special-display-config)
  (push '("*Buffer List*") popwin:special-display-config)
  (push '("*eshell*" :height 30 :dedicated t :stick t) popwin:special-display-config)
  (push '("*Warnings*") popwin:special-display-config))

(use-package xclip
  :if (or (executable-find "wl-copy")
          (executable-find "xclip")
          (executable-find "xsel")
          (executable-find "pbcopy"))
  :hook (after-init . xclip-mode))

(use-package dockerfile-mode)
(use-package editorconfig)
(use-package folding)
(use-package lua-mode)
(use-package magit)
(use-package markdown-mode)
(use-package toml-mode)
(use-package yaml-mode)
