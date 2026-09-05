-- Keybinds overrides — remplace certains binds par défaut d'Ambxst
-- La base ambxst (SUPER + Super_L launcher, etc.) est chargée avant ce fichier.

-- Supprime les binds ambxst conflictuels
hl.unbind("SUPER + C")
hl.unbind("SUPER + L")

-- Apps
hl.bind(kbTerminal, hl.dsp.exec_cmd(terminal))
hl.bind(kbBrowser, hl.dsp.exec_cmd(browser))
hl.bind(kbEditor, hl.dsp.exec_cmd(editor))
hl.bind("SUPER + G", hl.dsp.exec_cmd("nice -n -5 github-desktop"))
hl.bind(kbFileExplorer, hl.dsp.exec_cmd(fileExplorer))
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd("nice -n -5 nemo"))
hl.bind("CTRL + ALT + ESCAPE", hl.dsp.exec_cmd("nice -n -5 qps"))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("pavucontrol"))

-- Colour picker (ambxst utilise Super+Shift+C pour config)
hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd("hyprpicker -a"))

-- Volume — ambxst gère +10%, on garde juste le mic mute
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Lock (remplace le loginctl d'Ambxst par ambxst lock)
hl.bind(kbLock, hl.dsp.exec_cmd("ambxst lock"))

-- Sleep
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"), { locked = true })

-- Power profiles (customize for your monitor)
-- hl.bind("SUPER + F10", hl.dsp.exec_cmd('powerprofilesctl set power-saver && notify-send "Power" "Power Saver"'))
-- hl.bind("SUPER + F11", hl.dsp.exec_cmd('powerprofilesctl set balanced && notify-send "Power" "Balanced"'))
-- hl.bind("SUPER + F12", hl.dsp.exec_cmd('powerprofilesctl set performance && notify-send "Power" "Performance"'))

-- Utilitaires
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("nice -n -5 foot --app-id btop btop"))
hl.bind(kbPrevWs, hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(kbNextWs, hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + PAGE_UP", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + PAGE_DOWN", hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + PAGE_UP", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + PAGE_DOWN", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SHIFT + ALT + V", hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'), { locked = true })

-- Gestion fenêtres
hl.bind(kbCloseWindow, hl.dsp.window.close())
hl.bind("SUPER + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_class_opacity.sh"))
hl.bind("SUPER + F", function()
    if hl.get_active_workspace().tiled_layout == "scrolling" then
        hl.dispatch(hl.dsp.layout("colresize 1.0"))
    else
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
    end
end)

hl.bind("SUPER + ALT + F", function()
    hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle", layout_aware = false }))
end)

-- Sleep toggle (inhibition veille)
hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-sleep.sh"))
