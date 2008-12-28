;;; nxhtml-maintenance.el --- Some maintenance helpers
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2008-09-27T15:29:35+0200 Sat
;; Version: 0.5
;; Last-Updated: 2008-12-26 Fri
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   Cannot open load file: nxhtml-maintenance.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

;;(eval-when-compile (require 'ourcomments-util))

(defvar nxhtmlmaint-dir
  (file-name-directory (if load-file-name load-file-name buffer-file-name))
  "Maintenance directory for nXhtml.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Autoload helpers

(defun nxhtmlmaint-autoloads-file ()
  (file-truename (expand-file-name "nxhtml-loaddefs.el" nxhtmlmaint-dir)))

(defun nxhtmlmaint-util-dir ()
  (file-truename (file-name-as-directory
                  (expand-file-name "util" nxhtmlmaint-dir))))

(defvar nxhtmlmaint-autoload-default-directory (nxhtmlmaint-util-dir))

(defvar generated-autoload-file)

(defun nxhtmlmaint-initialize-autoloads-file ()
  (with-current-buffer (find-file-noselect generated-autoload-file)
    (when (= 0 (buffer-size))
      (insert ";; Autoloads for nXthml
;;
;; This file should be updated by `nxhtmlmaint-get-file-autoloads',
;; `nxhtmlmaint-get-dir-autoloads' or `nxhtmlmaint-get-all-autoloads'.")
    (basic-save-buffer))))

(defun nxmtmlmaint-advice-autoload (on)
  (if on
      (progn
        (ad-activate 'autoload-file-load-name)
        (ad-activate 'make-autoload))
    (ad-deactivate 'autoload-file-load-name)
    (ad-deactivate 'make-autoload)))

(defun nxhtmlmaint-get-file-autoloads (file)
  (interactive (list (buffer-file-name)))
  (let* ((generated-autoload-file (nxhtmlmaint-autoloads-file))
         (emacs-lisp-mode-hook nil)
         (default-directory (nxhtmlmaint-util-dir)))
    (nxhtmlmaint-initialize-autoloads-file)
    ;; Get the autoloads using advice
    (nxmtmlmaint-advice-autoload t)
    (update-file-autoloads file nil)
    (nxmtmlmaint-advice-autoload nil)
    ;; Display
    (display-buffer (find-file-noselect generated-autoload-file))))

(defun nxhtmlmaint-get-dir-autoloads (dir)
  (interactive (list (or (when (buffer-file-name)
                           (file-name-directory (buffer-file-name)))
                         default-directory)))
  (let* ((generated-autoload-file (nxhtmlmaint-autoloads-file))
         (emacs-lisp-mode-hook nil)
         (auto-buf (find-file-noselect generated-autoload-file)))
    (nxhtmlmaint-initialize-autoloads-file)
    ;; Get the autoloads using advice
    (nxmtmlmaint-advice-autoload t)
    ;; Fix-me: Loop instead, some files must be avoided.
    (update-directory-autoloads dir)
    (nxmtmlmaint-advice-autoload nil)
    ;; Display
    (display-buffer (find-file-noselect generated-autoload-file))))

(defun nxhtmlmaint-get-tree-autoloads (root)
  (interactive (list (or (when (buffer-file-name)
                           (file-name-directory (buffer-file-name)))
                         default-directory)))
  (nxhtmlmaint-get-dir-autoloads root)
  (message "----- ROOT=%s" root)
  (let* ((files (directory-files root))
         (sub-dirs (mapcar (lambda (file)
                             (when (and (not (member file '("." "..")))
                                        (not (member file '("nxml-mode-20041004" "old")))
                                        (not (member file '("in")))
                                        (file-directory-p (expand-file-name file root)))
                               file))
                           files)))
    (setq sub-dirs (delq nil sub-dirs))
    (message "sub-dirs=%s" sub-dirs)
    (dolist (dir sub-dirs)
      (let ((full-dir (expand-file-name dir root)))
        (unless (or (string= full-dir nxhtmlmaint-dir)
                    (string= dir "alts"))
          (nxhtmlmaint-get-tree-autoloads full-dir))))))

;;;###autoload
(defun nxhtmlmaint-get-all-autoloads ()
  (interactive)
  (let ((auto-buf (find-file-noselect (nxhtmlmaint-autoloads-file))))
    (with-current-buffer auto-buf
      (erase-buffer)
      (basic-save-buffer)))
  (nxhtmlmaint-get-tree-autoloads nxhtmlmaint-dir))

(defun nxhtmlmaint-autoload-file-load-name (file)
  (let ((name (if nxhtmlmaint-autoload-default-directory
                  (file-relative-name
                   file nxhtmlmaint-autoload-default-directory)
                (file-name-nondirectory file))))
    (if (string-match "\\.elc?\\(\\.\\|\\'\\)" name)
        (substring name 0 (match-beginning 0))
      name)))

(defadvice autoload-file-load-name (around
                                    nxhtmlmaint-advice-autoload-file-load-name
                                    ;;activate
                                    compile)
  (setq ad-return-value (nxhtmlmaint-autoload-file-load-name (ad-get-arg 0))))

(defun nxhtmlmaint-make-autoload (form file)
  ;;(message "form=%S" form)
  (if (or (not (listp form))
          (not (eq 'define-mumamo-multi-major-mode (car form))))
      ad-return-value
    (if ad-return-value
        ad-return-value
      ;; Fix-me: Maybe expand??
      (let ((name (nth 1 form))
            (doc  (nth 2 form)))
        `(autoload ',name ,file ,doc t)
        ))))

(defadvice make-autoload (after
                          nxhtmlmaint-advice-make-autoload
                          ;;activate
                          compile)
  (setq ad-return-value
        (nxhtmlmaint-make-autoload (ad-get-arg 0)
                                             (ad-get-arg 1))))

;; (defun nxhtmlmaint-generate-library-autoloads (library)
;;   "Insert at point autoloads for Emacs library LIBRARY.
;;   Works like `generate-file-autoloads', but for a library."
;;   (interactive
;;    (list (completing-read "Generate autoloads for library: "
;;                           'locate-file-completion
;;                           (cons load-path (get-load-suffixes)))))
;;   (let ((file (locate-library library)))
;;     ;; Fix-me: wasn't this defined???
;;     (generate-file-autoloads file)))

(defun nxhtmlmaint-start-byte-compilation ()
  (interactive)
  (let ((this-file (expand-file-name "nxhtml-maintenance.el" nxhtmlmaint-dir)))
    (message "this-file=%s" this-file)
    (call-process (ourcomments-find-emacs) nil 0 nil "-Q"
                  "-l" this-file
                  "-f" "nxhtmlmaint-byte-compile-all"))
  (message "Starting new Emacs instance for byte compiling ..."))

;;(nxhtmlmaint-byte-compile-all)
(defun nxhtmlmaint-byte-compile-all ()
  (let* ((load-path load-path)
         (nxhtml-dir (file-name-as-directory
                      (expand-file-name "nxhtml"
                                        nxhtmlmaint-dir)))
         (util-dir (file-name-as-directory
                    (expand-file-name "util"
                                      nxhtmlmaint-dir)))
         (related-dir (file-name-as-directory
                       (expand-file-name "related"
                                         nxhtmlmaint-dir)))
         (tests-dir (file-name-as-directory
                     (expand-file-name "tests"
                                       nxhtmlmaint-dir)))
         )
    (add-to-list 'load-path nxhtml-dir)
    (add-to-list 'load-path util-dir)
    (add-to-list 'load-path related-dir)
    (add-to-list 'load-path tests-dir)
    (let ((dummy-debug-on-error t))
      (nxhtmlmaint-byte-compile-dir nxhtmlmaint-dir nil nil))
    (message "Byte compiling is ready, restart Emacs to use the compiled files")))

;;(nxhtmlmaint-byte-uncompile-all)
(defun nxhtmlmaint-byte-uncompile-all ()
  (let ((dummy-debug-on-error t))
    (nxhtmlmaint-byte-compile-dir nxhtmlmaint-dir t t))
  (message "Byte uncompiling is ready, restart Emacs to use the elisp files"))

(defconst nxhtmlmaint-nonbyte-compile-dirs '("." ".." "alts" "nxml-mode-20041004" "old" "xtests"))

(defun nxhtmlmaint-byte-compile-dir (dir force del-elc)
  ;;(directory-files (file-name-directory buffer-file-name) t "\.el\\'")
  (dolist (el-src (directory-files dir t "\.el\\'"))
    (let ((elc-dst (concat el-src "c")))
      (if del-elc
          (when (file-exists-p elc-dst)
            (delete-file elc-dst)
            (message "Deleted %s" elc-dst))
        (when (or force (file-newer-than-file-p el-src elc-dst))
          (message "(byte-compile-file %s)" el-src)
          (unless (byte-compile-file el-src)
            (message "Couldn't compile %s" el-src))
          ))))
  (dolist (f (directory-files dir t))
    (when (file-directory-p f)
      ;; Fix-me: Avoid some dirs
      (let ((name (file-name-nondirectory f)))
        (unless (member name nxhtmlmaint-nonbyte-compile-dirs)
          (nxhtmlmaint-byte-compile-dir f force del-elc))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; nxhtml-maintenance.el ends here
