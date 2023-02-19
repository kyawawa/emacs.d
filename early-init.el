;;; early-init.el --- Early Initialization. -*- lexical-binding: t; no-byte-compile: t -*-
;;; Code:

;; Disable GC when start up
(setq gc-cons-threshold most-positive-fixnum)

;; Hidden menu bar
(push '(menu-bar-lines . 0) default-frame-alist)
;; Hidden tool bar
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; For straight.el
(setq package-enable-at-startup nil)

(provide 'early-init)
;;; early-init.el ends here
