#!/bin/bash
COLORS="$HOME/.cache/ambxst/colors.json"
SCHEME="$HOME/.config/hypr/scheme/current.conf"
DEFAULT="$HOME/.config/hypr/scheme/default.conf"
SCHEME_LUA="$HOME/.config/hypr/scheme/current.lua"
DEFAULT_LUA="$HOME/.config/hypr/scheme/default.lua"

[ -f "$COLORS" ] || exit 1
[ -f "$DEFAULT" ] || exit 1

cp "$DEFAULT" "$SCHEME"
if [ -f "$DEFAULT_LUA" ]; then
  cp "$DEFAULT_LUA" "$SCHEME_LUA"
fi

read -r primary surface onSurfaceVariant outline secondary tertiary overSurface error overPrimary < <(
  jq -r '[.primary,.surface,.overSurfaceVariant,.outline,.secondary,.tertiary,.overSurface,.error,.overPrimary]
         | map(gsub("^#";"")) | @tsv' "$COLORS"
)

cat >> "$SCHEME" << EOF

# Opacity color variants (regenerated from ambxst colors.json)
\$primarye6 = ${primary}e6
\$onSurfaceVariant11 = ${onSurfaceVariant}11
\$surfaced4 = ${surface}d4
\$primaryd4 = ${primary}d4
\$outlined4 = ${outline}d4
\$secondaryd4 = ${secondary}d4
EOF

if [ -f "$SCHEME_LUA" ]; then
cat >> "$SCHEME_LUA" << EOF

-- Opacity color variants (regenerated from ambxst colors.json)
primarye6 = "${primary}e6"
onSurfaceVariant11 = "${onSurfaceVariant}11"
surfaced4 = "${surface}d4"
primaryd4 = "${primary}d4"
outlined4 = "${outline}d4"
secondaryd4 = "${secondary}d4"

activeWindowBorderColour = "rgba(" .. primarye6 .. ")"
inactiveWindowBorderColour = "rgba(" .. onSurfaceVariant11 .. ")"
shadowColour = "rgba(" .. surfaced4 .. ")"
EOF
fi

# --- Fastfetch full config (cached) ---
FFBASE="$HOME/.config/fastfetch/config.jsonc"
FFCACHE="$HOME/.cache/ambxst/fastfetch.jsonc"
mkdir -p "$(dirname "$FFCACHE")"



if [ -f "$FFBASE" ]; then

pk_r=$((16#${primary:0:2})); pk_g=$((16#${primary:2:2})); pk_b=$((16#${primary:4:2}))
os_r=$((16#${overSurface:0:2})); os_g=$((16#${overSurface:2:2})); os_b=$((16#${overSurface:4:2}))
tt_r=$((16#${tertiary:0:2})); tt_g=$((16#${tertiary:2:2})); tt_b=$((16#${tertiary:4:2}))
sc_r=$((16#${secondary:0:2})); sc_g=$((16#${secondary:2:2})); sc_b=$((16#${secondary:4:2}))

jq \
  --arg pk "#$primary" \
  --arg os "#$overSurface" \
  --arg ol "#$outline" \
  --argjson pk_r "$pk_r" --argjson pk_g "$pk_g" --argjson pk_b "$pk_b" \
  --argjson os_r "$os_r" --argjson os_g "$os_g" --argjson os_b "$os_b" \
  --argjson tt_r "$tt_r" --argjson tt_g "$tt_g" --argjson tt_b "$tt_b" \
  --argjson sc_r "$sc_r" --argjson sc_g "$sc_g" --argjson sc_b "$sc_b" \
  '
    .display.color.keys = $pk
    | .display.color.title = $pk
    | .display.color.output = $os
    | .display.color.separator = $ol
    | .display.constants = [
        "\u001b[38;2;\($os_r);\($os_g);\($os_b)m",
        "\u001b[38;2;\($pk_r);\($pk_g);\($pk_b)m",
        "\u001b[38;2;\($tt_r);\($tt_g);\($tt_b)m",
        "\u001b[38;2;\($sc_r);\($sc_g);\($sc_b)m"
      ]
  ' "$FFBASE" > "$FFCACHE"
fi

# --- KDE color scheme ---
KDE_SCHEMES="$HOME/.local/share/color-schemes"
KDE_FILE="$KDE_SCHEMES/Ambxst.colors"
mkdir -p "$KDE_SCHEMES"



hex_to_dec() { echo "$((16#${1:0:2})),$((16#${1:2:2})),$((16#${1:4:2}))"; }
bg_dec=$(hex_to_dec "$surface")
fg_dec=$(hex_to_dec "$overSurface")
surf_dec=$(hex_to_dec "$surface")
pri_dec=$(hex_to_dec "$primary")
sec_dec=$(hex_to_dec "$secondary")
err_dec=$(hex_to_dec "$error")
ina_dec=$(hex_to_dec "$outline")
ter_dec=$(hex_to_dec "$tertiary")
lnk_dec=$(hex_to_dec "$tertiary")
sel_dec=$(hex_to_dec "$primary")
sfg_dec=$(hex_to_dec "$overPrimary")

cat > "$KDE_FILE" <<- KEOF
[ColorEffects:Disabled]
Color=$bg_dec
ColorAmount=0.5
ColorEffect=3
ContrastAmount=0
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=$bg_dec
ColorAmount=0.025
ColorEffect=0
ContrastAmount=0.1
ContrastEffect=0
Enable=true
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=$surf_dec
BackgroundNormal=$surf_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Complementary]
BackgroundAlternate=$bg_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Header]
BackgroundAlternate=$bg_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Header][Inactive]
BackgroundAlternate=$bg_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Selection]
BackgroundAlternate=$sel_dec
BackgroundNormal=$sel_dec
DecorationFocus=$sel_dec
DecorationHover=$sel_dec
ForegroundActive=$sfg_dec
ForegroundInactive=$sfg_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$sfg_dec
ForegroundNormal=$sfg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Tooltip]
BackgroundAlternate=$surf_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:View]
BackgroundAlternate=$surf_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[Colors:Window]
BackgroundAlternate=$surf_dec
BackgroundNormal=$bg_dec
DecorationFocus=$pri_dec
DecorationHover=$pri_dec
ForegroundActive=$fg_dec
ForegroundInactive=$ina_dec
ForegroundLink=$lnk_dec
ForegroundNegative=$err_dec
ForegroundNeutral=$fg_dec
ForegroundNormal=$fg_dec
ForegroundPositive=$sec_dec
ForegroundVisited=$ter_dec

[General]
ColorScheme=Ambxst
Name=Ambxst
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=$bg_dec
activeBlend=252,252,252
activeForeground=$fg_dec
inactiveBackground=$surf_dec
inactiveBlend=161,169,177
inactiveForeground=$ina_dec
KEOF

# Apply KDE color scheme if currently using Ambxst or MkosBigSurDark
current_scheme=$(grep -i "^ColorScheme" "$HOME/.config/kdeglobals" 2>/dev/null | head -1 | cut -d= -f2 | tr -d ' ')
if [ "$current_scheme" = "MkosBigSurDark" ] || [ "$current_scheme" = "Ambxst" ] || [ -z "$current_scheme" ]; then
  # Strip color sections from kdeglobals + inject ColorScheme=Ambxst
  awk '
    /^\[(ColorEffects|Colors|WM|KDE)\]/ { skip=1; next }
    /^\[/ && skip { skip=0 }
    /^[Cc]olor[Ss]cheme[= ]/ { next }
    /^\[General\]/ { print; print "ColorScheme=Ambxst"; next }
    !skip { print }
  ' "$HOME/.config/kdeglobals" > "$HOME/.config/kdeglobals.tmp" && mv "$HOME/.config/kdeglobals.tmp" "$HOME/.config/kdeglobals"

  # Ensure GTK theme is dark
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

  # Notify KDE apps to reload colors
  dbus-send --session --dest=org.kde.KGlobalSettings --type=method_call \
    /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
fi

# Ensure ColorScheme key is set (more robust than manual awk edits)
if command -v kwriteconfig5 >/dev/null 2>&1; then
  kwriteconfig5 --file kdeglobals --group General --key ColorScheme Ambxst || true
fi

# Notify KDE apps to reload colors (use qdbus if present, dbus-send fallback)
if command -v qdbus >/dev/null 2>&1; then
  qdbus org.kde.KGlobalSettings /KGlobalSettings org.kde.KGlobalSettings.notifyChange 0 0 >/dev/null 2>&1 || true
else
  dbus-send --session --dest=org.kde.KGlobalSettings --type=method_call \
    /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
fi


# --- Generate btop theme ---
BTOP_THEME="$HOME/.config/btop/themes/ambxst.theme"
mkdir -p "$(dirname "$BTOP_THEME")"

# Extract all necessary colors from colors.json
read -r background onBackground primary secondary tertiary error cyan blue magenta green yellow red surface surfaceBright surfaceDim overBackground overPrimary < <(
  jq -r '[.background,.onBackground,.primary,.secondary,.tertiary,.error,.cyan,.blue,.magenta,.green,.yellow,.red,.surface,.surfaceBright,.surfaceDim,.overBackground,.overPrimary]
         | map(select(. != null) | gsub("^#";"")) | @tsv' "$COLORS"
)

cat > "$BTOP_THEME" << TEOF
# Ambxst theme for btop (dynamically generated)
# Generated from $COLORS

# Main background
theme[main_bg]=#${background}

# Main text color
theme[main_fg]=#${onBackground}

# Title color for boxes
theme[title]=#${primary}

# Highlight color for keyboard shortcuts
theme[hi_fg]=#${secondary}

# Background color of selected item in processes box
theme[selected_bg]=#${surface}

# Foreground color of selected item in processes box
theme[selected_fg]=#${primary}

# Color of inactive/disabled text
theme[inactive_fg]=#${surfaceDim}

# Color of text appearing on top of graphs
theme[graph_text]=#${primary}

# Background color of the percentage meters
theme[meter_bg]=#${surface}

# Misc colors for processes box
theme[proc_misc]=#${primary}

# CPU, Memory, Network, Proc box outline colors
theme[cpu_box]=#${blue}
theme[mem_box]=#${magenta}
theme[net_box]=#${cyan}
theme[proc_box]=#${onBackground}

# Box divider line and small boxes line color
theme[div_line]=#${surfaceBright}

# Temperature graph color (Green -> Yellow -> Red)
theme[temp_start]=#${green}
theme[temp_mid]=#${yellow}
theme[temp_end]=#${red}

# CPU graph colors
theme[cpu_start]=#${cyan}
theme[cpu_mid]=#${blue}
theme[cpu_end]=#${magenta}

# Mem/Disk free meter
theme[free_start]=#${cyan}
theme[free_mid]=#${blue}
theme[free_end]=#${magenta}

# Mem/Disk cached meter
theme[cached_start]=#${blue}
theme[cached_mid]=#${magenta}
theme[cached_end]=#${red}

# Mem/Disk available meter
theme[available_start]=#${cyan}
theme[available_mid]=#${green}
theme[available_end]=#${error}

# Mem/Disk used meter
theme[used_start]=#${magenta}
theme[used_mid]=#${blue}
theme[used_end]=#${cyan}

# Download graph colors
theme[download_start]=#${cyan}
theme[download_mid]=#${green}
theme[download_end]=#${error}

# Upload graph colors
theme[upload_start]=#${magenta}
theme[upload_mid]=#${blue}
theme[upload_end]=#${cyan}

# Process box color gradient
theme[process_start]=#${cyan}
theme[process_mid]=#${blue}
theme[process_end]=#${magenta}
TEOF

