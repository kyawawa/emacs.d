;; -*- Mode: Emacs-Lisp; Coding: utf-8 -*-
;;; 49-cc-mode.el --- Elisp settings for cc-mode

(with-eval-after-load 'cc-mode
  (defun my-cc-style()
    (c-set-style "linux")
    (c-set-offset 'innamespace '0)
    (c-set-offset 'inextern-lang '0)
    (c-set-offset 'inline-open '0)
    (c-set-offset 'label '*)
    (c-set-offset 'case-label '*)
    (c-set-offset 'access-label '/)
    (setq c-basic-offset 4)
    (setq tab-width 4)
    (setq indent-tabs-mode nil)
    (hs-minor-mode t)
    )
  ;; Customizations for both c-mode and c++-mode
  (add-hook 'c-mode-common-hook 'my-cc-style)

  ;; For c++11
  ;; https://stackoverflow.com/questions/8549351/c11-mode-or-settings-for-emacs
  (defun --copy-face (new-face face)
    "Define NEW-FACE from existing FACE."
    (copy-face face new-face)
    (eval `(defvar ,new-face nil))
    (set new-face new-face))

  (--copy-face 'font-lock-label-face  ; labels, case, public, private, proteced, namespace-tags
               'font-lock-keyword-face)
  (--copy-face 'font-lock-doc-markup-face ; comment markups such as Javadoc-tags
               'font-lock-doc-face)
  (--copy-face 'font-lock-doc-string-face ; comment markups
               'font-lock-comment-face)

  (setq font-lock-maximum-decoration t)

  (add-hook 'c++-mode-hook
            '(lambda()
               (font-lock-add-keywords
                nil '(;; complete some fundamental keywords
                      ("\\<\\(void\\|unsigned\\|signed\\|char\\|short\\|bool\\|int\\|long\\|float\\|double\\)\\>" . font-lock-keyword-face)
                      ;; add the new C++11 keywords
                      ("\\<\\(alignof\\|alignas\\|constexpr\\|decltype\\|noexcept\\|nullptr\\|static_assert\\|thread_local\\|override\\|final\\)\\>" . font-lock-keyword-face)
                      ("\\<\\(char[0-9]+_t\\)\\>" . font-lock-keyword-face)
                      ;; PREPROCESSOR_CONSTANT
                      ("\\<[A-Z]+[A-Z_]+\\>" . font-lock-constant-face)
                      ;; hexadecimal numbers
                      ("\\<0[xX][0-9A-Fa-f]+\\>" . font-lock-constant-face)
                      ;; integer/float/scientific numbers
                      ("\\<[\\-+]*[0-9]*\\.?[0-9]+\\([ulUL]+\\|[eE][\\-+]?[0-9]+\\)?\\>" . font-lock-constant-face)
                      ;; user-types (customize!)
                      ("\\<[A-Za-z_]+[A-Za-z_0-9]*_\\(t\\|type\\|ptr\\)\\>" . font-lock-type-face)
                      ("\\<\\(xstring\\|xchar\\)\\>" . font-lock-type-face)
                      ))
               )))

(use-package ggtags
  :straight
  (:type git :host github :repo "leoliu/ggtags");; :branch "0.8.13")
  :hook
  (c-mode-hook c++-mode-hook java-mode-hook asm-mode-hook)
  :bind (:map ggtags-mode-map
         ("C-c g s" . ggtags-find-other-symbol)
         ("C-c g h" . ggtags-view-tag-history)
         ("C-c g r" . ggtags-find-reference)
         ("C-c g d" . ggtags-find-definition)
         ("C-c g f" . ggtags-find-file)
         ("C-c g c" . ggtags-create-tags)
         ("C-c g u" . ggtags-update-tags)
         ("M-,"     . pop-tag-mark))
  :config
  ;; use eldoc
  (setq-local eldoc-documentation-function #'ggtags-eldoc-function)
  ;; imenu
  (setq-local imenu-create-index-function #'ggtags-build-imenu-index)
  ;; update GTAGS
  (defun my-c-mode-update-gtags ()
    (interactive "P")
    (let* ((file (buffer-file-name (current-buffer)))
           (dir (directory-file-name (file-name-directory file))))
      (when (executable-find "global")
        (start-process "gtags-update" nil
                       "global" "-uv"))))
  (add-hook 'after-save-hook 'my-c-mode-update-gtags)
  )
