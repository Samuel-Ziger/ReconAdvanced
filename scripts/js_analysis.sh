#!/usr/bin/env bash

# Analisa arquivos JavaScript em busca de secrets e APIs expostas

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/js_analysis"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando JavaScript em busca de secrets e APIs..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_secrets.txt"
    
    cat "$subs_file" | httpx -silent -threads 10 | while read -r url; do
        # Baixa a página e extrai links para JS
        js_files=$(curl -s "$url" 2>/dev/null | grep -oE 'src="[^"]*\.js[^"]*"' | sed 's/src="//;s/"$//' | sed "s|^/|$url/|" | sed "s|^//|https://|")
        
        echo "$js_files" | while read -r js_url; do
            if [ -n "$js_url" ]; then
                # Normaliza URL
                if [[ ! "$js_url" =~ ^https?:// ]]; then
                    js_url="${url}/${js_url}"
                fi
                
                echo "[*] Analisando: $js_url" >> "$output_file"
                
                # Baixa e analisa o JS
                js_content=$(curl -s "$js_url" 2>/dev/null)
                
                # Procura por padrões suspeitos
                if echo "$js_content" | grep -qiE "(api[_-]?key|apikey|secret|password|token|auth)" | grep -v "//"; then
                    echo "  [!] Possível secret encontrado em: $js_url" >> "$output_file"
                    echo "$js_content" | grep -iE "(api[_-]?key|apikey|secret|password|token)" | head -5 >> "$output_file"
                fi
                
                # Procura por endpoints de API
                api_endpoints=$(echo "$js_content" | grep -oE "(/api/[^\"'`\s]+|api\.[a-zA-Z0-9.-]+/[^\"'`\s]+)" | sort -u)
                if [ -n "$api_endpoints" ]; then
                    echo "  [+] Endpoints de API encontrados:" >> "$output_file"
                    echo "$api_endpoints" | sed 's/^/    /' >> "$output_file"
                fi
            fi
        done
    done
    
    echo "  [-] Análise concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
