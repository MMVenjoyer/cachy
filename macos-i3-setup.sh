#!/usr/bin/env bash
# CachyOS/Arch: настраиваем i3 «под мак» без лишнего.
set -uo pipefail

log() { printf "\n==> %s\n" "$*"; }
try_install() {
  local pkgs=("$@")
  sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" || {
    echo "WARN: какие-то пакеты не встали: ${pkgs[*]}" >&2
    return 0
  }
}

log "Ставим базу (i3, лончер, композит, ФМ, терминал, zsh, темы, шрифты)"
try_install i3-wm rofi picom thunar alacritty zsh \
  arc-gtk-theme papirus-icon-theme \
  ttf-jetbrains-mono noto-fonts noto-fonts-emoji xclip feh

# Терминал по умолчанию (на случай, если Alt+Enter не работал)
TERM_BIN="$(command -v alacritty || true)"
[ -z "$TERM_BIN" ] && TERM_BIN="xterm"

log "Готовим каталоги и бэкапы"
mkdir -p "$HOME/.config/i3" "$HOME/.config/picom" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
[ -f "$HOME/.config/i3/config" ]    && cp -f "$HOME/.config/i3/config"    "$HOME/.config/i3/config.bak.$(date +%s)"
[ -f "$HOME/.config/picom/picom.conf" ] && cp -f "$HOME/.config/picom/picom.conf" "$HOME/.config/picom/picom.conf.bak.$(date +%s)"
[ -f "$HOME/.config/gtk-3.0/settings.ini" ] && cp -f "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini.bak.$(date +%s)"
[ -f "$HOME/.config/gtk-4.0/settings.ini" ] && cp -f "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini.bak.$(date +%s)"

log "Пишем конфиг i3"
cat > "$HOME/.config/i3/config" <<EOF
# === i3 config (Alt как Command) ===
set \$mod Mod1

# Терминал
bindsym \$mod+Return exec ${TERM_BIN}

# Запуск приложений (Spotlight-подобно)
bindsym \$mod+d exec rofi -modi drun,run -show drun

# Переключатель окон (Alt+Tab)
bindsym \$mod+Tab exec rofi -show window
bindsym \$mod+Shift+Tab exec rofi -show window

# Файловый менеджер и быстрые папки
bindsym \$mod+e exec thunar
bindsym \$mod+Shift+h exec thunar \$HOME
bindsym \$mod+Shift+d exec thunar \$HOME/Downloads
bindsym \$mod+Shift+r exec thunar /

# Закрыть окно / фулскрин
bindsym \$mod+q kill
bindsym \$mod+f fullscreen toggle

# Фокус по Vim-стилю
bindsym \$mod+h focus left
bindsym \$mod+j focus down
bindsym \$mod+k focus up
bindsym \$mod+l focus right

# Перемещение окон
bindsym \$mod+Shift+h move left
bindsym \$mod+Shift+j move down
bindsym \$mod+Shift+k move up
bindsym \$mod+Shift+l move right

# Рабочие столы 1..9
set \$ws1 "1"; set \$ws2 "2"; set \$ws3 "3"; set \$ws4 "4"; set \$ws5 "5"
set \$ws6 "6"; set \$ws7 "7"; set \$ws8 "8"; set \$ws9 "9"
bindsym \$mod+1 workspace \$ws1
bindsym \$mod+2 workspace \$ws2
bindsym \$mod+3 workspace \$ws3
bindsym \$mod+4 workspace \$ws4
bindsym \$mod+5 workspace \$ws5
bindsym \$mod+6 workspace \$ws6
bindsym \$mod+7 workspace \$ws7
bindsym \$mod+8 workspace \$ws8
bindsym \$mod+9 workspace \$ws9
bindsym \$mod+Shift+1 move container to workspace \$ws1
bindsym \$mod+Shift+2 move container to workspace \$ws2
bindsym \$mod+Shift+3 move container to workspace \$ws3
bindsym \$mod+Shift+4 move container to workspace \$ws4
bindsym \$mod+Shift+5 move container to workspace \$ws5
bindsym \$mod+Shift+6 move container to workspace \$ws6
bindsym \$mod+Shift+7 move container to workspace \$ws7
bindsym \$mod+Shift+8 move container to workspace \$ws8
bindsym \$mod+Shift+9 move container to workspace \$ws9

# Перезапуск/выход
bindsym \$mod+Shift+r restart
bindsym \$mod+Shift+e exec "i3-nagbar -t warning -m 'Exit i3?' -B 'Yes, exit' 'i3-msg exit'"

# Композитор и шрифт
font pango:JetBrains Mono 10
exec_always --no-startup-id picom --config \$HOME/.config/picom/picom.conf
EOF

log "Лёгкий picom.conf (без тяжёлого blur)"
cat > "$HOME/.config/picom/picom.conf" <<'EOF'
backend = "xrender";
vsync = true;
detect-rounded-corners = true;
detect-client-opacity = true;
use-damage = true;

shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;

fading = true;
fade-in-step = 0.08;
fade-out-step = 0.08;

corner-radius = 8;

wintypes:
{
  tooltip = { fade = true; shadow = true; };
  dock    = { shadow = false; };
  dnd     = { shadow = false; };
  popup_menu = { opacity = 0.95; };
  dropdown_menu = { opacity = 0.95; };
};
EOF

log "GTK тема и иконки через settings.ini (без gsettings)"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Darker
gtk-icon-theme-name=Papirus
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF

cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Arc-Darker
gtk-icon-theme-name=Papirus
gtk-font-name=Noto Sans 10
gtk-application-prefer-dark-theme=1
EOF

log "Zsh по умолчанию (без oh-my-zsh, чтобы не было интерактива)"
if command -v zsh >/dev/null 2>&1; then
  if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)" "$USER" || true
  fi
  [ ! -f "$HOME/.zshrc" ] && cat > "$HOME/.zshrc" <<'ZRC'
export EDITOR=vim
autoload -U promptinit; promptinit
prompt walters
ZRC
fi

log "Релоад i3"
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload >/dev/null 2>&1 || true
  i3-msg restart >/dev/null 2>&1 || true
fi

log "Готово. Горячие клавиши: Alt+D (приложения), Alt+Tab (окна), Alt+E (Thunar), Alt+Shift+D/H/R (папки)"
