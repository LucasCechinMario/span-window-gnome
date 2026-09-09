# Span Window

Extensão do GNOME Shell + patches personalizados do Mutter para maximização progressiva de janelas em múltiplos monitores.

O Span Window adiciona um sistema de **níveis de maximização**, permitindo alternar progressivamente entre uma janela normal, maximização no monitor atual, maximização em todos os monitores e fullscreen em toda a área de trabalho.

---

## ✨ Recursos

O Span Window possui quatro níveis de janela:

| Nível | Modo | Descrição |
|------:|------|-----------|
| **0** | 🪟 Normal | Janela em seu tamanho e posição normais |
| **1** | 🖥️ Maximizada | Maximiza a janela somente no monitor atual |
| **2** | 🖥️🖥️ Span | Maximiza a janela utilizando todos os monitores |
| **3** | ⛶ Fullscreen | Fullscreen real utilizando todos os monitores |

Os níveis podem ser alterados progressivamente utilizando os atalhos configurados.

### Exemplo

```text
             Super + Up
                  │
                  ▼
        ┌──────────────────┐
        │ Nível 0 — Normal │
        └────────┬─────────┘
                 │
                 ▼
     ┌──────────────────────────┐
     │ Nível 1 — Maximizada     │
     │ Monitor atual            │
     └────────────┬─────────────┘
                  │
                  ▼
     ┌──────────────────────────┐
     │ Nível 2 — Span           │
     │ Todos os monitores       │
     └────────────┬─────────────┘
                  │
                  ▼
     ┌──────────────────────────┐
     │ Nível 3 — Fullscreen     │
     │ Todos os monitores       │
     └──────────────────────────┘
```

---

## ⌨️ Atalhos

### Aumentar nível

```text
Super + Up
```

Aumenta o nível atual da janela:

```text
0 → 1 → 2 → 3
```

Ao atingir o nível 3, pressionar novamente o atalho não altera o estado.

### Diminuir nível

```text
Super + Down
```

Diminui o nível atual:

```text
3 → 2 → 1 → 0
```

Ao atingir o nível 0, pressionar novamente o atalho não altera o estado.

---

## 🖥️ Compatibilidade

O projeto foi desenvolvido e testado para:

- Ubuntu 26.04 LTS
- GNOME Shell 50.1
- Mutter 50.1
- Wayland
- arquitetura `amd64`

### Requisitos

O Span Window modifica o comportamento do Mutter.

Por isso, não é apenas uma extensão convencional do GNOME Shell.

É necessário utilizar a versão modificada do Mutter fornecida neste projeto.

---

## ⚠️ Antes da instalação

O Span Window utiliza os atalhos:

Super + Up
Super + Down

Esses atalhos podem entrar em conflito com os atalhos padrão de tiling (organização de janelas) do GNOME.

### Desabilite os atalhos de tiling do GNOME

Antes de utilizar o Span Window, é necessário desabilitar os atalhos de teclado padrão do GNOME que utilizam `Super + Up` e `Super + Down` para maximização ou organização de janelas.

Caso esses atalhos permaneçam ativos, o GNOME e o Span Window poderão responder simultaneamente ao mesmo comando, causando conflitos e comportamento inesperado.

No GNOME, acesse:

Configurações → Teclado → Atalhos de teclado → Janelas

e desabilite os atalhos de tiling/maximização que utilizam:

Super + Up
Super + Down

Importante: não é necessário desabilitar o sistema de tiling do GNOME inteiro. Apenas os atalhos de teclado que entram em conflito com o Span Window precisam ser desabilitados.

Depois disso, os atalhos do Span Window funcionarão da seguinte maneira:

Super + Up

0 → 1 → 2 → 3


Super + Down

3 → 2 → 1 → 0

---

## 📦 Instalação

Clone o repositório:

```bash
git clone https://github.com/LucasCechinMario/span-window-gnome.git
cd span-window-gnome
```

Execute o instalador:

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

Depois da instalação, faça **logout e login novamente** para garantir que o GNOME Shell carregue corretamente a versão modificada do Mutter.

Após entrar novamente na sessão, a extensão estará disponível.

---

## 🔍 Verificação da instalação

O projeto possui um script de verificação que testa os principais componentes:

```bash
./scripts/verify.sh
```

A verificação confirma:

- versão do Ubuntu;
- arquitetura;
- versão do GNOME Shell;
- versão do Mutter;
- bibliotecas instaladas;
- símbolos personalizados do Mutter;
- extensão;
- schema do GSettings;
- atalhos;
- suporte ao fullscreen;
- estado da instalação.

Uma instalação válida deve terminar com:

```text
Erros:   0
Avisos:  0
VERIFICAÇÃO: OK
```

---

## 🗑️ Desinstalação

Para remover o Span Window:

```bash
./scripts/uninstall.sh
```

O instalador mantém um backup das configurações alteradas durante a instalação.

Os backups são armazenados em:

```text
~/.local/share/span-window-v2-backup/
```

Isso permite recuperar configurações anteriores caso seja necessário.

---

## 🔧 Como funciona

O Span Window é composto por duas partes principais:

```text
Span Window
│
├── GNOME Shell Extension
│
└── Mutter modificado
```

### Extensão do GNOME Shell

A extensão controla os atalhos e determina qual nível deve ser aplicado à janela atualmente focada.

Ela utiliza as APIs adicionadas ao Mutter:

```text
get_maximize_level()
set_maximize_level()
```

O estado da janela é representado por um valor de `0` a `3`.

---

### Mutter modificado

O Mutter recebe alterações para permitir que o nível solicitado pela extensão seja respeitado durante o processo de maximização e fullscreen.

O projeto adiciona suporte para:

```text
Nível 0
Janela normal

Nível 1
Maximização no monitor atual

Nível 2
Maximização através de todos os monitores

Nível 3
Fullscreen através de todos os monitores
```

O comportamento de maximização entre múltiplos monitores exige alterações no sistema de restrições de geometria do Mutter.

Por isso, uma extensão GNOME Shell sozinha não seria suficiente para implementar o comportamento completo.

---

## 🖥️ Múltiplos monitores

O Span Window utiliza a área combinada dos monitores.

Por exemplo, com dois monitores lado a lado:

```text
┌──────────────────────┬────────────────────────────┐
│                      │                            │
│      Monitor 1       │         Monitor 2         │
│                      │                            │
│                      │                            │
└──────────────────────┴────────────────────────────┘
                    ↓
             Nível 2 — Span

┌────────────────────────────────────────────────────┐
│                                                    │
│                 Janela maximizada                  │
│                                                    │
└────────────────────────────────────────────────────┘
```

No nível 3, o comportamento passa para fullscreen utilizando a área total dos monitores:

```text
┌────────────────────────────────────────────────────┐
│                                                    │
│                                                    │
│                   FULLSCREEN                       │
│                                                    │
│                                                    │
└────────────────────────────────────────────────────┘
```

O nível 3 também permite que a janela ocupe a área normalmente utilizada pela barra superior e pelo dock.

---

## 📁 Estrutura do projeto

```text
span-window-gnome/
│
├── extension/
│   └── span-window@lucascechinmario/
│       ├── extension.js
│       ├── metadata.json
│       └── schemas/
│           └── org.gnome.shell.extensions.span-window.gschema.xml
│
├── mutter/
│   └── patches/
│       ├── 0001-add-maximize-level.patch
│       └── 0002-add-fullscreen-all-monitors.patch
│
├── packages/
│   └── ubuntu-26.04/
│       └── amd64/
│           ├── gir1.2-mutter-18_*.deb
│           ├── libmutter-18-0_*.deb
│           └── mutter_*.deb
│
├── scripts/
│   ├── build-mutter.sh
│   ├── install.sh
│   ├── uninstall.sh
│   └── verify.sh
│
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🧩 Patches do Mutter

Os patches estão disponíveis em:

```text
mutter/patches/
```

Eles adicionam ao Mutter o suporte necessário para:

- armazenar o nível de maximização;
- expor o nível através do GObject Introspection;
- permitir maximização através de múltiplos monitores;
- impedir que as restrições normais de monitor reduzam a janela;
- permitir fullscreen através de todos os monitores.

---

## ⚠️ Observações importantes

### Atualizações do Mutter

O Span Window modifica diretamente componentes do Mutter.

Uma atualização futura do Ubuntu ou do GNOME poderá substituir a biblioteca modificada pela versão oficial.

Após uma atualização do Mutter, execute:

```bash
./scripts/verify.sh
```

Se os símbolos personalizados não forem encontrados, será necessário reinstalar ou reconstruir o Span Window para a nova versão do Mutter.

---

### Compatibilidade de versões

Esta versão do projeto foi desenvolvida especificamente para:

```text
Ubuntu 26.04
GNOME Shell 50.1
Mutter 50.1
amd64
```

Não há garantia de compatibilidade com outras versões do GNOME, Mutter ou Ubuntu.

---

### Wayland

O projeto foi desenvolvido e testado utilizando:

```text
Wayland
```

O comportamento em sessões X11 não é o foco desta implementação.

---

## 🚧 Estado do projeto

**Funcional.**

A implementação atual possui:

- [x] Nível 0 — Janela normal
- [x] Nível 1 — Maximização no monitor atual
- [x] Nível 2 — Maximização em todos os monitores
- [x] Nível 3 — Fullscreen em todos os monitores
- [x] `Super + Up`
- [x] `Super + Down`
- [x] Limite mínimo no nível 0
- [x] Limite máximo no nível 3
- [x] Suporte a múltiplos monitores
- [x] Instalação automatizada
- [x] Desinstalação
- [x] Verificação automatizada
- [x] Backup das configurações
- [x] Pacotes `.deb` para Ubuntu 26.04 amd64

---

## 🛠️ Desenvolvimento

Para reconstruir o Mutter modificado:

```bash
./scripts/build-mutter.sh
```

Os patches utilizados estão disponíveis em:

```text
mutter/patches/
```

O projeto mantém os patches separados para facilitar a análise, manutenção e aplicação sobre o código-fonte correspondente do Mutter.

---

## 📜 Licença

Este projeto é distribuído sob a licença:

**GNU General Public License v3.0**

Consulte o arquivo [`LICENSE`](LICENSE) para obter o texto completo da licença.

---

## 👤 Autor

Desenvolvido por **Lucas Cechin Mário**.

GitHub:

**https://github.com/LucasCechinMario**

---

## ⭐ Contribuições

Sugestões, correções, testes e contribuições são bem-vindos.

Se você encontrar um problema, abra uma **Issue** descrevendo:

- versão do Ubuntu;
- versão do GNOME Shell;
- versão do Mutter;
- arquitetura;
- número de monitores;
- configuração dos monitores;
- comportamento esperado;
- comportamento observado;
- saída de:

```bash
./scripts/verify.sh
```

---

## ⭐ Apoie o projeto

Se o Span Window for útil para você, considere deixar uma ⭐ no repositório.

Isso ajuda o projeto a ganhar visibilidade e incentiva o desenvolvimento de novas funcionalidades.
