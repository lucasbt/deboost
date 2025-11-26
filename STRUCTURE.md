# 📂 Estrutura do Projeto Deboost

## Estrutura de Diretórios

```
deboost/
├── deboost                    # Executável principal (script bash)
├── install.sh                 # Instalador rápido via curl
├── Makefile                   # Automação para desenvolvimento
├── README.md                  # Documentação principal
├── STRUCTURE.md              # Este arquivo
├── LICENSE                    # Licença GPL-3.0
├── .gitignore                # Arquivos a ignorar no git
│
├── lib/                      # Bibliotecas compartilhadas
│   └── utils.sh              # Funções utilitárias para módulos
│
├── modules/                  # Módulos de instalação
│   ├── system-update.sh      # Atualização do sistema
│   ├── intel-graphics.sh     # Drivers Intel i965
│   ├── gnome-settings.sh     # Configurações GNOME
│   ├── fonts.sh              # Fontes e renderização
│   ├── dev-tools.sh          # Ferramentas de dev (asdf, docker)
│   ├── flatpak.sh            # Flatpak e Flathub
│   ├── browsers.sh           # Navegadores
│   └── ...                   # Adicione mais módulos aqui
│
├── config/                   # Configurações
│   └── env                   # Variáveis de ambiente (criado na instalação)
│
└── docs/                     # Documentação adicional (opcional)
    ├── CONTRIBUTING.md       # Guia de contribuição
    ├── MODULES.md           # Documentação de módulos
    └── FAQ.md               # Perguntas frequentes
```

## Arquivos Principais

### `deboost` (Executável Principal)
Script principal que gerencia todo o sistema:
- Bootstrap e instalação
- Gerenciamento de módulos
- Auto-update
- Interface CLI

### `install.sh` (Instalador)
Script autônomo que pode ser baixado via curl:
```bash
curl -fsSL https://raw.githubusercontent.com/lucasbt/deboost/main/install.sh | bash
```

### `lib/utils.sh` (Biblioteca de Funções)
Funções compartilhadas entre módulos:
- Logging colorido
- Execução de comandos (run, dry-run)
- Verificações de sistema
- Helpers para apt, gsettings, etc.

### `config/env` (Configuração)
Arquivo de variáveis de ambiente para personalização:
- Drivers (LIBVA_DRIVER_NAME)
- GNOME (tema, animações, fontes)
- Desenvolvimento (versões asdf)
- Comportamento (DRYRUN, VERBOSE)

## Como os Módulos Funcionam

### Estrutura de um Módulo

```bash
#!/usr/bin/env bash
# DESC: Descrição curta do módulo
# REQUIRES: sudo, git, curl
# TAGS: tag1, tag2, tag3

set -euo pipefail

# Importar funções utilitárias
source "${DEBOOST_HOME}/lib/utils.sh"

# Função principal do módulo
module_run() {
  log_info "Executando meu módulo..."
  
  # Usar funções da lib/utils.sh
  run "sudo apt install -y pacote"
  gsettings_set "org.gnome.desktop.interface" "color-scheme" "prefer-dark"
  
  log_success "Módulo concluído!"
}

# Executar
module_run
```

### Variáveis Disponíveis nos Módulos

Todas as variáveis do `config/env` são carregadas automaticamente:

```bash
${DEBOOST_HOME}              # ~/.local/share/deboost
${DEBOOST_CONFIG}            # ~/.local/share/deboost/config
${DRYRUN}                    # true/false
${VERBOSE}                   # true/false

# Variáveis personalizáveis (config/env)
${LIBVA_DRIVER_NAME}         # i965
${GNOME_COLOR_SCHEME}        # prefer-dark
${ASDF_JAVA_VERSION}         # temurin-25
# ... e todas as outras definidas em config/env
```

### Funções Disponíveis (lib/utils.sh)

```bash
# Logging
log_info "mensagem"
log_success "mensagem"
log_warn "mensagem"
log_error "mensagem"
log_debug "mensagem"

# Execução
run "comando"                # Respeita DRYRUN

# Verificações
require_command "git"
require_sudo
check_internet
is_wayland
is_gnome

# Interação
ask_yes_no "Pergunta?" "y"   # Retorna 0 para sim

# Pacotes
apt_install "pkg1" "pkg2"
apt_remove "pkg1" "pkg2"

# GNOME
gsettings_set "schema" "key" "value"

# Arquivos
backup_file "/path/to/file"
append_to_file "conteúdo" "/path/to/file"
```

## Fluxo de Instalação

```
┌─────────────────────────────────────────┐
│ 1. Usuário executa install.sh           │
│    curl ... | bash                       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Clone do repositório                 │
│    git clone ... ~/.local/share/deboost │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Criação da estrutura                 │
│    mkdir modules/ config/ lib/          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Symlink do executável                │
│    ln -s ... ~/.local/bin/deboost       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 5. Criação do config/env                │
│    (na primeira execução)               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 6. Usuário executa                      │
│    deboost install --apply              │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 7. Carrega config/env                   │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 8. Executa módulos em sequência         │
│    (system-update, intel-graphics, etc.)│
└─────────────────────────────────────────┘
```

## Fluxo de Execução de Módulo

```
┌─────────────────────────────────────────┐
│ deboost install nome-modulo --apply     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Carrega config/env                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Exporta variáveis (DRYRUN, etc.)        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Source do módulo (bash)                 │
│ modules/nome-modulo.sh                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Módulo importa lib/utils.sh             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Executa module_run()                    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Sucesso: retorna 0                      │
│ Falha: retorna 1                        │
└─────────────────────────────────────────┘
```

## Comandos Make para Desenvolvimento

```bash
make install      # Instala localmente para testes
make uninstall    # Remove instalação
make reinstall    # Reinstala (uninstall + install)

make test         # Testa todos os módulos (dry-run)
make test-module MODULE=nome  # Testa módulo específico

make lint         # Verifica sintaxe bash
make shellcheck   # Executa shellcheck
make format       # Formata scripts (requer shfmt)

make modules      # Lista módulos disponíveis
make check        # Verifica instalação
make clean        # Remove arquivos temporários

make dev-setup    # Configura ambiente de dev
make help         # Mostra ajuda
```

## Criando um Novo Módulo

1. **Criar arquivo em `modules/`**:
   ```bash
   touch modules/meu-modulo.sh
   chmod +x modules/meu-modulo.sh
   ```

2. **Usar o template**:
   ```bash
   #!/usr/bin/env bash
   # DESC: Descrição do módulo
   # REQUIRES: deps
   # TAGS: tags
   
   set -euo pipefail
   source "${DEBOOST_HOME}/lib/utils.sh"
   
   module_run() {
     log_info "Executando..."
     run "comando"
     log_success "Concluído!"
   }
   
   module_run
   ```

3. **Testar**:
   ```bash
   make test-module MODULE=meu-modulo
   ```

4. **Executar**:
   ```bash
   deboost install meu-modulo --apply
   ```

## Organização no GitHub

```
Repositório: https://github.com/lucasbt/deboost

Branches:
  main        - branch principal (estável)
  develop     - desenvolvimento
  feature/*   - novas funcionalidades
  hotfix/*    - correções urgentes

Releases:
  v1.0.0      - Release inicial
  v1.1.0      - Novos módulos
  ...

Issues/Labels:
  - enhancement
  - bug
  - module
  - documentation
  - question
```

## Convenções de Código

### Bash Style Guide
- Usar `set -euo pipefail` em todos os scripts
- Variáveis em MAIÚSCULAS para ambiente
- Funções em snake_case
- Comentários descritivos
- Validar comandos antes de usar (`command -v`)

### Mensagens de Log
- `log_info`: Informações gerais
- `log_success`: Operação bem-sucedida (verde)
- `log_warn`: Avisos não-críticos (amarelo)
- `log_error`: Erros críticos (vermelho)
- `log_debug`: Debug detalhado (só com --verbose)

### Módulos
- Um módulo = uma funcionalidade específica
- Devem ser idempotentes (rodar várias vezes sem problema)
- Usar `run()` para respeitar dry-run
- Verificar dependências no início

## Checklist para Novos Módulos

- [ ] Arquivo `.sh` em `modules/`
- [ ] Comentário `# DESC:` no topo
- [ ] Importa `lib/utils.sh`
- [ ] Função `module_run()`
- [ ] Usa `log_*` para output
- [ ] Usa `run` para comandos
- [ ] Testado com `--dry-run`
- [ ] Testado com `--apply`
- [ ] Documentado no código
- [ ] Adicionado ao README se relevante