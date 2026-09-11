#!/usr/bin/env bash

set -euo pipefail

# ==============================================================
# SPAN WINDOW V2
# Instalador oficial
# Ubuntu 26.04 / amd64 / GNOME 50
# ==============================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PACKAGE_DIR="$PROJECT_DIR/packages/ubuntu-26.04/amd64"

EXTENSION_NAME="span-window@lucascechinmario"

EXTENSION_SOURCE="$PROJECT_DIR/extension/$EXTENSION_NAME"
EXTENSION_TARGET="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_NAME"

VERSION="2.0"
MUTTER_VERSION="50.1-0ubuntu2.2"

LIB="/usr/lib/x86_64-linux-gnu/libmutter-18.so.0"

BACKUP_ROOT="$HOME/.local/share/span-window-v2-backup"
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"

PACKAGES=(
    "$PACKAGE_DIR/libmutter-18-0_${MUTTER_VERSION}_amd64.deb"
    "$PACKAGE_DIR/gir1.2-mutter-18_${MUTTER_VERSION}_amd64.deb"
    "$PACKAGE_DIR/mutter_${MUTTER_VERSION}_amd64.deb"
)

# ==============================================================
# FUNÇÕES
# ==============================================================

error()
{
    echo
    echo "ERRO: $*"
    echo
    exit 1
}

info()
{
    echo "  $*"
}

# ==============================================================
# CABEÇALHO
# ==============================================================

echo
echo "=============================================================="
echo "              SPAN WINDOW V$VERSION"
echo "                 INSTALADOR"
echo "=============================================================="
echo
echo "Projeto:"
echo "  $PROJECT_DIR"
echo

# ==============================================================
# SEGURANÇA
# ==============================================================

if [[ "$EUID" -eq 0 ]]; then
    error "não execute este instalador como root.

Execute normalmente:

  ./scripts/install.sh"
fi

if [[ ! -r /etc/os-release ]]; then
    error "/etc/os-release não encontrado."
fi

source /etc/os-release

# ==============================================================
# 1. SISTEMA
# ==============================================================

echo "[1/10] Verificando sistema..."

if [[ "${ID:-}" != "ubuntu" ]]; then
    error "este instalador exige Ubuntu.

Sistema detectado:
${PRETTY_NAME:-desconhecido}"
fi

if [[ "${VERSION_ID:-}" != "26.04" ]]; then
    error "este release foi preparado para Ubuntu 26.04.

Sistema detectado:
${PRETTY_NAME:-desconhecido}"
fi

ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
    error "este release suporta somente amd64.

Arquitetura detectada:
$ARCH"
fi

info "Sistema:      ${PRETTY_NAME}"
info "Arquitetura:  $ARCH"

echo

# ==============================================================
# 2. GNOME SHELL
# ==============================================================

echo "[2/10] Verificando GNOME Shell..."

if ! command -v gnome-shell >/dev/null 2>&1; then
    error "GNOME Shell não encontrado."
fi

GNOME_VERSION="$(gnome-shell --version 2>/dev/null || true)"

if [[ -z "$GNOME_VERSION" ]]; then
    error "não foi possível determinar a versão do GNOME Shell."
fi

info "$GNOME_VERSION"

if [[ "$GNOME_VERSION" != *"50."* ]]; then

    echo
    echo "AVISO:"
    echo "Este release foi desenvolvido para GNOME Shell 50."
    echo "Versão detectada: $GNOME_VERSION"
    echo

    read -r -p "Continuar mesmo assim? [s/N] " ANSWER

    if [[ ! "$ANSWER" =~ ^[Ss]$ ]]; then
        echo
        echo "Instalação cancelada."
        exit 0
    fi
fi

echo

# ==============================================================
# 3. DEPENDÊNCIAS BÁSICAS
# ==============================================================

echo "[3/10] Verificando ferramentas..."

for command in dpkg dpkg-deb gsettings glib-compile-schemas nm; do

    if ! command -v "$command" >/dev/null 2>&1; then
        error "comando necessário não encontrado: $command"
    fi

    info "$command OK"
done

echo

# ==============================================================
# 4. PACOTES
# ==============================================================

echo "[4/10] Verificando pacotes do Mutter..."

for package in "${PACKAGES[@]}"; do

    if [[ ! -f "$package" ]]; then
        error "pacote não encontrado:

$package"
    fi

    NAME="$(dpkg-deb -f "$package" Package)"
    VERSION_CHECK="$(dpkg-deb -f "$package" Version)"
    ARCH_CHECK="$(dpkg-deb -f "$package" Architecture)"

    if [[ "$VERSION_CHECK" != "$MUTTER_VERSION" ]]; then
        error "versão incorreta em $NAME.

Esperada:
$MUTTER_VERSION

Encontrada:
$VERSION_CHECK"
    fi

    if [[ "$ARCH_CHECK" != "amd64" && "$ARCH_CHECK" != "all" ]]; then
        error "arquitetura incorreta em $NAME.

Encontrada:
$ARCH_CHECK"
    fi

    info "OK: $NAME $VERSION_CHECK ($ARCH_CHECK)"

done

echo

# ==============================================================
# 5. EXTENSÃO
# ==============================================================

echo "[5/10] Verificando extensão..."

if [[ ! -d "$EXTENSION_SOURCE" ]]; then
    error "diretório da extensão não encontrado:

$EXTENSION_SOURCE"
fi

REQUIRED_FILES=(
    "$EXTENSION_SOURCE/extension.js"
    "$EXTENSION_SOURCE/metadata.json"
    "$EXTENSION_SOURCE/schemas/org.gnome.shell.extensions.span-window.gschema.xml"
)

for file in "${REQUIRED_FILES[@]}"; do

    if [[ ! -f "$file" ]]; then
        error "arquivo obrigatório não encontrado:

$file"
    fi

    info "OK: $(basename "$file")"

done

SCHEMA_DIR="$EXTENSION_SOURCE/schemas"
SCHEMA_XML="$SCHEMA_DIR/org.gnome.shell.extensions.span-window.gschema.xml"

echo

# ==============================================================
# 6. SCHEMA
# ==============================================================

echo "[6/10] Verificando schema..."

# Verifica o tipo das duas chaves independentemente da formatação
# do XML (atributos podem estar em linhas diferentes).

MAX_KEY_BLOCK="$(
    sed -n '/<key name="span-window-maximize"/,/\/key>/p' \
    "$SCHEMA_XML"
)"

MIN_KEY_BLOCK="$(
    sed -n '/<key name="span-window-unmaximize"/,/\/key>/p' \
    "$SCHEMA_XML"
)"

if ! grep -q 'type="as"' <<< "$MAX_KEY_BLOCK"; then
    error "o schema não define span-window-maximize como type=\"as\"."
fi

if ! grep -q 'type="as"' <<< "$MIN_KEY_BLOCK"; then
    error "o schema não define span-window-unmaximize como type=\"as\"."
fi

info "span-window-maximize: type as"
info "span-window-unmaximize: type as"

echo
echo "  Recompilando gschemas.compiled..."

glib-compile-schemas "$SCHEMA_DIR"

if [[ ! -f "$SCHEMA_DIR/gschemas.compiled" ]]; then
    error "falha ao gerar gschemas.compiled."
fi

info "gschemas.compiled OK"

echo

# ==============================================================
# 7. VERIFICAÇÃO DO CONTEÚDO DA EXTENSÃO
# ==============================================================

echo "[7/10] Verificando código da extensão..."

if ! grep -q "get_maximize_level" \
    "$EXTENSION_SOURCE/extension.js"; then

    error "get_maximize_level() não encontrado na extensão."
fi

if ! grep -q "set_maximize_level" \
    "$EXTENSION_SOURCE/extension.js"; then

    error "set_maximize_level() não encontrado na extensão."
fi

if ! grep -q "span-window-maximize" \
    "$EXTENSION_SOURCE/extension.js"; then

    error "keybinding span-window-maximize não encontrado."
fi

if ! grep -q "span-window-unmaximize" \
    "$EXTENSION_SOURCE/extension.js"; then

    error "keybinding span-window-unmaximize não encontrado."
fi

info "API maximize_level OK"
info "keybindings OK"

echo

# ==============================================================
# 8. BACKUP
# ==============================================================

echo "[8/10] Criando backup..."

mkdir -p "$BACKUP_DIR"

info "Backup: $BACKUP_DIR"

# --------------------------------------------------------------
# Estado dos pacotes
# --------------------------------------------------------------

{
    echo "SPAN WINDOW V$VERSION"
    echo
    echo "Data: $(date)"
    echo
    echo "Pacotes instalados antes da instalação:"
    echo

    for package_name in \
        libmutter-18-0 \
        gir1.2-mutter-18 \
        mutter \
        mutter-common \
        mutter-common-bin
    do

        printf "%-24s " "$package_name"

        dpkg-query \
            -W \
            -f='${Status} ${Version}\n' \
            "$package_name" \
            2>/dev/null || echo "não instalado"

    done

} > "$BACKUP_DIR/package-state.txt"

# --------------------------------------------------------------
# Backup da extensão
# --------------------------------------------------------------

if [[ -d "$EXTENSION_TARGET" ]]; then

    info "Extensão existente encontrada."

    cp -a \
        "$EXTENSION_TARGET" \
        "$BACKUP_DIR/extension"

    info "Backup da extensão criado."

else

    info "Nenhuma instalação anterior da extensão."

    echo "NONE" > "$BACKUP_DIR/no-previous-extension"
fi

# --------------------------------------------------------------
# Backup dos atalhos
# --------------------------------------------------------------

{
    echo "span-window-maximize="
    gsettings get \
        org.gnome.shell.extensions.span-window \
        span-window-maximize \
        2>/dev/null || echo "UNAVAILABLE"

    echo "span-window-unmaximize="
    gsettings get \
        org.gnome.shell.extensions.span-window \
        span-window-unmaximize \
        2>/dev/null || echo "UNAVAILABLE"

} > "$BACKUP_DIR/keybindings.txt"

info "Backup dos keybindings criado."

echo

# ==============================================================
# CONFIRMAÇÃO
# ==============================================================

echo "=============================================================="
echo "                    CONFIRMAÇÃO"
echo "=============================================================="
echo
echo "O instalador irá:"
echo
echo "  • instalar o Mutter modificado"
echo "  • instalar a extensão Span Window V2"
echo "  • configurar Super + Up"
echo "  • configurar Super + Down"
echo "  • recompilar o schema"
echo "  • manter um backup"
echo
echo "Backup:"
echo "  $BACKUP_DIR"
echo
echo "=============================================================="
echo

read -r -p "Continuar com a instalação? [s/N] " ANSWER

if [[ ! "$ANSWER" =~ ^[Ss]$ ]]; then
    echo
    echo "Instalação cancelada."
    exit 0
fi

echo

# ==============================================================
# 9. MUTTER
# ==============================================================

echo "[9/10] Instalando Mutter modificado..."

sudo dpkg -i "${PACKAGES[@]}"

echo
info "Pacotes do Mutter instalados."

# --------------------------------------------------------------
# Verificação do estado dpkg
# --------------------------------------------------------------

if ! dpkg --audit >/dev/null 2>&1; then

    echo
    echo "AVISO: existem pacotes com configuração pendente."
    echo
    echo "Tentando configurar pacotes..."
    echo

    sudo dpkg --configure -a

fi

echo

# ==============================================================
# EXTENSÃO + KEYBINDINGS
# ==============================================================

echo "[10/10] Instalando extensão..."

if command -v gnome-extensions >/dev/null 2>&1; then

    if gnome-extensions list 2>/dev/null |
        grep -qx "$EXTENSION_NAME"; then

        info "Desabilitando instalação anterior..."

        gnome-extensions disable \
            "$EXTENSION_NAME" \
            2>/dev/null || true

    fi

fi

rm -rf "$EXTENSION_TARGET"

mkdir -p "$(dirname "$EXTENSION_TARGET")"

cp -a \
    "$EXTENSION_SOURCE" \
    "$EXTENSION_TARGET"

info "Extensão copiada."

# ==============================================================
# RECOMPILAR SCHEMA DA INSTALAÇÃO
# ==============================================================

INSTALLED_SCHEMA_DIR="$EXTENSION_TARGET/schemas"

glib-compile-schemas "$INSTALLED_SCHEMA_DIR"

info "Schema compilado."

export GSETTINGS_SCHEMA_DIR="$INSTALLED_SCHEMA_DIR"

# ==============================================================
# CONFIGURAÇÃO EXPLÍCITA DOS ATALHOS
# ==============================================================

echo
echo "Configurando atalhos..."

gsettings set \
    org.gnome.shell.extensions.span-window \
    span-window-maximize \
    "['<Super>Up']"

gsettings set \
    org.gnome.shell.extensions.span-window \
    span-window-unmaximize \
    "['<Super>Down']"

MAX_KEY="$(gsettings get \
    org.gnome.shell.extensions.span-window \
    span-window-maximize)"

MIN_KEY="$(gsettings get \
    org.gnome.shell.extensions.span-window \
    span-window-unmaximize)"

if [[ "$MAX_KEY" != "['<Super>Up']" ]]; then
    error "não foi possível configurar Super + Up.

Valor atual:
$MAX_KEY"
fi

if [[ "$MIN_KEY" != "['<Super>Down']" ]]; then
    error "não foi possível configurar Super + Down.

Valor atual:
$MIN_KEY"
fi

info "Super + Up OK"
info "Super + Down OK"

# ==============================================================
# VERIFICAÇÃO FINAL
# ==============================================================

echo
echo "Verificando instalação final..."

FAIL=0

# --------------------------------------------------------------
# Extensão
# --------------------------------------------------------------

if [[ ! -f "$EXTENSION_TARGET/extension.js" ]]; then
    echo "  ERRO: extension.js não encontrado."
    FAIL=1
else
    info "extension.js OK"
fi

# --------------------------------------------------------------
# Schema
# --------------------------------------------------------------

if [[ ! -f "$EXTENSION_TARGET/schemas/gschemas.compiled" ]]; then
    echo "  ERRO: gschemas.compiled não encontrado."
    FAIL=1
else
    info "gschemas.compiled OK"
fi

# --------------------------------------------------------------
# Schema runtime
# --------------------------------------------------------------

SCHEMA_RANGE_MAX="$(gsettings range \
    org.gnome.shell.extensions.span-window \
    span-window-maximize 2>/dev/null || true)"

SCHEMA_RANGE_MIN="$(gsettings range \
    org.gnome.shell.extensions.span-window \
    span-window-unmaximize 2>/dev/null || true)"

if [[ "$SCHEMA_RANGE_MAX" != "type as" ]]; then
    echo "  ERRO: schema runtime de Super + Up não é type as."
    echo "        Detectado: $SCHEMA_RANGE_MAX"
    FAIL=1
else
    info "schema Super + Up: type as"
fi

if [[ "$SCHEMA_RANGE_MIN" != "type as" ]]; then
    echo "  ERRO: schema runtime de Super + Down não é type as."
    echo "        Detectado: $SCHEMA_RANGE_MIN"
    FAIL=1
else
    info "schema Super + Down: type as"
fi

# --------------------------------------------------------------
# Keybindings
# --------------------------------------------------------------

if [[ "$MAX_KEY" != "['<Super>Up']" ]]; then
    echo "  ERRO: Super + Up incorreto."
    FAIL=1
else
    info "Super + Up configurado"
fi

if [[ "$MIN_KEY" != "['<Super>Down']" ]]; then
    echo "  ERRO: Super + Down incorreto."
    FAIL=1
else
    info "Super + Down configurado"
fi

# --------------------------------------------------------------
# Biblioteca
# --------------------------------------------------------------

if [[ ! -f "$LIB" ]]; then

    echo "  ERRO: $LIB não encontrada."
    FAIL=1

else

    SYMBOLS="$(nm -D "$LIB" 2>/dev/null || true)"

    if grep -Fq "meta_window_set_maximize_level" <<< "$SYMBOLS"; then
        info "meta_window_set_maximize_level OK"
    else
        echo "  ERRO: meta_window_set_maximize_level não encontrado."
        FAIL=1
    fi

    if grep -Fq "meta_window_get_maximize_level" <<< "$SYMBOLS"; then
        info "meta_window_get_maximize_level OK"
    else
        echo "  ERRO: meta_window_get_maximize_level não encontrado."
        FAIL=1
    fi

fi

# --------------------------------------------------------------
# Versão instalada
# --------------------------------------------------------------

INSTALLED_VERSION="$(
    dpkg-query \
        -W \
        -f='${Version}' \
        libmutter-18-0 \
        2>/dev/null || true
)"

if [[ "$INSTALLED_VERSION" == "$MUTTER_VERSION" ]]; then
    info "libmutter-18-0 $INSTALLED_VERSION OK"
else
    echo "  ERRO: versão instalada incorreta."
    echo "        Esperada: $MUTTER_VERSION"
    echo "        Atual:    ${INSTALLED_VERSION:-não instalada}"
    FAIL=1
fi

# --------------------------------------------------------------
# Estado da extensão
# --------------------------------------------------------------

if command -v gnome-extensions >/dev/null 2>&1; then

    gnome-extensions enable \
        "$EXTENSION_NAME" \
        2>/dev/null || true

    if gnome-extensions list --enabled 2>/dev/null |
        grep -qx "$EXTENSION_NAME"; then

        info "extensão habilitada"

    else

        echo "  AVISO: extensão não aparece como habilitada."
        echo "        Ela poderá ser ativada após logout/login."

    fi

fi

# ==============================================================
# RESULTADO
# ==============================================================

echo

if [[ "$FAIL" -ne 0 ]]; then

    echo "=============================================================="
    echo "              INSTALAÇÃO COM ERROS"
    echo "=============================================================="
    echo
    echo "Backup:"
    echo "  $BACKUP_DIR"
    echo
    echo "NÃO reinicie a sessão ainda."
    echo
    exit 1
fi

echo "=============================================================="
echo "        SPAN WINDOW V$VERSION - INSTALAÇÃO OK"
echo "=============================================================="
echo
echo "Mutter modificado: instalado"
echo "Extensão:           instalada"
echo "Schema:             compilado"
echo "Super + Up:         configurado"
echo "Super + Down:       configurado"
echo
echo "Níveis:"
echo
echo "  0  Janela normal"
echo "  1  Maximizada no monitor atual"
echo "  2  Maximizada em todos os monitores"
echo "  3  Fullscreen em todos os monitores"
echo
echo "Backup:"
echo "  $BACKUP_DIR"
echo
echo "=============================================================="
echo
echo "IMPORTANTE"
echo
echo "Faça logout e login novamente antes de testar."
echo
echo "Depois de uma atualização do Ubuntu, execute:"
echo
echo "  ./scripts/verify.sh"
echo
echo "O pacote modificado usa a mesma versão do pacote oficial:"
echo
echo "  $MUTTER_VERSION"
echo
echo "Uma atualização futura do Mutter pode substituir"
echo "a biblioteca modificada."
echo
echo "=============================================================="
