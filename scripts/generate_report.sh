#!/usr/bin/env bash

# Gera relatório consolidado de todos os resultados

BUG_BOUNTY_DIR="./"
OUTPUT_DIR="./reports"
REPORT_FILE="$OUTPUT_DIR/relatorio_consolidado_$(date +%Y%m%d_%H%M%S).md"

mkdir -p "$OUTPUT_DIR"

echo "[*] Gerando relatório consolidado..."

{
    echo "# Relatório Consolidado de Reconhecimento"
    echo ""
    echo "**Data:** $(date '+%d/%m/%Y %H:%M:%S')"
    echo ""
    echo "---"
    echo ""
    
    # Estatísticas gerais
    echo "## Estatísticas Gerais"
    echo ""
    
    total_domains=$(find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | wc -l)
    echo "- **Total de Domínios Processados:** $total_domains"
    
    total_subs=$(find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" -exec cat {} \; | wc -l)
    echo "- **Total de Subdomínios Encontrados:** $total_subs"
    
    total_endpoints=$(find "$BUG_BOUNTY_DIR" -type f -path "*/fuzzing/*.json" -exec jq '.results | length' {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
    echo "- **Total de Endpoints Encontrados:** ${total_endpoints:-0}"
    
    echo ""
    echo "---"
    echo ""
    
    # Detalhes por domínio
    echo "## Detalhes por Domínio"
    echo ""
    
    find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | while read -r subs_file; do
        domain_dir=$(dirname "$subs_file")
        domain=$(basename "$domain_dir")
        
        echo "### $domain"
        echo ""
        echo "#### Subdomínios Encontrados"
        echo ""
        cat "$subs_file" | sed 's/^/- /' | head -20
        if [ $(wc -l < "$subs_file") -gt 20 ]; then
            echo "- ... e mais $(($(wc -l < "$subs_file") - 20)) subdomínios"
        fi
        echo ""
        
        # Endpoints do fuzzing
        if [ -d "$domain_dir/fuzzing" ]; then
            echo "#### Endpoints Encontrados (Fuzzing)"
            echo ""
            find "$domain_dir/fuzzing" -name "*.json" -exec jq -r '.results[] | "\(.status) - \(.url)"' {} \; 2>/dev/null | \
            head -10 | sed 's/^/- /'
            echo ""
        fi
        
        echo "---"
        echo ""
    done
    
    # Resumo de vulnerabilidades encontradas
    if [ -d "$OUTPUT_DIR/vulnerabilities" ]; then
        echo "## Resumo de Vulnerabilidades"
        echo ""
        find "$OUTPUT_DIR/vulnerabilities" -type f -name "*_vulns.txt" | while read -r vuln_file; do
            if [ -s "$vuln_file" ]; then
                echo "### $(basename "$vuln_file" _vulns.txt)"
                echo ""
                grep "\[!\]" "$vuln_file" | sed 's/^/- /' | head -5
                echo ""
            fi
        done
    fi
    
    # Arquivos sensíveis
    if [ -d "$OUTPUT_DIR/sensitive_files" ]; then
        echo "## Arquivos Sensíveis Encontrados"
        echo ""
        find "$OUTPUT_DIR/sensitive_files" -type f -name "*_sensitive.txt" | while read -r sens_file; do
            if [ -s "$sens_file" ]; then
                grep "\[!\]" "$sens_file" | sed 's/^/- /'
            fi
        done
        echo ""
    fi
    
} > "$REPORT_FILE"

echo "[+] Relatório gerado: $REPORT_FILE"
