-- ### Hyprland ###
-- Apps
HOME = "/home/fadele"
terminal = "kitty"
browser = "chromium"
editor = "code"
fileExplorer = "dolphin"

-- Touchpad
touchpadDisableTyping = true
touchpadScrollFactor = 1
workspaceSwipeFingers = 4
gestureFingers = 3
gestureFingersMore = 4

-- Blur
blurEnabled = true
blurSpecialWs = false
blurPopups = false
blurInputMethods = false
blurXray = false
blurSize =1
blurPasses =2

-- Shadow
shadowEnabled = true
shadowRange = 4
shadowRenderPower = 3

-- Gaps (espace confortable entre fenêtres)
workspaceGaps = 1
windowGapsIn = 2
windowGapsOut = 2
singleWindowGapsOut = 2

-- Window styling
windowOpacity = 1.0
windowRounding = 25
windowBorderSize = 2

-- Opacity color variants (dérivés du Material You scheme)
-- scheme/current.lua (regénéré) écrase ces valeurs au chargement.
primarye6 = "ffb3aee6"
onSurfaceVariant11 = "d8c2bf11"
surfaced4 = "080303d4"
primaryd4 = "ffb3aed4"
outlined4 = "a08c8ad4"
secondaryd4 = "e7bdb9d4"

activeWindowBorderColour = "rgba(" .. primarye6 .. ")"
inactiveWindowBorderColour = "rgba(" .. onSurfaceVariant11 .. ")"
shadowColour = "rgba(" .. surfaced4 .. ")"

-- Misc
volumeStep = 1
cursorTheme = "sweet-cursors"
cursorSize = 24

-- ### Keybinds ###
-- Format: "MOD + KEY" (modificateurs en MAJUSCULES, cf. parseKeyString Hyprland)
kbMoveWinToWs = "SUPER + ALT"
kbMoveWinToWsGroup = "CTRL + SUPER + ALT"
kbGoToWs = "SUPER"
kbGoToWsGroup = "CTRL + SUPER"

kbNextWs = "CTRL + SUPER + right"
kbPrevWs = "CTRL + SUPER + left"

kbToggleSpecialWs = "SUPER + S"

-- Window groups
kbWindowGroupCycleNext = "ALT + TAB"
kbWindowGroupCyclePrev = "SHIFT + ALT + TAB"
kbUngroup = "SUPER + U"
kbToggleGroup = "SUPER + COMMA"

-- Window actions
kbMoveWindow = "SUPER + Z"
kbResizeWindow = "SUPER + X"
kbPinWindow = "SUPER + P"
kbWindowFullscreen = "SUPER + ALT + F"
kbWindowBorderedFullscreen = "SUPER + F"
kbToggleWindowFloating = "SUPER + ALT + SPACE"
kbCloseWindow = "SUPER + Q"

-- Special workspace toggles
kbMusic = "SUPER + M"
kbCommunication = "SUPER + D"
kbTodo = "SUPER + R"

-- Apps
kbTerminal = "SUPER + T"
kbBrowser = "SUPER + W"
kbEditor = "SUPER + C"
kbFileExplorer = "SUPER + E"

-- Misc
kbSession = "CTRL + ALT + DELETE"
kbLock = "SUPER + L"
kbRestoreLock = "SUPER + ALT + L"
