#!/usr/bin/env bash

set -euo pipefail

EXTENSION_ID="span-window@lucascechinmario"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID"
BACKUP_DIR="$HOME/.local/share/span-window-v2-backup"

echo
echo "=============================================================="
echo "       SPAN WINDOW V2.0 - DESINSTALAÇÃO / ROLLBACK"
echo "=============================================================="
echo

if [[ $EUID -eq 0 ]]; then
    echo "ERRO: não execute como root."
    exit 1
fi

echo "Esta operação irá:"
echo
echo "  1. Remover a extensão Span Window."
echo "  2. Restaurar os pacotes oficiais do Ubuntu."
echo
echo "O GNOME Shell poderá precisar de logout/login."
echo

read -r -p "Continuar? [s/N] " ANSWER

if [[ ! "$ANSWER" =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo
echo "[1/3] Removendo extensão..."

if [[ -d "$EXTENSION_DIR" ]]; then
    rm -rf "$EXTENSION_DIR"
    echo "  Extensão removida."
else
    echo "  Extensão não encontrada."
fi

echo
echo "[2/3] Restaurando pacotes oficiais..."

sudo apt-get install --reinstall \
    libmutter-18-0 \
    gir1.2-mutter-18 \
    mutter

echo
echo "[3/3] Verificando..."

if [[ -f /usr/lib/x86_64-linux-gnu/libmutter-18.so.0 ]]; then
    if strings /usr/lib/x86_64-linux-gnu/libmutter-18.so.0 | \
       grep -q "meta_window_set_maximize_level"; then
        echo
        echo "AVISO: o símbolo do Span Window ainda está presente."
        echo "Isso pode acontecer se o APT tiver reinstalado a mesma"
        echo "versão customizada disponível localmente."
    else
        echo "  Biblioteca oficial restaurada."
    fi
fi

echo
echo "=============================================================="
echo "              ROLLBACK CONCLUÍDO"
echo "=============================================================="
echo
echo "Faça logout/login para reiniciar completamente o GNOME Shell."
echo
