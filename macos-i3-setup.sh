#!/bin/bash

# macOS-style i3 Setup Script for CachyOS
# Автоматическая установка и настройка i3 с macOS-подобным интерфейсом

set -e

echo "🍎 Установка macOS-подобного i3 окружения на CachyOS..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка что запущено под обычным пользователем
if [ "$EUID" -eq 0 ]; then
    print_error "Не запускайте скрипт под root! Используйте обычного пользователя."
    exit 1
fi

print_status "Обновление системы..."
sudo pacman -Syu --noconfirm

print_status "Определение аудиосистемы..."
# Проверяем что установлено - PulseAudio или PipeWire
if systemctl --user is-active --quiet pipewire-pulse.service || pgrep -f pipewire > /dev/null; then
    print_status "Обнаружен PipeWire, используем pipewire-pulse..."
    AUDIO_SYSTEM="pipewire"
    sudo pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa pavucontrol
elif pgrep -f pulseaudio > /dev/null; then
    print_status "Обнаружен PulseAudio..."
    AUDIO_SYSTEM="pulseaudio"
    sudo pacman -S --needed --noconfirm pulseaudio pulseaudio-alsa pavucontrol
else
    print_status "Аудиосистема не обнаружена, устанавливаем PipeWire (современное решение)..."
    AUDIO_SYSTEM="pipewire"
    # Удаляем PulseAudio если установлен
    sudo pacman -Rns --noconfirm pulseaudio pulseaudio-alsa 2>/dev/null || true
    sudo pacman -S --needed --noconfirm pipewire pipewire-pulse pipewire-alsa pavucontrol wireplumber
fi

print_status "Установка основных пакетов..."
sudo pacman -S --noconfirm \
    i3-wm i3status i3lock \
    rofi \
    picom \
    feh \
    thunar thunar-volman thunar-archive-plugin \
    alacritty \
    polybar \
    dunst \
    playerctl \
    brightnessctl \
    network-manager-applet \
    blueman \
    lxappearance \
    gtk-engine-murrine \
    papirus-icon-theme \
    ttf-fira-code \
    ttf-roboto \
    ttf-dejavu \
    noto-fonts \
    noto-fonts-emoji \
    maim \
    xclip \
    redshift \
    arandr \
    neofetch \
    htop \
    firefox \
    python-pip \
    python-i3ipc \
    base-devel \
    git

print_status "Проверка наличия AUR helper..."
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    print_status "Установка AUR helper (yay)..."
    # Проверяем зависимости для сборки
    sudo pacman -S --needed --noconfirm base-devel git
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    AUR_HELPER="yay"
fi
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    AUR_HELPER="yay"
fi

print_status "Установка дополнительных пакетов из AUR..."
# Альтернативы для основных пакетов если AUR недоступен
if command -v $AUR_HELPER &> /dev/null; then
    print_status "Установка через $AUR_HELPER..."
    $AUR_HELPER -S --noconfirm \
        sf-pro-display-fonts \
        rofi-calc \
        i3-gaps-next-git \
        autotiling \
        arc-gtk-theme-git || {
        print_warning "Некоторые AUR пакеты не установились, используем альтернативы..."
        # Устанавливаем альтернативы из официальных репозиториев
        sudo pacman -S --noconfirm i3-gaps || sudo pacman -S --noconfirm i3-wm
    }
else
    print_warning "AUR helper недоступен, используем пакеты из официальных репозиториев..."
    sudo pacman -S --noconfirm i3-gaps || print_warning "i3-gaps недоступен, используется обычный i3"
    
    # Создаем autotiling скрипт вручную
    print_status "Создание autotiling скрипта..."
    sudo pip install autotiling 2>/dev/null || {
        print_warning "pip недоступен, создаем простой autotiling скрипт..."
        cat > ~/.local/bin/autotiling << 'AUTOTILING_EOF'
#!/usr/bin/env python3
import i3ipc
import sys

def on_window_focus(ipc, event):
    try:
        focused = ipc.get_tree().find_focused()
        if focused.parent.layout in ['splitv', 'splith']:
            if focused.rect.width > focused.rect.height:
                focused.parent.command('split v')
            else:
                focused.parent.command('split h')
    except:
        pass

def main():
    ipc = i3ipc.Connection()
    ipc.on('window::focus', on_window_focus)
    ipc.main()

if __name__ == '__main__':
    main()
AUTOTILING_EOF
        chmod +x ~/.local/bin/autotiling
        mkdir -p ~/.local/bin
    }
fi

print_status "Настройка шрифтов..."
# Используем системные шрифты если SF Pro недоступен
FONT_FAMILY="SF Pro Display"
if ! fc-list | grep -i "sf pro" > /dev/null 2>&1; then
    print_warning "SF Pro Display недоступен, используем Roboto"
    FONT_FAMILY="Roboto"
fi
# Создание директорий конфигурации
print_status "Создание директорий конфигурации..."
mkdir -p ~/.config/{i3,polybar,rofi,picom,dunst,alacritty}
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/Pictures/Wallpapers

print_status "Создание конфигурации i3..."
cat > ~/.config/i3/config << 'EOF'
# i3 config file (v4) - macOS Style
# Модификатор: Cmd (Super) как в macOS
set $mod Mod4
set $alt Mod1

# Шрифт
font pango:$FONT_FAMILY 11

# Автозапуск
exec --no-startup-id picom
exec --no-startup-id dunst
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id redshift -l 51.1694:71.4491 # Координаты Кокшетау
exec --no-startup-id feh --bg-scale ~/Pictures/Wallpapers/wallpaper.jpg
exec --no-startup-id polybar main
exec_always --no-startup-id ~/.local/bin/autotiling 2>/dev/null || echo "autotiling недоступен"

# Цвета в стиле macOS
set $bg-color            #2c3e50
set $inactive-bg-color   #34495e
set $text-color          #ecf0f1
set $inactive-text-color #95a5a6
set $urgent-bg-color     #e74c3c
set $indicator-color     #3498db

# Настройка окон
client.focused          $bg-color           $bg-color          $text-color          $indicator-color
client.unfocused        $inactive-bg-color  $inactive-bg-color $inactive-text-color $indicator-color
client.focused_inactive $inactive-bg-color  $inactive-bg-color $inactive-text-color $indicator-color
client.urgent           $urgent-bg-color    $urgent-bg-color   $text-color          $indicator-color

hide_edge_borders both

# Гапы как в macOS
gaps inner 12
gaps outer 6
smart_gaps on
smart_borders on

# Плавающие окна по умолчанию (как в macOS)
for_window [class=".*"] floating enable

# Хоткеи в стиле macOS
# Cmd+Return = терминал
bindsym $mod+Return exec alacritty

# Cmd+Q = закрыть окно
bindsym $mod+q kill

# Cmd+Space = Spotlight (rofi)
bindsym $mod+space exec rofi -show drun

# Cmd+Tab = переключение окон
bindsym $mod+Tab exec rofi -show window

# Cmd+Shift+3 = скриншот всего экрана
bindsym $mod+Shift+3 exec maim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Cmd+Shift+4 = скриншот выделенной области
bindsym $mod+Shift+4 exec maim -s ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Cmd+Shift+L = блокировка экрана
bindsym $mod+Shift+l exec i3lock -c 000000

# Управление яркостью
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-

# Управление звуком (работает и с PulseAudio и с PipeWire)
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Управление музыкой
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Файловый менеджер
bindsym $mod+Shift+f exec thunar

# Настройки
bindsym $mod+comma exec lxappearance

# Перезагрузка конфига
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# Выход
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Do you want to exit i3?' -B 'Yes' 'i3-msg exit'"

# Фокус окон
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Перемещение окон
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Разделение окон
bindsym $mod+h split h
bindsym $mod+v split v

# Полноэкранный режим
bindsym $mod+f fullscreen toggle

# Переключение между тайловым и плавающим режимом
bindsym $mod+Shift+space floating toggle

# Воркспейсы
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# Изменение размера окон
mode "resize" {
    bindsym Left resize shrink width 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt

    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"
EOF

print_status "Создание конфигурации Polybar..."
cat > ~/.config/polybar/config.ini << 'EOF'
[colors]
background = #1a1a1a
background-alt = #373B41
foreground = #C5C8C6
primary = #0080ff
secondary = #8ABEB7
alert = #A54242
disabled = #707880

[bar/main]
width = 100%
height = 28
radius = 0
fixed-center = true

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 2

border-size = 0
border-color = #00000000

padding-left = 2
padding-right = 2

module-margin-left = 1
module-margin-right = 2

font-0 = SF Pro Display:size=10;1
font-1 = Font Awesome 6 Free:style=Solid:size=10;1
font-2 = Font Awesome 6 Brands:size=10;1

modules-left = i3
modules-center = date
modules-right = pulseaudio battery wlan

tray-position = right
tray-padding = 2

cursor-click = pointer
cursor-scroll = ns-resize

[module/i3]
type = internal/i3
format = <label-state> <label-mode>
index-sort = true
wrapping-scroll = false

label-mode-padding = 2
label-mode-foreground = #000
label-mode-background = ${colors.primary}

label-focused = %index%
label-focused-background = ${colors.background-alt}
label-focused-underline= ${colors.primary}
label-focused-padding = 2

label-unfocused = %index%
label-unfocused-padding = 2

label-visible = %index%
label-visible-background = ${self.label-focused-background}
label-visible-underline = ${self.label-focused-underline}
label-visible-padding = ${self.label-focused-padding}

label-urgent = %index%
label-urgent-background = ${colors.alert}
label-urgent-padding = 2

[module/wlan]
type = internal/network
interface-type = wireless
interval = 3.0

format-connected = <ramp-signal> <label-connected>
label-connected = %essid%

format-disconnected = 

ramp-signal-0 = 
ramp-signal-1 = 
ramp-signal-2 = 
ramp-signal-3 = 
ramp-signal-4 = 

[module/date]
type = internal/date
interval = 1

date = %H:%M
date-alt = %Y-%m-%d %H:%M:%S

label = %date%

[module/pulseaudio]
type = internal/pulseaudio

format-volume-prefix = " "
format-volume-prefix-foreground = ${colors.primary}
format-volume = <label-volume>

label-volume = %percentage%%

label-muted = muted
label-muted-foreground = ${colors.disabled}

[module/battery]
type = internal/battery
battery = BAT0
adapter = ADP1

format-charging = <animation-charging> <label-charging>
format-discharging = <ramp-capacity> <label-discharging>

label-charging = %percentage%%
label-discharging = %percentage%%

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-3 = 
ramp-capacity-4 = 

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-3 = 
animation-charging-4 = 
animation-charging-framerate = 750

[settings]
screenchange-reload = true
pseudo-transparency = true
EOF

print_status "Создание скрипта запуска Polybar..."
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar main &
EOF
chmod +x ~/.config/polybar/launch.sh

print_status "Создание конфигурации Rofi (Spotlight)..."
cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,window,run,calc";
    show-icons: true;
    font: "SF Pro Display 12";
    drun-display-format: "{name}";
    disable-history: false;
    hide-scrollbar: true;
    sidebar-mode: false;
}

@theme "spotlight"
EOF

# Создаем тему Spotlight для rofi
mkdir -p ~/.local/share/rofi/themes
cat > ~/.local/share/rofi/themes/spotlight.rasi << 'EOF'
* {
    background-color:      transparent;
    text-color:           #ffffff;
    selbg:                #0080ff;
    actbg:                #262626;
    urgbg:                #e53e3e;
    winbg:                #1a1a1a;

    selected-normal-foreground: @winbg;
    normal-foreground:          @text-color;
    selected-normal-background: @actbg;
    normal-background:          @winbg;

    selected-urgent-foreground: @background-color;
    urgent-foreground:          @text-color;
    selected-urgent-background: @urgbg;
    urgent-background:          @background-color;

    selected-active-foreground: @winbg;
    active-foreground:          @text-color;
    selected-active-background: @actbg;
    active-background:          @selbg;

    line-margin:                2;
    line-padding:               2;
    separator-style:            "none";
    hide-scrollbar:             "true";
    margin:                     0;
    padding:                    0;
}

window {
    location: center;
    anchor: center;
    transparency: "screenshot";
    padding: 10px;
    border: 0px;
    border-radius: 12px;
    background-color: @winbg;
    spacing: 0;
    children: [mainbox];
    orientation: horizontal;
    width: 600px;
}

mainbox {
    spacing: 0;
    children: [ inputbar, message, listview ];
}

message {
    border-color: @selbg;
    border: 0px 2px 2px 2px;
    padding: 5;
    background-color: @winbg;
}

inputbar {
    color: @normal-foreground;
    padding: 14px;
    background-color: @winbg;
    border: 2px 2px 2px 2px;
    border-radius: 12px 12px 0px 0px;
    border-color: @selbg;
    font: "SF Pro Display 14";
}

entry, prompt, case-indicator {
    text-font: inherit;
    text-color: inherit;
}

prompt {
    margin: 0px 0.3em 0em 0em;
}

listview {
    padding: 8px;
    border-radius: 0px 0px 12px 12px;
    border-color: @selbg;
    border: 0px 2px 2px 2px;
    background-color: @winbg;
    dynamic: false;
    lines: 8;
}

element {
    padding: 8px;
    vertical-align: 0.5;
    border-radius: 6px;
    background-color: transparent;
    color: @normal-foreground;
    text-color: rgb(216, 222, 233);
}

element selected.normal {
    background-color: @selected-normal-background;
    text-color: @selected-normal-foreground;
}

element-text, element-icon {
    background-color: inherit;
    text-color: inherit;
}

button {
    padding: 6px;
    color: @normal-foreground;
    horizontal-align: 0.5;
    border: 2px 0px 2px 2px;
    border-radius: 4px 0px 0px 4px;
    border-color: @normal-foreground;
}

button selected normal {
    border: 2px 0px 2px 2px;
    border-color: @selected-normal-background;
}
EOF

print_status "Создание конфигурации picom..."
cat > ~/.config/picom/picom.conf << 'EOF'
# Тени
shadow = true;
shadow-radius = 12;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.7;

# Прозрачность
inactive-opacity = 0.95;
active-opacity = 1.0;
frame-opacity = 0.9;

# Размытие
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 5;

# Анимации
transition-length = 300;
transition-pow-x = 0.1;
transition-pow-y = 0.1;
transition-pow-w = 0.1;
transition-pow-h = 0.1;
size-transition = true;

# Скругленные углы
corner-radius = 12;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# Исключения для теней
shadow-exclude = [
    "name = 'Notification'",
    "class_g ?= 'Notify-osd'",
    "class_g = 'Cairo-clock'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Vsync
vsync = true;

# Backend
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;

# Другие настройки
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 0;
use-ewmh-active-win = true;
unredir-if-possible = false;
focus-exclude = [ "class_g = 'Cairo-clock'" ];
detect-transient = true;
detect-client-leader = true;
invert-color-include = [ ];

wintypes:
{
    tooltip = { fade = true; shadow = true; opacity = 0.95; focus = true; full-shadow = false; }
    dock = { shadow = false; }
    dnd = { shadow = false; }
    popup_menu = { opacity = 0.98; }
    dropdown_menu = { opacity = 0.98; }
};
EOF

print_status "Создание конфигурации dunst..."
cat > ~/.config/dunst/dunstrc << 'EOF'
[global]
    monitor = 0
    follow = mouse
    geometry = "300x60-20+48"
    indicate_hidden = yes
    shrink = no
    transparency = 10
    notification_height = 0
    separator_height = 2
    padding = 12
    horizontal_padding = 12
    frame_width = 2
    frame_color = "#0080ff"
    separator_color = frame
    sort = yes
    idle_threshold = 120
    font = SF Pro Display 11
    line_height = 0
    markup = full
    format = "<b>%s</b>\n%b"
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ellipsize = middle
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    max_icon_size = 32
    sticky_history = yes
    history_length = 20
    browser = firefox
    always_run_script = true
    title = Dunst
    class = Dunst
    startup_notification = false
    force_xinerama = false

[experimental]
    per_monitor_dpi = false

[shortcuts]
    close = ctrl+space
    close_all = ctrl+shift+space
    history = ctrl+grave
    context = ctrl+shift+period

[urgency_low]
    background = "#1a1a1a"
    foreground = "#ffffff"
    timeout = 5

[urgency_normal]
    background = "#1a1a1a"
    foreground = "#ffffff"
    timeout = 10

[urgency_critical]
    background = "#e53e3e"
    foreground = "#ffffff"
    frame_color = "#ff0000"
    timeout = 0
EOF

print_status "Создание конфигурации Alacritty..."
cat > ~/.config/alacritty/alacritty.yml << 'EOF'
env:
  TERM: xterm-256color

window:
  dimensions:
    columns: 120
    lines: 30
  padding:
    x: 12
    y: 12
  dynamic_padding: false
  decorations: none
  opacity: 0.95
  startup_mode: Windowed

scrolling:
  history: 10000
  multiplier: 3

font:
  normal:
    family: Fira Code
    style: Regular
  bold:
    family: Fira Code
    style: Bold
  italic:
    family: Fira Code
    style: Italic
  bold_italic:
    family: Fira Code
    style: Bold Italic
  size: 12

colors:
  primary:
    background: '#1a1a1a'
    foreground: '#ffffff'
  cursor:
    text: '#1a1a1a'
    cursor: '#ffffff'
  normal:
    black:   '#1a1a1a'
    red:     '#ff6b6b'
    green:   '#51cf66'
    yellow:  '#ffd43b'
    blue:    '#74c0fc'
    magenta: '#f783ac'
    cyan:    '#3bc9db'
    white:   '#ffffff'
  bright:
    black:   '#495057'
    red:     '#ff8787'
    green:   '#69db7c'
    yellow:  '#ffe066'
    blue:    '#91d5ff'
    magenta: '#faa2c1'
    cyan:    '#66d9ef'
    white:   '#ffffff'

key_bindings:
  - { key: V,        mods: Command,       action: Paste            }
  - { key: C,        mods: Command,       action: Copy             }
  - { key: Q,        mods: Command,       action: Quit             }
  - { key: N,        mods: Command,       action: SpawnNewInstance }
  - { key: Plus,     mods: Command,       action: IncreaseFontSize }
  - { key: Minus,    mods: Command,       action: DecreaseFontSize }
  - { key: Key0,     mods: Command,       action: ResetFontSize    }
EOF

print_status "Настройка GTK темы..."
# Проверяем доступные темы и выбираем подходящую
if [ -d "/usr/share/themes/Arc-Dark" ]; then
    GTK_THEME="Arc-Dark"
elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
    GTK_THEME="Adwaita-dark"
elif [ -d "/usr/share/themes/Breeze-Dark" ]; then
    GTK_THEME="Breeze-Dark"
else
    GTK_THEME="Adwaita"
    print_warning "Arc-Dark тема не найдена, используется $GTK_THEME"
fi

cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=SF Pro Display 10
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

# Также создаем для GTK2
cat > ~/.gtkrc-2.0 << EOF
gtk-theme-name="$GTK_THEME"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="SF Pro Display 10"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
EOF

print_status "Загрузка обоев в стиле macOS..."
curl -L "https://4kwallpapers.com/images/wallpapers/macos-monterey-abstract-colorful-wwdc-2021-5120x2880-5889.jpg" \
     -o ~/Pictures/Wallpapers/wallpaper.jpg || \
curl -L "https://wallpapercave.com/wp/wp2757737.jpg" \
     -o ~/Pictures/Wallpapers/wallpaper.jpg || \
echo "Не удалось загрузить обои, создаю градиентную заливку..." && \
convert -size 1920x1080 gradient:#1a1a1a-#2c3e50 ~/Pictures/Wallpapers/wallpaper.jpg 2>/dev/null || \
echo "Установите imagemagick для создания обоев: sudo pacman -S imagemagick"

print_status "Создание скрипта автозапуска..."
cat > ~/.xprofile << 'EOF'
#!/bin/bash

# Запуск композитора
picom &

# Запуск панели
~/.config/polybar/launch.sh &

# Фон рабочего стола
feh --bg-scale ~/Pictures/Wallpapers/wallpaper.jpg &

# Уведомления
dunst &

# Сетевое подключение
nm-applet &

# Bluetooth
blueman-applet &

# Фильтр синего света
redshift -l 51.1694:71.4491 &

# Автотайлинг
~/.local/bin/autotiling 2>/dev/null &
EOF
chmod +x ~/.xprofile

print_status "Создание .xinitrc..."
if [ ! -f ~/.xinitrc ]; then
    cat > ~/.xinitrc << 'EOF'
#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

# Load .xprofile
[ -f ~/.xprofile ] && source ~/.xprofile

# Start i3
exec i3
EOF
fi

print_success "Установка завершена!"
print_status "Перезагрузите систему и выберите i3 в менеджере входа в систему"

echo ""
echo "🎉 Ваш macOS-подобный i3 готов к использованию!"
echo ""
echo "Основные хоткеи:"
echo "  Cmd+Space        - Spotlight (поиск приложений)"
echo "  Cmd+Return       - Терминал"
echo "  Cmd+Q            - Закрыть окно"  
echo "  Cmd+Tab          - Переключение окон"
echo "  Cmd+Shift+3      - Скриншот экрана"
echo "  Cmd+Shift+4      - Скриншот области"
echo "  Cmd+Shift+F      - Файловый менеджер"
echo "  Cmd+Shift+L      - Заблокировать экран"
echo "  Cmd+1-9          - Переключение рабочих столов"
echo ""
echo "Для тонкой настройки:"
echo "  lxappearance     - Настройка тем GTK"
echo "  pavucontrol      - Настройка звука"
echo "  arandr           - Настройка мониторов"
echo ""
print_warning "Перезагрузите систему для применения всех настроек!"