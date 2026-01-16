#!/usr/bin/env bash

# Analisa certificados SSL/TLS dos subdomínios

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/ssl"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando certificados SSL/TLS..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_ssl.txt"
    
    cat "$subs_file" | while read -r subdomain; do
        # Tenta HTTPS primeiro
        if command -v openssl &> /dev/null; then
            echo "=== $subdomain ===" >> "$output_file"
            
            # Obtém informações do certificado
            echo | openssl s_client -connect "$subdomain:443" -servername "$subdomain" 2>/dev/null | \
            openssl x509 -noout -dates -subject -issuer 2>/dev/null >> "$output_file"
            
            # Verifica expiração
            expiry=$(echo | openssl s_client -connect "$subdomain:443" -servername "$subdomain" 2>/dev/null | \
                    openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
            
            if [ -n "$expiry" ]; then
                expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
                now_epoch=$(date +%s)
                days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
                
                if [ "$days_left" -lt 30 ]; then
                    echo "  [!] CERTIFICADO EXPIRA EM $days_left DIAS!" >> "$output_file"
                fi
            fi
            
            echo "" >> "$output_file"
        else
            echo "  [!] openssl não encontrado"
        fi
    done
    
    echo "  [-] Análise concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
