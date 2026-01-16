#!/usr/bin/env bash

# Verifica configurações de CORS

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/cors"

mkdir -p "$OUTPUT_DIR"

echo "[*] Verificando configurações de CORS..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_cors.txt"
    
    cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
        # Faz requisição OPTIONS para verificar CORS
        cors_headers=$(curl -s -I -X OPTIONS -H "Origin: https://evil.com" "$url" 2>/dev/null)
        
        access_control=$(echo "$cors_headers" | grep -i "access-control")
        
        if [ -n "$access_control" ]; then
            echo "=== $url ===" >> "$output_file"
            echo "$access_control" >> "$output_file"
            
            # Verifica se permite qualquer origem
            if echo "$access_control" | grep -qi "access-control-allow-origin.*\*"; then
                echo "  [!] CORS PERMISSIVO: Permite qualquer origem (*)" >> "$output_file"
            fi
            
            # Verifica credenciais
            if echo "$access_control" | grep -qi "access-control-allow-credentials.*true"; then
                echo "  [!] CORS com credenciais habilitadas" >> "$output_file"
            fi
            
            echo "" >> "$output_file"
        fi
    done
    
    echo "  [-] Verificação concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
