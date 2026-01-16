#!/usr/bin/env bash

# Verifica arquivos sensíveis expostos

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/sensitive_files"

mkdir -p "$OUTPUT_DIR"

echo "[*] Verificando arquivos sensíveis expostos..."

# Lista de arquivos sensíveis comuns
sensitive_files=(
    ".env" ".git/config" ".git/HEAD" ".svn/entries"
    "backup.sql" "dump.sql" "database.sql"
    ".DS_Store" "Thumbs.db"
    "config.php" "config.json" "config.yaml"
    "wp-config.php" ".htpasswd"
    "id_rsa" "id_dsa" "private.key"
    "composer.json" "package.json"
)

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_sensitive.txt"
    
    cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
        base_url=$(echo "$url" | sed 's|/$||')
        
        for file in "${sensitive_files[@]}"; do
            test_url="${base_url}/${file}"
            status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url" 2>/dev/null)
            
            if [ "$status" = "200" ]; then
                size=$(curl -s -I "$test_url" 2>/dev/null | grep -i "content-length" | cut -d: -f2 | xargs)
                echo "[!] ARQUIVO SENSÍVEL ENCONTRADO: $test_url (Tamanho: $size bytes)" >> "$output_file"
            fi
        done
    done
    
    echo "  [-] Verificação concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
