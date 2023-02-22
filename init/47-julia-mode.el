;; -*- Mode: Emacs-Lisp; Coding: utf-8; no-compile: t -*-
;;; 48-julia-mode.el --- Elisp settings for julia-mode

(set-language-environment "UTF-8")

(use-package julia-mode
  :defer t
  )

(use-package julia-repl
  :defer t
  :after julia-mode
  :hook ((julia-mode-hook . julia-repl-mode))
  )

;; comment out due to bug of project.el (< emacs 26.3)
(use-package eglot
  :hook ((julia-mode-hook . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(julia-mode . ("julia" "-e using LanguageServer, LanguageServer.SymbolServer; runserver()")))
  )
