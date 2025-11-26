# 🤝 Contribuindo para o Deboost

Obrigado por considerar contribuir com o Deboost! Este documento fornece diretrizes para contribuir com o projeto.

## 📋 Tabela de Conteúdos

- [Como Contribuir](#como-contribuir)
- [Reportando Bugs](#reportando-bugs)
- [Sugerindo Melhorias](#sugerindo-melhorias)
- [Criando Novos Módulos](#criando-novos-módulos)
- [Processo de Pull Request](#processo-de-pull-request)
- [Estilo de Código](#estilo-de-código)
- [Testes](#testes)

## Como Contribuir

Existem várias formas de contribuir com o Deboost:

1. **Reportar bugs** - Encontrou um problema? Abra uma issue!
2. **Sugerir melhorias** - Tem ideias? Compartilhe conosco!
3. **Criar novos módulos** - Adicione funcionalidades úteis
4. **Melhorar documentação** - Ajude outros usuários
5. **Testar** - Execute em diferentes configurações e reporte resultados
6. **Revisar PRs** - Ajude a revisar contribuições de outros

## 🐛 Reportando Bugs

Antes de reportar um bug:

1. **Verifique se já foi reportado** - Procure nas [issues existentes](https://github.com/lucasbt/deboost/issues)
2. **Use a versão mais recente** - Execute `deboost update`
3. **Teste em modo dry-run** - Confirme que o problema persiste

### Template para Bug Report

```markdown
**Descrição do Bug**
Uma descrição clara e concisa do problema.

**Como Reproduzir**
Passos para reproduzir o comportamento:
1. Execute '...'
2. Observe '...'
3. Veja erro

**Comportamento Esperado**
O que você esperava que acontecesse.

**Logs**
```bash
# Cole aqui a saída do comando com --verbose
deboost install modulo --verbose --dry-run
```

**Ambiente**
- OS: Debian 13
- Desktop: GNOME/Wayland
- Versão Deboost: [execute `deboost version`]
- Hardware relevante: [CPU, GPU, etc.]

**Contexto Adicional**
Qualquer outra informação relevante.
```

## 💡 Sugerindo Melhorias

### Template para Feature Request

```markdown
**Descrição da Funcionalidade**
Uma descrição clara do que você gostaria de adicionar.

**Motivação**
Por que essa funcionalidade seria útil?

**Proposta de Implementação**
Como você imagina que isso funcionaria?

**Alternativas Consideradas**
Outras soluções que você considerou?

**Contexto Adicional**
Screenshots, exemplos, referências, etc.
```

## 🧩 Criando Novos Módulos

### 1. Planejamento

Antes de começar:
- Verifique se a funcionalidade já existe
- Discuta em uma issue se for uma mudança grande
- Certifique-se que se encaixa no escopo do Deboost

### 2. Estrutura do Módulo

Crie um arquivo em `modules/` seguindo este template:

```bash
#!/usr/bin/env bash
# DESC: Descrição curta e clara do módulo
# REQUIRES: pacote1, pacote2
# TAGS: tag1, tag2

set -euo pipefail

# Importar funções utilitárias
source "${DEBOOST_HOME}/lib/utils.sh"

# Verificações iniciais (opcional)
module_check() {
  require_command "comando-necessario"
  
  if ! is_wayland; then
    log_warn "Este módulo funciona melhor em Wayland"
  fi
}

# Função principal
module_run() {
  log_info "Iniciando módulo..."
  
  # Use 'run' para respeitar dry-run
  run "sudo apt install -y pacote"
  
  # Use funções da lib/utils.sh
  gsettings_set "schema" "key" "value"
  
  # Sempre use log_* para output
  log_success "Módulo concluído!"
}

# Executar
module_check
module_run
```

### 3. Boas Práticas para Módulos

#### ✅ Faça:
- Use `set -euo pipefail` no início
- Importe `lib/utils.sh`
- Use funções `log_*` para output
- Use `run` para todos os comandos que modificam o sistema
- Verifique dependências antes de usar
- Trate erros apropriadamente
- Documente variáveis de ambiente usadas
- Torne o módulo idempotente (pode executar múltiplas vezes)
- Adicione comentários explicativos

#### ❌ Não faça:
- Usar `echo` direto (use `log_*`)
- Executar comandos sem `run` (ignora dry-run)
- Assumir que comandos existem (use `require_command`)
- Fazer mudanças irreversíveis sem aviso
- Deixar o sistema em estado inconsistente se falhar

### 4. Variáveis de Ambiente

Se seu módulo usa variáveis configuráveis:

1. Documente no topo do módulo:
```bash
# ENV_VARS:
#   MEU_MODULO_OPCAO1  - Descrição (padrão: valor)
#   MEU_MODULO_OPCAO2  - Descrição (padrão: valor)
```

2. Adicione ao `config/env` template (no script principal)

### 5. Testando seu Módulo

```bash
# 1. Instalar Deboost localmente
make install

# 2. Testar sintaxe
make lint

# 3. Testar em dry-run
deboost install seu-modulo --dry-run

# 4. Testar com verbose
deboost install seu-modulo --dry-run --verbose

# 5. Testar aplicação real (em VM recomendado!)
deboost install seu-modulo --apply

# 6. Verificar que é idempotente
deboost install seu-modulo --apply  # segunda vez
```

### 6. Documentação

Adicione documentação para seu módulo:

1. Comentário `# DESC:` no topo
2. Atualizar README.md se relevante
3. Adicionar exemplo em EXAMPLES.md se apropriado
4. Documentar variáveis em config/env

## 🔄 Processo de Pull Request

### 1. Fork e Clone

```bash
# Fork no GitHub, depois:
git clone https://github.com/SEU-USUARIO/deboost.git
cd deboost
git remote add upstream https://github.com/lucasbt/deboost.git
```

### 2. Criar Branch

```bash
# Para nova funcionalidade
git checkout -b feature/nome-da-funcionalidade

# Para correção de bug
git checkout -b fix/nome-do-bug

# Para novo módulo
git checkout -b module/nome-do-modulo
```

### 3. Fazer Mudanças

```bash
# Criar/editar arquivos
nano modules/meu-modulo.sh

# Testar
make test-module MODULE=meu-modulo

# Commit
git add modules/meu-modulo.sh
git commit -m "feat: adicionar módulo XYZ"
```

### 4. Seguir Convenções de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: adicionar módulo de backup automático
fix: corrigir erro no módulo de fontes
docs: atualizar README com exemplos
style: formatar código do módulo X
refactor: melhorar estrutura da lib/utils.sh
test: adicionar testes para módulo Y
chore: atualizar .gitignore
```

### 5. Push e PR

```bash
# Push para seu fork
git push origin feature/nome-da-funcionalidade

# Abrir PR no GitHub
# Preencher template do PR
```

### Template de Pull Request

```markdown
**Descrição**
Breve descrição das mudanças.

**Tipo de Mudança**
- [ ] Bug fix (correção que não quebra funcionalidade existente)
- [ ] Nova funcionalidade (mudança que adiciona funcionalidade)
- [ ] Breaking change (correção ou funcionalidade que causaria quebra)
- [ ] Documentação

**Como Foi Testado?**
Descreva os testes realizados.

**Checklist**
- [ ] Código segue o estilo do projeto
- [ ] Realizei self-review do meu código
- [ ] Comentei código em áreas complexas
- [ ] Atualizei documentação relevante
- [ ] Minhas mudanças não geram novos warnings
- [ ] Testei em dry-run e apply
- [ ] Módulo é idempotente
- [ ] Não quebra módulos existentes

**Screenshots** (se aplicável)
```

## 🎨 Estilo de Código

### Bash Style Guide

```bash
# 1. Sempre use set -euo pipefail
set -euo pipefail

# 2. Variáveis de ambiente em MAIÚSCULAS
MINHA_VARIAVEL="valor"

# 3. Variáveis locais em minúsculas
local minha_var="valor"

# 4. Funções em snake_case
minha_funcao() {
  # ...
}

# 5. Use aspas duplas para variáveis
echo "${VARIAVEL}"

# 6. Use aspas para strings com espaços
comando "string com espaços"

# 7. Prefira [[ ]] ao invés de [ ]
if [[ "${VAR}" == "valor" ]]; then
  # ...
fi

# 8. Use $( ) ao invés de ``
resultado=$(comando)

# 9. Indentação: 2 espaços
if true; then
  echo "exemplo"
fi

# 10. Comente código não-óbvio
# Isso é necessário porque...
comando_complexo
```

### Mensagens de Log

```bash
# Informação geral
log_info "Instalando pacotes..."

# Sucesso
log_success "Instalação concluída!"

# Aviso (não-crítico)
log_warn "Pacote X não disponível, pulando"

# Erro (crítico)
log_error "Falha ao instalar pacote Y"

# Debug (só com --verbose)
log_debug "Valor da variável: ${VAR}"
```

## 🧪 Testes

### Testes Locais

```bash
# Verificar sintaxe
make lint

# Executar shellcheck (recomendado)
make shellcheck

# Testar todos os módulos
make test

# Testar módulo específico
make test-module MODULE=nome

# Verificar instalação
make check
```

### Testes em Diferentes Ambientes

Idealmente, teste em:

1. **VM com Debian 13 limpo** - Instalação fresh
2. **Sistema com configurações existentes** - Verificar se não quebra
3. **Hardware diferente** - Intel, AMD, NVIDIA se aplicável

## 📚 Recursos para Contribuidores

### Documentação Útil

- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Debian Documentation](https://www.debian.org/doc/)
- [GNOME Developer Documentation](https://developer.gnome.org/)

### Ferramentas Recomendadas

```bash
# Instalar ferramentas de desenvolvimento
sudo apt install shellcheck shfmt

# Configurar git hooks (opcional)
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
make lint
EOF
chmod +x .git/hooks/pre-commit
```

## 💬 Comunicação

### Onde Discutir

- **GitHub Issues** - Para bugs, features, discussões gerais
- **Pull Requests** - Para revisão de código
- **README** - Para documentação geral

### Etiqueta

- Seja respeitoso e construtivo
- Forneça contexto adequado
- Seja paciente com revisões
- Ajude outros contribuidores

## 🏆 Reconhecimento

Todos os contribuidores são valorizados! Contribuições significativas serão reconhecidas no README.

## 📄 Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob a licença GPL-3.0 do projeto.

---

**Obrigado por contribuir com o Deboost! 🚀**

Se tiver dúvidas, não hesite em abrir uma issue para discussão.