#!/bin/bash

# Power menu script for waybar

option=$(echo -e "  Выключить\n  Перезагрузить\n  Выйти\n  Заблокировать" | wofi --dmenu --prompt "Питание" --width 250 --height 200)

case $option in
    "  Выключить")
        systemctl poweroff
        ;;
    "  Перезагрузить")
        systemctl reboot
        ;;
    "  Выйти")
        hyprctl dispatch exit
        ;;
    "  Заблокировать")
        hyprlock
        ;;
esac
