;; -*- Mode: Emacs-Lisp; Coding: utf-8; no-compile: t -*-
;;; 48-python-mode.el --- Elisp settings for python-mode

;; (use-package jedi
;;   :defer t
;;   :init
;;   (add-hook 'python-mode-hook 'jedi:setup)
;;   :custom
;;   (jedi:complete-on-dot t)
;;   (jedi:use-shortcuts t) ;; M-. : jump definition, M-, : return from definition
;;   )

(use-package column-marker
  :straight nil
  :functions column-marker-1
  :config
  (add-hook 'python-mode-hook (lambda () (interactive) (column-marker-3 80)))
  )

(use-package python-isort
  :straight
  (:type git :host github :repo "wyuenho/emacs-python-isort")
  :defer t
  :hook (python-mode . python-isort-on-save-mode))

(use-package elpy
  :defer t
  :init
  (advice-add 'python-mode :before 'elpy-enable)
  :config
  (remove-hook 'elpy-modules 'elpy-module-highlight-indentation)
  (remove-hook 'elpy-modules 'elpy-module-flymake)
  :custom
  (elpy-rpc-python-command "python3")
  (flycheck-python-flake8-executable "flake8")
  ;; :bind (elpy-mode-map ("C-c C-r f" . elpy-format-code))
  ;; :hook ((elpy-mode-hook . flycheck-mode))
  )

(use-package poetry
  :defer t
  :after elpy
  :hook ((elpy-mode-hook . poetry-tracking-mode)))
