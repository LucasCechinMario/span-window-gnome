#!/usr/bin/env bash

set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_DIR="$PROJECT_DIR/packages/ubuntu-26.04/amd64"
EXTENSION_DIR="$PROJECT_DIR/extension/span-window@lucascechinmario"

EXPECTED_VERSION="50.1-0ubuntu2.2"
EXPECTED_ARCH="amd64"

ERRORS=0
WARNINGS=0

ok() {
    echo "  OK: $1"
}

error() {
    echo "  ERRO: $1"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo "  AVISO: $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "=============================================================="
echo " SPAN WINDOW V2 - VERIFICAÇÃO DO RELEASE"
echo "=============================================================="
echo
echo "Projeto:     $PROJECT_DIR"
echo "Pacotes:     $PACKAGE_DIR"
echo "Versão alvo: $EXPECTED_VERSION"
echo

# ==============================================================
# 1. SISTEMA
# ==============================================================

echo "[1/8] Verificando sistema..."

if [[ -r /etc/os-release ]]; then
    . /etc/os-release

    echo "  Sistema: ${PRETTY_NAME:-desconhecido}"

    if [[ "${VERSION_ID:-}" == "26.04" ]]; then
        ok "Ubuntu 26.04 detectado."
    else
        error "Ubuntu 26.04 é obrigatório."
    fi
else
    error "/etc/os-release não encontrado."
fi

# ==============================================================
# 2. ARQUITETURA
# ==============================================================

echo
echo "[2/8] Verificando arquitetura..."

ARCH="$(dpkg --print-architecture 2>/dev/null || true)"

echo "  Arquitetura: ${ARCH:-desconhecida}"

if [[ "$ARCH" == "$EXPECTED_ARCH" ]]; then
    ok "Arquitetura amd64."
else
    error "Este release suporta somente amd64."
fi

# ==============================================================
# 3. GNOME SHELL
# ==============================================================

echo
echo "[3/8] Verificando GNOME Shell..."

GNOME_VERSION="$(gnome-shell --version 2>/dev/null || true)"

if [[ -n "$GNOME_VERSION" ]]; then
    echo "  $GNOME_VERSION"

    if [[ "$GNOME_VERSION" == *"50"* ]]; then
        ok "GNOME Shell 50 detectado."
    else
        warning "GNOME Shell 50 não foi detectado."
    fi
else
    warning "Não foi possível detectar o GNOME Shell."
fi

# ==============================================================
# 4. PACOTES DO RELEASE
# ==============================================================

echo
echo "[4/8] Verificando pacotes do release..."

PACKAGES=(
    "libmutter-18-0_50.1-0ubuntu2.2_amd64.deb"
    "gir1.2-mutter-18_50.1-0ubuntu2.2_amd64.deb"
    "mutter_50.1-0ubuntu2.2_amd64.deb"
)

for package in "${PACKAGES[@]}"; do
    FILE="$PACKAGE_DIR/$package"

    if [[ ! -f "$FILE" ]]; then
        error "Pacote ausente: $package"
        continue
    fi

    PACKAGE_NAME="$(dpkg-deb -f "$FILE" Package 2>/dev/null || true)"
    PACKAGE_VERSION="$(dpkg-deb -f "$FILE" Version 2>/dev/null || true)"
    PACKAGE_ARCH="$(dpkg-deb -f "$FILE" Architecture 2>/dev/null || true)"

    if [[ -z "$PACKAGE_NAME" ]]; then
        error "Pacote inválido: $package"
        continue
    fi

    if [[ "$PACKAGE_VERSION" != "$EXPECTED_VERSION" ]]; then
        error "$package: versão $PACKAGE_VERSION (esperada $EXPECTED_VERSION)"
        continue
    fi

    if [[ "$PACKAGE_ARCH" != "$EXPECTED_ARCH" && "$PACKAGE_ARCH" != "all" ]]; then
        error "$package: arquitetura $PACKAGE_ARCH"
        continue
    fi

    ok "$PACKAGE_NAME $PACKAGE_VERSION ($PACKAGE_ARCH)"
done

# ==============================================================
# 5. EXTENSÃO
# ==============================================================

echo
echo "[5/8] Verificando extensão..."

FILES=(
    "$EXTENSION_DIR/extension.js"
    "$EXTENSION_DIR/metadata.json"
    "$EXTENSION_DIR/schemas/org.gnome.shell.extensions.span-window.gschema.xml"
    "$EXTENSION_DIR/schemas/gschemas.compiled"
)

for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        ok "$(basename "$file")"
    else
        error "Arquivo ausente: $file"
    fi
done

# ==============================================================
# 6. CONTEÚDO DA EXTENSÃO
# ==============================================================

echo
echo "[6/8] Verificando conteúdo da extensão..."

EXTENSION_JS="$EXTENSION_DIR/extension.js"
METADATA="$EXTENSION_DIR/metadata.json"
SCHEMA="$EXTENSION_DIR/schemas/org.gnome.shell.extensions.span-window.gschema.xml"

if [[ -f "$EXTENSION_JS" ]]; then

    if grep -q "get_maximize_level" "$EXTENSION_JS"; then
        ok "Extensão utiliza get_maximize_level()."
    else
        error "get_maximize_level() não encontrado."
    fi

    if grep -q "set_maximize_level" "$EXTENSION_JS"; then
        ok "Extensão utiliza set_maximize_level()."
    else
        error "set_maximize_level() não encontrado."
    fi

    if grep -q "make_fullscreen" "$EXTENSION_JS"; then
        ok "Suporte ao nível 3 fullscreen."
    else
        error "make_fullscreen() não encontrado."
    fi

    if grep -q "span-window-maximize" "$EXTENSION_JS"; then
        ok "Atalho de avanço encontrado."
    else
        error "Atalho de avanço não encontrado."
    fi

    if grep -q "span-window-unmaximize" "$EXTENSION_JS"; then
        ok "Atalho de retrocesso encontrado."
    else
        error "Atalho de retrocesso não encontrado."
    fi
fi

if [[ -f "$METADATA" ]]; then
    if grep -q '"uuid": "span-window@lucascechinmario"' "$METADATA"; then
        ok "UUID correto."
    else
        error "UUID incorreto."
    fi

    if grep -q '"shell-version": \["50"\]' "$METADATA"; then
        ok "Compatibilidade com GNOME Shell 50."
    else
        warning "shell-version não corresponde exatamente ao release."
    fi
fi

if [[ -f "$SCHEMA" ]]; then
    if grep -q 'org.gnome.shell.extensions.span-window' "$SCHEMA"; then
        ok "Schema correto."
    else
        error "ID do schema não encontrado."
    fi
fi

# ==============================================================
# 7. MASSERTER INSTALADO
# ==============================================================

echo
echo "[7/8] Verificando Mutter atualmente instalado..."

INSTALLED_VERSION="$(
    dpkg-query -W -f='${Version}' libmutter-18-0 2>/dev/null || true
)"

if [[ -n "$INSTALLED_VERSION" ]]; then
    echo "  libmutter-18-0: $INSTALLED_VERSION"

    if [[ "$INSTALLED_VERSION" == "$EXPECTED_VERSION"* ]]; then
        ok "Versão instalada corresponde ao release."
    else
        warning "A versão instalada é diferente da versão do release."
    fi
else
    warning "libmutter-18-0 não está instalado."
fi

LIB="/usr/lib/x86_64-linux-gnu/libmutter-18.so.0"

if [[ -f "$LIB" ]]; then

    if command -v nm >/dev/null 2>&1; then

        if nm -D "$LIB" 2>/dev/null |
            grep -q "meta_window_set_maximize_level"; then
            ok "meta_window_set_maximize_level encontrado."
        else
            warning "meta_window_set_maximize_level não encontrado."
        fi

        if nm -D "$LIB" 2>/dev/null |
            grep -q "meta_window_get_maximize_level"; then
            ok "meta_window_get_maximize_level encontrado."
        else
            warning "meta_window_get_maximize_level não encontrado."
        fi

    else
        warning "nm não está instalado; símbolos não foram verificados."
    fi

else
    warning "libmutter-18.so.0 não encontrada."
fi

# ==============================================================
# 8. SCHEMA COMPILADO
# ==============================================================

echo
echo "[8/8] Verificando schema compilado..."

COMPILED_SCHEMA="$EXTENSION_DIR/schemas/gschemas.compiled"

if [[ -f "$COMPILED_SCHEMA" ]]; then

    if command -v gsettings >/dev/null 2>&1; then

        if GSETTINGS_SCHEMA_DIR="$EXTENSION_DIR/schemas" \
            gsettings list-keys org.gnome.shell.extensions.span-window \
            >/dev/null 2>&1; then

            ok "Schema carregável pelo GSettings."

            KEYS="$(
                GSETTINGS_SCHEMA_DIR="$EXTENSION_DIR/schemas" \
                gsettings list-keys \
                org.gnome.shell.extensions.span-window
            )"

            if echo "$KEYS" | grep -qx "span-window-maximize"; then
                ok "Chave span-window-maximize encontrada."
            else
                error "Chave span-window-maximize ausente."
            fi

            if echo "$KEYS" | grep -qx "span-window-unmaximize"; then
                ok "Chave span-window-unmaximize encontrada."
            else
                error "Chave span-window-unmaximize ausente."
            fi

        else
            error "Schema compilado não pôde ser carregado."
        fi

    else
        warning "gsettings não está disponível."
    fi
fi

# ==============================================================
# RESULTADO
# ==============================================================

echo
echo "=============================================================="
echo " RESULTADO"
echo "=============================================================="
echo
echo " Erros:   $ERRORS"
echo " Avisos:  $WARNINGS"
echo

if [[ "$ERRORS" -eq 0 ]]; then
    echo " VERIFICAÇÃO: OK"
    echo
    echo " O projeto está estruturalmente pronto para instalação."
    echo " Avisos sobre o Mutter instalado podem ser normais"
    echo " antes da instalação do release."
    echo
    echo "=============================================================="
    exit 0
else
    echo " VERIFICAÇÃO: FALHOU"
    echo
    echo " Corrija os erros acima antes de instalar."
    echo
    echo "=============================================================="
    exit 1
fi
