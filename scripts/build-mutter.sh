#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# SPAN WINDOW - BUILD MUTTER
# Ubuntu 26.04 / Mutter 50.1
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

MUTTER_VERSION="50.1-0ubuntu2.2"

SOURCE_DIR="${1:-}"
BUILD_DIR="$PROJECT_DIR/.build/mutter"
PACKAGE_DIR="$PROJECT_DIR/packages/ubuntu-26.04/amd64"
PATCH_DIR="$PROJECT_DIR/mutter/patches"

echo "=============================================================="
echo " SPAN WINDOW - BUILD MUTTER"
echo "=============================================================="
echo
echo "[INFO] Projeto:"
echo "       $PROJECT_DIR"
echo
echo "[INFO] Versão do Mutter:"
echo "       $MUTTER_VERSION"
echo

# ------------------------------------------------------------
# Verificações básicas
# ------------------------------------------------------------

if [[ ! -f "$PATCH_DIR/0001-add-maximize-level.patch" ]]; then
    echo "[ERRO] Patch 0001 não encontrado:"
    echo "       $PATCH_DIR/0001-add-maximize-level.patch"
    exit 1
fi

if [[ ! -f "$PATCH_DIR/0002-add-fullscreen-all-monitors.patch" ]]; then
    echo "[ERRO] Patch 0002 não encontrado:"
    echo "       $PATCH_DIR/0002-add-fullscreen-all-monitors.patch"
    exit 1
fi

command -v dpkg-buildpackage >/dev/null 2>&1 || {
    echo "[ERRO] dpkg-buildpackage não encontrado."
    exit 1
}

command -v dpkg-source >/dev/null 2>&1 || {
    echo "[ERRO] dpkg-source não encontrado."
    exit 1
}

# ------------------------------------------------------------
# Fonte do Mutter
#
# Se um diretório for informado como argumento, ele será usado.
#
# Exemplo:
#   ./scripts/build-mutter.sh /caminho/mutter-50.1
# ------------------------------------------------------------

if [[ -n "$SOURCE_DIR" ]]; then

    SOURCE_DIR="$(realpath "$SOURCE_DIR")"

    if [[ ! -d "$SOURCE_DIR" ]]; then
        echo "[ERRO] Diretório informado não existe:"
        echo "       $SOURCE_DIR"
        exit 1
    fi

    echo "[OK] Fonte do Mutter:"
    echo "     $SOURCE_DIR"

else

    echo "[INFO] Nenhum diretório de source foi informado."
    echo
    echo "Para este primeiro build, informe o diretório de uma"
    echo "árvore limpa do Mutter 50.1."
    echo
    echo "Exemplo:"
    echo
    echo "  ./scripts/build-mutter.sh /caminho/mutter-50.1"
    echo
    exit 1

fi

# ------------------------------------------------------------
# Verificar se é realmente Mutter 50.1
# ------------------------------------------------------------

if [[ ! -f "$SOURCE_DIR/debian/changelog" ]]; then
    echo "[ERRO] O diretório informado não parece ser um source"
    echo "       Debian/Ubuntu do Mutter."
    exit 1
fi

if ! grep -q "^mutter (" "$SOURCE_DIR/debian/changelog"; then
    echo "[ERRO] O source informado não parece ser o Mutter."
    exit 1
fi

if ! grep -q "^mutter (${MUTTER_VERSION}" "$SOURCE_DIR/debian/changelog"; then
    echo "[ERRO] O source informado não corresponde à versão esperada:"
    echo "       Mutter $MUTTER_VERSION"
    exit 1
fi

echo "[OK] Source Mutter $MUTTER_VERSION confirmado."
echo

# ------------------------------------------------------------
# Preparar cópia limpa
# ------------------------------------------------------------

echo "=============================================================="
echo " PREPARANDO SOURCE LIMPO"
echo "=============================================================="

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "[INFO] Copiando source..."
cp -a "$SOURCE_DIR" "$BUILD_DIR/mutter-50.1"

WORK_DIR="$BUILD_DIR/mutter-50.1"

echo "[OK] Source copiado para:"
echo "     $WORK_DIR"
echo

# ------------------------------------------------------------
# Aplicar patches
# ------------------------------------------------------------

echo "=============================================================="
echo " APLICANDO PATCHES"
echo "=============================================================="

cd "$WORK_DIR"

echo "[INFO] Aplicando 0001..."
patch --dry-run -p1 < \
    "$PATCH_DIR/0001-add-maximize-level.patch"

patch -p1 < \
    "$PATCH_DIR/0001-add-maximize-level.patch"

echo "[OK] 0001 aplicado."
echo

echo "[INFO] Aplicando 0002..."
patch --dry-run -p1 < \
    "$PATCH_DIR/0002-add-fullscreen-all-monitors.patch"

patch -p1 < \
    "$PATCH_DIR/0002-add-fullscreen-all-monitors.patch"

echo "[OK] 0002 aplicado."
echo

# ------------------------------------------------------------
# Build
# ------------------------------------------------------------

echo "=============================================================="
echo " COMPILANDO MUTTER"
echo "=============================================================="
echo

DEB_BUILD_OPTIONS=nocheck \
    dpkg-buildpackage -us -uc -b

echo
echo "[OK] Build concluído."
echo

# ------------------------------------------------------------
# Copiar pacotes
# ------------------------------------------------------------

echo "=============================================================="
echo " COPIANDO PACOTES"
echo "=============================================================="

mkdir -p "$PACKAGE_DIR"

rm -f "$PACKAGE_DIR"/libmutter-18-0_*.deb
rm -f "$PACKAGE_DIR"/gir1.2-mutter-18_*.deb
rm -f "$PACKAGE_DIR"/mutter_*.deb

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
echo
echo "Pacotes:"
ls -lh "$PACKAGE_DIR"/*.deb 2>/dev/null || true
echo
