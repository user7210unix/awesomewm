; Thunar GtkAccelMap rc-file -*- scheme -*-
;
; Custom bindings for the Win2000-dark rig. Thunar keybindings are stored
; as a GTK accelerator map; the canonical location and mechanism are
; documented at:
;   https://docs.xfce.org/xfce/thunar/start  (see "Keyboard Shortcuts")
;   https://wiki.archlinux.org/title/Thunar  ("To configure the keybindings,
;   edit the file ~/.config/Thunar/accels.scm")
;
; Uncommented lines below are ACTIVE bindings (this is how gtk_accel_map
; files work: a leading ";" means "not set / default", removing it enables
; the mapping). Action-path names (e.g. "<Actions>/ThunarWindow/open-parent")
; are Thunar's own internal action identifiers, taken from real accel-map
; dumps rather than guessed.
;
; Explorer/Win2000-style navigation muscle memory:
(gtk_accel_path "<Actions>/ThunarWindow/open-parent" "<Alt>Up")
(gtk_accel_path "<Actions>/ThunarWindow/back" "<Alt>Left")
(gtk_accel_path "<Actions>/ThunarWindow/forward" "<Alt>Right")
(gtk_accel_path "<Actions>/ThunarWindow/reload" "F5")
(gtk_accel_path "<Actions>/ThunarStandardView/rename" "F2")
(gtk_accel_path "<Actions>/ThunarStandardView/select-all-files" "<Primary>a")
(gtk_accel_path "<Actions>/ThunarStandardView/move-to-trash" "Delete")
(gtk_accel_path "<Actions>/ThunarWindow/empty-trash" "<Primary><Shift>Delete")
(gtk_accel_path "<Actions>/ThunarWindow/new-window" "<Primary>n")
(gtk_accel_path "<Actions>/ThunarWindow/close-all-windows" "<Primary>q")
(gtk_accel_path "<Actions>/ThunarWindow/view-side-pane-shortcuts" "<Primary>b")
(gtk_accel_path "<Actions>/ThunarWindow/view-location-selector-pathbar" "<Primary>l")
(gtk_accel_path "<Actions>/ThunarLauncher/open" "<Primary>o")
(gtk_accel_path "<Actions>/ThunarStandardView/copy" "<Primary>c")
(gtk_accel_path "<Actions>/ThunarActionManager/cut" "<Primary>x")
(gtk_accel_path "<Actions>/ThunarStandardView/select-by-pattern" "<Primary>s")

; Everything else keeps Thunar's own defaults; this file is merged with
; those, it does not need to be exhaustive.
