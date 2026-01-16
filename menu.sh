#!/usr/bin/env bash

# Menu principal para seleção de ferramentas de monitoramento avançado
# Baseado nos subdomínios gerados pelo Dns.sh

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Diretório base
BUG_BOUNTY_DIR="./"

# Função para exibir banner
exibir_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║          🕷️  MONITORAMENTO AVANÇADO - MENU PRINCIPAL  🚀            ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função para encontrar todos os arquivos subs.txt
encontrar_subdominios() {
    local subdominios_encontrados=()
    
    while IFS= read -r -d '' subs_file; do
        subdominios_encontrados+=("$subs_file")
    done < <(find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" -print0 2>/dev/null)
    
    printf '%s\n' "${subdominios_encontrados[@]}"
}

# Função para exibir menu de seleção de subdomínios
selecionar_arquivo_subs() {
    local arquivos=("$@")
    
    if [ ${#arquivos[@]} -eq 0 ]; then
        echo -e "${RED}[!] Nenhum arquivo subs.txt encontrado!${NC}"
        echo -e "${YELLOW}[*] Execute primeiro o Dns.sh para gerar os subdomínios${NC}"
        return 1
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Arquivos de subdomínios encontrados:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    local i=1
    for arquivo in "${arquivos[@]}"; do
        local dominio_dir=$(dirname "$arquivo")
        local dominio=$(basename "$dominio_dir")
        local count=$(wc -l < "$arquivo" 2>/dev/null || echo "0")
        
        echo -e "${CYAN}[$i]${NC} $arquivo"
        echo -e "    ${YELLOW}Domínio:${NC} $dominio | ${YELLOW}Subdomínios:${NC} $count"
        echo ""
        i=$((i + 1))
    done
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Selecione o arquivo (1-${#arquivos[@]}) ou 0 para voltar:${NC} "
    read -r escolha
    
    if [ "$escolha" = "0" ]; then
        return 1
    fi
    
    if [ "$escolha" -ge 1 ] && [ "$escolha" -le ${#arquivos[@]} ]; then
        local indice=$((escolha - 1))
        echo "${arquivos[$indice]}"
        return 0
    else
        echo -e "${RED}[!] Opção inválida!${NC}"
        return 1
    fi
}

# Função para executar Port-Hunter
executar_port_hunter() {
    local subs_file=$1
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🕷️  PORT-HUNTER INTELIGENTE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Criar diretório de saída baseado no arquivo
    local dominio_dir=$(dirname "$subs_file")
    local dominio=$(basename "$dominio_dir")
    local output_dir="${dominio_dir}/port_hunter_results"
    
    echo -e "${YELLOW}[*] Arquivo:${NC} $subs_file"
    echo -e "${YELLOW}[*] Saída:${NC} $output_dir"
    echo ""
    
    # Verificar se Python está instalado
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}[!] Erro: python3 não encontrado!${NC}"
        read -p "Pressione Enter para continuar..."
        return 1
    fi
    
    # Verificar se nmap está instalado
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}[!] Erro: nmap não encontrado!${NC}"
        echo -e "${YELLOW}[*] Instale o nmap primeiro${NC}"
        read -p "Pressione Enter para continuar..."
        return 1
    fi
    
    # Executar Port-Hunter
    python3 port_hunter.py "$subs_file" -o "$output_dir"
    
    echo ""
    echo -e "${GREEN}[✓] Port-Hunter concluído!${NC}"
    read -p "Pressione Enter para continuar..."
}

# Função para executar Fuzzer Turbo
executar_fuzzer_turbo() {
    local subs_file=$1
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 FUZZER DE DIRETÓRIOS TURBO${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Criar diretório de saída
    local dominio_dir=$(dirname "$subs_file")
    local dominio=$(basename "$dominio_dir")
    local output_dir="${dominio_dir}/fuzzer_results"
    
    echo -e "${YELLOW}[*] Arquivo:${NC} $subs_file"
    echo -e "${YELLOW}[*] Saída:${NC} $output_dir"
    echo ""
    
    # Solicitar wordlist
    echo -e "${CYAN}Digite o caminho da wordlist (ou Enter para padrão):${NC}"
    echo -e "${YELLOW}Padrão: /usr/share/wordlists/dirb/common.txt${NC}"
    read -r wordlist
    
    if [ -z "$wordlist" ]; then
        wordlist="/usr/share/wordlists/dirb/common.txt"
    fi
    
    # Verificar se wordlist existe
    if [ ! -f "$wordlist" ]; then
        echo -e "${RED}[!] Wordlist não encontrada: $wordlist${NC}"
        echo -e "${YELLOW}[*] Você pode baixar wordlists em:${NC}"
        echo "    - https://github.com/danielmiessler/SecLists"
        read -p "Pressione Enter para continuar..."
        return 1
    fi
    
    # Solicitar número de threads
    echo -e "${CYAN}Número de threads (padrão: 40):${NC}"
    read -r threads
    
    if [ -z "$threads" ]; then
        threads=40
    fi
    
    # Executar Fuzzer
    bash fuzzer_turbo.sh "$subs_file" "$wordlist" "$output_dir" "$threads"
    
    echo ""
    echo -e "${GREEN}[✓] Fuzzer Turbo concluído!${NC}"
    read -p "Pressione Enter para continuar..."
}

# Função para exibir menu principal
exibir_menu_principal() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Selecione uma opção:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} 🕷️  Port-Hunter Inteligente (Nmap + Análise)"
    echo -e "    Analisa serviços e alerta sobre vulnerabilidades"
    echo ""
    echo -e "${CYAN}[2]${NC} 🚀 Fuzzer de Diretórios Turbo (ffuf)"
    echo -e "    Fuzzing em massa com filtros inteligentes"
    echo ""
    echo -e "${CYAN}[3]${NC} 🔄 Executar Dns.sh (Recon DNS)"
    echo -e "    Gera lista de subdomínios"
    echo ""
    echo -e "${CYAN}[0]${NC} Sair"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}Escolha uma opção:${NC} "
}

# Função principal
main() {
    while true; do
        exibir_banner
        
        # Encontrar arquivos de subdomínios
        mapfile -t arquivos_subs < <(encontrar_subdominios)
        
        exibir_menu_principal
        read -r opcao
        
        case $opcao in
            1)
                # Port-Hunter
                exibir_banner
                arquivo_selecionado=$(selecionar_arquivo_subs "${arquivos_subs[@]}")
                
                if [ -n "$arquivo_selecionado" ]; then
                    executar_port_hunter "$arquivo_selecionado"
                fi
                ;;
            2)
                # Fuzzer Turbo
                exibir_banner
                arquivo_selecionado=$(selecionar_arquivo_subs "${arquivos_subs[@]}")
                
                if [ -n "$arquivo_selecionado" ]; then
                    executar_fuzzer_turbo "$arquivo_selecionado"
                fi
                ;;
            3)
                # Executar Dns.sh
                exibir_banner
                echo -e "${GREEN}🔄 Executando Dns.sh...${NC}"
                echo ""
                bash Dns.sh
                echo ""
                echo -e "${GREEN}[✓] Dns.sh concluído!${NC}"
                read -p "Pressione Enter para continuar..."
                ;;
            0)
                echo -e "${GREEN}Até logo! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Executar menu principal
main
