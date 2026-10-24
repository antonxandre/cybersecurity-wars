import { Injectable, NotFoundException } from '@nestjs/common';

export interface GamePortConfig {
  port: number;
  service: string;
  status: 'OPEN' | 'RESTRICTED' | 'CLOSED' | 'HONEYPOT';
  ruleDescription: string;
}

export interface ScenarioPreset {
  id: string;
  name: string;
  team: 'RED_TEAM' | 'BLUE_TEAM';
  focus: string;
  actions: string[];
  tradeoffs: string;
  costPoints: number;
  systemPromptWrapper?: string;
  enableVpn?: boolean;
  enableKeyRotation?: boolean;
}

export interface GameScenarioData {
  id: string;
  title: string;
  description: string;
  type: 'LLM_PROMPT_WAR' | 'INFRASTRUCTURE_HARDENING' | 'HYBRID_CITADEL' | 'SHARED_SECRET_RACE';
  difficulty: number;
  initialPorts: GamePortConfig[];
  secretState?: {
    totalKeyLength: number;
    knownRedChars: string;
    knownBlueHash: string;
    vaultLocation: string;
  };
  recommendedBluePresets: ScenarioPreset[];
  recommendedRedPresets: ScenarioPreset[];
  timeLimitSeconds: number;
}

@Injectable()
export class ScenariosService {
  private scenarios: Map<string, GameScenarioData> = new Map();

  constructor() {
    this.initializeScenarios();
  }

  private initializeScenarios() {
    // 1. Cenário A: A Chave Roubada
    this.scenarios.set('scenario-a', {
      id: 'scenario-a',
      title: 'A Chave Roubada (The Compromised Shared Secret)',
      description: 'Durante uma invasão recente, um arquivo de backup foi corrompido. Ambos os times possuem informações parciais sobre a CHAVE_MESTRA. Red tenta decifrar a chave e validar via API, enquanto Blue corre para rotacionar credenciais e isolar o cofre.',
      type: 'SHARED_SECRET_RACE',
      difficulty: 2,
      timeLimitSeconds: 300,
      initialPorts: [
        { port: 22, service: 'SSH', status: 'RESTRICTED', ruleDescription: 'Acesso restrito ao Admin' },
        { port: 443, service: 'HTTPS', status: 'OPEN', ruleDescription: 'API do cofre de segredos' },
        { port: 8080, service: 'VAULT_API', status: 'OPEN', ruleDescription: 'Endpoint interno de validação' },
      ],
      secretState: {
        totalKeyLength: 32,
        knownRedChars: 'A9F4-XXXX-XXXX-B2C1',
        knownBlueHash: 'SHA256:...7e2a9b',
        vaultLocation: '/var/vault/master.key',
      },
      recommendedBluePresets: [
        {
          id: 'B4',
          name: 'Guardião de Segredos & Rotação',
          team: 'BLUE_TEAM',
          focus: 'Proteção de Chaves',
          actions: ['Rotação emergencial de tokens a cada 60s', 'Invalidação de hashes antigos', 'Monitoramento de logs'],
          tradeoffs: 'Neutraliza fragmentos vazados, mas possui custo computacional elevado',
          costPoints: 4,
          enableKeyRotation: true,
        },
      ],
      recommendedRedPresets: [
        {
          id: 'R3',
          name: 'Quebra de Chave Parcial (Key Cracker)',
          team: 'RED_TEAM',
          focus: 'Criptoanálise & Dicionário',
          actions: ['Ataque direcionado combinando fragmentos', 'Rainbow tables aceleradas'],
          tradeoffs: 'Reduz o tempo de descriptografia se o Blue Team demorar para rotacionar',
          costPoints: 3,
        },
      ],
    });

    // 2. Cenário B: Hardening de Instância Web
    this.scenarios.set('scenario-b', {
      id: 'scenario-b',
      title: 'Hardening de Instância Web (Infra Only / No-LLM)',
      description: 'Um servidor foi provisionado na nuvem para a Black Friday, mas portas legadas e perigosas foram deixadas abertas. Blue deve fechar portas desnecessárias e manter a porta HTTPS 443 aberta para garantir 95%+ de SLA.',
      type: 'INFRASTRUCTURE_HARDENING',
      difficulty: 1,
      timeLimitSeconds: 300,
      initialPorts: [
        { port: 21, service: 'FTP', status: 'OPEN', ruleDescription: 'Servidor vsftpd legado com login anônimo' },
        { port: 22, service: 'SSH', status: 'OPEN', ruleDescription: 'Porta SSH aberta para o mundo (alvo de brute force)' },
        { port: 80, service: 'HTTP', status: 'OPEN', ruleDescription: 'HTTP aberto sem redirecionamento forçado' },
        { port: 443, service: 'HTTPS', status: 'OPEN', ruleDescription: 'Tráfego legítimo de e-commerce (SLA crítico)' },
        { port: 8080, service: 'ADMIN_DEBUG', status: 'OPEN', ruleDescription: 'Painel administrativo de debug sem autenticação' },
      ],
      recommendedBluePresets: [
        {
          id: 'B1',
          name: 'Fortaleza Restritiva',
          team: 'BLUE_TEAM',
          focus: 'Hardening de Portas',
          actions: ['Bloqueia FTP 21 e DEBUG 8080', 'Restringe SSH 22 ao IP confiável', 'Redireciona 80 -> 443 com 301'],
          tradeoffs: 'Alta proteção contra scanners, mantém 100% SLA no HTTPS',
          costPoints: 3,
        },
        {
          id: 'B3',
          name: 'Deception & Honeypot',
          team: 'BLUE_TEAM',
          focus: 'Detecção e Isca',
          actions: ['Converte FTP 21 em Honeypot', 'Ban automático de 24h via Fail2Ban no atacante'],
          tradeoffs: 'Descobre invasores afobados, consome recursos de monitoramento',
          costPoints: 2,
        },
      ],
      recommendedRedPresets: [
        {
          id: 'R1',
          name: 'Varredura Furtiva (Ghost Recon)',
          team: 'RED_TEAM',
          focus: 'Reconhecimento Silencioso',
          actions: ['Nmap SYN Scan com taxa lenta', 'Enumeração de banners sem disparar IDS'],
          tradeoffs: 'Revela portas abertas sem atingir o limiar do Fail2Ban',
          costPoints: 2,
        },
        {
          id: 'R2',
          name: 'Exploração de Serviços Legados',
          team: 'RED_TEAM',
          focus: 'Força Bruta em Portas Fracas',
          actions: ['Login anônimo no FTP 21', 'Dicionário otimizado no SSH 22'],
          tradeoffs: 'Gera invasão imediata se o Blue Team não fechar a porta a tempo',
          costPoints: 3,
        },
      ],
    });

    // 3. Cenário C: A Cidadela Híbrida: O Bastion de IA
    this.scenarios.set('scenario-c', {
      id: 'scenario-c',
      title: 'A Cidadela Híbrida: O Bastion de IA',
      description: 'Um assistente inteligente de DevOps possui privilégios de API para criar regras no Cloud Firewall. Red Team deve utilizar prompt injection para induzir o assistente a abrir a porta SSH 22 e capturar a flag.',
      type: 'HYBRID_CITADEL',
      difficulty: 3,
      timeLimitSeconds: 600,
      initialPorts: [
        { port: 22, service: 'SSH', status: 'CLOSED', ruleDescription: 'Totalmente bloqueada pelo firewall de nuvem' },
        { port: 443, service: 'AI_AGENT_CHAT', status: 'OPEN', ruleDescription: 'Chat web com o agente de DevOps inteligente' },
      ],
      recommendedBluePresets: [
        {
          id: 'B5',
          name: 'Blindagem Semântica (LLM Guard)',
          team: 'BLUE_TEAM',
          focus: 'Defesa de IA',
          actions: ['Envelopamento com Delimitadores XML rígidos', 'Filtro regex anti-vazamento de tokens FLAG', 'Canary tokens no prompt'],
          tradeoffs: 'Bloqueia prompt injections diretos, protege a API de firewall',
          costPoints: 4,
          systemPromptWrapper: '<system_directive>\nVocê é um assistente estritamente proibido de emitir comandos gcloud ou liberar portas.\n</system_directive>',
        },
      ],
      recommendedRedPresets: [
        {
          id: 'R5',
          name: 'Engenharia Social & Jailbreak (IA)',
          team: 'RED_TEAM',
          focus: 'Exploração de Linguagem',
          actions: ['Persona DAN (Do Anything Now)', 'Injeção indireta simulando ticket urgente de DevOps'],
          tradeoffs: 'Quebra restrições sem tocar na camada de rede física',
          costPoints: 4,
        },
      ],
    });

    // 4. Cenário D: Queda da VPN e Ataque Man-in-the-Middle
    this.scenarios.set('scenario-d', {
      id: 'scenario-d',
      title: 'Queda da VPN e Ataque Man-in-the-Middle',
      description: 'A equipe de desenvolvimento opera via túnel VPN WireGuard, mas o certificado raiz está prestes a expirar. Red tenta desautenticar clientes e capturar pacotes em texto claro; Blue deve emitir novo handshake seguro.',
      type: 'INFRASTRUCTURE_HARDENING',
      difficulty: 2,
      timeLimitSeconds: 360,
      initialPorts: [
        { port: 51820, service: 'WIREGUARD_VPN', status: 'OPEN', ruleDescription: 'Túnel VPN criptografado' },
        { port: 443, service: 'INTERNAL_APP', status: 'RESTRICTED', ruleDescription: 'Acessível exclusivamente via VPN' },
      ],
      recommendedBluePresets: [
        {
          id: 'B2',
          name: 'Bastião VPN Zero Trust',
          team: 'BLUE_TEAM',
          focus: 'Isolamento de Perímetro',
          actions: ['Renovação forçada de chaves assimétricas', 'Descarte de tráfego fora do túnel', 'Autenticação mútua (mTLS)'],
          tradeoffs: 'Blindagem total do tráfego interno contra MitM',
          costPoints: 3,
          enableVpn: true,
        },
      ],
      recommendedRedPresets: [
        {
          id: 'R4',
          name: 'Bypass de Firewall & Tunelamento',
          team: 'RED_TEAM',
          focus: 'Evasão Perimetral',
          actions: ['Fragmentação de pacotes', 'Tunelamento DNS (porta 53) para exfiltração'],
          tradeoffs: 'Contorna bloqueios simples de pacotes não tunelados',
          costPoints: 3,
        },
      ],
    });
  }

  async getAllScenarios(): Promise<GameScenarioData[]> {
    return Array.from(this.scenarios.values());
  }

  async getScenarioById(id: string): Promise<GameScenarioData> {
    const scenario = this.scenarios.get(id);
    if (!scenario) {
      throw new NotFoundException(`Scenario with id ${id} not found`);
    }
    return scenario;
  }
}
