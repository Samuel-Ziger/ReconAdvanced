#!/usr/bin/env bash

# Compara resultados entre execuções

BUG_BOUNTY_DIR="./"
BACKUP_DIR="./backups"
OUTPUT_DIR="./reports/comparison"

mkdir -p "$OUTPUT_DIR" "$BACKUP_DIR"

echo "[*] Comparando resultados..."

# Cria backup dos resultados atuais se não existir
if [ ! -d "$BACKUP_DIR/previous" ]; then
    echo "[*] Criando backup inicial..."
    mkdir -p "$BACKUP_DIR/previous"
    find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" -exec cp {} "$BACKUP_DIR/previous/" \;
    find "$BUG_BOUNTY_DIR" -type d -name "fuzzing" -exec cp -r {} "$BACKUP_DIR/previous/" \;
    echo "[+] Backup criado"
fi

# Compara subdomínios
find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
    domain_dir=$(dirname "$subs_file")
    domain=$(basename "$domain_dir")
    
    echo "[+] Comparando: $domain"
    output_file="$OUTPUT_DIR/${domain}_comparison.txt"
    
    current_subs="$subs_file"
    previous_subs="$BACKUP_DIR/previous/$(basename "$subs_file")"
    
    if [ -f "$previous_subs" ]; then
        echo "=== Comparação de Subdomínios ===" > "$output_file"
        echo "" >> "$output_file"
        
        # Novos subdomínios
        new_subs=$(comm -13 <(sort "$previous_subs") <(sort "$current_subs"))
        if [ -n "$new_subs" ]; then
            echo "[+] Novos Subdomínios Encontrados:" >> "$output_file"
            echo "$new_subs" | sed 's/^/  - /' >> "$output_file"
            echo "" >> "$output_file"
        fi
        
        # Subdomínios removidos
        removed_subs=$(comm -23 <(sort "$previous_subs") <(sort "$current_subs"))
        if [ -n "$removed_subs" ]; then
            echo "[-] Subdomínios Removidos:" >> "$output_file"
            echo "$removed_subs" | sed 's/^/  - /' >> "$output_file"
            echo "" >> "$output_file"
        fi
        
        count_new=$(echo "$new_subs" | grep -c . || echo "0")
        count_removed=$(echo "$removed_subs" | grep -c . || echo "0")
        
        echo "Resumo:" >> "$output_file"
        echo "  - Novos: $count_new" >> "$output_file"
        echo "  - Removidos: $count_removed" >> "$output_file"
    else
        echo "Nenhum backup anterior encontrado para comparação" > "$output_file"
    fi
done

echo "[+] Comparação concluída. Resultados em: $OUTPUT_DIR"
echo "[*] Para atualizar o backup, execute novamente após a próxima execução do Dns.sh"
