;;; speechd-ssip.el --- SSIP driver

;; Copyright (C) 2004 Brailcom, o.p.s.

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
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Code:


(require 'eieio)

(require 'speechd)
(require 'speechd-out)


(defclass speechd-ssip-driver (speechd-driver)
  ((name :initform 'ssip)
   (host :initform speechd-host :initarg :host)
   (port :initform speechd-port :initarg :port)))
  
(defmethod speechd.cancel ((driver speechd-ssip-driver))
  (speechd-cancel))

(defmethod speechd.stop ((driver speechd-ssip-driver))
  (speechd-stop))

(defmethod speechd.pause ((driver speechd-ssip-driver))
  (speechd-pause))

(defmethod speechd.resume ((driver speechd-ssip-driver))
  (speechd-resume))

(defmethod speechd.repeat ((driver speechd-ssip-driver))
  (speechd-repeat))

(defmethod speechd.block-begin ((driver speechd-ssip-driver))
  (speechd--send-command '("BLOCK BEGIN")))

(defmethod speechd.block-end ((driver speechd-ssip-driver))
  (speechd--send-command '("BLOCK END")))

(defmethod speechd.text ((driver speechd-ssip-driver) text cursor)
  (speechd-say-text text))

(defmethod speechd.icon ((driver speechd-ssip-driver) icon)
  (speechd-say-sound icon))

(defmethod speechd.char ((driver speechd-ssip-driver) char)
  (speechd-say-char char))

(defmethod speechd.key ((driver speechd-ssip-driver) key)
  (speechd-say-key key))

(defmethod speechd.set ((driver speechd-ssip-driver) parameter value)
  (when (eq parameter 'priority)
    (setq parameter 'message-priority))
  (speechd--set-parameter parameter value))

(defmethod speechd.shutdown ((driver speechd-ssip-driver))
  (speechd-close-all))


(speechd-out-register-driver (make-instance 'speechd-ssip-driver))


;;; Announce

(provide 'speechd-ssip)


;;; speechd-ssip.el ends here