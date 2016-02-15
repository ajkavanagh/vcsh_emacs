;; ECB configuration stuff - this is the directory browser++ software!

; first get semantic, eieio and speedbar

(require 'ecb)
(ecb-winman-escreen-enable-support)
(setq ecb-tip-of-the-day nil)  ; no tip of day - really annoying

(defun ajk/kill-semantic-timer ()
  (interactive)
  (semantic-idle-scheduler-kill-timer))



(global-set-key (kbd "<f11>") 'ajk/kill-semantic-timer)


;; end.
(provide 'ecb-config)

