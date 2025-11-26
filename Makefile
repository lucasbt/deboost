# Deboost - Makefile para desenvolvimento

.PHONY: help install uninstall test lint clean modules check

DEBOOST_HOME := $(HOME)/.local/share/deboost
DEBOOST_BIN := $(HOME)/.local/bin
SHELL := /bin/bash

# Cores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help: ## Mostra esta ajuda
	@echo ""
	@echo "$(BLUE)Deboost - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Comandos disponíveis:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Instala Deboost localmente
	@echo "$(BLUE)→ Instalando Deboost...$(NC)"
	@mkdir -p $(DEBOOST_HOME)
	@mkdir -p $(DEBOOST_BIN)
	@mkdir -p $(DEBOOST_HOME)/lib
	@mkdir -p $(DEBOOST_HOME)/modules
	@mkdir -p $(DEBOOST_HOME)/config
	@cp -r * $(DEBOOST_HOME)/ 2>/dev/null || true
	@ln -sf $(DEBOOST_HOME)/deboost $(DEBOOST_BIN)/deboost
	@chmod +x $(DEBOOST_BIN)/deboost
	@chmod +x $(DEBOOST_HOME)/modules/*.sh 2>/dev/null || true
	@echo "$(GREEN)✓ Deboost instalado em $(DEBOOST_HOME)$(NC)"

uninstall: ## Remove Deboost
	@echo "$(RED)→ Removendo Deboost...$(NC)"
	@rm -rf $(DEBOOST_HOME)
	@rm -f $(DEBOOST_BIN)/deboost
	@echo "$(GREEN)✓ Deboost removido$(NC)"

reinstall: uninstall install ## Reinstala Deboost

test: ## Testa todos os módulos em modo dry-run
	@echo "$(BLUE)→ Testando módulos (dry-run)...$(NC)"
	@if [ -x $(DEBOOST_BIN)/deboost ]; then \
		$(DEBOOST_BIN)/deboost install --dry-run; \
	else \
		echo "$(RED)✗ Deboost não instalado. Execute 'make install' primeiro.$(NC)"; \
		exit 1; \
	fi

test-module: ## Testa um módulo específico (uso: make test-module MODULE=nome)
	@if [ -z "$(MODULE)" ]; then \
		echo "$(RED)✗ Especifique o módulo: make test-module MODULE=nome$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)→ Testando módulo $(MODULE) (dry-run)...$(NC)"
	@$(DEBOOST_BIN)/deboost install $(MODULE) --dry-run

lint: ## Verifica sintaxe dos scripts
	@echo "$(BLUE)→ Verificando sintaxe...$(NC)"
	@errors=0; \
	for script in deboost lib/*.sh modules/*.sh; do \
		if [ -f "$$script" ]; then \
			echo "  Verificando $$script..."; \
			if ! bash -n "$$script" 2>/dev/null; then \
				echo "$(RED)✗ Erro de sintaxe em $$script$(NC)"; \
				errors=$$((errors + 1)); \
			fi; \
		fi; \
	done; \
	if [ $$errors -eq 0 ]; then \
		echo "$(GREEN)✓ Todos os scripts estão corretos$(NC)"; \
	else \
		echo "$(RED)✗ $$errors erro(s) encontrado(s)$(NC)"; \
		exit 1; \
	fi

shellcheck: ## Executa shellcheck nos scripts
	@echo "$(BLUE)→ Executando shellcheck...$(NC)"
	@if ! command -v shellcheck &>/dev/null; then \
		echo "$(YELLOW)⚠ shellcheck não instalado. Execute: sudo apt install shellcheck$(NC)"; \
		exit 1; \
	fi
	@shellcheck -x deboost lib/*.sh modules/*.sh 2>&1 | grep -v "Can't follow" || true
	@echo "$(GREEN)✓ shellcheck concluído$(NC)"

modules: ## Lista módulos disponíveis
	@$(DEBOOST_BIN)/deboost list

check: ## Verifica instalação e configuração
	@echo "$(BLUE)→ Verificando instalação...$(NC)"
	@echo ""
	@if [ -d "$(DEBOOST_HOME)" ]; then \
		echo "$(GREEN)✓$(NC) Deboost instalado: $(DEBOOST_HOME)"; \
	else \
		echo "$(RED)✗$(NC) Deboost não instalado"; \
	fi
	@if [ -x "$(DEBOOST_BIN)/deboost" ]; then \
		echo "$(GREEN)✓$(NC) Executável: $(DEBOOST_BIN)/deboost"; \
	else \
		echo "$(RED)✗$(NC) Executável não encontrado"; \
	fi
	@if [ -f "$(DEBOOST_HOME)/config/env" ]; then \
		echo "$(GREEN)✓$(NC) Configuração: $(DEBOOST_HOME)/config/env"; \
	else \
		echo "$(YELLOW)⚠$(NC) Arquivo de configuração não encontrado"; \
	fi
	@echo ""
	@module_count=$$(find $(DEBOOST_HOME)/modules -name "*.sh" 2>/dev/null | wc -l); \
	echo "$(GREEN)✓$(NC) Módulos disponíveis: $$module_count"
	@echo ""
	@if [[ ":$$PATH:" == *":$(DEBOOST_BIN):"* ]]; then \
		echo "$(GREEN)✓$(NC) PATH configurado corretamente"; \
	else \
		echo "$(YELLOW)⚠$(NC) $(DEBOOST_BIN) não está no PATH"; \
		echo "  Adicione ao ~/.bashrc: export PATH=\"\$$HOME/.local/bin:\$$PATH\""; \
	fi

clean: ## Limpa arquivos temporários
	@echo "$(BLUE)→ Limpando arquivos temporários...$(NC)"
	@find . -type f -name "*.bak" -delete
	@find . -type f -name "*~" -delete
	@find . -type f -name ".*.swp" -delete
	@echo "$(GREEN)✓ Limpeza concluída$(NC)"

version: ## Mostra versão do Deboost
	@$(DEBOOST_BIN)/deboost version 2>/dev/null || echo "Não instalado"

update: ## Atualiza Deboost via git
	@$(DEBOOST_BIN)/deboost update

dev-setup: ## Configura ambiente de desenvolvimento
	@echo "$(BLUE)→ Configurando ambiente de desenvolvimento...$(NC)"
	@if ! command -v shellcheck &>/dev/null; then \
		echo "  Instalando shellcheck..."; \
		sudo apt install -y shellcheck; \
	fi
	@if ! command -v shfmt &>/dev/null; then \
		echo "  shfmt não disponível (opcional)"; \
	fi
	@echo "$(GREEN)✓ Ambiente configurado$(NC)"

format: ## Formata scripts com shfmt (se disponível)
	@if command -v shfmt &>/dev/null; then \
		echo "$(BLUE)→ Formatando scripts...$(NC)"; \
		shfmt -w -i 2 -bn -ci -sr deboost lib/*.sh modules/*.sh; \
		echo "$(GREEN)✓ Scripts formatados$(NC)"; \
	else \
		echo "$(YELLOW)⚠ shfmt não instalado$(NC)"; \
	fi

.DEFAULT_GOAL := help
