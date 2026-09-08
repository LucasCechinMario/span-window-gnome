#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$HOME/span-window-v2"
MUTTER_DIR="$HOME/mutter-dev/mutter-50.1-v2"

echo "=============================================================="
echo " SPAN WINDOW V2 - BUILD MUTTER"
echo "=============================================================="

if [[ ! -d "$MUTTER_DIR" ]]; then
    echo "[ERRO] Diretório do Mutter não encontrado:"
    echo "       $MUTTER_DIR"
    exit 1
fi

echo "[OK] Fonte do Mutter encontrada."
echo

cd "$MUTTER_DIR"

echo "[INFO] Limpando builds anteriores..."
rm -f ../mutter_*.deb
rm -f ../libmutter-*.deb
rm -f ../gir1.2-mutter-*.deb
rm -f ../mutter-common*.deb

echo
echo "[INFO] Compilando Mutter..."
echo

DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -b

echo
echo "[OK] Build concluído."
echo

echo "Pacotes gerados:"
ls -lh ../*.deb 2>/dev/null || true

echo
echo "=============================================================="
echo " COPIANDO PACOTES PARA O PROJETO"
echo "=============================================================="

PACKAGE_DIR="$PROJECT_DIR/packages/ubuntu-26.04/amd64"

mkdir -p "$PACKAGE_DIR"

for package in \
    ../libmutter-18-0_*.deb \
    ../gir1.2-mutter-18_*.deb \
    ../mutter_*.deb
do
    if [[ -f "$package" ]]; then
        cp "$package" "$PACKAGE_DIR/"
        echo "[OK] $(basename "$package")"
    fi
done

echo
echo "=============================================================="
echo " BUILD FINALIZADO"
echo "=============================================================="
