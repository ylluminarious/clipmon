;;; clipmon (clipboard monitor)
;
; Description:
; Automatically paste contents of clipboard if change detected - 
; makes it easier to take notes from web pages.
;
; Usage: 
; Call clipmon-start to start timer
; It will check the clipboard every clipmon-interval seconds 
; If clipboard has changed, paste the contents 
; If no change detected after clipmon-timeout seconds, turn off the timer 
; Or call clipmon-stop manually to turn it off 
;
; Site: https://github.com/bburns/clipmon
; Author: brian burns <bburns.km@gmail.com>
; Date: 2014-02-21


; todo:
; convert to a minor mode
; only use external clipboard, not emacs one. so can cut/rearrange text while it's running.
 


; name: clipboard monitor, clipm, clipmon, autocopy, autoclip, autopaste?
; prefix: clipm, clipmon, cmon, clipmonitor?



;;; User settings

(defcustom clipmon-interval 2
  "Interval for checking clipboard, in seconds.")

(defcustom clipmon-timeout 5
  "Stop the timer if no clipboard activity after this many minutes. Set to nil for no timeout.")

(defcustom clipmon-newlines 1
  "Number of newlines to append after pasting clipboard contents.")

(defcustom clipmon-sound t
  "Sound to play when pasting text - t for default beep, nil for none, or path to sound file.")

(defcustom clipmon-trim-string t
  "Remove leading whitespace from string before pasting.")


;;; Private variables

(defvar clipmon-timer nil "Timer handle for clipboard monitor.")
(defvar clipmon-timeout-start nil "Time that timeout timer was started.")
(defvar clipmon-previous-contents nil "Last contents of the clipboard.")


;;; Keybindings

; (setq clipmon-key "<f12>")
(setq clipmon-key "<M-f2>")

(global-set-key (kbd clipmon-key) (lambda () (interactive)
                                (if clipmon-timer (clipmon-stop) (clipmon-start))))


;;; Public functions

(defun clipmon-start () (interactive)
  "Start the clipboard monitor timer, and check the clipboard contents each interval."
  (if clipmon-timer (message "Clipboard monitor already running. Stop with %s." clipmon-key)
    (setq clipmon-previous-contents (clipboard-contents))
    (setq clipmon-timeout-start (time))
    (setq clipmon-timer (run-at-time nil clipmon-interval 'clipmon-tick))
    (message "Clipboard monitor started with timer interval %d seconds. Stop with %s." clipmon-interval clipmon-key)
    (clipmon-play-sound)
    ))

(defun clipmon-stop () (interactive)
  "Stop the clipboard monitor timer."
  (cancel-timer clipmon-timer)
  (setq clipmon-timer nil)
  (message "Clipboard monitor stopped.")
  )


;;; Private functions

(defun clipmon-tick ()
  "Check the contents of the clipboard - if they've changed, paste the contents."
  (let ((current-contents (clipboard-contents)))
    (if (not (string= current-contents clipmon-previous-contents))
        (progn
          (if clipmon-trim-string
              (insert (s-trim-left current-contents))
            (insert current-contents))
          (dotimes (i clipmon-newlines) (insert "\n"))
          (if clipmon-sound (clipmon-play-sound))
          (setq clipmon-previous-contents current-contents)
          (setq clipmon-timeout-start (time)))
        ; no change in clipboard - stop monitor if it's been idle a while
        (if clipmon-timeout
            (let ((idletime (- (time) clipmon-timeout-start)))
              (when (> idletime (* 60 clipmon-timeout))
                (clipmon-stop)
                (message "Clipboard monitor stopped after %d minutes of inactivity." clipmon-timeout)
                (beep)
                )))
        )))


(defun clipmon-play-sound ()
  "Play a sound - if clipmon-sound is t, play the default beep, otherwise
if it's a string, play the sound file at the path."
  ; (if clipmon-sound
      ; (if (stringp clipmon-sound) (play-sound-file clipmon-sound)) (beep)))
  (cond
   ((eq clipmon-sound t) (beep))
   ((stringp clipmon-sound) (play-sound-file clipmon-sound)))) ;. catch error


;;; Library

(defun clipboard-contents (&optional arg)
  "Return the current or previous clipboard contents.
With nil or 0 argument, return the most recent item.
With numeric argument, return that item.
With :all, return all clipboard contents in a list."
  (cond
   ((null arg) (current-kill 0))
   ((integerp arg) (current-kill arg))
   ((eq :all arg) kill-ring)
   (t nil)))

; test
; (clipboard-contents)
; (clipboard-contents 0)
; (clipboard-contents 9)
; (clipboard-contents :all)
; (clipboard-contents t)
; (clipboard-contents "hi")


; from https://github.com/magnars/s.el
(defun s-trim-left (s)
  "Remove whitespace at the beginning of S."
  (if (string-match "\\`[ \t\n\r]+" s)
      (replace-match "" t t s)
    s))



;;; Testing

; (setq clipmon-timeout 5)
; timer-list
; (cancel-function-timers 'clipmon-tick)


;;; Provide

(provide 'clipmon)

; eof
