#!/usr/bin/env bash

set -e

echo "[1/9] Обновляем систему..."
sudo pacman -Syu --noconfirm

echo "[2/9] Устанавливаем базовые пакеты..."
sudo pacman -S --noconfirm --needed \
    i3-gaps i3status i3lock kitty thunar rofi picom polybar feh \
    ttf-dejavu ttf-font-awesome noto-fonts \
    arc-gtk-theme papirus-icon-theme lxappearance \
    zsh wget curl git unzip

echo "[3/9] Ставим oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    chsh -s $(which zsh)
fi

echo "[4/9] Настраиваем i3..."
mkdir -p ~/.config/i3
cat << 'EOF' > ~/.config/i3/config
set \$mod Mod1  # Alt как Command

# Основные хоткеи
bindsym \$mod+Return exec kitty
bindsym \$mod+d exec rofi -show drun
bindsym \$mod+Tab exec "rofi -show window"
bindsym \$mod+Shift+e exec "i3-msg exit"
bindsym \$mod+Shift+q kill

# Открытие Thunar в /
bindsym \$mod+f exec thunar /

# Плавающие окна по умолчанию
for_window [class=".*"] floating enable

# Перезапуск i3
bindsym \$mod+Shift+r restart

# Autostart
exec_always --no-startup-id feh --bg-fill ~/wallpaper.jpg
exec_always --no-startup-id picom --config ~/.config/picom.conf
exec_always --no-startup-id polybar example
EOF

echo "[5/9] Конфиг Polybar..."
mkdir -p ~/.config/polybar
cat << 'EOF' > ~/.config/polybar/config
[bar/example]
width = 100%
height = 30
background = #222
foreground = #fff
modules-left = date
modules-right = memory cpu
font-0 = "DejaVu Sans:size=10"
EOF

echo "[6/9] Конфиг Picom..."
mkdir -p ~/.config
cat << 'EOF' > ~/.config/picom.conf
backend = "glx";
vsync = true;
shadow = true;
fading = true;
blur-method = "gaussian";
EOF

echo "[7/9] Ставим тему и иконки..."
mkdir -p ~/.themes ~/.icons
lxappearance

echo "[8/9] Добавляем обои..."
wget -O ~/wallpaper.jpg https://w.wallhaven.cc/full/ym/wallhaven-ymj5j7.jpg

echo "[9/9] Готово! Перезагрузи X с i3"
echo "После перезапуска введи: startx"
