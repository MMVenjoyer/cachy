#!/usr/bin/env bash

set -e

echo "🚀 Устанавливаю i3 + macOS-стиль..."

# === 1. Обновление системы и установка базового софта ===
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm i3-wm i3status i3lock dmenu rofi thunar alacritty \
  picom feh zsh unzip wget git lxappearance arc-gtk-theme \
  papirus-icon-theme ttf-dejavu ttf-font-awesome ttf-jetbrains-mono

# === 2. Ставим yay для AUR пакетов (если нет) ===
if ! command -v yay &>/dev/null; then
  echo "Устанавливаю yay..."
  sudo pacman -S --noconfirm --needed base-devel
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay && makepkg -si --noconfirm
fi

# === 3. Ставим oh-my-zsh и powerlevel10k ===
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Устанавливаю oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "Ставлю Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# === 4. Делаем zsh шеллом по умолчанию ===
chsh -s $(which zsh)

# === 5. Настройка i3 ===
mkdir -p ~/.config/i3
cat > ~/.config/i3/config << 'EOF'
set $mod Mod1  # Alt как Command
font pango:JetBrains Mono 10

# Терминал
bindsym $mod+Return exec alacritty

# Перезапуск i3
bindsym $mod+Shift+r restart

# Закрыть окно
bindsym $mod+q kill

# Запуск приложений (Spotlight)
bindsym $mod+d exec rofi -show drun

# Открыть Thunar (файловый менеджер)
bindsym $mod+e exec thunar

# Открыть Downloads
bindsym $mod+Shift+e exec thunar ~/Загрузки

# Менеджер рабочих столов
bindsym $mod+Tab workspace next

# Менеджер окон по стрелкам
bindsym $mod+Left focus left
bindsym $mod+Right focus right
bindsym $mod+Up focus up
bindsym $mod+Down focus down

# Перемещение окон
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Down move down

# Разметка
bindsym $mod+f fullscreen toggle
bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Перезагрузка конфигурации
bindsym $mod+Shift+c reload

# Запуск браузера
bindsym $mod+b exec firefox

# Фон через feh
exec_always --no-startup-id feh --bg-scale ~/Pictures/wallpaper.jpg

# Compton для теней и прозрачности
exec_always --no-startup-id picom --experimental-backends
EOF

# === 6. Темы и шрифты (WhiteSur GTK + иконки) ===
yay -S --noconfirm whitesur-gtk-theme whitesur-icon-theme

# === 7. Скачиваем красивый обой (macOS Big Sur) ===
mkdir -p ~/Pictures
wget -O ~/Pictures/wallpaper.jpg https://images.unsplash.com/photo-1605902711622-cfb43c4437d9?auto=format&fit=crop&w=1920&q=80

# === 8. Настройка прозрачности в Alacritty ===
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
window:
  opacity: 0.9

font:
  normal:
    family: "JetBrains Mono"
    style: Regular
  size: 12.0
EOF

# === 9. Настройка Zsh с Powerlevel10k ===
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

echo "✅ Готово! Перезагрузи сессию и выбери i3 в логине."
echo "Совет: после первого входа открой терминал и запусти: p10k configure"
