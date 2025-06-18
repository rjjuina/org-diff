;;; org-diff.el --- Inline text comparison for org-mode code blocks -*- lexical-binding: t; -*-

;; Copyright (C) 2024

;; Author: org-diff
;; Version: 1.0.0
;; Package-Requires: ((emacs "31.0") (org "9.0"))
;; Keywords: convenience, text, org
;; URL: https://github.com/your-username/org-diff

;; This file is not part of GNU Emacs.

;;; Commentary:

;; org-diff provides inline text comparison within org-mode code blocks.
;; Type `<diff` followed by TAB to expand into a diff code block, then use
;; `M-x org-diff-check` to analyze and highlight differences between lines.

;;; Code:

(require 'org)
(require 'org-tempo)

(defgroup org-diff nil
  "Inline text comparison for org-mode code blocks."
  :group 'org
  :prefix "org-diff-")

(defface org-diff-added
  '((t :background "#d4edda" :foreground "#155724" :weight bold))
  "Face for highlighting different/changed characters."
  :group 'org-diff)

(defface org-diff-identical
  '((t :foreground "#6c757d"))
  "Face for dimming identical lines."
  :group 'org-diff)

(defvar org-diff-overlays nil
  "List of overlays created by org-diff.")

(defun org-diff-clear ()
  "Clear all diff highlighting."
  (interactive)
  (mapc #'delete-overlay org-diff-overlays)
  (setq org-diff-overlays nil)
  (message "Diff highlighting cleared"))

(defun org-diff--find-diff-block ()
  "Find the boundaries of the current diff block.
Returns a list (begin end) or nil if not in a diff block."
  (save-excursion
    (let ((begin nil)
          (end nil))
      ;; Look for #+begin_diff
      (when (re-search-backward "^[ \t]*#\\+begin_diff" nil t)
        (setq begin (line-beginning-position))
        ;; Look for #+end_diff
        (when (re-search-forward "^[ \t]*#\\+end_diff" nil t)
          (setq end (line-end-position))
          (list begin end))))))

(defun org-diff--get-block-lines (begin end)
  "Extract lines from diff block between BEGIN and END.
Returns a list of (line-text . line-position) pairs."
  (save-excursion
    (goto-char begin)
    (forward-line 1) ; Skip #+begin_diff
    (let ((lines '())
          (current-pos (point)))
      (while (and (< (point) end)
                  (not (looking-at "^[ \t]*#\\+end_diff")))
        (let ((line-text (buffer-substring-no-properties
                          (line-beginning-position)
                          (line-end-position))))
          (unless (string-match-p "^[ \t]*$" line-text) ; Skip empty lines
            (push (cons line-text current-pos) lines)))
        (forward-line 1)
        (setq current-pos (point)))
      (reverse lines))))

(defun org-diff--char-differences (str1 str2)
  "Find character-level differences between STR1 and STR2.
Returns a list of (start end) positions in STR1 that differ from STR2."
  (let ((differences '())
        (len1 (length str1))
        (len2 (length str2))
        (i 0))
    (while (< i (max len1 len2))
      (let ((char1 (if (< i len1) (aref str1 i) nil))
            (char2 (if (< i len2) (aref str2 i) nil)))
        (when (not (equal char1 char2))
          (let ((start i))
            ;; Find the end of the different sequence
            (while (and (< i (max len1 len2))
                        (let ((c1 (if (< i len1) (aref str1 i) nil))
                              (c2 (if (< i len2) (aref str2 i) nil)))
                          (not (equal c1 c2))))
              (setq i (1+ i)))
            (push (list start i) differences))))
      (setq i (1+ i)))
    (reverse differences)))

(defun org-diff--highlight-differences (lines)
  "Highlight differences between LINES.
LINES is a list of (line-text . line-position) pairs."
  (let ((reference-line (caar lines))) ; Use first line as reference
    (dolist (line-data lines)
      (let ((line-text (car line-data))
            (line-pos (cdr line-data)))
        (save-excursion
          (goto-char line-pos)
          (if (string-equal line-text reference-line)
              ;; Identical line - dim it
              (let ((overlay (make-overlay (line-beginning-position)
                                           (line-end-position))))
                (overlay-put overlay 'face 'org-diff-identical)
                (push overlay org-diff-overlays))
            ;; Different line - highlight differences
            (let ((differences (org-diff--char-differences line-text reference-line)))
              (dolist (diff differences)
                (let* ((start-char (car diff))
                       (end-char (cadr diff))
                       (start-pos (+ (line-beginning-position) start-char))
                       (end-pos (+ (line-beginning-position) end-char))
                       (overlay (make-overlay start-pos end-pos)))
                  (overlay-put overlay 'face 'org-diff-added)
                  (push overlay org-diff-overlays))))))))))

(defun org-diff-check ()
  "Analyze the diff block at cursor position and highlight differences."
  (interactive)
  (org-diff-clear) ; Clear existing highlights
  (let ((block-bounds (org-diff--find-diff-block)))
    (if block-bounds
        (let* ((begin (car block-bounds))
               (end (cadr block-bounds))
               (lines (org-diff--get-block-lines begin end)))
          (if (< (length lines) 2)
              (message "Need at least 2 lines to compare")
            (org-diff--highlight-differences lines)
            (message "Diff analysis complete - %d lines compared" (length lines))))
      (message "Not in a diff block"))))

;; Template expansion setup
(defun org-diff--setup-templates ()
  "Setup org-tempo templates for diff blocks."
  (add-to-list 'org-structure-template-alist '("diff" . "diff")))

;; Initialize when org-mode is loaded
(with-eval-after-load 'org
  (org-diff--setup-templates))

(provide 'org-diff)

;;; org-diff.el ends here