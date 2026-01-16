#!/usr/bin/env bash

# Analisa registros DNS e histórico

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/dns"

mkdir -p "$OUTPUT_DIR"

echo "[*] Analisando registros DNS..."

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_dns.txt"
    
    cat "$subs_file" | while read -r subdomain; do
        echo "=== $subdomain ===" >> "$output_file"
        
        # Registros DNS comuns
        if command -v dig &> /dev/null; then
            echo "[*] Registros A:" >> "$output_file"
            dig +short A "$subdomain" >> "$output_file" 2>/dev/null
            
            echo "[*] Registros AAAA:" >> "$output_file"
            dig +short AAAA "$subdomain" >> "$output_file" 2>/dev/null
            
            echo "[*] Registros CNAME:" >> "$output_file"
            dig +short CNAME "$subdomain" >> "$output_file" 2>/dev/null
            
            echo "[*] Registros MX:" >> "$output_file"
            dig +short MX "$subdomain" >> "$output_file" 2>/dev/null
            
            echo "[*] Registros TXT:" >> "$output_file"
            dig +short TXT "$subdomain" >> "$output_file" 2>/dev/null
            
            echo "[*] NS Records:" >> "$output_file"
            dig +short NS "$subdomain" >> "$output_file" 2>/dev/null
        elif command -v host &> /dev/null; then
            host "$subdomain" >> "$output_file" 2>/dev/null
        else
            echo "  [!] Instale dig ou host para análise DNS"
        fi
        
        echo "" >> "$output_file"
    done
    
    echo "  [-] Análise concluída para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
