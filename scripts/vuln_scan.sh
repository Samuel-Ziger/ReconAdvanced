#!/usr/bin/env bash

# Testa vulnerabilidades comuns nos endpoints encontrados

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/vulnerabilities"

mkdir -p "$OUTPUT_DIR"

echo "[*] Testando vulnerabilidades comuns..."

# Extrai URLs dos resultados do FFUF
find "$BUG_BOUNTY_DIR" -type f -path "*/fuzzing/*.json" | while read -r json_file; do
    domain_dir=$(dirname "$(dirname "$json_file")")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_vulns.txt"
    
    if command -v jq &> /dev/null; then
        # Extrai URLs 200 do FFUF
        jq -r '.results[] | select(.status == 200) | .url' "$json_file" 2>/dev/null | \
        while read -r url; do
            echo "[*] Testando: $url" >> "$output_file"
            
            # Teste de SQL Injection básico
            test_url="${url}?id=1'"
            response=$(curl -s -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null)
            if echo "$response" | grep -q "500\|error\|mysql\|sql"; then
                echo "  [!] Possível SQL Injection em: $test_url" >> "$output_file"
            fi
            
            # Teste de XSS básico
            test_url="${url}?q=<script>alert(1)</script>"
            response=$(curl -s "$test_url" 2>/dev/null)
            if echo "$response" | grep -q "<script>alert(1)</script>"; then
                echo "  [!] Possível XSS em: $test_url" >> "$output_file"
            fi
            
            # Verifica se é um diretório listável
            if echo "$url" | grep -q "/$"; then
                response=$(curl -s "$url" 2>/dev/null)
                if echo "$response" | grep -qi "index of\|directory listing"; then
                    echo "  [!] Diretório listável: $url" >> "$output_file"
                fi
            fi
        done
        
        echo "  [-] Testes concluídos para $domain"
    else
        echo "  [!] jq não encontrado"
    fi
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
echo "[!] IMPORTANTE: Estes são testes básicos. Use ferramentas especializadas para análise completa."
