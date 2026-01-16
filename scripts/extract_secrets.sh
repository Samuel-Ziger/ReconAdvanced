#!/usr/bin/env bash

# Extrai informações sensíveis usando regex

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/secrets"

mkdir -p "$OUTPUT_DIR"

echo "[*] Extraindo informações sensíveis..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_secrets.txt"
    
    cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
        echo "[*] Analisando: $url" >> "$output_file"
        
        # Baixa o conteúdo da página
        content=$(curl -s -L "$url" 2>/dev/null)
        
        # Padrões de busca
        patterns=(
            "api[_-]?key['\"]?\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})"
            "secret['\"]?\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})"
            "password['\"]?\s*[:=]\s*['\"]?([a-zA-Z0-9@#$%^&*_-]{8,})"
            "token['\"]?\s*[:=]\s*['\"]?([a-zA-Z0-9_-]{20,})"
            "aws[_-]?access[_-]?key[_-]?id['\"]?\s*[:=]\s*['\"]?([A-Z0-9]{20})"
            "aws[_-]?secret[_-]?access[_-]?key['\"]?\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{40})"
            "ghp_[a-zA-Z0-9]{36}"
            "xox[baprs]-[0-9]{12}-[0-9]{12}-[a-zA-Z0-9]{32}"
            "sk_live_[0-9a-zA-Z]{24,}"
            "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
        )
        
        for pattern in "${patterns[@]}"; do
            matches=$(echo "$content" | grep -oE "$pattern" | head -5)
            if [ -n "$matches" ]; then
                echo "  [!] Padrão encontrado ($pattern):" >> "$output_file"
                echo "$matches" | sed 's/^/    /' >> "$output_file"
            fi
        done
        
        echo "" >> "$output_file"
    done
    
    echo "  [-] Extração concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
echo "[!] IMPORTANTE: Revise os resultados manualmente. Podem haver falsos positivos."
