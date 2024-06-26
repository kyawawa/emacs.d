;; -*- Mode: Emacs-Lisp; Coding: utf-8; no-compile: t -*-

;; paste with indent
(defun yank-with-indent ()
  (interactive)
  (let ((indent
         (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (message indent)
    (yank)
    (narrow-to-region (mark t) (point))
    (pop-to-mark-command)
    (while (search-forward "\n" nil t)
      (replace-match (concat "\n" indent)))
    (widen)))

;;; Delete endline whitespace with saving files
;; (add-hook 'before-save-hook 'delete-trailing-whitespace)
(defvar delete-trailing-whitespece-before-save t)

;;; Auto insert
;; TODO: http://d.hatena.ne.jp/higepon/20080731/1217491155
;; TODO: 初回ビルド時にauto-insertが暴発する(wsl ubuntu20.04) <- :hookにより解決?
(use-package autoinsert
  :straight nil
  :defer t
  ;; :hook (find-file-not-found . auto-insert)
  :hook (find-file . auto-insert)
  :config
  (setq auto-insert-directory (locate-user-emacs-file "templates/"))
  (setq auto-insert-alist
        (append '(("\\.l$" . "template.l")
                  ("\\.sh$" . "template.sh")
                  ("\\.bash$" . "template.sh")
                  ("\\.cpp$" . ["template.cpp" my-template])
                  ("\\.h$" . ["template.h" my-template])
                  ("\\.py$" . "template.py")
                  ("\\.jl$" . "template.jl")
                  ("\\.lua$" . "template.lua")
                  ("\\.launch$" . "template.launch")
                  ("\\.html$" . "template.html")
                  ("Makefile$" . "template.Makefile")
                  ("CMakeLists.txt" . "template.CMakeLists")
                  ) auto-insert-alist))
  (defvar template-replacements-alists
    '(("%file%"             . (lambda () (file-name-nondirectory (buffer-file-name))))
      ("%file-without-ext%" . (lambda () (file-name-sans-extension (file-name-nondirectory (buffer-file-name)))))
      ("%include-guard%"    . (lambda () (format "%s_H" (upcase (file-name-sans-extension (file-name-nondirectory buffer-file-name))))))))
  (defun my-template ()
    (time-stamp)
    (mapc #'(lambda(c)
              (progn
                (goto-char (point-min))
                (while (search-forward (car c) nil t)
                  (replace-match (funcall (cdr c))))))
          template-replacements-alists)
    (goto-char (point-max))
    (message "done.")))

;; backtab
;; http://d.hatena.ne.jp/mtv/20110925/p1
(global-set-key (kbd "<backtab>") 'backtab-line-or-region)
(defun backtab()
  "Do reverse indentation."
  (interactive)
  (back-to-indentation)
  (delete-char
   (if (< (current-column) (car tab-stop-list))
       (- (car (let ((value (list 0)))
                 (dolist (element tab-stop-list value)
                   (setq value (if (< element (current-column)) (cons element value) value)))))
          (current-column)
          ))))

(defun backtab-line-or-region ()
  (interactive)
  (if mark-active (save-excursion
                    (defvar count (count-lines (region-beginning) (region-end)))
                    (goto-char (region-beginning))
                    (dotimes (i count)
                      (backtab)
                      (forward-line))
                    (setq deactivate-mark nil))
    (backtab)))

(defun tab-to-tab-stop-line-or-region ()
  (interactive)
  (if mark-active (save-excursion
                    (defvar count (count-lines (region-beginning) (region-end)))
                    (goto-char (region-beginning))
                    (dotimes (i count)
                      (tab-to-tab-stop)
                      (forward-line))
                    (setq deactivate-mark nil))
    (tab-to-tab-stop)))

;;; Replace region using s.el
(defun apply-function-to-region (fn)
  (interactive "XFunction to apply to region: ")
  (save-excursion
    (let* ((beg (region-beginning))
           (end (region-end))
           (resulting-text
            (funcall
             fn
             (buffer-substring-no-properties beg end))))
      (kill-region beg end)
      (insert resulting-text))))

(use-package s
  :config
  (defun convert-to-lower-camel ()
    (interactive)
    (apply-function-to-region 's-lower-camel-case))
  )

;;; tabbar
(use-package tabbar
  :init
  (tabbar-mode 1)
  :custom
  ;; tab width
  (tabbar-separator '(1.5))
  ;; (tabbar-background-color (face-attribute 'mode-line-inactive :background))
  :bind
  ("<M-right>" . tabbar-forward-tab)
  ("\C-\\"     . tabbar-forward-tab)
  ("<M-left>"  . tabbar-backward-tab)
  ("\C-^"      . tabbar-backward-tab)
  :config
  ;; タブ上でマウスホイール操作無効
  (tabbar-mwheel-mode -1)
  ;; グループ化しない
  ;; (setq tabbar-buffer-groups-function nil)
  ;; 左に表示されるボタンを無効化
  (dolist (btn '(tabbar-buffer-home-button
                 tabbar-scroll-left-button
                 tabbar-scroll-right-button))
    (set btn (cons (cons "" nil)
                   (cons "" nil))))
  (set-face-attribute
   'tabbar-default nil
   :family "Comic Sans MS"
   ;; :background (face-attribute 'mode-line-inactive :foreground)
   ;; :foreground (face-attribute 'mode-line-inactive :background)
   :background "black"
   :foreground "gray72"
   :height 1.0)
  (set-face-attribute
   'tabbar-unselected nil
   ;; :background (face-attribute 'mode-line-inactive :background)
   ;; :foreground (face-attribute 'mode-line-inactive :foreground)
   :background "black"
   :foreground "gray72"
   :box nil)
  (set-face-attribute
   'tabbar-selected nil
   ;; :background "cyan"
   ;; :foreground "black"
   :background "black"
   :foreground "yellow"
   :box nil)
  (set-face-attribute
   'tabbar-button nil
   :box nil)
  ;; タブに表示させるバッファの設定
  (defvar my-tabbar-displayed-buffers
    '("*scratch*" "*shell*" "*Colors*" "*Faces*" "*vc-" "*inferior-lisp*")
    "*Regexps matches buffer names always included tabs.")
  (defun my-tabbar-buffer-list ()
    "Return the list of buffers to show in tabs.
Exclude buffers whose name starts with a space or an asterisk.
The current buffer and buffers matches `my-tabbar-displayed-buffers'
are always included."
    (let* ((hides (list ?\  ?\*))
           (re (regexp-opt my-tabbar-displayed-buffers))
           (cur-buf (current-buffer))
           (tabs (delq nil
                       (mapcar (lambda (buf)
                                 (let ((name (buffer-name buf)))
                                   (when (or (string-match re name)
                                             (not (memq (aref name 0) hides)))
                                     buf)))
                               (buffer-list)))))
      ;; Always include the current buffer.
      (if (memq cur-buf tabs)
          tabs
        (cons cur-buf tabs))))
  (defvar tabbar-buffer-list-function 'my-tabbar-buffer-list)
  ;; sort by fullpath
  ;;  (defun tabbar-add-tab (tabset object &optional append_ignored)
  ;;    "Add to TABSET a tab with value OBJECT if there isn't one there yet.
  ;; If the tab is added, it is added at the beginning of the tab list,
  ;; unless the optional argument APPEND is non-nil, in which case it is
  ;; added at the end."
  ;;    (let ((tabs (tabbar-tabs tabset)))
  ;;      (if (tabbar-get-tab object tabset)
  ;;          tabs
  ;;        (let ((tab (tabbar-make-tab object tabset)))
  ;;          (tabbar-set-template tabset nil)
  ;;          (set tabset (sort (cons tab tabs)
  ;;                            (lambda (a b) (string< (buffer-name (car a)) (buffer-name (car b))))))))))
  )

;;; Ido
(use-package ido
  :straight nil
  :init
  (ido-mode t)
  (ido-everywhere t)
  :config
  ;; ;;; Open protected file as root automatically
  ;; (defadvice ido-find-file (after find-file-sudo activate)
  ;;   "Find file as root if necessary."
  ;;   (unless (and buffer-file-name
  ;;                (file-writable-p buffer-file-name))
  ;;     (find-alternate-file (concat "/sudo:root@localhost:" buffer-file-name))))
  :custom
  (ido-confirm-unique-completion t)
  (ros-completion-function 'ido-completing-read) ;; For rosemacs
  )

(use-package ido-completing-read+
  :after ido
  :init
  (ido-ubiquitous-mode t))

(use-package ido-vertical-mode
  :after ido
  :init
  (ido-vertical-mode t)
  :custom
  (ido-vertical-define-keys 'C-n-and-C-p-only) ;; C-n/C-pで候補選択する
  (ido-vertical-show-count t)
  )

(use-package smex
  :after ido
  :init
  (smex-initialize)
  :bind
  (("M-x" . smex)
   ("M-X" . smex-major-mode-commands))
  ;; This is your old M-x.
  ;; ("M-x" . execute-extended-command)
  )

(use-package company
  :init
  (add-hook 'after-init-hook 'global-company-mode)
  :custom
  (company-idle-delay 0)
  (company-minimum-prefix-length 2)
  (company-selection-wrap-around t)
  :bind (:map company-active-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous)
         ("<tab>" . company-complete-selection)
         :map company-search-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous))
  ;; ("M-/" . company-complete-common-or-cycle)
  ("C-TAB" . company-complete)
  ;; :config
  ;; (eval-after-load "shell"
  ;;   '(define-key shell-mode-map (kbd "TAB") #'company-complete))
  ;; (add-hook 'shell-mode-hook #'company-mode)
  )

(use-package flycheck
  :init
  (global-flycheck-mode))

;; lsp-mode TODO: use eglot
(use-package lsp-mode
  :ensure
  :hook ((python-mode) . lsp)
  :commands lsp
  :custom
  (lsp-prefer-flymake nil)
  ;; (lsp-clients-clangd-executable "clangd")
  (lsp-eldoc-render-all t)
  (lsp-idle-delay 0.6)
  ;;; rust settings
   ;; what to use when checking on-save. "check" is default, I prefer clippy
  (lsp-rust-analyzer-cargo-watch-command "clippy")
  ;; This controls the overlays that display type and other hints inline. Enable
  ;; / disable as you prefer. Well require a `lsp-workspace-restart' to have an
  ;; effect on open projects.
  (lsp-rust-analyzer-server-display-inlay-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints nil)
  (lsp-rust-analyzer-display-reborrow-hints nil)
  )

(use-package lsp-ui
  :hook ((lsp-mode) . lsp-ui)
  :commands lsp-ui-mode
  :bind
  ("M-j" . lsp-ui-imenu)
  ("M-?" . lsp-find-references)
  :custom
  (lsp-ui-peek-always-show t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-doc-enable nil)
  )

(use-package company-lsp
  :commands company-lsp)

(use-package popwin
  :config
  (setq display-buffer-function 'popwin:display-buffer))

(use-package direx
  :defer t
  :after popwin
  :bind
  ("C-x C-j" . direx:jump-to-directory-other-window)
  :config
  (add-to-list 'popwin:special-display-config
               '(direx:direx-mode :position left :width 35 :dedicated t))
  :custom
  (direx:leaf-icon "  ")
  (direx:open-icon "- ")
  (direx:closed-icon "+ "))

;; show undo-tree C-x u
(use-package undo-tree
  :after popwin
  :init
  (global-undo-tree-mode t)
  :config
  (add-to-list 'popwin:special-display-config
               '(" *undo-tree*" :width 40 :position right))
  :custom
  (undo-tree-auto-save-history nil)
  :bind
  (("M-/" . undo-tree-redo)
   :map undo-tree-visualizer-mode-map
   ("C-g" . undo-tree-visualizer-quit))
  :custom
  (undo-tree-auto-save-history nil)
  )

(use-package yasnippet
  :init
  (yas-global-mode 1)
  :bind
  (("C-M-y" . yas-expand)
   ;; insert existing snippet
   ("C-c i i" . yas-insert-snippet)
   ;; edit new snippet
   ("C-c i n" . yas-new-snippet)
   ;; edit existing snippet
   ("C-c i v" . yas-visit-snippet-file)
   :map yas-minor-mode-map
   ("TAB" . nil))
  )

(use-package atomic-chrome
  :defer t
  :custom
  (atomic-chrome-url-major-mode-alist
   '(("github\\.com" . gfm-mode)
     ("overleaf\\.com" . latex-mode)
     ))
  )

;; Docker
(use-package dockerfile-mode
  :defer t
  :mode "Dockerfile\\'")

;; Markdown
(use-package markdown-mode
  :mode (("\\.markdown\\'" . markdown-mode)
         ("\\.md\\'" . markdown-mode)
         ("README\\.md\\'" . gfm-mode)
         )
  :custom
  ;; always open the preview window at the right
  (markdown-split-window-direction 'right)
  ;; delete exported HTML file after markdown-live-preview-export is called
  (markdown-live-preview-delete-export 'delete-on-export)
  )

;; Qt
(use-package qml-mode
  :defer t
  :mode "\\.qml\\'"
  :config
  ;; Change comment style from /* */ to //
  (with-eval-after-load 'qml-mode
    (defun my-qml-style()
      (setq comment-start "//")
      (setq comment-end "")
      )
    (add-hook 'qml-mode-hook 'my-qml-style))
  )

(use-package toml-mode
  ;; :straight
  ;; (:type git :host github :repo "dryman/toml-mode.el")
  :defer t
  )

(add-to-list 'auto-mode-alist '("\\.qrc\\'" . nxml-mode))

;; rust
;; $ git clone https://github.com/rust-analyzer/rust-analyzer.git
;; $ cd rust-analyzer
;; $ cargo xtask install --server # will install rust-analyzer into $HOME/.cargo/bin

(use-package rustic
  :straight
  (:type git :host github :repo "brotzeit/rustic")
  :custom
  (rustic-format-trigger 'on-save)
  ;; (rustic-lsp-server 'rls)
  (rustic-lsp-client 'eglot)
  :bind (:map rustic-mode-map
              ("C-c C-c l" . flycheck-list-errors)
              ("C-c C-c a" . lsp-execute-code-action)
              ("C-c C-c r" . lsp-rename)
              ("C-c C-c q" . lsp-workspace-restart)
              ("C-c C-c Q" . lsp-workspace-shutdown)
              ("C-c C-c s" . lsp-rust-analyzer-status)
              ("C-c C-c e" . lsp-rust-analyzer-expand-macro)
              ("C-c C-c d" . dap-hydra)
              ("C-c C-c h" . lsp-ui-doc-glance)
              ("C-c C-r r" . rustic-cargo-run)
              ("C-c s" . (lambda() (interactive)
                           (print "Execute current file by rust-script" t)
                           (print
                            (shell-command-to-string
                             (mapconcat #'shell-quote-argument
                                        (list "rust-script" (buffer-file-name))
                                        " "))
                            t)))
              )
  )

(use-package eglot)

(use-package project)

;; Powershell
(use-package powershell
  ;; Use old powershell due to problem, see
  ;; https://github.com/jschaf/powershell.el/issues/31
  ;; :custom
  ;; (powershell-location-of-exe (or (executable-find "pwsh") (executable-find "powershell")))
  )

;; CSV
(use-package csv-mode
  :defer t
  :hook ((csv-mode) . csv-align-mode)
  :init
  (add-hook 'csv-mode-hook '(lambda () (interactive) (toggle-truncate-lines nil)))
  )

(provide '30-basics)

;;; 30-basics.el ends here
