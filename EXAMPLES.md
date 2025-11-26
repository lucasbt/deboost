# 📚 Deboost - Exemplos de Uso

## Instalação

### Instalação Rápida (Recomendado)

```bash
# Instalar via curl
curl -fsSL https://raw.githubusercontent.com/lucasbt/deboost/main/install.sh | bash

# Adicionar ao PATH (se necessário)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Instalação Manual

```bash
# Clonar repositório
git clone https://github.com/lucasbt/deboost.git ~/.local/share/deboost

# Executar bootstrap
cd ~/.local/share/deboost
./deboost bootstrap
```

## Uso Básico

### Ver Ajuda

```bash
deboost help
deboost --help
deboost -h
```

### Listar Módulos Disponíveis

```bash
deboost list
```

Saída esperada:
```
Módulos disponíveis:
  system-update        Atualiza o sistema e instala firmware essencial
  intel-graphics       Configura drivers Intel i965 para GPUs Haswell
  gnome-settings       Configura GNOME/Wayland com otimizações anti-fadiga
  fonts                Instala e configura fontes otimizadas
  dev-tools            Instala asdf e ferramentas de desenvolvimento
  flatpak              Instala e configura Flatpak + Flathub
  browsers             Instala navegadores populares
Total: 7 módulo(s)
```

### Executar Todos os Módulos

```bash
# Modo dry-run (apenas mostra o que seria feito)
deboost install --dry-run

# Aplicar mudanças de verdade
deboost install --apply

# Com verbose para debug
deboost install --apply --verbose
```

### Executar Módulo Específico

```bash
# Apenas atualizar o sistema
deboost install system-update --apply

# Configurar GNOME
deboost install gnome-settings --apply

# Instalar fontes
deboost install fonts --apply
```

## Fluxo de Trabalho Típico

### 1. Instalação Inicial (Debian Fresh Install)

```bash
# 1. Instalar Deboost
curl -fsSL https://raw.githubusercontent.com/lucasbt/deboost/main/install.sh | bash
source ~/.bashrc

# 2. Ver o que será feito
deboost install --dry-run

# 3. Personalizar configuração (opcional)
deboost config
# Editar variáveis conforme necessidade

# 4. Executar instalação completa
deboost install --apply

# 5. Reiniciar (recomendado)
sudo reboot
```

### 2. Instalação Seletiva (Escolher Módulos)

```bash
# Apenas sistema básico
deboost install system-update --apply
deboost install intel-graphics --apply

# Apenas interface
deboost install gnome-settings --apply
deboost install fonts --apply

# Apenas desenvolvimento
deboost install dev-tools --apply

# Apenas aplicativos
deboost install flatpak --apply
deboost install browsers --apply
```

### 3. Manutenção e Atualização

```bash
# Atualizar Deboost para última versão
deboost update

# Re-executar configurações GNOME
deboost install gnome-settings --apply

# Verificar versão
deboost version
```

## Personalização

### Editando Configurações

```bash
# Abrir editor de configuração
deboost config

# Ou editar manualmente
nano ~/.local/share/deboost/config/env
```

### Exemplos de Personalização

#### 1. Mudar Temperatura do Night Light

```bash
# Em ~/.local/share/deboost/config/env
GNOME_NIGHT_LIGHT_TEMP=4000  # Mais frio
GNOME_NIGHT_LIGHT_TEMP=3000  # Mais quente (padrão: 3700)
```

#### 2. Habilitar Animações

```bash
GNOME_ENABLE_ANIMATIONS=true
```

#### 3. Ajustar Escala de Texto

```bash
GNOME_TEXT_SCALING=1.10  # 110%
GNOME_TEXT_SCALING=1.25  # 125% (para visão reduzida)
```

#### 4. Mudar Versões de Linguagens (asdf)

```bash
ASDF_JAVA_VERSION=temurin-21
ASDF_NODEJS_VERSION=20.0.0
ASDF_PYTHON_VERSION=3.11.0
ASDF_GOLANG_VERSION=1.22.0
```

#### 5. Desabilitar Firmware Proprietário

```bash
INSTALL_PROPRIETARY_FIRMWARE=false
```

## Cenários Específicos

### Cenário 1: Dell 2014 com Intel Haswell

```bash
# 1. Instalar sistema base
deboost install system-update --apply

# 2. Configurar drivers Intel i965
deboost install intel-graphics --apply

# 3. Verificar driver
vainfo
# Deve mostrar: Intel i965 driver

# 4. Configurar interface
deboost install gnome-settings --apply
deboost install fonts --apply

# 5. Reiniciar
sudo reboot
```

### Cenário 2: Máquina de Desenvolvimento

```bash
# 1. Base
deboost install system-update --apply

# 2. Ferramentas de dev
deboost install dev-tools --apply

# 3. Verificar instalações
asdf list
docker --version
podman --version

# 4. Instalar linguagens específicas
asdf install java temurin-21
asdf install nodejs lts
asdf install python 3.12.0
```

### Cenário 3: Desktop Minimalista

```bash
# Apenas essenciais
deboost install system-update --apply
deboost install gnome-settings --apply
deboost install fonts --apply

# Desabilitar módulos não necessários
# Em config/env:
DEBOOST_MODULES_IGNORE="dev-tools browsers"
```

## Troubleshooting

### Problema: Comando `deboost` não encontrado

```bash
# Verificar se está no PATH
echo $PATH | grep ".local/bin"

# Se não estiver, adicionar
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verificar instalação
ls -la ~/.local/bin/deboost
```

### Problema: Módulo falhou durante execução

```bash
# Executar com verbose
deboost install nome-modulo --verbose --apply

# Ver logs detalhados
# Os comandos exatos executados serão mostrados
```

### Problema: Night Light não está funcionando

```bash
# Verificar se está em Wayland
echo $XDG_SESSION_TYPE
# Deve retornar: wayland

# Reexecutar configurações GNOME
deboost install gnome-settings --apply

# Verificar manualmente
gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled
gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature
```

### Problema: Driver Intel não está funcionando

```bash
# Verificar se variável está configurada
echo $LIBVA_DRIVER_NAME
# Deve retornar: i965

# Verificar com vainfo
vainfo

# Se não funcionar, reexecutar módulo
deboost install intel-graphics --apply

# Fazer logout/login
```

### Problema: asdf não encontra comandos

```bash
# Verificar se asdf está no shell
which asdf

# Se não estiver, adicionar ao .bashrc
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
source ~/.bashrc

# Verificar plugins instalados
asdf plugin list

# Listar versões instaladas
asdf list java
asdf list nodejs
```

### Problema: Docker exige sudo

```bash
# Verificar se usuário está no grupo docker
groups | grep docker

# Se não estiver, adicionar
sudo usermod -aG docker $USER

# Fazer logout/login para aplicar
```

## Testes e Validação

### Testar Configuração GNOME

```bash
# Ver todas as configurações aplicadas
gsettings list-recursively org.gnome.desktop.interface
gsettings list-recursively org.gnome.settings-daemon.plugins.color
```

### Verificar Aceleração de Vídeo

```bash
# Intel
vainfo

# Mesa
glxinfo | grep "OpenGL renderer"
```

### Verificar Fontes Instaladas

```bash
# Listar fontes disponíveis
fc-list | grep -i "jetbrains\|inter\|fira"

# Testar renderização
fc-cache -fv
```

### Verificar Ferramentas de Dev

```bash
# asdf
asdf list

# Docker
docker ps
docker run hello-world

# Podman
podman ps
```

## Comandos Úteis

### Limpar Sistema Após Instalação

```bash
sudo apt autoremove -y
sudo apt autoclean
sudo apt clean
```

### Backup de Configurações

```bash
# Backup do arquivo env
cp ~/.local/share/deboost/config/env ~/.local/share/deboost/config/env.backup

# Backup das configurações GNOME
dconf dump /org/gnome/ > ~/gnome-settings-backup.conf
```

### Restaurar Configurações GNOME

```bash
# Se algo der errado, restaurar padrões
gsettings reset org.gnome.desktop.interface color-scheme
gsettings reset org.gnome.desktop.interface enable-animations
gsettings reset org.gnome.settings-daemon.plugins.color night-light-temperature
```

### Desinstalar Completamente

```bash
# Desinstalar Deboost
deboost uninstall

# Remover configurações GNOME aplicadas (opcional)
# Faça isso manualmente via GNOME Settings ou:
gsettings reset org.gnome.desktop.interface color-scheme
gsettings reset org.gnome.desktop.interface enable-animations
# ... etc

# Remover variáveis de ambiente
sudo rm /etc/profile.d/deboost_libva.sh
```

## Dicas e Melhores Práticas

### 1. Sempre Teste com Dry-Run Primeiro

```bash
deboost install --dry-run
```

### 2. Use Verbose para Debug

```bash
deboost install --verbose --apply
```

### 3. Backup Antes de Mudanças Grandes

```bash
# Backup do sistema
sudo timeshift create-snapshot

# Ou pelo menos backup das configs
dconf dump / > ~/dconf-backup.conf
```

### 4. Reinicie Após Mudanças de Driver

```bash
sudo reboot
```

### 5. Personalize Antes de Executar

```bash
deboost config
# Ajuste as variáveis
deboost install --apply
```

### 6. Documente Suas Personalizações

```bash
# Crie um arquivo de notas
echo "Minhas configurações do Deboost" > ~/deboost-notes.md
echo "- GNOME_NIGHT_LIGHT_TEMP=3500" >> ~/deboost-notes.md
```

## Recursos Adicionais

### Links Úteis

- Repositório: https://github.com/lucasbt/deboost
- Issues: https://github.com/lucasbt/deboost/issues
- Documentação Debian: https://www.debian.org/doc/
- GNOME Tweaks: `sudo apt install gnome-tweaks`

### Comunidade

- Reporte bugs via GitHub Issues
- Contribua com novos módulos via Pull Requests
- Compartilhe suas configurações

### Próximos Passos

Após configurar o sistema com Deboost:

1. Explore `gnome-tweaks` para mais personalizações
2. Configure atalhos de teclado
3. Instale extensões GNOME via Extension Manager
4. Configure seu ambiente de desenvolvimento
5. Personalize aplicativos via Flatpak