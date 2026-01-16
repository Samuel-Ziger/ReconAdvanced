#!/usr/bin/env bash

# Fingerprinting de tecnologias usando whatweb ou wappalyzer

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/technologies"

mkdir -p "$OUTPUT_DIR"

echo "[*] Executando fingerprinting de tecnologias..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_tech.txt"
    
    # Resolve URLs válidas primeiro
    if command -v httpx &> /dev/null && command -v whatweb &> /dev/null; then
        cat "$subs_file" | httpx -silent -threads 10 | \
        whatweb --no-errors --quiet --log-json=- 2>/dev/null | \
        jq -r '.[] | "\(.target) | \(.plugins | keys | join(", "))"' > "$output_file" 2>/dev/null
        
        count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
        echo "  [-] $count URLs analisadas"
    elif command -v wappalyzer &> /dev/null; then
        cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
            wappalyzer "$url" >> "$output_file" 2>/dev/null
        done
    else
        echo "  [!] Instale whatweb ou wappalyzer para fingerprinting"
        echo "      apt install whatweb ou npm install -g wappalyzer"
    fi
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
