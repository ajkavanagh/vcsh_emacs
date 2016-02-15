;; Python configuration stuff that is useful for python editing

;(defun flymake-create-temp-in-system-tempdir (filename prefix)
;  (make-temp-file (or prefix "flymake")))

;; (when (load "flymake" t)
;;   (defun flymake-pyflakes-init ()
;;     (let* ((temp-file (flymake-init-create-temp-buffer-copy
;; 		       'flymake-create-temp-in-system-tempdir)))
;;       (list "epylint" (list temp-file))))
;;   (add-to-list 'flymake-allowed-file-name-masks
;; 	       '("\\.py\\'" flymake-pyflakes-init)))

(when (load "flymake" t)
  (defun flymake-pyflakes-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
		       'flymake-create-temp-inplace)))
      (list "/home/alex/unison-root/emacs/pyflymake.py" (list temp-file))))
  (add-to-list 'flymake-allowed-file-name-masks
	       '("\\.py\\'" flymake-pyflakes-init)))

;(setq flymake-log-level 3)

;(require 'pymacs)
;(pymacs-load "ropemacs" "rope-")

(require 'cl)
(require 'flymake-cursor)


(add-hook 'python-mode-hook
      (lambda ()
        (unless (eq buffer-file-name nil) (flymake-mode 1)) ;dont invoke flymake on temporary buffers for the interpreter
        (local-set-key [f2] 'flymake-goto-prev-error)
        (local-set-key [f3] 'flymake-goto-next-error)
        ))

(add-hook 'python-mode-hook
	  (lambda () (linum-mode 1)))

(provide 'python-config)
