-- Appended to ~/.config/hypr/hyprland/keybinds.lua.
--
-- Qt only turns BTN_SIDE/BTN_EXTRA (mouse buttons 275/276) into Qt.BackButton/Qt.ForwardButton,
-- so QML never sees BTN_BACK/BTN_FORWARD (278/277) -- some mice use those for the same two
-- buttons. Route them through the shell's global shortcuts instead. `non_consuming` leaves the
-- buttons working in apps that do understand them; the shell only acts while a settings window
-- has focus.

hl.bind("mouse:278", hl.dsp.global("caelestia:nexusBack"), { non_consuming = true })
hl.bind("mouse:277", hl.dsp.global("caelestia:nexusForward"), { non_consuming = true })
