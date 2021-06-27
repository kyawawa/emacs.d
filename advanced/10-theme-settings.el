;; -*- Mode: Emacs-Lisp; Coding: utf-8 -*-
;;; theme-settings.el --- Elisp theme settings

;; (add-hook 'tty-setup-hook '(lambda () (set-terminal-parameter nil 'background-mode 'dark)))

;; ;; Temporary fix for TERM=screen environment
;; (let ((frame-background-mode 'light)) (frame-set-background-mode nil))

;; (defun set-background-for-terminal (&optional frame)
;;   (or frame (setq frame (selected-frame)))
;;   "unsets the background color in terminal mode"
;;   (unless (display-graphic-p frame)
;;     (set-face-background 'default "unspecified-bg" frame)))
;; (add-hook 'after-make-frame-functions 'set-background-for-terminal)
;; (add-hook 'window-setup-hook 'set-background-for-terminal)

(set-face-background 'vertical-border "#880000")
(set-face-foreground 'vertical-border (face-background 'vertical-border))

;; set transparency
;; (set-frame-parameter (selected-frame) 'alpha '(85 85))
;; (add-to-list 'default-frame-alist '(alpha 85 85))

;; Theme
(use-package cyberpunk-theme
  :init
  ;; Memo: Autumn theme
  ;; (setq cyberpunk-pink "#ff9500")
  ;; (setq cyberpunk-pink-1 "#ff0000")
  (load-theme 'cyberpunk t)
  :config
  (set-background-color "#1e1e1e")
  )

(provide 'theme-settings)
