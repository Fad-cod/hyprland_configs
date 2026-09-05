#!/bin/bash
layout=$(hyprctl activeworkspace | grep -oP 'layout: \K\S+')
if [ "$layout" = "scrolling" ]; then
    hyprctl dispatch layoutmsg "colresize 1.0"
else
    hyprctl dispatch fullscreen 1
fi
