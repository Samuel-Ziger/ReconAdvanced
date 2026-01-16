#!/bin/bash

# Recebe o caminho do alvo enviado pelo menu
TARGET_PATH="$1"
SUBS_FILE="$TARGET_PATH/todos_subdominios.txt" # Ajuste conforme o nome final que seu script 1 gera
NMAP_DIR="$TARGET_PATH/nmap_scans"

if [ ! -f "$SUBS_FILE" ]; then
    echo "❌ Arquivo de subdomínios não encontrado em: $SUBS_FILE"
    echo "Rode o script de Recon DNS primeiro."
    exit 1
fi

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
