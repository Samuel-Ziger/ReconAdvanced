#!/usr/bin/env bash

# Fuzzer de Diretórios "Turbo" - Wrapper inteligente para ffuf
# Filtra falsos positivos e automatiza fuzzing em massa

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar se ffuf está instalado
if ! command -v ffuf &> /dev/null; then
    echo -e "${RED}[!] Erro: ffuf não encontrado. Instale o ffuf primeiro.${NC}"
    echo "    Instalação: go install github.com/ffuf/ffuf/v2@latest"
    exit 1
fi

# Verificar se httpx está instalado (para verificar subdomínios vivos)
if ! command -v httpx &> /dev/null; then
    echo -e "${YELLOW}[!] Aviso: httpx não encontrado. Vou usar todos os subdomínios.${NC}"
    echo "    Recomendado: go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
fi

# Função para verificar se subdomínio está vivo
verificar_subdominio_vivo() {
    local subdominio=$1
    
    if command -v httpx &> /dev/null; then
        if httpx -u "https://$subdominio" -silent -status-code -no-color 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
            return 0
        fi
        if httpx -u "http://$subdominio" -silent -status-code -no-color 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
            return 0
        fi
    else
        # Fallback: tentar curl
        if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$subdominio" 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
            return 0
        fi
        if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$subdominio" 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
            return 0
        fi
    fi
    
    return 1
}

# Função para filtrar falsos positivos
filtrar_falsos_positivos() {
    local arquivo_resultado=$1
    local arquivo_filtrado="${arquivo_resultado}.filtrado"
    
    # Remover linhas com:
    # - Status 404 (mas manter 403, 401 que podem ser interessantes)
    # - Tamanho muito pequeno (provavelmente página de erro padrão)
    # - Palavras comuns de erro
    
    awk '{
        # Ignorar 404s
        if ($2 == "404") next
        
        # Ignorar tamanhos muito pequenos (< 100 bytes) que não sejam 403/401
        if ($3 < 100 && $2 !~ /^(403|401)$/) next
        
        print
    }' "$arquivo_resultado" > "$arquivo_filtrado"
    
    # Remover duplicatas
    sort -u "$arquivo_filtrado" > "${arquivo_filtrado}.tmp"
    mv "${arquivo_filtrado}.tmp" "$arquivo_filtrado"
    
    echo "$arquivo_filtrado"
}

# Função principal de fuzzing
executar_fuzzing() {
    local subdominio=$1
    local wordlist=$2
    local output_dir=$3
    local threads=${4:-40}
    
    local protocolo="https"
    local url="https://$subdominio"
    
    # Tentar HTTPS primeiro, se falhar tenta HTTP
    if ! curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
        protocolo="http"
        url="http://$subdominio"
        
        if ! curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null | grep -qE "^(200|301|302|403|401)"; then
            echo -e "${YELLOW}[!] Subdomínio não responde: $subdominio${NC}"
            return 1
        fi
    fi
    
    echo -e "${BLUE}[*] Iniciando fuzzing em: $url${NC}"
    
    # Arquivo de saída
    local output_file="$output_dir/${subdominio//./_}_fuzz.txt"
    
    # Executar ffuf
    echo -e "${GREEN}[*] Executando ffuf...${NC}"
    
    ffuf \
        -u "$url/FUZZ" \
        -w "$wordlist" \
        -t "$threads" \
        -mc 200,204,301,302,307,401,403 \
        -fs 0 \
        -o "$output_file" \
        -of csv \
        -s \
        -ac \
        2>/dev/null | tee "${output_file}.log"
    
    # Filtrar falsos positivos
    if [ -f "$output_file" ]; then
        echo -e "${GREEN}[*] Filtrando falsos positivos...${NC}"
        arquivo_filtrado=$(filtrar_falsos_positivos "$output_file")
        
        # Contar resultados
        total=$(wc -l < "$output_file" 2>/dev/null || echo "0")
        filtrados=$(wc -l < "$arquivo_filtrado" 2>/dev/null || echo "0")
        
        echo -e "${GREEN}[✓] Fuzzing concluído para $subdominio${NC}"
        echo -e "    Total de resultados: $total"
        echo -e "    Após filtro: $filtrados"
        echo -e "    Resultados salvos em: $arquivo_filtrado"
        
        # Mostrar alguns resultados interessantes
        if [ "$filtrados" -gt 0 ]; then
            echo -e "\n${YELLOW}[!] Alguns resultados interessantes:${NC}"
            head -10 "$arquivo_filtrado" | while IFS=',' read -r url status size words lines; do
                echo -e "    ${GREEN}[$status]${NC} $url (Tamanho: $size bytes)"
            done
        fi
    fi
}

# Função principal
main() {
    local subs_file=$1
    local wordlist=${2:-"/usr/share/wordlists/dirb/common.txt"}
    local output_dir=${3:-"./fuzzer_results"}
    local threads=${4:-40}
    
    # Verificar se arquivo de subdomínios existe
    if [ ! -f "$subs_file" ]; then
        echo -e "${RED}[!] Erro: Arquivo não encontrado: $subs_file${NC}"
        exit 1
    fi
    
    # Verificar se wordlist existe
    if [ ! -f "$wordlist" ]; then
        echo -e "${RED}[!] Erro: Wordlist não encontrada: $wordlist${NC}"
        echo -e "${YELLOW}[*] Você pode baixar wordlists em:${NC}"
        echo "    - https://github.com/danielmiessler/SecLists"
        echo "    - /usr/share/wordlists/dirb/common.txt (Kali Linux)"
        exit 1
    fi
    
    # Criar diretório de saída
    mkdir -p "$output_dir"
    
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         FUZZER DE DIRETÓRIOS TURBO 🚀                   ║"
    echo "║     Fuzzing em massa com filtros inteligentes           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Ler subdomínios
    local subdominios=()
    while IFS= read -r line || [ -n "$line" ]; do
        subdominio=$(echo "$line" | tr -d '\r\n' | xargs)
        if [ -n "$subdominio" ]; then
            subdominios+=("$subdominio")
        fi
    done < "$subs_file"
    
    if [ ${#subdominios[@]} -eq 0 ]; then
        echo -e "${RED}[!] Nenhum subdomínio encontrado no arquivo${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[*] Encontrados ${#subdominios[@]} subdomínios${NC}"
    
    # Verificar subdomínios vivos (se httpx estiver disponível)
    local subdominios_vivos=()
    if command -v httpx &> /dev/null; then
        echo -e "${BLUE}[*] Verificando subdomínios vivos...${NC}"
        for subdominio in "${subdominios[@]}"; do
            if verificar_subdominio_vivo "$subdominio"; then
                subdominios_vivos+=("$subdominio")
                echo -e "${GREEN}[✓]${NC} $subdominio"
            else
                echo -e "${YELLOW}[!]${NC} $subdominio (não responde)"
            fi
        done
        
        if [ ${#subdominios_vivos[@]} -eq 0 ]; then
            echo -e "${RED}[!] Nenhum subdomínio vivo encontrado${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}[*] ${#subdominios_vivos[@]} subdomínios vivos encontrados${NC}"
        subdominios=("${subdominios_vivos[@]}")
    else
        echo -e "${YELLOW}[!] Pulando verificação de subdomínios vivos (httpx não encontrado)${NC}"
    fi
    
    # Executar fuzzing em cada subdomínio
    local contador=1
    for subdominio in "${subdominios[@]}"; do
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}[$contador/${#subdominios[@]}] Processando: $subdominio${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        executar_fuzzing "$subdominio" "$wordlist" "$output_dir" "$threads"
        
        contador=$((contador + 1))
    done
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         FUZZING CONCLUÍDO! 🎉                            ║${NC}"
    echo -e "${GREEN}║     Resultados salvos em: $output_dir${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    echo "Uso: $0 <arquivo_subs.txt> [wordlist] [output_dir] [threads]"
    echo ""
    echo "Exemplo:"
    echo "  $0 ./domains/example.com/subs.txt /usr/share/wordlists/dirb/common.txt ./results 40"
    exit 1
fi

main "$@"
