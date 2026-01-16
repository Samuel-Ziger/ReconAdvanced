#!/usr/bin/env bash

# Analisa APIs REST encontradas

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/api_analysis"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando APIs REST..."

find "$BUG_BOUNTY_DIR" -type f -path "*/fuzzing/*.json" | while read -r json_file; do
    domain_dir=$(dirname "$(dirname "$json_file")")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_api.txt"
    
    if command -v jq &> /dev/null; then
        # Extrai URLs que parecem ser APIs
        jq -r '.results[] | select(.status == 200) | .url' "$json_file" 2>/dev/null | \
        grep -iE "(api|/v[0-9]|/rest|/graphql|/swagger|/openapi)" | \
        while read -r api_url; do
            echo "=== $api_url ===" >> "$output_file"
            
            # Testa métodos HTTP
            for method in GET POST PUT DELETE PATCH; do
                response=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$api_url" 2>/dev/null)
                if [ "$response" != "405" ] && [ "$response" != "404" ]; then
                    echo "  [+] $method: $response" >> "$output_file"
                fi
            done
            
            # Verifica se é documentação de API
            if echo "$api_url" | grep -qiE "(swagger|openapi|docs|documentation)"; then
                echo "  [!] Documentação de API encontrada: $api_url" >> "$output_file"
            fi
            
            echo "" >> "$output_file"
        done
        
        echo "  [-] Análise concluída para $domain"
    else
        echo "  [!] jq não encontrado"
    fi
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
