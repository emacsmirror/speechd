;;; speechd-braille.el --- Emacs braille emulator driver

;; Copyright (C) 2004, 2005, 2006 Brailcom, o.p.s.

;; Author: Milan Zamazal <pdm@brailcom.org>

;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

;;; Code:


(require 'eieio)

(require 'braille)
(require 'mmanager)
(require 'speechd-common)
(require 'speechd-out)



(defgroup speechd-braille ()
  "speechd-el Braille output."
  :group 'speechd-el)

(defcustom speechd-braille-display-time 3
  "How many seconds to display a message before displaying the next one."
  :type 'number
  :group 'speechd-braille)


(defvar speechd-braille--vetoed-icons '("message"))


(defconst speechd-braille--empty-message '("" nil))

(defvar speechd-braille--paused-message speechd-braille--empty-message)

(defvar speechd-braille--last-message speechd-braille--empty-message)

(defvar speechd-braille--last-message-time 0)

(defvar speechd-braille--display-timer nil)


(defun speechd-braille--time ()
  (funcall (if (fboundp 'time-to-seconds)
               #'time-to-seconds
             ;; taken from time-date.el
             #'(lambda (time)
                 (+ (* (car time) 65536.0)
                    (cadr time)
                    (/ (or (nth 2 time) 0) 1000000.0))))
           (current-time)))

(defun speechd-braille--display (manager message &optional sticky)
  (speechd-braille--stop manager)
  (apply (mmanager-get manager 'braille-display) message)
  (setq speechd-braille--last-message message)
  (setq speechd-braille--last-message-time (speechd-braille--time))
  (unless sticky
    (setq speechd-braille--display-timer
          (run-at-time speechd-braille-display-time nil
                       #'mmanager-next manager))))

(defun speechd-braille--stop (manager)
  (when speechd-braille--display-timer
    (cancel-timer speechd-braille--display-timer))  
  (setq speechd-braille--display-timer nil))

(defun speechd-braille--pause (manager)
  (setq speechd-braille--paused-message speechd-braille--last-message))

(defun speechd-braille--resume (manager)
  (speechd-braille--display manager speechd-braille--paused-message)
  (setq speechd-braille--paused-message speechd-braille--empty-message))

(defun speechd-braille--busy (manager)
  (and speechd-braille--display-timer
       (< (- (speechd-braille--time) speechd-braille--last-message-time)
          speechd-braille-display-time)))

(defun speechd-braille--create-manager (display-func)
  (let ((manager (mmanager-create display-func
                                  #'speechd-braille--stop
                                  #'speechd-braille--pause
                                  #'speechd-braille--resume
                                  #'speechd-braille--busy)))
    (mmanager-put manager 'braille-display #'braille-display)
    manager))

(defun speechd-braille--maybe-enqueue (driver text message)
  (with-slots (manager priority) driver
    (if speechd.update
        (mmanager-enqueue manager speechd-client-name
                          (speechd-braille--make-message
                           driver
                           (speechd-out-update-text speechd.update)
                           (speechd-out-update-cursor speechd.update))
                          priority (speechd-out-update-group speechd.update))
      (unless (string= text "")
        (mmanager-enqueue manager speechd-client-name message priority)))))

;;; Interface functions

(defclass speechd-braille-emu-driver (speechd-driver)
  ((name :initform 'braille-emu)
   (manager :initform (lambda () (speechd-braille--create-manager
                                  #'speechd-braille--display)))
   (priority :initform (lambda () speechd-default-text-priority))))

(defmethod speechd-braille--make-message
    ((driver speechd-braille-emu-driver) text cursor)
  (list text cursor))

(defmethod speechd.cancel ((driver speechd-braille-emu-driver) all)
  (mmanager-cancel (slot-value driver 'manager) speechd-client-name))

(defmethod speechd.stop ((driver speechd-braille-emu-driver) all)
  (mmanager-next (slot-value driver 'manager)))

(defmethod speechd.pause ((driver speechd-braille-emu-driver) all)
  ;; do nothing
  )

(defmethod speechd.resume ((driver speechd-braille-emu-driver) all)
  ;; do nothing
  )

(defmethod speechd.repeat ((driver speechd-braille-emu-driver))
  ;; do nothing
  )

(defmethod speechd.block-begin ((driver speechd-braille-emu-driver))
  (mmanager-start-block (slot-value driver 'manager) speechd-client-name
                        (slot-value driver 'priority)))

(defmethod speechd.block-end ((driver speechd-braille-emu-driver))
  (mmanager-finish-block (slot-value driver 'manager) speechd-client-name))

(defmethod speechd.text ((driver speechd-braille-emu-driver) text cursor)
  (speechd-braille--maybe-enqueue
   driver text (speechd-braille--make-message driver text cursor)))

(defmethod speechd.icon ((driver speechd-braille-emu-driver) icon)
  (unless (member icon speechd-braille--vetoed-icons)
    (speechd-braille--maybe-enqueue
     driver icon (speechd-braille--make-message driver icon nil))))

(defmethod speechd.char ((driver speechd-braille-emu-driver) char)
  (let ((text (char-to-string char)))
    (speechd-braille--maybe-enqueue
     driver text (speechd-braille--make-message driver text nil))))

(defmethod speechd.key ((driver speechd-braille-emu-driver) key)
  (let ((key-string (format (if (numberp key) "%c" "%s") key)))
    (speechd-braille--maybe-enqueue
     driver key-string (speechd-braille--make-message driver key-string nil))))

(defmethod speechd.set ((driver speechd-braille-emu-driver) parameter value)
  (when (eq parameter 'priority)
    (setf (slot-value driver 'priority) value)))

(defmethod speechd.shutdown ((driver speechd-braille-emu-driver))
  ;; do nothing
  )


(speechd-out-register-driver (make-instance 'speechd-braille-emu-driver))


;;; Announce

(provide 'speechd-braille)


;;; speechd-braille.el ends here
