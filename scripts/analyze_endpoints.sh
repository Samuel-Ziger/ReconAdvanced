#!/usr/bin/env bash

# Analisa os endpoints encontrados pelo FFUF e extrai informações úteis

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/endpoints"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando endpoints encontrados no fuzzing..."

find "$BUG_BOUNTY_DIR" -type f -path "*/fuzzing/*.json" | while read -r json_file; do
    domain_dir=$(dirname "$(dirname "$json_file")")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    
    # Extrai URLs dos resultados do FFUF (requer jq)
    if command -v jq &> /dev/null; then
        output_file="$OUTPUT_DIR/${domain}_endpoints.txt"
        
        jq -r '.results[] | "\(.status) - \(.url)"' "$json_file" 2>/dev/null | \
        sort -u > "$output_file"
        
        count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
        echo "  [-] $count endpoints encontrados"
        
        # Categoriza por código de status
        echo "  [*] Categorizando por status code..."
        grep " 200 " "$output_file" > "$OUTPUT_DIR/${domain}_200.txt" 2>/dev/null
        grep " 301\|302 " "$output_file" > "$OUTPUT_DIR/${domain}_redirects.txt" 2>/dev/null
        grep " 403 " "$output_file" > "$OUTPUT_DIR/${domain}_403.txt" 2>/dev/null
    else
        echo "  [!] jq não encontrado. Instale com: apt install jq"
    fi
done

echo "[+] Análise concluída! Resultados em: $OUTPUT_DIR"
