#!/usr/bin/env bash

set -e

echo "🚀 Удаляем старый конфиг i3..."
rm -rf ~/.config/i3
mkdir -p ~/.config/i3

echo "📦 Обновляем систему и ставим пакеты..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm i3-wm i3status i3lock dmenu rofi alacritty zsh fzf

echo "🎨 Ставим тему и шрифты..."
sudo pacman -S --noconfirm arc-gtk-theme ttf-jetbrains-mono ttf-font-awesome

echo "⚡ Настраиваем i3..."
cat > ~/.config/i3/config <<'EOF'
# МОДИФИКАТОР (Alt вместо Win)
set \$mod Mod1

# ТЕРМИНАЛ
bindsym \$mod+Return exec alacritty

# ВЫХОД
bindsym \$mod+Shift+e exec "i3-msg exit"

# РЕСТАРТ i3
bindsym \$mod+Shift+r restart

# СПИСОК ОКОН (Alt+Tab)
bindsym \$mod+Tab exec rofi -show window

# МЕНЮ (Alt+D)
bindsym \$mod+d exec rofi -show drun

# ОТКРЫТЬ ДОМАШНЮЮ ПАПКУ (Alt+F)
bindsym \$mod+f exec alacritty --working-directory \$HOME

# ОТКРЫТЬ ЗАГРУЗКИ (Alt+Shift+F)
bindsym \$mod+Shift+f exec alacritty --working-directory \$HOME/Загрузки

# СПОТЛАЙТ (Alt+Space)
bindsym \$mod+space exec rofi -show run

# УПРАВЛЕНИЕ ОКНАМИ
bindsym \$mod+h focus left
bindsym \$mod+l focus right
bindsym \$mod+k focus up
bindsym \$mod+j focus down

bindsym \$mod+Shift+h move left
bindsym \$mod+Shift+l move right
bindsym \$mod+Shift+k move up
bindsym \$mod+Shift+j move down

# WORKSPACES
set \$ws1 "1"
set \$ws2 "2"
set \$ws3 "3"

bindsym \$mod+1 workspace \$ws1
bindsym \$mod+2 workspace \$ws2
bindsym \$mod+3 workspace \$ws3

# ВНЕШНИЙ ВИД
new_window pixel 2
font pango:JetBrains Mono 12
client.focused      #4c7899 #285577 #ffffff #2e9ef4 #285577
client.unfocused    #333333 #222222 #888888 #292d2e #222222
EOF

echo "✅ Конфиг i3 обновлён!"

echo "⚡ Делаем zsh по умолчанию..."
chsh -s $(which zsh)

echo "🎉 Готово! Перезагрузись или перезапусти i3 (Mod+Shift+R)."
