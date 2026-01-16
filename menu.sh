#!/usr/bin/env bash

# Cores para o menu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BUG_BOUNTY_DIR="./"

# Função para verificar se o Dns.sh foi executado
check_dns_execution() {
    local found_results=false
    
    # Procura por arquivos subs.txt ou resultados de fuzzing
    find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" 2>/dev/null | head -1 | read -r first_subs
    find "$BUG_BOUNTY_DIR" -type d -name "fuzzing" 2>/dev/null | head -1 | read -r first_fuzzing
    
    if [ -n "$first_subs" ] || [ -n "$first_fuzzing" ]; then
        found_results=true
    fi
    
    echo "$found_results"
}

# Função para mostrar o menu
show_menu() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     MENU DE ANÁLISE PÓS-RECONHECIMENTO DNS              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Escolha uma opção:${NC}"
    echo ""
    echo -e "  ${YELLOW}1)${NC}  Analisar Endpoints Encontrados (FFUF)"
    echo -e "  ${YELLOW}2)${NC}  Capturar Screenshots dos URLs"
    echo -e "  ${YELLOW}3)${NC}  Fingerprinting de Tecnologias"
    echo -e "  ${YELLOW}4)${NC}  Análise de Headers de Segurança"
    echo -e "  ${YELLOW}5)${NC}  Teste de Vulnerabilidades Comuns"
    echo -e "  ${YELLOW}6)${NC}  Análise de Certificados SSL/TLS"
    echo -e "  ${YELLOW}7)${NC}  Verificar Arquivos Sensíveis Expostos"
    echo -e "  ${YELLOW}8)${NC}  Análise de JavaScript (Secrets/APIs)"
    echo -e "  ${YELLOW}9)${NC}  Verificação de CORS"
    echo -e "  ${YELLOW}10)${NC} Análise de APIs REST"
    echo -e "  ${YELLOW}11)${NC} Scan de Portas nos Subdomínios"
    echo -e "  ${YELLOW}12)${NC} Análise de DNS (Registros/Histórico)"
    echo -e "  ${YELLOW}13)${NC} Gerar Relatório Consolidado"
    echo -e "  ${YELLOW}14)${NC} Comparar Resultados Entre Execuções"
    echo -e "  ${YELLOW}15)${NC} Extrair Informações Sensíveis (Regex)"
    echo ""
    echo -e "  ${RED}0)${NC}  Sair"
    echo ""
    echo -n -e "${GREEN}Opção: ${NC}"
}

# Função principal
main() {
    # Verifica se o Dns.sh foi executado
    if [ "$(check_dns_execution)" = "false" ]; then
        echo -e "${RED}[!] ERRO: O script Dns.sh precisa ser executado primeiro!${NC}"
        echo -e "${YELLOW}[*] Execute: ./Dns.sh${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] Resultados do Dns.sh encontrados!${NC}"
    sleep 1
    
    while true; do
        show_menu
        read -r option
        
        case $option in
            1)
                echo -e "\n${BLUE}[*] Executando análise de endpoints...${NC}"
                ./scripts/analyze_endpoints.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            2)
                echo -e "\n${BLUE}[*] Capturando screenshots...${NC}"
                ./scripts/screenshot_urls.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            3)
                echo -e "\n${BLUE}[*] Executando fingerprinting...${NC}"
                ./scripts/tech_fingerprint.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            4)
                echo -e "\n${BLUE}[*] Analisando headers de segurança...${NC}"
                ./scripts/security_headers.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            5)
                echo -e "\n${BLUE}[*] Testando vulnerabilidades...${NC}"
                ./scripts/vuln_scan.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            6)
                echo -e "\n${BLUE}[*] Analisando certificados SSL...${NC}"
                ./scripts/ssl_analysis.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            7)
                echo -e "\n${BLUE}[*] Verificando arquivos sensíveis...${NC}"
                ./scripts/sensitive_files.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            8)
                echo -e "\n${BLUE}[*] Analisando JavaScript...${NC}"
                ./scripts/js_analysis.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            9)
                echo -e "\n${BLUE}[*] Verificando CORS...${NC}"
                ./scripts/cors_check.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            10)
                echo -e "\n${BLUE}[*] Analisando APIs REST...${NC}"
                ./scripts/api_analysis.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            11)
                echo -e "\n${BLUE}[*] Escaneando portas...${NC}"
                ./scripts/port_scan.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            12)
                echo -e "\n${BLUE}[*] Analisando DNS...${NC}"
                ./scripts/dns_analysis.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            13)
                echo -e "\n${BLUE}[*] Gerando relatório...${NC}"
                ./scripts/generate_report.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            14)
                echo -e "\n${BLUE}[*] Comparando resultados...${NC}"
                ./scripts/compare_results.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            15)
                echo -e "\n${BLUE}[*] Extraindo informações sensíveis...${NC}"
                ./scripts/extract_secrets.sh
                echo -e "\n${GREEN}[+] Pressione Enter para continuar...${NC}"
                read -r
                ;;
            0)
                echo -e "\n${GREEN}[+] Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "\n${RED}[!] Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

main
