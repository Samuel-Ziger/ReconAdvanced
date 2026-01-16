# 🕷️ Monitoramento Avançado - Ferramentas de Bug Bounty

Sistema completo de monitoramento e análise para bug bounty, incluindo recon DNS, análise de portas e fuzzing de diretórios.

## 📋 Ferramentas Incluídas

### 1. **Dns.sh** - Recon DNS
Script que encontra arquivos `domains.txt` e executa `subfinder` para descobrir subdomínios.

### 2. **Port-Hunter Inteligente** 🕷️
Script Python que:
- Executa scans Nmap em subdomínios
- Analisa automaticamente os resultados XML
- Alerta sobre serviços não-padrão ou versões vulneráveis
- Filtra ruído e foca em vetores reais de ataque

### 3. **Fuzzer de Diretórios Turbo** 🚀
Script Shell que:
- Executa fuzzing em massa com `ffuf`
- Filtra falsos positivos (404s disfarçados, etc.)
- Verifica subdomínios vivos automaticamente
- Otimizado para encontrar painéis admin e arquivos de config

### 4. **Menu Principal** 🎯
Menu interativo para selecionar e executar as ferramentas baseado nos subdomínios gerados.

## 🚀 Instalação

### Pré-requisitos

```bash
# Ferramentas necessárias
- subfinder (go install -v github.com/projectdiscovery/subfinder/v2/subfinder@latest)
- nmap
- ffuf (go install github.com/ffuf/ffuf/v2@latest)
- httpx (go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest) - opcional mas recomendado
- parallel (GNU parallel)
- anew
- Python 3
- curl

# Wordlists para fuzzing
- SecLists: https://github.com/danielmiessler/SecLists
- Ou use: /usr/share/wordlists/dirb/common.txt (Kali Linux)
```

## 📖 Como Usar

### Estrutura de Diretórios

O sistema espera a seguinte estrutura:
```
./
├── domains.txt                    # Lista de domínios (um por linha)
├── domains/
│   └── example.com/
│       └── subs.txt              # Subdomínios gerados pelo Dns.sh
├── Dns.sh
├── menu.sh
├── port_hunter.py
└── fuzzer_turbo.sh
```

### Passo 1: Preparar domínios

Crie um arquivo `domains.txt` com seus domínios:
```
example.com
target.com
another-target.com
```

### Passo 2: Executar recon DNS

```bash
bash Dns.sh
```

Isso irá:
- Procurar todos os arquivos `domains.txt`
- Para cada domínio, executar `subfinder`
- Salvar subdomínios em `./domains/<DOMAIN>/subs.txt`

### Passo 3: Usar o Menu Principal

```bash
bash menu.sh
```

O menu oferece 3 opções:
1. **Port-Hunter Inteligente**: Analisa serviços e detecta vulnerabilidades
2. **Fuzzer Turbo**: Executa fuzzing em massa nos subdomínios
3. **Executar Dns.sh**: Gera/atualiza lista de subdomínios

### Uso Direto (sem menu)

#### Port-Hunter
```bash
python3 port_hunter.py <arquivo_subs.txt> -o <diretorio_saida>
```

Exemplo:
```bash
python3 port_hunter.py ./domains/example.com/subs.txt -o ./results
```

#### Fuzzer Turbo
```bash
bash fuzzer_turbo.sh <arquivo_subs.txt> [wordlist] [output_dir] [threads]
```

Exemplo:
```bash
bash fuzzer_turbo.sh ./domains/example.com/subs.txt /usr/share/wordlists/dirb/common.txt ./fuzz_results 40
```

## 📊 Saídas

### Port-Hunter
- Arquivos XML do Nmap: `output_dir/<subdomain>.xml`
- Relatório de alertas: `output_dir/relatorio_alertas.txt`

### Fuzzer Turbo
- Resultados brutos: `output_dir/<subdomain>_fuzz.txt`
- Resultados filtrados: `output_dir/<subdomain>_fuzz.txt.filtrado`

## 🔍 Recursos do Port-Hunter

O Port-Hunter detecta automaticamente:
- ✅ Serviços vulneráveis conhecidos (Tomcat, Jenkins, RDP, VNC, etc.)
- ✅ Versões antigas de software
- ✅ Portas não-padrão com serviços interessantes
- ✅ Serviços remotos expostos (RDP, VNC, Telnet)

## 🚀 Recursos do Fuzzer Turbo

- ✅ Verificação automática de subdomínios vivos
- ✅ Filtragem inteligente de falsos positivos
- ✅ Suporte a múltiplos protocolos (HTTP/HTTPS)
- ✅ Threading configurável para performance
- ✅ Remoção de duplicatas

## ⚙️ Configurações

### Port-Hunter
Edite `port_hunter.py` para personalizar:
- `PORTS_PADRAO`: Portas consideradas seguras
- `SERVICOS_VULNERAVEIS`: Serviços que geram alertas
- `VERSOES_VULNERAVEIS`: Versões antigas que geram alertas

### Fuzzer Turbo
Parâmetros configuráveis:
- Threads (padrão: 40)
- Wordlist personalizada
- Filtros de tamanho e status code

## 📝 Notas

- O Port-Hunter pode levar tempo dependendo do número de subdomínios
- O Fuzzer Turbo é otimizado para performance, mas respeite rate limits
- Sempre verifique permissões antes de executar scans em produção
- Use responsavelmente e apenas em sistemas que você tem permissão para testar

## 🐛 Troubleshooting

### "nmap não encontrado"
```bash
# Linux
sudo apt install nmap

# macOS
brew install nmap
```

### "ffuf não encontrado"
```bash
go install github.com/ffuf/ffuf/v2@latest
```

### "httpx não encontrado"
```bash
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

### Wordlist não encontrada
Baixe SecLists:
```bash
git clone https://github.com/danielmiessler/SecLists.git
```

## 📄 Licença

Use responsavelmente. Apenas teste sistemas que você tem permissão para testar.
