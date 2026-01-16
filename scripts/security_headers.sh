#!/usr/bin/env bash

# Analisa headers de segurança dos URLs encontrados

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/security_headers"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando headers de segurança..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_headers.txt"
    
    # Headers importantes para verificar
    important_headers=("X-Frame-Options" "X-Content-Type-Options" "X-XSS-Protection" 
                      "Strict-Transport-Security" "Content-Security-Policy" 
                      "Referrer-Policy" "Permissions-Policy")
    
    cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
        echo "=== $url ===" >> "$output_file"
        
        # Usa curl para pegar headers
        headers=$(curl -s -I -L "$url" 2>/dev/null)
        
        # Verifica cada header importante
        for header in "${important_headers[@]}"; do
            if echo "$headers" | grep -qi "$header"; then
                echo "  [+] $header: $(echo "$headers" | grep -i "$header" | cut -d: -f2- | xargs)" >> "$output_file"
            else
                echo "  [-] $header: AUSENTE" >> "$output_file"
            fi
        done
        
        echo "" >> "$output_file"
    done
    
    echo "  [-] Análise concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
