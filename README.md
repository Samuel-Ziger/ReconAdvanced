# Sistema de Monitoramento Avançado - Bug Bounty

Sistema completo de reconhecimento e análise pós-descoberta para bug bounty.

## 📋 Estrutura

```
.
├── Dns.sh                    # Script principal de reconhecimento DNS
├── menu.sh                   # Menu interativo de análise pós-reconhecimento
├── scripts/                  # Scripts de análise individuais
│   ├── analyze_endpoints.sh
│   ├── screenshot_urls.sh
│   ├── tech_fingerprint.sh
│   ├── security_headers.sh
│   ├── vuln_scan.sh
│   ├── ssl_analysis.sh
│   ├── sensitive_files.sh
│   ├── js_analysis.sh
│   ├── cors_check.sh
│   ├── api_analysis.sh
│   ├── port_scan.sh
│   ├── dns_analysis.sh
│   ├── generate_report.sh
│   ├── compare_results.sh
│   └── extract_secrets.sh
└── reports/                  # Diretório de resultados (criado automaticamente)
```

## 🚀 Como Usar

### 1. Preparação

Certifique-se de ter as seguintes ferramentas instaladas:

**Obrigatórias:**
- `subfinder` - Descoberta de subdomínios
- `httpx` - Resolução de URLs
- `ffuf` - Fuzzing de diretórios
- `parallel` - Execução paralela
- `anew` - Adiciona apenas novos itens

**Opcionais (dependendo das análises que usar):**
- `jq` - Processamento JSON
- `whatweb` / `wappalyzer` - Fingerprinting
- `gowitness` / `cutycapt` - Screenshots
- `nmap` / `nc` - Scan de portas
- `dig` / `host` - Análise DNS
- `curl` - Requisições HTTP

### 2. Estrutura de Diretórios

Crie a seguinte estrutura:

```
./
├── empresa1/
│   └── domains.txt          # Lista de domínios (um por linha)
├── empresa2/
│   └── domains.txt
└── ...
```

**Exemplo de `domains.txt`:**
```
example.com
target.com
```

### 3. Execução

#### Passo 1: Executar Reconhecimento DNS
```bash
./Dns.sh
```

Este script irá:
- Descobrir subdomínios usando `subfinder`
- Salvar resultados em `empresa/domains/dominio/subs.txt`
- Fazer fuzzing com `ffuf` nos subdomínios válidos
- Salvar resultados em `empresa/domains/dominio/fuzzing/*.json`

#### Passo 2: Menu de Análise
```bash
./menu.sh
```

O menu só aparecerá se o `Dns.sh` já foi executado (verifica existência de `subs.txt` ou diretórios `fuzzing`).

## 📊 Funcionalidades do Menu

### 1. Analisar Endpoints Encontrados (FFUF)
- Extrai e categoriza endpoints dos resultados do FFUF
- Separa por código de status HTTP
- Requer: `jq`

### 2. Capturar Screenshots dos URLs
- Captura screenshots visuais de todos os URLs encontrados
- Requer: `gowitness` ou `cutycapt`

### 3. Fingerprinting de Tecnologias
- Identifica tecnologias usadas (CMS, frameworks, etc.)
- Requer: `whatweb` ou `wappalyzer`

### 4. Análise de Headers de Segurança
- Verifica presença de headers de segurança importantes
- Detecta headers ausentes ou mal configurados

### 5. Teste de Vulnerabilidades Comuns
- Testa SQL Injection básico
- Testa XSS básico
- Detecta diretórios listáveis
- ⚠️ **Aviso:** Testes básicos. Use ferramentas especializadas para análise completa.

### 6. Análise de Certificados SSL/TLS
- Verifica validade e expiração de certificados
- Identifica certificados próximos do vencimento
- Requer: `openssl`

### 7. Verificar Arquivos Sensíveis Expostos
- Busca arquivos comuns expostos (.env, .git, backups, etc.)
- Lista arquivos encontrados com tamanho

### 8. Análise de JavaScript (Secrets/APIs)
- Analisa arquivos JS em busca de secrets
- Identifica endpoints de API expostos
- Procura por chaves de API, tokens, etc.

### 9. Verificação de CORS
- Verifica configurações de CORS
- Identifica CORS permissivos ou mal configurados

### 10. Análise de APIs REST
- Identifica endpoints de API
- Testa métodos HTTP suportados
- Detecta documentação de API (Swagger, OpenAPI)

### 11. Scan de Portas nos Subdomínios
- Escaneia portas comuns nos subdomínios
- Requer: `nmap` ou `netcat`

### 12. Análise de DNS (Registros/Histórico)
- Coleta registros DNS (A, AAAA, CNAME, MX, TXT, NS)
- Requer: `dig` ou `host`

### 13. Gerar Relatório Consolidado
- Gera relatório em Markdown com todos os resultados
- Inclui estatísticas e resumos
- Requer: `jq` (para alguns dados)

### 14. Comparar Resultados Entre Execuções
- Compara resultados atuais com execução anterior
- Identifica novos subdomínios
- Identifica subdomínios removidos

### 15. Extrair Informações Sensíveis (Regex)
- Busca padrões de secrets usando regex
- Procura por API keys, tokens, senhas, etc.
- ⚠️ **Aviso:** Pode gerar falsos positivos. Revise manualmente.

## 📁 Estrutura de Resultados

Após executar as análises, os resultados serão salvos em:

```
reports/
├── endpoints/           # Análise de endpoints
├── screenshots/         # Screenshots
├── technologies/        # Fingerprinting
├── security_headers/    # Headers de segurança
├── vulnerabilities/     # Vulnerabilidades encontradas
├── ssl/                 # Análise SSL
├── sensitive_files/     # Arquivos sensíveis
├── js_analysis/         # Análise JavaScript
├── cors/                # Verificação CORS
├── api_analysis/        # Análise de APIs
├── ports/               # Scan de portas
├── dns/                 # Análise DNS
├── secrets/             # Secrets extraídos
└── comparison/          # Comparações
```

## ⚙️ Configurações

### Ajustar Wordlist do FFUF

Edite `Dns.sh` linha 19:
```bash
WORDLIST="/usr/share/wordlists/dirb/common.txt"
```

### Ajustar Threads/Paralelismo

Edite `Dns.sh` linha 12:
```bash
parallel -j 4  # Altere o número de jobs paralelos
```

## 🔒 Segurança e Ética

⚠️ **IMPORTANTE:** Este sistema é para uso em:
- Programas de Bug Bounty autorizados
- Testes de penetração com autorização escrita
- Ambientes próprios para testes

**NUNCA use em sistemas sem autorização explícita!**

## 📝 Notas

- Os scripts são modulares e podem ser executados individualmente
- Todos os scripts verificam dependências antes de executar
- Resultados são salvos em formato texto para fácil análise
- O menu verifica se o `Dns.sh` foi executado antes de permitir análises

## 🐛 Troubleshooting

**Erro: "Dns.sh precisa ser executado primeiro"**
- Execute `./Dns.sh` antes de usar o menu
- Certifique-se de que existem arquivos `subs.txt` ou diretórios `fuzzing`

**Erro: "comando não encontrado"**
- Instale as ferramentas necessárias
- Verifique se estão no PATH do sistema

**Scripts muito lentos**
- Ajuste o número de threads no `Dns.sh`
- Use `-j` menor no `parallel` para reduzir carga

## 📚 Referências

- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [FFUF](https://github.com/ffuf/ffuf)
- [HTTPx](https://github.com/projectdiscovery/httpx)
- [Anew](https://github.com/tomnomnom/anew)
