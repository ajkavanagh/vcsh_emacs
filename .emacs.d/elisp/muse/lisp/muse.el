;;; muse.el --- an authoring and publishing tool for Emacs

;; Copyright (C) 2004, 2005, 2006, 2007 Free Software Foundation, Inc.

;; Emacs Lisp Archive Entry
;; Filename: muse.el
;; Version: 3.03
;; Date: Sun 17-Jun-2007
;; Keywords: hypermedia
;; Author: John Wiegley (johnw AT gnu DOT org)
;; Maintainer: Michael Olson <mwolson@gnu.org>
;; Description: An authoring and publishing tool for Emacs
;; URL: http://mwolson.org/projects/EmacsMuse.html
;; Compatibility: Emacs21 XEmacs21 Emacs22

;; This file is part of Emacs Muse.  It is not part of GNU Emacs.

;; Emacs Muse is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 3, or (at your
;; option) any later version.

;; Emacs Muse is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Emacs Muse; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Muse is a tool for easily authoring and publishing documents.  It
;; allows for rapid prototyping of hyperlinked text, which may then be
;; exported to multiple output formats -- such as HTML, LaTeX,
;; Texinfo, etc.

;; The markup rules used by Muse are intended to be very friendly to
;; people familiar with Emacs.  See the included manual for more
;; information.

;;; Contributors:

;;; Code:

;; Indicate that this version of Muse supports nested tags
(provide 'muse-nested-tags)

(defvar muse-version "3.03"
  "The version of Muse currently loaded")

(defun muse-version (&optional insert)
  "Display the version of Muse that is currently loaded.
If INSERT is non-nil, insert the text instead of displaying it."
  (interactive "P")
  (if insert
      (insert muse-version)
    (message muse-version)))

(defgroup muse nil
  "Options controlling the behavior of Muse.
The markup used by Muse is intended to be very friendly to people
familiar with Emacs."
  :group 'hypermedia)

(defvar muse-under-windows-p (memq system-type '(ms-dos windows-nt)))

(provide 'muse)

(require 'wid-edit)
(require 'muse-regexps)

(defvar muse-update-values-hook nil
  "Hook for values that are automatically generated.
This is to be used by add-on modules for Muse.
It is run just before colorizing or publishing a buffer.")

;; Default file extension

;; By default, use the .muse file extension.
;;;###autoload (add-to-list 'auto-mode-alist '("\\.muse\\'" . muse-mode-choose-mode))

;; We need to have this at top-level, as well, so that any Muse or
;; Planner documents opened during init will just work.
(add-to-list 'auto-mode-alist '("\\.muse\\'" . muse-mode-choose-mode))

(eval-when-compile
  (defvar muse-ignored-extensions))

(defvar muse-ignored-extensions-regexp nil
  "A regexp of extensions to omit from the ending of a Muse page name.
This is autogenerated from `muse-ignored-extensions'.")

(defun muse-update-file-extension (sym val)
  "Update the value of `muse-file-extension'."
  (when (and (featurep 'muse-mode)
             (boundp sym) (stringp (symbol-value sym))
             (or (not (stringp val))
                 (not (string= (symbol-value sym) val))))
    ;; remove old auto-mode-alist association
    (setq auto-mode-alist
          (delete (cons (concat "\\." (symbol-value sym) "\\'")
                        'muse-mode-choose-mode)
                  auto-mode-alist)))
  (set sym val)
  ;; associate the new file extension with muse-mode
  (when (and (featurep 'muse-mode)
             (stringp val)
             (or (not (stringp (symbol-value sym)))
                 (not (string= (symbol-value sym) val))))
    (add-to-list 'auto-mode-alist
                 (cons (concat "\\." val "\\'")
                       'muse-mode-choose-mode)))
  ;; update the ignored extensions regexp
  (when (and (fboundp 'muse-update-ignored-extensions-regexp)
             (or (not (stringp (symbol-value sym)))
                 (not (stringp val))
                 (not (string= (symbol-value sym) val))))
    (muse-update-ignored-extensions-regexp
     'muse-ignored-extensions muse-ignored-extensions)))

(defcustom muse-file-extension "muse"
  "File extension of Muse files.  Omit the period at the beginning.
If you don't want Muse files to have an extension, set this to nil."
  :type '(choice
          (const :tag "None" nil)
          (string))
  :set 'muse-update-file-extension
  :group 'muse)

(defcustom muse-completing-read-function 'completing-read
  "Function to call when prompting user to choose between a list of options.
This should take the same arguments as `completing-read'."
  :type 'function
  :group 'muse)

(defun muse-update-ignored-extensions-regexp (sym val)
  "Update the value of `muse-ignored-extensions-regexp'."
  (set sym val)
  (if val
      (setq muse-ignored-extensions-regexp
            (concat "\\.\\("
                    (regexp-quote (or muse-file-extension "")) "\\|"
                    (mapconcat 'identity val "\\|")
                    "\\)\\'"))
    (setq muse-ignored-extensions-regexp
          (if muse-file-extension
              (concat "\\.\\(" muse-file-extension "\\)\\'")
            nil))))

(add-hook 'muse-update-values-hook
          (lambda ()
            (muse-update-ignored-extensions-regexp
             'muse-ignored-extensions muse-ignored-extensions)))

(defcustom muse-ignored-extensions '("bz2" "gz" "[Zz]")
  "A list of extensions to omit from the ending of a Muse page name.
These are regexps.

Don't put a period at the beginning of each extension unless you
understand that it is part of a regexp."
  :type '(repeat (regexp :tag "Extension"))
  :set 'muse-update-ignored-extensions-regexp
  :group 'muse)

(defun muse-update-file-extension-after-init ()
  ;; This is short, but it has to be a function, otherwise Emacs21
  ;; does not load it properly when running after-init-hook
  (muse-update-file-extension 'muse-file-extension muse-file-extension))

;; Once the user's init file has been processed, determine whether
;; they want a file extension
(add-hook 'after-init-hook 'muse-update-file-extension-after-init)

;; URL protocols

(require 'muse-protocols)

;; Helper functions

(defsubst muse-delete-file-if-exists (file)
  (when (file-exists-p file)
    (delete-file file)
    (message "Removed %s" file)))

(defsubst muse-time-less-p (t1 t2)
  "Say whether time T1 is less than time T2."
  (or (< (car t1) (car t2))
      (and (= (car t1) (car t2))
           (< (nth 1 t1) (nth 1 t2)))))

(eval-when-compile
  (defvar muse-publishing-current-file nil))

(defun muse-current-file ()
  "Return the name of the currently visited or published file."
  (or (and (boundp 'muse-publishing-current-file)
           muse-publishing-current-file)
      (buffer-file-name)
      (concat default-directory (buffer-name))))

(defun muse-page-name (&optional name)
  "Return the canonical form of a Muse page name.
All this means is that certain extensions, like .gz, are removed."
  (save-match-data
    (unless (and name (not (string= name "")))
      (setq name (muse-current-file)))
    (if name
        (let ((page (file-name-nondirectory name)))
          (if (and muse-ignored-extensions-regexp
                   (string-match muse-ignored-extensions-regexp page))
              (replace-match "" t t page)
            page)))))

(defun muse-display-warning (message)
  "Display the given MESSAGE as a warning."
  (if (fboundp 'display-warning)
      (display-warning 'muse message
                       (if (featurep 'xemacs)
                           'warning
                         :warning))
    (let ((buf (get-buffer-create "*Muse warnings*")))
      (with-current-buffer buf
        (goto-char (point-max))
        (insert "Warning (muse): " message)
        (unless (bolp)
          (newline)))
      (display-buffer buf)
      (sit-for 0))))

(defun muse-eval-lisp (form)
  "Evaluate the given form and return the result as a string."
  (require 'pp)
  (save-match-data
    (condition-case err
        (let ((object (eval (read form))))
          (cond
           ((stringp object) object)
           ((and (listp object)
                 (not (eq object nil)))
            (let ((string (pp-to-string object)))
              (substring string 0 (1- (length string)))))
           ((numberp object)
            (number-to-string object))
           ((eq object nil) "")
           (t
            (pp-to-string object))))
      (error
       (muse-display-warning (format "%s: Error evaluating %s: %s"
                                     (muse-page-name) form err))
       "; INVALID LISP CODE"))))

(defmacro muse-with-temp-buffer (&rest body)
  "Create a temporary buffer, and evaluate BODY there like `progn'.
See also `with-temp-file' and `with-output-to-string'.

Unlike `with-temp-buffer', this will never attempt to save the
temp buffer.  It is meant to be used along with
`insert-file-contents' or `insert-file-contents-literally'.

Additionally, if `debug-on-error' is set to t, keep the buffer
around for debugging purposes rather than removing it."
  (let ((temp-buffer (make-symbol "temp-buffer")))
    `(let ((,temp-buffer (generate-new-buffer " *muse-temp*")))
       (unwind-protect
           (if debug-on-error
               (with-current-buffer ,temp-buffer
                 ,@body)
             (condition-case err
                 (with-current-buffer ,temp-buffer
                   ,@body)
               (error
                (if (and (boundp 'muse-batch-publishing-p)
                         muse-batch-publishing-p)
                    (progn
                      (message "%s: Error occured: %s"
                               (muse-page-name) err)
                      (backtrace))
                  (muse-display-warning
                   (format (concat "An error occurred while publishing"
                                   " %s:\n  %s\n\nSet debug-on-error to"
                                   " `t' if you would like a backtrace.")
                                 (muse-page-name) err))))))
         (when (buffer-live-p ,temp-buffer)
           (with-current-buffer ,temp-buffer
             (set-buffer-modified-p nil))
           (unless debug-on-error (kill-buffer ,temp-buffer)))))))

(put 'muse-with-temp-buffer 'lisp-indent-function 0)
(put 'muse-with-temp-buffer 'edebug-form-spec '(body))

(defun muse-write-file (filename)
  "Write current buffer into file FILENAME.
Unlike `write-file', this does not visit the file, try to back it
up, or interact with vc.el in any way.

If the file was not written successfully, return nil.  Otherwise,
return non-nil."
  (let ((backup-inhibited t)
        (buffer-file-name filename)
        (buffer-file-truename (file-truename filename)))
    (save-current-buffer
      (save-restriction
        (widen)
        (if (not (file-writable-p buffer-file-name))
            (prog1 nil
              (muse-display-warning
               (format "Cannot write file %s:\n  %s" buffer-file-name
                       (let ((dir (file-name-directory buffer-file-name)))
                         (if (not (file-directory-p dir))
                             (if (file-exists-p dir)
                                 (format "%s is not a directory" dir)
                               (format "No directory named %s exists" dir))
                           (if (not (file-exists-p buffer-file-name))
                               (format "Directory %s write-protected" dir)
                             "File is write-protected"))))))
          (write-region (point-min) (point-max) buffer-file-name)
          t)))))

(defun muse-collect-alist (list element &optional test)
  "Collect items from LIST whose car is equal to ELEMENT.
If TEST is specified, use it to compare ELEMENT."
  (unless test (setq test 'equal))
  (let ((items nil))
    (dolist (item list)
      (when (funcall test element (car item))
        (setq items (cons item items))))
    items))

(defmacro muse-sort-with-closure (list predicate closure)
  "Sort LIST, stably, comparing elements using PREDICATE.
Returns the sorted list.  LIST is modified by side effects.
PREDICATE is called with two elements of list and CLOSURE.
PREDICATE should return non-nil if the first element should sort
before the second."
  `(sort ,list (lambda (a b) (funcall ,predicate a b ,closure))))

(put 'muse-sort-with-closure 'lisp-indent-function 0)
(put 'muse-sort-with-closure 'edebug-form-spec '(form function-form form))

(defun muse-sort-by-rating (rated-list &optional test)
  "Sort RATED-LIST according to the rating of each element.
The rating is stripped out in the returned list.
Default sorting is highest-first.

If TEST if specified, use it to sort the list."
  (unless test (setq test '>))
  (mapcar (function cdr)
          (muse-sort-with-closure
            rated-list
            (lambda (a b closure)
              (let ((na (numberp (car a)))
                    (nb (numberp (car b))))
                (cond ((and na nb) (funcall closure (car a) (car b)))
                      (na (not nb))
                      (t nil))))
            test)))

(defun muse-escape-specials-in-string (specials string &optional reverse)
  "Apply the transformations in SPECIALS to STRING.

The transforms should form a fully reversible and non-ambiguous
syntax when STRING is parsed from left to right.

If REVERSE is specified, reverse an already-escaped string."
  (let ((rules (mapcar (lambda (rule)
                         (cons (regexp-quote (if reverse
                                                 (cdr rule)
                                               (car rule)))
                               (if reverse (car rule) (cdr rule))))
                       specials)))
    (with-temp-buffer
      (insert string)
      (goto-char (point-min))
      (save-match-data
        (while (not (eobp))
          (unless (catch 'found
                    (dolist (rule rules)
                      (when (looking-at (car rule))
                        (replace-match (cdr rule) t t)
                        (throw 'found t))))
            (forward-char))))
      (buffer-string))))

(defun muse-trim-whitespace (string)
  "Return a version of STRING with no initial nor trailing whitespace."
  (muse-replace-regexp-in-string
   (concat "\\`[" muse-regexp-blank "]+\\|[" muse-regexp-blank "]+\\'")
   "" string))

(defun muse-path-sans-extension (path)
  "Return PATH sans final \"extension\".

The extension, in a file name, is the part that follows the last `.',
except that a leading `.', if any, doesn't count.

This differs from `file-name-sans-extension' in that it will
never modify the directory part of the path."
  (concat (file-name-directory path)
          (file-name-nondirectory (file-name-sans-extension path))))

;; The following code was extracted from cl

(defun muse-const-expr-p (x)
  (cond ((consp x)
         (or (eq (car x) 'quote)
             (and (memq (car x) '(function function*))
                  (or (symbolp (nth 1 x))
                      (and (eq (and (consp (nth 1 x))
                                    (car (nth 1 x))) 'lambda) 'func)))))
        ((symbolp x) (and (memq x '(nil t)) t))
        (t t)))

(put 'muse-assertion-failed 'error-conditions '(error))
(put 'muse-assertion-failed 'error-message "Assertion failed")

(defun muse-list* (arg &rest rest)
  "Return a new list with specified args as elements, cons'd to last arg.
Thus, `(list* A B C D)' is equivalent to `(nconc (list A B C) D)', or to
`(cons A (cons B (cons C D)))'."
  (cond ((not rest) arg)
        ((not (cdr rest)) (cons arg (car rest)))
        (t (let* ((n (length rest))
                  (copy (copy-sequence rest))
                  (last (nthcdr (- n 2) copy)))
             (setcdr last (car (cdr last)))
             (cons arg copy)))))

(defmacro muse-assert (form &optional show-args string &rest args)
  "Verify that FORM returns non-nil; signal an error if not.
Second arg SHOW-ARGS means to include arguments of FORM in message.
Other args STRING and ARGS... are arguments to be passed to `error'.
They are not evaluated unless the assertion fails.  If STRING is
omitted, a default message listing FORM itself is used."
  (let ((sargs
         (and show-args
              (delq nil (mapcar
                         (function
                          (lambda (x)
                            (and (not (muse-const-expr-p x)) x)))
                         (cdr form))))))
    (list 'progn
          (list 'or form
                (if string
                    (muse-list* 'error string (append sargs args))
                  (list 'signal '(quote muse-assertion-failed)
                        (muse-list* 'list (list 'quote form) sargs))))
          nil)))

;; Compatibility functions

(if (fboundp 'looking-back)
    (defalias 'muse-looking-back 'looking-back)
  (defun muse-looking-back (regexp &optional limit &rest ignored)
    (save-excursion
      (re-search-backward (concat "\\(?:" regexp "\\)\\=") limit t))))

(eval-and-compile
  (if (fboundp 'line-end-position)
      (defalias 'muse-line-end-position 'line-end-position)
    (defun muse-line-end-position (&optional n)
      (save-excursion (end-of-line n) (point))))

  (if (fboundp 'line-beginning-position)
      (defalias 'muse-line-beginning-position 'line-beginning-position)
    (defun muse-line-beginning-position (&optional n)
      (save-excursion (beginning-of-line n) (point))))

  (if (fboundp 'match-string-no-properties)
      (defalias 'muse-match-string-no-properties 'match-string-no-properties)
    (defun muse-match-string-no-properties (num &optional string)
      (match-string num string))))

(defun muse-replace-regexp-in-string (regexp replacement text &optional fixedcase literal)
  "Replace REGEXP with REPLACEMENT in TEXT.

Return a new string containing the replacements.

If fourth arg FIXEDCASE is non-nil, do not alter case of replacement text.
If fifth arg LITERAL is non-nil, insert REPLACEMENT literally."
  (cond
   ((and (featurep 'xemacs) (fboundp 'replace-in-string))
    (replace-in-string text regexp replacement literal))
   ((fboundp 'replace-regexp-in-string)
    (replace-regexp-in-string regexp replacement text fixedcase literal))
   (t (let ((repl-len (length replacement))
            start)
        (unless (string= regexp "")
          (save-match-data
            (while (setq start (string-match regexp text start))
              (setq start (+ start repl-len)
                    text (replace-match replacement fixedcase literal
                                        text))))))
      text)))

(if (fboundp 'add-to-invisibility-spec)
    (defalias 'muse-add-to-invisibility-spec 'add-to-invisibility-spec)
  (defun muse-add-to-invisibility-spec (element)
    "Add ELEMENT to `buffer-invisibility-spec'.
See documentation for `buffer-invisibility-spec' for the kind of elements
that can be added."
    (if (eq buffer-invisibility-spec t)
        (setq buffer-invisibility-spec (list t)))
    (setq buffer-invisibility-spec
          (cons element buffer-invisibility-spec))))

(if (fboundp 'read-directory-name)
    (defalias 'muse-read-directory-name  'read-directory-name)
  (defun muse-read-directory-name (prompt &optional dir default-dirname mustmatch initial)
    "Read directory name - see `read-file-name' for details."
    (unless dir
      (setq dir default-directory))
    (read-file-name prompt dir (or default-dirname
                                   (if initial (expand-file-name initial dir)
                                     dir))
                    mustmatch initial)))

(defun muse-file-remote-p (file)
  "Test whether FILE specifies a location on a remote system.
Return non-nil if the location is indeed remote.

For example, the filename \"/user@host:/foo\" specifies a location
on the system \"/user@host:\"."
  (cond ((fboundp 'file-remote-p)
         (file-remote-p file))
        ((fboundp 'tramp-handle-file-remote-p)
         (tramp-handle-file-remote-p file))
        ((and (boundp 'ange-ftp-name-format)
              (string-match (car ange-ftp-name-format) file))
         t)
        (t nil)))

;; Set face globally in a predictable fashion
(defun muse-copy-face (old new)
  "Copy face OLD to NEW."
  (if (featurep 'xemacs)
      (copy-face old new 'all)
    (copy-face old new)))

;; Widget compatibility functions

(defun muse-widget-type-value-create (widget)
  "Convert and instantiate the value of the :type attribute of WIDGET.
Store the newly created widget in the :children attribute.

The value of the :type attribute should be an unconverted widget type."
  (let ((value (widget-get widget :value))
        (type (widget-get widget :type)))
    (widget-put widget :children
                (list (widget-create-child-value widget
                                                 (widget-convert type)
                                                 value)))))

(defun muse-widget-child-value-get (widget)
  "Get the value of the first member of :children in WIDGET."
  (widget-value (car (widget-get widget :children))))

(defun muse-widget-type-match (widget value)
  "Non-nil if the :type value of WIDGET matches VALUE.

The value of the :type attribute should be an unconverted widget type."
  (widget-apply (widget-convert (widget-get widget :type)) :match value))

;; Link-handling functions and variables

(defun muse-get-link (&optional target)
  "Based on the match data, retrieve the link.
Use TARGET to get the string, if it is specified."
  (muse-match-string-no-properties 1 target))

(defun muse-get-link-desc (&optional target)
  "Based on the match data, retrieve the link description.
Use TARGET to get the string, if it is specified."
  (muse-match-string-no-properties 2 target))

(defvar muse-link-specials
  '(("[" . "%5B")
    ("]" . "%5D")
    ("%" . "%%"))
  "Syntax used for escaping and unescaping links.
This allows brackets to occur in explicit links as long as you
use the standard Muse functions to create them.")

(defun muse-link-escape (text)
  "Escape characters in TEXT that conflict with the explicit link
regexp."
  (when (stringp text)
    (muse-escape-specials-in-string muse-link-specials text)))

(defun muse-link-unescape (text)
  "Un-escape characters in TEXT that conflict with the explicit
link regexp."
  (when (stringp text)
    (muse-escape-specials-in-string muse-link-specials text t)))

(defun muse-handle-url (&optional string)
  "If STRING or point has a URL, match and return it."
  (if (if string (string-match muse-url-regexp string)
        (looking-at muse-url-regexp))
      (match-string 0 string)))

(defcustom muse-implicit-link-functions '(muse-handle-url)
  "A list of functions to handle an implicit link.
An implicit link is one that is not surrounded by brackets.

By default, Muse handles URLs only.
If you want to handle WikiWords, load muse-wiki.el."
  :type 'hook
  :options '(muse-handle-url)
  :group 'muse)

(defun muse-handle-implicit-link (&optional link)
  "Handle implicit links.  If LINK is not specified, look at point.
An implicit link is one that is not surrounded by brackets.
By default, Muse handles URLs only.
If you want to handle WikiWords, load muse-wiki.el.

This function modifies the match data so that match 0 is the
link.

The match data is restored after each unsuccessful handler
function call.  If LINK is specified, only restore at very end.

This behavior is needed because the part of the buffer that
`muse-implicit-link-regexp' matches must be narrowed to the part
that is an accepted link."
  (let ((funcs muse-implicit-link-functions)
        (res nil)
        (data (match-data t)))
    (while funcs
      (setq res (funcall (car funcs) link))
      (if res
          (setq funcs nil)
        (unless link (set-match-data data))
        (setq funcs (cdr funcs))))
    (when link (set-match-data data))
    res))

(defcustom muse-explicit-link-functions nil
  "A list of functions to handle an explicit link.
An explicit link is one [[like][this]] or [[this]]."
  :type 'hook
  :group 'muse)

(defun muse-handle-explicit-link (&optional link)
  "Handle explicit links.  If LINK is not specified, look at point.
An explicit link is one that looks [[like][this]] or [[this]].

The match data is preserved.  If no handlers are able to process
LINK, return LINK (if specified) or the 1st match string.  If
LINK is not specified, it is assumed that Muse has matched
against `muse-explicit-link-regexp' before calling this
function."
  (let ((funcs muse-explicit-link-functions)
        (res nil))
    (save-match-data
      (while funcs
        (setq res (funcall (car funcs) link))
        (if res
            (setq funcs nil)
          (setq funcs (cdr funcs)))))
    (muse-link-unescape
     (if res
         res
       (or link (muse-get-link))))))

;; Movement functions

(defun muse-list-item-type (str)
  "Determine the type of list given STR.
Returns either 'ul, 'ol, 'dl-term, 'dl-entry, or nil."
  (save-match-data
    (cond ((or (string= str "")
               (< (length str) 2))
           nil)
          ((string-match muse-dl-entry-regexp str)
           'dl-entry)
          ((string-match muse-dl-term-regexp str)
           'dl-term)
          ((string-match muse-ol-item-regexp str)
           'ol)
          ((string-match muse-ul-item-regexp str)
           'ul)
          (t nil))))

(defun muse-list-item-critical-point (&optional offset)
  "Figure out where the important markup character for the
currently-matched list item is.

If OFFSET is specified, it is the number of groupings outside of
the contents of `muse-list-item-regexp'."
  (unless offset (setq offset 0))
  (if (match-end (+ offset 2))
      ;; at a definition list
      (match-end (+ offset 2))
    ;; at a different kind of list
    (match-beginning (+ offset 1))))

(defun muse-forward-paragraph (&optional pattern)
  "Move forward safely by one paragraph, or according to PATTERN."
  (when (get-text-property (point) 'end-list)
    (goto-char (next-single-property-change (point) 'end-list)))
  (setq pattern (if pattern
                    (concat "^\\(?:" pattern "\\|\n\\|\\'\\)")
                  "^\\s-*\\(\n\\|\\'\\)"))
  (let ((next-list-end (or (next-single-property-change (point) 'end-list)
                           (point-max))))
    (forward-line 1)
    (if (re-search-forward pattern nil t)
        (goto-char (match-beginning 0))
      (goto-char (point-max)))
    (when (> (point) next-list-end)
      (goto-char next-list-end))))

(defun muse-forward-list-item-1 (type empty-line indented-line)
  "Determine whether a nested list item is after point."
  (if (match-beginning 1)
      ;; if we are given a dl entry, skip past everything on the same
      ;; level, except for other dl entries
      (and (eq type 'dl-entry)
           (not (eq (char-after (match-beginning 2)) ?\:)))
    ;; blank line encountered with no list item on the same
    ;; level after it
    (let ((beg (point)))
      (forward-line 1)
      (if (save-match-data
            (and (looking-at indented-line)
                 (not (looking-at empty-line))))
          ;; found that this blank line is followed by some
          ;; indentation, plus other text, so we'll keep
          ;; going
          t
        (goto-char beg)
        nil))))

(defun muse-forward-list-item (type indent &optional no-skip-nested)
  "Move forward to the next item of TYPE.
Return non-nil if successful, nil otherwise.
The beginning indentation is given by INDENT.

If NO-SKIP-NESTED is non-nil, do not skip past nested items.
Note that if you desire this behavior, you will also need to
provide a very liberal INDENT value, such as
\(concat \"[\" muse-regexp-blank \"]*\")."
  (let* ((list-item (format muse-list-item-regexp indent))
         (empty-line (concat "^[" muse-regexp-blank "]*\n"))
         (indented-line (concat "^" indent "[" muse-regexp-blank "]"))
         (list-pattern (concat "\\(?:" empty-line "\\)?"
                               "\\(" list-item "\\)")))
    (while (progn
             (muse-forward-paragraph list-pattern)
             ;; make sure we don't go past boundary
             (and (not (or (get-text-property (point) 'end-list)
                           (>= (point) (point-max))))
                  ;; move past markup that is part of another construct
                  (or (and (match-beginning 1)
                           (or (get-text-property
                                (muse-list-item-critical-point 1) 'muse-link)
                               (and (derived-mode-p 'muse-mode)
                                    (get-text-property
                                     (muse-list-item-critical-point 1)
                                     'face))))
                      ;; skip nested items
                      (and (not no-skip-nested)
                           (muse-forward-list-item-1 type empty-line
                                                     indented-line))))))
    (cond ((or (get-text-property (point) 'end-list)
               (>= (point) (point-max)))
           ;; at a list boundary, so stop
           nil)
          ((let ((str (when (match-beginning 2)
                        ;; get the entire line
                        (save-excursion
                          (goto-char (match-beginning 2))
                          (buffer-substring (muse-line-beginning-position)
                                            (muse-line-end-position))))))
             (and str (eq type (muse-list-item-type str))))
           ;; same type, so indicate that there are more items to be
           ;; parsed
           (goto-char (match-beginning 1)))
          (t
           (when (match-beginning 1)
             (goto-char (match-beginning 1)))
           ;; move to just before foreign list item markup
           nil))))

(defun muse-goto-tag-end (tag nested)
  "Move forward past the end of TAG.

If NESTED is non-nil, look for other instances of this tag that
may be nested inside of this tag, and skip past them."
  (if (not nested)
      (search-forward (concat "</" tag ">") nil t)
    (let ((nesting 1)
          (tag-regexp (concat "\\(<\\(/?\\)" tag ">\\)"))
          (match-found nil))
      (while (and (> nesting 0)
                  (setq match-found (re-search-forward tag-regexp nil t)))
        (if (string-equal (match-string 2) "/")
            (setq nesting (1- nesting))
          (setq nesting (1+ nesting))))
      match-found)))

;;; muse.el ends here
