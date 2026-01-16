#!/usr/bin/env python3
"""
Port-Hunter Inteligente - Analisa serviços e alerta sobre vulnerabilidades
"""

import subprocess
import xml.etree.ElementTree as ET
import sys
import os
import argparse
from pathlib import Path

# Portas e serviços padrão que geralmente são seguros
PORTS_PADRAO = {
    80: 'HTTP',
    443: 'HTTPS',
    22: 'SSH',
    21: 'FTP',
    25: 'SMTP',
    53: 'DNS',
    3306: 'MySQL',
    5432: 'PostgreSQL',
    27017: 'MongoDB'
}

# Serviços vulneráveis conhecidos
SERVICOS_VULNERAVEIS = {
    'tomcat': ['Apache Tomcat'],
    'jenkins': ['Jenkins'],
    'rdp': ['Microsoft Terminal Services', 'rdp'],
    'vnc': ['VNC'],
    'samba': ['Samba'],
    'ftp': ['FTP'],
    'telnet': ['Telnet'],
    'redis': ['Redis'],
    'elasticsearch': ['Elasticsearch'],
    'kibana': ['Kibana']
}

# Versões antigas conhecidas por vulnerabilidades
VERSOES_VULNERAVEIS = [
    '1.0', '2.0', '3.0', '4.0', '5.0',
    '6.0', '7.0', '8.0', '9.0'
]


def executar_nmap(target, output_file):
    """Executa nmap e salva o resultado em XML"""
    print(f"[*] Executando scan nmap em {target}...")
    
    cmd = [
        'nmap',
        '-sV',           # Version detection
        '-sC',           # Default scripts
        '-oX', output_file,  # XML output
        '--top-ports', '1000',  # Top 1000 portas
        target
    ]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minutos timeout
        )
        
        if result.returncode != 0:
            print(f"[!] Erro ao executar nmap: {result.stderr}")
            return False
        
        return True
    except subprocess.TimeoutExpired:
        print(f"[!] Timeout ao escanear {target}")
        return False
    except FileNotFoundError:
        print("[!] Erro: nmap não encontrado. Instale o nmap primeiro.")
        return False


def analisar_xml(xml_file):
    """Analisa o XML do nmap e identifica serviços interessantes"""
    alertas = []
    
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        for host in root.findall('host'):
            # Pular hosts que não estão up
            status = host.find('status')
            if status is None or status.get('state') != 'up':
                continue
            
            # Obter endereço IP
            address = host.find('address')
            ip = address.get('addr') if address is not None else 'Desconhecido'
            
            # Analisar portas
            ports = host.find('ports')
            if ports is None:
                continue
            
            for port in ports.findall('port'):
                port_id = port.get('portid')
                state = port.find('state')
                
                if state is None or state.get('state') != 'open':
                    continue
                
                service = port.find('service')
                if service is None:
                    continue
                
                service_name = service.get('name', 'desconhecido')
                service_product = service.get('product', '')
                service_version = service.get('version', '')
                service_info = service.get('extrainfo', '')
                
                # Verificar se é porta não-padrão
                porta_int = int(port_id)
                is_porta_padrao = porta_int in PORTS_PADRAO
                
                # Verificar serviços vulneráveis
                alerta = None
                motivo = []
                
                # Verificar se é serviço vulnerável conhecido
                for vuln_key, vuln_names in SERVICOS_VULNERAVEIS.items():
                    if any(vuln_name.lower() in service_name.lower() or 
                          vuln_name.lower() in service_product.lower() 
                          for vuln_name in vuln_names):
                        motivo.append(f"Serviço vulnerável conhecido: {service_name}")
                        alerta = True
                        break
                
                # Verificar versões antigas
                if service_version:
                    for versao_vuln in VERSOES_VULNERAVEIS:
                        if versao_vuln in service_version:
                            motivo.append(f"Versão antiga detectada: {service_version}")
                            alerta = True
                            break
                
                # Verificar portas não-padrão com serviços interessantes
                if not is_porta_padrao and service_name not in ['tcpwrapped', 'unknown']:
                    motivo.append(f"Porta não-padrão: {port_id}")
                    alerta = True
                
                # Verificar RDP, VNC, Telnet (sempre alertar)
                if service_name.lower() in ['rdp', 'vnc', 'telnet']:
                    motivo.append(f"Serviço remoto exposto: {service_name}")
                    alerta = True
                
                if alerta:
                    alertas.append({
                        'ip': ip,
                        'porta': port_id,
                        'servico': service_name,
                        'produto': service_product,
                        'versao': service_version,
                        'info': service_info,
                        'motivo': ' | '.join(motivo)
                    })
    
    except ET.ParseError as e:
        print(f"[!] Erro ao parsear XML: {e}")
        return []
    except Exception as e:
        print(f"[!] Erro ao analisar XML: {e}")
        return []
    
    return alertas


def processar_subdominios(subs_file, output_dir):
    """Processa lista de subdomínios e executa scans"""
    if not os.path.exists(subs_file):
        print(f"[!] Arquivo não encontrado: {subs_file}")
        return
    
    # Criar diretório de saída
    os.makedirs(output_dir, exist_ok=True)
    
    # Ler subdomínios
    with open(subs_file, 'r') as f:
        subdominios = [line.strip() for line in f if line.strip()]
    
    if not subdominios:
        print(f"[!] Nenhum subdomínio encontrado em {subs_file}")
        return
    
    print(f"[*] Processando {len(subdominios)} subdomínios...")
    
    resultados_gerais = []
    
    for subdominio in subdominios:
        print(f"\n{'='*60}")
        print(f"[*] Analisando: {subdominio}")
        print(f"{'='*60}")
        
        # Arquivo XML temporário
        xml_file = os.path.join(output_dir, f"{subdominio.replace('.', '_')}.xml")
        
        # Executar nmap
        if executar_nmap(subdominio, xml_file):
            # Analisar resultados
            alertas = analisar_xml(xml_file)
            
            if alertas:
                print(f"\n[!] ALERTAS ENCONTRADOS para {subdominio}:")
                resultados_gerais.append({
                    'subdominio': subdominio,
                    'alertas': alertas
                })
                
                for alerta in alertas:
                    print(f"\n  [+] IP: {alerta['ip']}")
                    print(f"     Porta: {alerta['porta']}")
                    print(f"     Serviço: {alerta['servico']}")
                    if alerta['produto']:
                        print(f"     Produto: {alerta['produto']}")
                    if alerta['versao']:
                        print(f"     Versão: {alerta['versao']}")
                    print(f"     ⚠️  Motivo: {alerta['motivo']}")
            else:
                print(f"[✓] Nenhum alerta para {subdominio} (apenas portas padrão)")
        else:
            print(f"[!] Falha ao escanear {subdominio}")
    
    # Salvar relatório
    if resultados_gerais:
        relatorio_file = os.path.join(output_dir, "relatorio_alertas.txt")
        with open(relatorio_file, 'w', encoding='utf-8') as f:
            f.write("="*60 + "\n")
            f.write("RELATÓRIO DE ALERTAS - PORT-HUNTER\n")
            f.write("="*60 + "\n\n")
            
            for resultado in resultados_gerais:
                f.write(f"\n{'='*60}\n")
                f.write(f"Subdomínio: {resultado['subdominio']}\n")
                f.write(f"{'='*60}\n\n")
                
                for alerta in resultado['alertas']:
                    f.write(f"IP: {alerta['ip']}\n")
                    f.write(f"Porta: {alerta['porta']}\n")
                    f.write(f"Serviço: {alerta['servico']}\n")
                    if alerta['produto']:
                        f.write(f"Produto: {alerta['produto']}\n")
                    if alerta['versao']:
                        f.write(f"Versão: {alerta['versao']}\n")
                    f.write(f"Motivo: {alerta['motivo']}\n")
                    f.write("-" * 60 + "\n\n")
        
        print(f"\n[✓] Relatório salvo em: {relatorio_file}")


def main():
    parser = argparse.ArgumentParser(
        description='Port-Hunter Inteligente - Analisa serviços e alerta sobre vulnerabilidades'
    )
    parser.add_argument(
        'subs_file',
        help='Arquivo com lista de subdomínios (um por linha)'
    )
    parser.add_argument(
        '-o', '--output',
        default='./port_hunter_results',
        help='Diretório de saída (padrão: ./port_hunter_results)'
    )
    
    args = parser.parse_args()
    
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║         PORT-HUNTER INTELIGENTE 🕷️                      ║
    ║     Analisando serviços e detectando vulnerabilidades    ║
    ╚══════════════════════════════════════════════════════════╝
    """)
    
    processar_subdominios(args.subs_file, args.output)


if __name__ == '__main__':
    main()
