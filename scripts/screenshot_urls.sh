#!/usr/bin/env bash

# Captura screenshots dos URLs encontrados

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/screenshots"

mkdir -p "$OUTPUT_DIR"

echo "[*] Capturando screenshots dos URLs..."

# Coleta todos os URLs únicos dos subdomínios
find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    
    # Usa httpx para resolver URLs válidas
    if command -v httpx &> /dev/null; then
        cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
            clean_name=$(echo "$url" | sed "s|https\?://||" | tr -cd "[:alnum:].-")
            
            # Usa gowitness se disponível
            if command -v gowitness &> /dev/null; then
                gowitness single "$url" --destination "$OUTPUT_DIR/${domain}_${clean_name}.png" 2>/dev/null
                echo "  [-] Screenshot: $url"
            # Alternativa com cutycapt (se disponível)
            elif command -v cutycapt &> /dev/null; then
                cutycapt --url="$url" --out="$OUTPUT_DIR/${domain}_${clean_name}.png" 2>/dev/null
                echo "  [-] Screenshot: $url"
            else
                echo "  [!] Instale gowitness ou cutycapt para capturar screenshots"
                exit 1
            fi
        done
    else
        echo "  [!] httpx não encontrado"
    fi
done

echo "[+] Screenshots salvos em: $OUTPUT_DIR"
