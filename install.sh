#!/bin/bash

# Этот скрипт устанавливает Zsh, Git, Oh My Zsh, настраивает тему "arrow",
# добавляет плагин подсветки синтаксиса и переключает стандартную оболочку на Zsh.
# После установки скрипт автоматически перезапускает оболочку без необходимости
# перезагружать компьютер.

# Функция для вывода информационных сообщений
echo_info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

# Функция для вывода сообщений об ошибках
echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
}

# Функция для проверки и установки пакета, если он не установлен
check_and_install() {
    PACKAGE_NAME=$1
    INSTALL_NAME=$2

    if ! command -v "$PACKAGE_NAME" &> /dev/null; then
        echo_info "$PACKAGE_NAME не найден. Устанавливаем $INSTALL_NAME..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update
            sudo apt-get install -y "$INSTALL_NAME"
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y "$INSTALL_NAME"
        elif [ -x "$(command -v pacman)" ]; then
            sudo pacman -Sy --noconfirm "$INSTALL_NAME"
        else
            echo_error "Неизвестный менеджер пакетов. Установите $INSTALL_NAME вручную."
            exit 1
        fi
    else
        echo_info "$PACKAGE_NAME уже установлен."
    fi
}

# Проверка и установка необходимых зависимостей
check_and_install "zsh" "zsh"
check_and_install "git" "git"
check_and_install "curl" "curl"

# Установка Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo_info "Устанавливаем Oh My Zsh..."
    # Используем curl или wget для установки
    if command -v curl &> /dev/null; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    elif command -v wget &> /dev/null; then
        sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
    else
        echo_error "Не найден ни curl, ни wget. Установите один из них и повторите попытку."
        exit 1
    fi
else
    echo_info "Oh My Zsh уже установлен."
fi

# Установка плагина zsh-syntax-highlighting
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

if [ ! -d "$PLUGIN_DIR" ]; then
    echo_info "Устанавливаем плагин zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR"
else
    echo_info "Плагин zsh-syntax-highlighting уже установлен."
fi

# Установка темы "arrow"
THEME_NAME="arrow"

echo_info "Устанавливаем тему Oh My Zsh: $THEME_NAME..."
ZSHRC_FILE="$HOME/.zshrc"

# Резервное копирование .zshrc, если еще не сделано
if [ ! -f "$HOME/.zshrc.backup" ]; then
    cp "$ZSHRC_FILE" "$HOME/.zshrc.backup"
    echo_info "Создана резервная копия .zshrc -> .zshrc.backup"
fi

# Изменение темы в .zshrc
if grep -q "^ZSH_THEME=\"$THEME_NAME\"" "$ZSHRC_FILE"; then
    echo_info "Тема Oh My Zsh уже установлена на \"$THEME_NAME\"."
else
    # Проверка, существует ли тема "arrow"
    THEME_PATH="$ZSH/custom/themes/$THEME_NAME.zsh-theme"
    if [ ! -f "$THEME_PATH" ]; then
        echo_info "Скачиваем тему \"$THEME_NAME\"..."
        mkdir -p "$ZSH_CUSTOM/themes"
        git clone https://github.com/agnoster/agnoster-zsh-theme.git "$ZSH_CUSTOM/themes/agnoster-zsh-theme"
        # Переименовываем тему в "arrow"
        cp "$ZSH_CUSTOM/themes/agnoster-zsh-theme/agnoster.zsh-theme" "$ZSH_CUSTOM/themes/$THEME_NAME.zsh-theme"
        echo_info "Тема \"$THEME_NAME\" установлена."
    fi

    # Изменение темы в .zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$THEME_NAME\"/" "$ZSHRC_FILE"
    echo_info "Тема Oh My Zsh установлена на \"$THEME_NAME\"."
fi

# Добавление плагина в .zshrc
if grep -q "zsh-syntax-highlighting" "$ZSHRC_FILE"; then
    echo_info "Плагин zsh-syntax-highlighting уже добавлен в .zshrc."
else
    echo_info "Добавляем плагин zsh-syntax-highlighting в .zshrc..."
    sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' "$ZSHRC_FILE"
    echo "source \$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$ZSHRC_FILE"
    echo_info "Плагин zsh-syntax-highlighting добавлен в .zshrc."
fi

# Смена стандартного шелла на Zsh
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    echo_info "Сменяем стандартный шелл на Zsh..."
    chsh -s "$(which zsh)"
    echo_info "Стандартный шелл изменён на Zsh."
else
    echo_info "Стандартный шелл уже установлен на Zsh."
fi

echo_info "Установка и настройка завершены успешно!"

# Перезапуск оболочки для применения изменений
echo_info "Перезапускаем оболочку на Zsh..."
exec zsh
