#!/bin/bash

BASE_DIR="./" # Mesmo diretório base do outro script

echo "🔍 === BUG BOUNTY CONTROL CENTER === 🔍"
echo ""

# 1. Listar as empresas disponíveis baseadas nas pastas
echo "Selecione o alvo:"
# Cria um array com os diretórios encontrados
mapfile -t targets < <(find "$BASE_DIR" -maxdepth 1 -type d -not -path '*/.*' -not -path "$BASE_DIR" | sed 's|^\./||')

if [ ${#targets[@]} -eq 0 ]; then
    echo "❌ Nenhuma pasta de alvo encontrada."
    exit 1
fi

# Mostra as opções numeradas
for i in "${!targets[@]}"; do 
    echo "[$i] ${targets[$i]}"
done

echo ""
read -p "Digite o número do alvo: " target_index

# Validação simples
if [[ -z "${targets[$target_index]}" ]]; then
    echo "❌ Opção inválida."
    exit 1
fi

SELECTED_TARGET="${targets[$target_index]}"
TARGET_PATH="$BASE_DIR/$SELECTED_TARGET"

echo ""
echo "🎯 Alvo selecionado: $SELECTED_TARGET"
echo "---------------------------------------"
echo "O que você deseja fazer?"
echo "[1] 🕷️ Nmap Hunter (Port Scan Inteligente)"
echo "[2] 🚀 Fuzzer de Diretórios (FFUF/Dirb)"
echo "[3] 📸 Tirar Screenshots (Aquatone/Witness)"
echo "[4] 🚪 Sair"

read -p "Escolha uma opção: " action

case $action in
    1)
        echo "Iniciando Nmap Hunter..."
        # Chama o script do Nmap passando o caminho do alvo como argumento
        ./modules/nmap_hunter.sh "$TARGET_PATH"
        ;;
    2)
        echo "Iniciando Fuzzer..."
        ./modules/fuzzer.sh "$TARGET_PATH"
        ;;
    3)
        echo "Iniciando Screenshots..."
        ./modules/screens.sh "$TARGET_PATH"
        ;;
    *)
        echo "Saindo..."
        exit 0
        ;;
esac
