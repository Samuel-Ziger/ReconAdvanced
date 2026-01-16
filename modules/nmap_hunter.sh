#!/bin/bash

# Recebe o caminho do alvo enviado pelo menu
TARGET_PATH="$1"
# Normaliza o caminho (remove barras duplicadas e ./ desnecessários)
TARGET_PATH=$(echo "$TARGET_PATH" | sed 's|/\./|/|g' | sed 's|//|/|g' | sed 's|^\./||')
SUBS_FILE="$TARGET_PATH/todos_subdominios.txt"
NMAP_DIR="$TARGET_PATH/nmap_scans"

# Procura todos os arquivos subs.txt gerados pelo recon DNS
# O recon DNS cria em: $COMPANY_DIR/domains/$DOMAIN/subs.txt
echo "🔍 Procurando arquivos subs.txt em: $TARGET_PATH"
SUBS_FILES=$(find "$TARGET_PATH" -type f -name "subs.txt" 2>/dev/null)

if [ -z "$SUBS_FILES" ]; then
    echo "❌ Nenhum arquivo de subdomínios encontrado em: $TARGET_PATH"
    echo "📁 Estrutura esperada: $TARGET_PATH/domains/*/subs.txt"
    echo ""
    echo "💡 Verificando estrutura de pastas..."
    if [ -d "$TARGET_PATH" ]; then
        echo "   ✓ Pasta do alvo existe: $TARGET_PATH"
        if [ -d "$TARGET_PATH/domains" ]; then
            echo "   ✓ Pasta 'domains' encontrada"
            echo "   📂 Domínios encontrados:"
            find "$TARGET_PATH/domains" -maxdepth 1 -type d ! -path "$TARGET_PATH/domains" | sed 's|^|      |'
        else
            echo "   ✗ Pasta 'domains' não encontrada"
        fi
    else
        echo "   ✗ Pasta do alvo não existe: $TARGET_PATH"
    fi
    echo ""
    echo "Rode o script de Recon DNS primeiro (dns_reconEvolution.sh)."
    exit 1
fi

# Consolida todos os subs.txt em um único arquivo, removendo duplicatas
echo "📋 Consolidando subdomínios de todos os domínios..."
NUM_FILES=$(echo "$SUBS_FILES" | wc -l)

# Usa while read para lidar com espaços nos caminhos
echo "$SUBS_FILES" | while read -r sub_file; do
    if [ -f "$sub_file" ]; then
        cat "$sub_file"
    fi
done | sort -u > "$SUBS_FILE"

TOTAL_SUBS=$(wc -l < "$SUBS_FILE" 2>/dev/null || echo "0")
if [ "$TOTAL_SUBS" -eq 0 ] || [ -z "$TOTAL_SUBS" ]; then
    echo "❌ Nenhum subdomínio encontrado após consolidação."
    exit 1
fi

echo "✅ Consolidados $TOTAL_SUBS subdomínios únicos de $NUM_FILES arquivos."

mkdir -p "$NMAP_DIR"

echo "🔥 Iniciando Nmap Hunter em $(wc -l < "$SUBS_FILE") subdomínios..."
echo "📂 Salvando resultados em: $NMAP_DIR"

# DICA PRO: Usar o 'nmap' com input list (-iL) é mais rápido que loops
# -sV: Versões de serviço
# --top-ports 1000: Foca nas portas mais comuns (agilidade)
# --open: Mostra só o que está aberto
# -oA: Salva em 3 formatos (nmap, gnmap, xml) para fácil parsing depois

nmap -iL "$SUBS_FILE" \
     -sV --open -T4 --top-ports 1000 \
     -oA "$NMAP_DIR/scan_result" \
     --exclude-ports 80,443 \
     -v

# EXTRA: Parsear o .gnmap para mostrar só o que é interessante no terminal agora
echo ""
echo "🚨 === DESTAQUES (Portas Não-Web) === 🚨"
# Filtra o arquivo .gnmap procurando por portas abertas que NÃO sejam 80 ou 443
grep "Open" "$NMAP_DIR/scan_result.gnmap" | grep -v " 80/tcp" | grep -v " 443/tcp" | awk '{print $2 " -> " $0}'

echo ""
echo "✅ Scan finalizado!"
