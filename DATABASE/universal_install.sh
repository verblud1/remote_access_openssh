#!/bin/bash

set -e

echo "=== УНИВЕРСАЛЬНАЯ УСТАНОВКА КЛИЕНТА БАЗЫ ДАННЫХ ==="

# Автоматическое определение путей
USER_HOME="$HOME"
APP_NAME="database_client"
APP_DIR="$USER_HOME/.local/share/$APP_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📁 Создаю директорию приложения..."
mkdir -p "$APP_DIR"

# Копируем основные файлы
cp "$SCRIPT_DIR/database_client.sh" "$APP_DIR/"
cp "$SCRIPT_DIR/config.env" "$APP_DIR/" 2>/dev/null || true
chmod +x "$APP_DIR/database_client.sh"

# Функция определения среды рабочего стола
detect_desktop_environment() {
    local de=""
    
    # Проверяем переменные среды
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        de=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
    elif [ -n "$DESKTOP_SESSION" ]; then
        de=$(echo "$DESKTOP_SESSION" | tr '[:upper:]' '[:lower:]')
    fi
    
    # Определяем конкретную среду
    case "$de" in
        *gnome*)
            echo "gnome"
            ;;
        *kde*|*plasma*)
            echo "kde"
            ;;
        *mate*)
            echo "mate"
            ;;
        *xfce*)
            echo "xfce"
            ;;
        *cinnamon*)
            echo "cinnamon"
            ;;
        *lxde*|*lxqt*)
            echo "lxde"
            ;;
        *)
            # Если не определили, пробуем определить по процессам
            if pgrep -l "gnome-session" >/dev/null; then
                echo "gnome"
            elif pgrep -l "plasmashell" >/dev/null; then
                echo "kde"
            elif pgrep -l "mate-session" >/dev/null; then
                echo "mate"
            elif pgrep -l "xfce4-session" >/dev/null; then
                echo "xfce"
            else
                echo "неизвестно"
            fi
            ;;
    esac
}

# Функция определения пути к рабочему столу
detect_desktop_path() {
    local desktop_path=""
    
    # Пробуем XDG стандарт
    if [ -n "$XDG_DESKTOP_DIR" ]; then
        desktop_path="$XDG_DESKTOP_DIR"
    elif command -v xdg-user-dir >/dev/null 2>&1; then
        desktop_path=$(xdg-user-dir DESKTOP 2>/dev/null)
    fi
    
    # Если XDG не сработал, пробуем стандартные пути
    if [ -z "$desktop_path" ] || [ ! -d "$desktop_path" ]; then
        local possible_paths=(
            "$USER_HOME/Desktop"
            "$USER_HOME/desktop"
            "$USER_HOME/Рабочий стол"
            "$USER_HOME/рабочий стол"
            "$USER_HOME/Stały"
            "$USER_HOME/Écrán"
            "$USER_HOME/Schreibtisch"
            "$USER_HOME/Escritorio"
        )
        
        for path in "${possible_paths[@]}"; do
            if [ -d "$path" ]; then
                desktop_path="$path"
                break
            fi
        done
    fi
    
    # Если всё ещё не нашли, создаем стандартный Desktop
    if [ -z "$desktop_path" ] || [ ! -d "$desktop_path" ]; then
        desktop_path="$USER_HOME/Desktop"
        mkdir -p "$desktop_path"
    fi
    
    echo "$desktop_path"
}

# Функция определения терминала
detect_terminal() {
    local terminals=(
        "gnome-terminal" "konsole" "mate-terminal" "xfce4-terminal"
        "lxterminal" "terminator" "xterm" "uxterm" "st" "alacritty"
        "kitty" "tilix" "qterminal" "sakura" "roxterm"
    )
    
    for term in "${terminals[@]}"; do
        if command -v "$term" >/dev/null 2>&1; then
            echo "$term"
            return 0
        fi
    done
    
    echo "xterm" # запасной вариант
}

# Функция создания универсального ярлыка
create_universal_shortcut() {
    local desktop_path="$1"
    local desktop_env="$2"
    local terminal="$3"
    
    local desktop_file="$desktop_path/База_данных.desktop"
    
    # Базовый desktop файл
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=База данных
GenericName=Подключение к базе данных
Comment=Подключение к корпоративной базе данных
Exec=$APP_DIR/database_client.sh
Icon=network-wired
Categories=Network;
EOF
    
    # Добавляем специфичные настройки для разных сред
    case "$desktop_env" in
        "gnome"|"mate"|"xfce"|"cinnamon"|"lxde")
            echo "Terminal=true" >> "$desktop_file"
            ;;
        "kde")
            echo "Terminal=true" >> "$desktop_file"
            echo "StartupNotify=true" >> "$desktop_file"
            ;;
        *)
            echo "Terminal=true" >> "$desktop_file"
            ;;
    esac
    
    chmod +x "$desktop_file"
    echo "$desktop_file"
}

# Функция создания альтернативного ярлыка с явным терминалом
create_terminal_shortcut() {
    local desktop_path="$1"
    local terminal="$2"
    
    local desktop_file="$desktop_path/База_данных_Терминал.desktop"
    local terminal_cmd=""
    
    # Определяем команду для терминала
    case "$terminal" in
        "gnome-terminal")
            terminal_cmd="gnome-terminal --working-directory=$APP_DIR -e ./database_client.sh"
            ;;
        "konsole")
            terminal_cmd="konsole --workdir $APP_DIR -e ./database_client.sh"
            ;;
        "mate-terminal")
            terminal_cmd="mate-terminal --working-directory=$APP_DIR -e ./database_client.sh"
            ;;
        "xfce4-terminal")
            terminal_cmd="xfce4-terminal --working-directory=$APP_DIR -e ./database_client.sh"
            ;;
        "lxterminal")
            terminal_cmd="lxterminal --working-directory=$APP_DIR -e ./database_client.sh"
            ;;
        *)
            terminal_cmd="$terminal -e 'cd $APP_DIR && ./database_client.sh'"
            ;;
    esac
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=База данных (Терминал)
Comment=Подключение к корпоративной базе данных с явным терминалом
Exec=$terminal_cmd
Icon=network-wired
Categories=Network;
EOF
    
    chmod +x "$desktop_file"
    echo "$desktop_file"
}

# Основной процесс установки
echo "🔍 Определяю среду рабочего стола..."
DESKTOP_ENV=$(detect_desktop_environment)
echo "   Среда рабочего стола: $DESKTOP_ENV"

echo "📁 Определяю путь к рабочему столу..."
DESKTOP_PATH=$(detect_desktop_path)
echo "   Путь к рабочему столу: $DESKTOP_PATH"

echo "💻 Определяю терминал..."
TERMINAL=$(detect_terminal)
echo "   Терминал: $TERMINAL"

echo "🖱️ Создаю ярлыки..."
SHORTCUT1=$(create_universal_shortcut "$DESKTOP_PATH" "$DESKTOP_ENV" "$TERMINAL")
SHORTCUT2=$(create_terminal_shortcut "$DESKTOP_PATH" "$TERMINAL")

echo "✅ Установка завершена!"
echo ""
echo "📊 ОТЧЕТ ОБ УСТАНОВКЕ:"
echo "   📁 Приложение: $APP_DIR"
echo "   🖥️  Среда: $DESKTOP_ENV"
echo "   📂 Путь к рабочему столу: $DESKTOP_PATH"
echo "   💻 Терминал: $TERMINAL"
echo "   🖱️  Ярлык 1: $SHORTCUT1"
echo "   🖱️  Ярлык 2: $SHORTCUT2"
echo ""
echo "🚀 ИСПОЛЬЗОВАНИЕ:"
echo "   Дважды щелкните 'База данных' на рабочем столе"
echo "   Или запустите: $APP_DIR/database_client.sh"
echo ""
echo "🔧 УСТРАНЕНИЕ ПРОБЛЕМ:"
echo "   Если один ярлык не работает, попробуйте другой"
echo "   Проверьте config.env: nano $APP_DIR/config.env"