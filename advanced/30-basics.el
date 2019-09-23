;; -*- Mode: Emacs-Lisp; Coding: utf-8 -*-

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
(defun my-delete-trailing-whitespace ()
  (if delete-trailing-whitespece-before-save
      (delete-trailing-whitespace)))
(add-hook 'before-save-hook 'my-delete-trailing-whitespace)
;; Disable delete-trailing-whitespace at some modes below
(add-hook 'markdown-mode-hook
          '(lambda ()
             (set (make-local-variable 'delete-trailing-whitespece-before-save) nil)))

;;; Auto insert
;; TODO: http://d.hatena.ne.jp/higepon/20080731/1217491155
(add-hook 'find-file-not-found-hooks 'auto-insert)
(use-package autoinsert
  :defer t
  :config
  (setq auto-insert-directory (locate-user-emacs-file "templates/"))
  (setq auto-insert-alist
        (append '(("\\.l$" . "template.l")
                  ("\\.sh$" . "template.sh")
                  ("\\.bash$" . "template.sh")
                  ("Makefile$" . "template.Makefile")
                  ("\\.cpp$" . ["template.cpp" my-template])
                  ("\\.h$" . ["template.h" my-template])
                  ("\\.py$" . "template.py")
                  ("\\.jl$" . "template.jl")
                  ("\\.lua$" . "template.lua")
                  ("\\.launch$" . "template.launch")
                  ("\\.html$" . "template.html")
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
  "Do reverse indentation"
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
  ("M-x" . smex)
  ("M-X" . smex-major-mode-commands)
  ;; This is your old M-x.
  ;; ("M-x" . execute-extended-command)
  )

;;; http://qiita.com/sune2/items/b73037f9e85962f5afb7
;; (use-package company-statistics)
;; (use-package company
;;   :after company-statistics
;;   :config
;;   (add-hook 'after-init-hook 'global-company-mode)
;;   ;; (add-hook 'cmake-mode-hook 'company-mode)
;;   ;; (add-hook 'LaTeX-mode-hook 'company-mode)
;;   (setq company-idle-delay 0) ; デフォルトは0.5
;;   (setq company-minimum-prefix-length 2) ; デフォルトは4
;;   (setq company-selection-wrap-around t) ; 候補の一番下でさらに下に行こうとすると一番上に戻る
;;   (setq company-transformers '(company-sort-by-statistics company-sort-by-backend-importance))
;;   (set-face-attribute 'company-tooltip nil
;;                       :foreground "black" :background "lightgrey")
;;   (set-face-attribute 'company-tooltip-common nil
;;                       :foreground "black" :background "lightgrey")
;;   (set-face-attribute 'company-tooltip-common-selection nil
;;                       :foreground "white" :background "steelblue")
;;   (set-face-attribute 'company-tooltip-selection nil
;;                       :foreground "black" :background "steelblue")
;;   (set-face-attribute 'company-preview-common nil
;;                       :background nil :foreground "lightgrey" :underline t)
;;   (set-face-attribute 'company-scrollbar-fg nil
;;                       :background "orange")
;;   (set-face-attribute 'company-scrollbar-bg nil
;;                       :background "gray40")
;;   :bind (:map company-active-map
;;          ("M-n" . nil)
;;          ("M-p" . nil)
;;          ("C-n" . company-select-next)
;;          ("C-p" . company-select-previous)
;;          ("C-h" . nil)
;;          )
;;   )

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
  :bind
  (("M-/" . undo-tree-redo)
   :map undo-tree-visualizer-mode-map
   ("C-g" . undo-tree-visualizer-quit))
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
