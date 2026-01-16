#!/usr/bin/env bash

# Escaneia portas nos subdomínios encontrados

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports/ports"

mkdir -p "$OUTPUT_DIR"

echo "[*] Escaneando portas nos subdomínios..."

# Portas comuns para verificar
common_ports=(80 443 8080 8443 3000 8000 8888 9000 22 21 25 53 3306 5432 6379 27017)

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Processando: $domain"
    output_file="$OUTPUT_DIR/${domain}_ports.txt"
    
    cat "$subs_file" | while read -r subdomain; do
        echo "=== $subdomain ===" >> "$output_file"
        
        if command -v nmap &> /dev/null; then
            # Scan rápido das portas comuns
            nmap -p "$(IFS=,; echo "${common_ports[*]}")" --open -T4 "$subdomain" 2>/dev/null | \
            grep -E "(PORT|open)" >> "$output_file"
        elif command -v nc &> /dev/null; then
            # Alternativa com netcat (mais lento)
            for port in "${common_ports[@]}"; do
                if nc -z -w 1 "$subdomain" "$port" 2>/dev/null; then
                    echo "  [+] Porta $port: ABERTA" >> "$output_file"
                fi
            done
        else
            echo "  [!] Instale nmap ou netcat para scan de portas"
            break
        fi
        
        echo "" >> "$output_file"
    done
    
    echo "  [-] Scan concluído para $domain"
done

echo "[+] Resultados salvos em: $OUTPUT_DIR"
