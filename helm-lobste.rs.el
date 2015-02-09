;;; helm-lobste.rs.el --- helm interface of lobste.rs.el

;; Copyright (C) 2015 by Julien Blanchard

;; Author: Julien BLANCHARD <julien@sideburns.eu>
;; URL: https://github.com/julienXX/emacs-helm-lobste.rs
;; Version: 0.01
;; Package-Requires: ((helm "1.0") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)

(require 'helm)
(require 'json)
(require 'browse-url)

(defgroup helm-lobste.rs nil
  "hacker news with helm interface"
  :group 'lobste.rs)

(defface helm-lobste.rs-title
  '((((class color) (background light))
     :foreground "red" :weight semi-bold)
    (((class color) (background dark))
     :foreground "green" :weight semi-bold))
  "face of post title"
  :group 'helm-lobste.rs)

(defvar helm-lobste.rs-url "https://lobste.rs/newest.json")

(defun helm-lobste.rs-get-posts ()
  (with-temp-buffer
    (unless (zerop (call-process "curl" nil t nil "-s" helm-lobste.rs-url))
      (error "Failed: 'curl -s %s'" helm-lobste.rs-url))
    (let* ((json nil)
           (ret (ignore-errors
                  (setq json (json-read-from-string
                              (buffer-substring-no-properties
                               (point-min) (point-max))))
                  t)))
      (unless ret
        (error "Error: Can't get JSON response"))
      json)))

(defun helm-lobste.rs-sort-predicate (a b)
  (let ((score-a (plist-get (cdr a) :score))
        (score-b (plist-get (cdr b) :score)))
    (> score-a score-b)))

(defun helm-lobste.rs-init ()
  (let ((stories (helm-lobste.rs-get-posts)))
    (sort (cl-loop for story across stories
                   for score = (assoc-default 'score story)
                   for title = (assoc-default 'title story)
                   for url = (assoc-default 'url story)
                   for comments = (assoc-default 'comment_count story)
                   for comments-url = (assoc-default 'comments_url story)
                   for cand = (format "%s %s (%d comments)"
                                      (format "[%d]" score)
                                      (propertize title 'face 'helm-lobste.rs-title)
                                      comments)
                   collect
                   (cons cand
                         (list :url url :score score :comments-url comments-url)))
          'helm-lobste.rs-sort-predicate)))

(defun helm-lobste.rs-browse-link (cand)
  (browse-url (plist-get cand :url)))

(defun helm-lobste.rs-browse-post-page (cast)
  (browse-url (plist-get cast :comments-url)))

(defvar helm-lobste.rs-source
  '((name . "Lobste.rs")
    (candidates . helm-lobste.rs-init)
    (action . (("Browse Link" . helm-lobste.rs-browse-link)
               ("Browse Post Page"  . helm-lobste.rs-browse-post-page)))
    (candidate-number-limit . 9999)))

;;;###autoload
(defun helm-lobste.rs ()
  (interactive)
  (helm :sources '(helm-lobste.rs-source) :buffer "*helm-lobste.rs*"))

(provide 'helm-lobste.rs)

;;; helm-lobste.rs.el ends here
