;; Alex's .emacs config file

;; Use .emacs to keep anything PLATFORM specific.

;; This is the base of some of the odd .el files that I use that are platform
;; agnostic.  Any platform specific stuff will be in ~/elisp set up from
;; ~/.emacs
(add-to-list 'load-path "~/.emacs.d/elisp")

;; we hate toolbar really, but only if we are graphical!
(if (functionp 'tool-bar-mode) (tool-bar-mode nil))

;; This is to not display the initial message (which says to a novice
;; user what to do first if he/she is confused).
(setq inhibit-startup-message t)

;; ...and this inhibits the startup blurb in the echo area.
(setq inhibit-startup-echo-area-message "tinwood")

;; do a nice font for emacs-snapshot (23)
;(if (>= emacs-major-version 23)
;  (set-default-font “Monospace-9″))

;; Longline mode for text files
(autoload 'longlines-mode
  "longlines.el"
  "Minor mode for automatically wrapping long lines." t)
(setq longlines-wrap-follows-window-size t)
(setq window-min-width 1)
;;(add-hook 'text-mode-hook 'longlines-mode)

(global-set-key (kbd "<f8> l SPC") 'longlines-mode)

(defun my-occur ()
  "Switch to *Occur* buffer, or run `occur'."
  (interactive)
  (if (get-buffer "*Occur*")
      (switch-to-buffer-other-window "*Occur*")
    (call-interactively 'occur)))

(global-set-key (kbd "C-c o") 'my-occur)

(global-set-key (kbd "C-c C-M-o")
		'(lambda ()
		   "Kill the *Occur* buffer"
		   (interactive)
		   (kill-buffer "*Occur*")
		   (delete-other-windows)))

;; I like cut and paste to work
(setq x-select-enable-clipboard t)

;; Interative do mode (ido.el)
(require 'ido)
(setq ido-enable-flex-matching t)
(ido-mode t)


;; Maintain a list of recent files. C-x C-r to open from that list
(require 'recentf)

;; enable recent files mode.
(recentf-mode t)

; 50 files ought to be enough.
(setq recentf-max-saved-items 50)

(require 'uniquify)
(setq uniquify-buffer-name-style 'post-forward)

;; auto-complete mode:
(add-to-list 'load-path "~/.emacs.d/elisp/auto-complete")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/dict")
(ac-config-default)
(set-cursor-color "white")
(setq ac-auto-start 3)
(define-key ac-completing-map "\M-?" 'ac-stop)
(setq ac-use-menu-map t)
;; Default settings
(define-key ac-menu-map "\C-n" 'ac-next)
(define-key ac-menu-map "\C-p" 'ac-previous)


;; I prefer cperl-mode to perl-mode
(defalias 'perl-mode 'cperl-mode)
(setq cperl-invalid-face nil)
(setq cperl-electric-keywords nil)

;; Get rid of those annoying backup files...
(setq
   backup-by-copying t      ; don't clobber symlinks
   backup-directory-alist
    '(("." . "~/.emacs.d/backup-files"))    ; don't litter my fs tree
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t)       ; use versioned backups


;; Get aspell to work with GNU Emacs
(setq-default ispell-program-name "aspell")
;;Setup some dictionary languages
(setq ispell-dictionary "british")
(setq flyspell-default-dictionary "british")
;(add-hook 'text-mode-hook
;         '(lambda()
;            (turn-on-auto-fill)
;            (turn-on-filladapt-mode)
;            (flyspell-mode)))
(add-hook 'text-mode-hook 'flyspell-mode)

;; we like auto-fill
;(add-hook 'text-mode-hook 'auto-fill-mode)
;(add-hook 'text-mode-hook 'turn-on-auto-fill)

(require 'filladapt)
;(add-hook 'text-mode-hook 'turn-on-filladapt-mode)

;; we like outline-minor-mode for out text files
(add-hook 'text-mode-hook 'outline-minor-mode)

;; Calendar config
(setq calendar-week-start-day 1)
(setq european-calendar-style t)
(setq diary-file "~/.emacs.d/diary")
(setq mark-diary-entries-in-calendar t)

(setq timeclock-file "~/.emacs.d/timelog")

(load "escreen")
;; note don't activate escreen yet as ecb needs it off until it is going.

;; Load all the configurations files - note the order is important!
(require 'parenface)

;; org mode activation
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(setq org-log-done t)
(setq org-agenda-include-diary t)

;; now we can start escreen after ecb has been configured.
;(escreen-install)
(global-set-key "\C-z" 'escreen-prefix)

;;(require 'tramp)


;; yaml-mode config
(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yml|\\.yaml$" .yaml-mode))

;;; Commentary:
;; Use this mode for editing files in the dot-language (www.graphviz.org and
;; http://www.research.att.com/sw/tools/graphviz/).
;;
;; To use graphviz-dot-mode, add
;; (load-file "PATH_TO_FILE/graphviz-dot-mode.el")
;; to your .emacs or ~/.xemacs/init.el
(load-file "~/.emacs.d/elisp/graphviz-dot-mode.el")
;;
;; The graphviz-dot-mode will do font locking, indentation, preview of graphs
;; and eases compilation/error location. There is support for both GNU Emacs
;; and XEmacs.
;;
;; Font locking is automatic, indentation uses the same commands as
;; other modes, tab, M-j and C-M-q. Insertion of comments uses the
;; same commands as other modes, M-; . You can compile a file using
;; M-x compile or C-c c, after that M-x next-error will also work.
;; There is support for viewing an generated image with C-c p.

;; set my default browser to Firefox:

(setq browse-url-browser-function 'browse-url-mozilla)

; Outline-minor-mode key map
(define-prefix-command 'cm-map nil "Outline-")
; HIDE
(define-key cm-map "q" 'hide-sublevels)    ; Hide everything but the top-level headings
(define-key cm-map "t" 'hide-body)         ; Hide everything but headings (all body lines)
(define-key cm-map "o" 'hide-other)        ; Hide other branches
(define-key cm-map "c" 'hide-entry)        ; Hide this entry's body
(define-key cm-map "l" 'hide-leaves)       ; Hide body lines in this entry and sub-entries
(define-key cm-map "d" 'hide-subtree)      ; Hide everything in this entry and sub-entries
; SHOW
(define-key cm-map "a" 'show-all)          ; Show (expand) everything
(define-key cm-map "e" 'show-entry)        ; Show this heading's body
(define-key cm-map "i" 'show-children)     ; Show this heading's immediate child sub-headings
(define-key cm-map "k" 'show-branches)     ; Show all sub-headings under this heading
(define-key cm-map "s" 'show-subtree)      ; Show (expand) everything in this heading & below
; MOVE
(define-key cm-map "u" 'outline-up-heading)                ; Up
(define-key cm-map "n" 'outline-next-visible-heading)      ; Next
(define-key cm-map "p" 'outline-previous-visible-heading)  ; Previous
(define-key cm-map "f" 'outline-forward-same-level)        ; Forward - same level
(define-key cm-map "b" 'outline-backward-same-level)       ; Backward - same level
(global-set-key "\M-o" cm-map)

(line-number-mode 1)
(column-number-mode 1)


;; now some convenience features

(defun count-words-region (start end)
  (interactive "r")
  (save-excursion
    (let ((n 0))
      (goto-char start)
      (while (< (point) end)
        (if (forward-word 1)
            (setq n (1+ n))))
      (message "Region has %d words" n)
      n)))

(defun count-lines-words-region (start end)
  "Print number of lines words and characters in the region."
  (interactive "r")
  (message "Region has %d lines, %d words, %d characters"
           (count-lines start end)
           (count-words-region start end)
           (- end start)))

(global-set-key "\C-c#" 'count-words-region)

(global-set-key "\C-cg" 'goto-line)

;; after http://www.fourmilab.ch/webtools/demoroniser/
(defun demoronize ()
  (interactive)
  (format-replace-strings '(("\221" . "'")
                            ("\222" . "'")
                            ("\223" . "\"")
                            ("\224" . "\"")
                            ("\213" . " -- ")
                            ("\205" . "--")
                            ("\226" . "--")
                            ("\227" . "\-"))))


;;; mmm mode stuff

;(when (= emacs-major-version 23)
;  (add-to-list 'load-path "/usr/share/emacs21/site-lisp/mmm-mode")
;  (require 'mmm-auto))
;(add-to-list 'auto-mode-alist '("\\.mhtml\\'" . html-mode))
;(add-to-list 'auto-mode-alist '("\\.mas\\'" . html-mode))
;(mmm-add-mode-ext-class 'html-mode "\\.mhtml\\'" 'mason)
;(mmm-add-mode-ext-class 'html-mode "\\.mas\\'" 'mason)

;;; rails rinari stuff for editing rails apps
;(add-to-list 'load-path "~/unison-root/emacs/elisp/rinari")
;(add-to-list 'load-path "~/unison-root/emacs/elisp/rinari/rhtml")
;(require 'rinari)

;;; emacs-on-rails is an alternative system - we will try both.
;(add-to-list 'load-path "~/unison-root/emacs/elisp/emacs-rails")
;(require 'rails)

;;; and now finally some ri stuff!

;(setq ri-ruby-script "~/unison-root/emacs/elisp/ri-emacs/ri-emacs.rb")
;(autoload 'ri "~/unison-root/emacs/elisp/ri-emacs/ri-ruby.el" nil t)
;;
;;  You may want to bind the ri command to a key.
;;  For example to bind it to F1 in ruby-mode:
;;  Method/class completion is also available.
;;
;(add-hook 'ruby-mode-hook (lambda ()
;                            (local-set-key (kbd "<f1>") 'ri)
;                            (local-set-key (kbd "M-\ C-i") 'ri-ruby-complete-symbol)
;                            (local-set-key (kbd "<f4>") 'ri-ruby-show-args)
;                            ))

;;; now configure up the ruby-mode and ruby-inf stuff
;; note that most of it is done in the start up code that debian uses
;; just switch on ruby-electric
;(require 'ruby-electric)



;; demo-frame by M. Hermenegildo
(defun demo-frame ()
  "Create a frame with suitable dimensions for demos."
  (interactive)
  (setq demoframe
        (make-frame '((user-position . f)
                      (name . "Demo Screen")
                      (height . 25)
                      (width . 40)
                      (minibuffer . t))))
  (select-frame demoframe)
 ;; (set-default-font "-Adobe-Courier-Bold-R-Normal--*-100-*-*-M-*-Iso8859-1")
 ;; (set-default-font "-misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-iso8859-1")
 ;; (set-default-font "-bitstream-bitstream vera sans mono-medium-r-*-*-*-120-*-*-*-*-*-*")
 ;; (set-default-font "-windows-proggyclean-medium-r-normal--13-80-96-96-c-70-iso8859-1")
 ;; (set-default-font "-*-profont-*-*-*-*-15-*-*-*-*-*-*-*")
    (set-default-font "-*-lucidatypewriter-*-r-*-sans-14-100-*-*-*-80-*-*")
  )


;; python useful stuff
(require 'python-config)


;; make the title bar show the whole file name
(setq-default
 frame-title-format
 (list '((buffer-file-name " %f" (dired-directory
	 			  dired-directory
				  (revert-buffer-function " %b"
				  ("%b - Dir:  " default-directory)))))))


;; and nXhtml mode stuff
;; disabled because I'm trying multi-web-mode (see end of file)
;;(load "~/unison-root/emacs/elisp/nxhtml/autostart.el")

;; add in prog modes stuff
(add-to-list 'load-path "~/.emacs.d/elisp/prog-modes")
;;(autoload 'js2-mode "js2" nil t)
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

;;(add-hook 'js2-mode-hook
;;	  '(lambda ()
;;	     (setq indent-tabs-mode nil)))

;; After js2 has parsed a js file, we look for jslint globals decl
;; comment ("/* global Fred, _, Harry */") and add any symbols to a
;; buffer-local var of acceptable global vars Note that we also
;; support the "symbol: true" way of specifying names via a hack
;; (remove any ":true" to make it look like a plain decl, and any
;; ':false' are left behind so they'll effectively be ignored as you
;; can;t have a symbol called "someName:false"
(add-hook 'js2-post-parse-callbacks
          (lambda ()
            (let ((btext (replace-regexp-in-string
                          ": *true" " "
                          (replace-regexp-in-string "[\n\t ]+" " " (buffer-substring-no-properties 1 (buffer-size)) t t))))
              (setq js2-additional-externs
                    (split-string
                     (if (string-match "/\\* *global *\\(.*?\\) *\\*/" btext) (match-string-no-properties 1 btext) "")
                     " *, *" t))
              )))

;; reStructuredText mode (rst)
(require 'rst)
(add-to-list 'auto-mode-alist '("\\.rst$" . rst-mode))
(add-to-list 'auto-mode-alist '("\\.rest$" . rst-mode))

; Autmatically update the TOC if we add a section
(add-hook 'rst-adjust-hook 'rst-toc-update)
; make it update font-lock all the time
(setq rst-mode-lazy nil)

;; fic mode highlights todos, etc.
(require 'fic-mode)
(add-hook 'python-mode-hook 'turn-on-fic-mode)
(add-hook 'js2-mode-hook 'turn-on-fic-mode)

;; we don't like trailing whitespace, so lets lose it.
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; finally we quite like the idea of yasnippets, so lets use them too
(add-to-list 'load-path "~/.emacs.d/elisp/yasnippet-0.6.1c")
(require 'yasnippet) ;; not yasnippet-bundle
(yas/initialize)
(yas/load-directory "~/.emacs.d/elisp/yasnippet-0.6.1c/snippets")

;; end of file

(defun switch-to-minibuffer-window ()
  "switch to minibuffer window (if active)"
  (interactive)
  (when (active-minibuffer-window)
    (select-window (active-minibuffer-window))))
(global-set-key (kbd "<f7>") 'switch-to-minibuffer-window)


(defun colonize ()
  "For languages that insist on putting a colon at the end of a line,
   do that. But stay where you're thinking is at."
  (interactive)
  (save-excursion
    (move-end-of-line nil)
    (insert ";")))

(global-set-key (kbd "C-M-;") 'colonize)


;; autopair goodness
(require 'autopair)
(autopair-global-mode) ;; enable autopair in all buffers

;; multi-web-mode for web editing
(require 'multi-web-mode)
(setq mweb-default-major-mode 'html-mode)
(setq mweb-tags '((php-mode "<\\?php\\|<\\? \\|<\\?=" "\\?>")
                  (js-mode "<script +\\(type=\"text/javascript\"\\|language=\"javascript\"\\)[^>]*>" "</script>")
                  (css-mode "<style +type=\"text/css\"[^>]*>" "</style>")))
(setq mweb-filename-extensions '("php" "htm" "html" "ctp" "phtml" "php4" "php5"))
(multi-web-global-mode 1)
;; disable flymake in xml modes.
(defun flymake-xml-init ())

(add-hook 'html-mode-hook
	  (lambda () (linum-mode 1)))
(add-hook 'css-mode-hook
	  (lambda() (linum-mode 1)))
(add-hook 'php-mode-hook
	  (lambda() (linum-mode 1)))

;; add in jade-mode for jade stuff
(require 'sws-mode)
(require 'jade-mode)
(add-to-list 'auto-mode-alist '("\\.styl$" . sws-mode))
(add-to-list 'auto-mode-alist '("\\.jade$" . jade-mode))
(add-hook 'jade-mode-hook
	  (lambda()
	    (linum-mode 1)
	    (setq indent-tabs-mode nil)))
