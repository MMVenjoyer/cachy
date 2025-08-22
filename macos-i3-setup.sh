#!/usr/bin/env bash

set -e

echo "=== Обновляем пакеты ==="
sudo pacman -Syu --noconfirm

echo "=== Ставим i3, rofi, picom, thunar, zsh, темы и иконки ==="
sudo pacman -S --noconfirm i3 rofi picom thunar zsh wget unzip git \
    arc-gtk-theme papirus-icon-theme ttf-font-awesome

echo "=== Делаем zsh основным шеллом ==="
chsh -s $(which zsh)

echo "=== Настраиваем i3 конфиг ==="
mkdir -p ~/.config/i3

cat > ~/.config/i3/config <<'EOF'
# Основной мод (Alt вместо Win)
set $mod Mod1

# Терминал
bindsym $mod+Return exec alacritty

# Закрыть окно
bindsym $mod+Shift+q kill

# Перезапуск i3
bindsym $mod+Shift+r restart

# Rofi как Spotlight
bindsym $mod+d exec rofi -show drun

# Переключение окон (Alt+Tab)
bindsym $mod+Tab workspace next
bindsym $mod+Shift+Tab workspace prev

# Файловый менеджер (Alt+e)
bindsym $mod+e exec thunar

# Разметка окон
bindsym $mod+f fullscreen toggle

# Перемещение между окнами
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Перемещение окон
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Старт picom (эффекты)
exec_always --no-startup-id picom --experimental-backends
EOF

echo "=== Ставим тему WhiteSur GTK ==="
mkdir -p ~/Themes
cd ~/Themes
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
./install.sh -n WhiteSur -c Light -t all

echo "=== Ставим иконки WhiteSur ==="
cd ~/Themes
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh

echo "=== Применяем GTK тему ==="
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Light"
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"

echo "=== Устанавливаем oh-my-zsh ==="
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "=== Готово! Перезапусти сессию или i3 (Mod+Shift+r) ==="
