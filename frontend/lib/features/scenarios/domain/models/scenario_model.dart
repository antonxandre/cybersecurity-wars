import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ScenarioCategory { networkInfra, llmPrompt, hybridCitadel, vpnMitM }

/// Modelo de Cenário Tático de Batalha (Scenario Hub).
class ScenarioModel {
  final String id;
  final String title;
  final String description;
  final ScenarioCategory category;
  final int difficulty; // 1, 2, 3 estrelas
  final String objectiveBlue;
  final String objectiveRed;
  final IconData icon;

  const ScenarioModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.objectiveBlue,
    required this.objectiveRed,
    required this.icon,
  });

  String get categoryTag {
    switch (category) {
      case ScenarioCategory.networkInfra:
        return 'REDES & INFRA (NO-LLM)';
      case ScenarioCategory.llmPrompt:
        return 'LLM PURO (PROMPT WAR)';
      case ScenarioCategory.hybridCitadel:
        return 'HÍBRIDO (INFRA + IA)';
      case ScenarioCategory.vpnMitM:
        return 'TUNELAMENTO & CRIPTO';
    }
  }

  Color get categoryColor {
    switch (category) {
      case ScenarioCategory.networkInfra:
        return AppColors.blueTeam;
      case ScenarioCategory.llmPrompt:
        return AppColors.coreAi;
      case ScenarioCategory.hybridCitadel:
        return AppColors.cpuClock;
      case ScenarioCategory.vpnMitM:
        return AppColors.bandwidth;
    }
  }

  /// Catálogo de cenários oficiais descritos em docs/ideias_cenarios_e_mecanicas.md
  static List<ScenarioModel> get catalog {
    return const [
      ScenarioModel(
        id: 'scenario_hardening_instance',
        title: 'Hardening de Instância Web',
        description:
            'Servidor de produção expôs portas perigosas (FTP 21, Telnet 23) por engano durante a Black Friday.',
        category: ScenarioCategory.networkInfra,
        difficulty: 1,
        objectiveBlue: 'Fechar portas legadas, manter HTTPS 443 operando acima de 95% de SLA.',
        objectiveRed: 'Realizar Port Scanning rápido e explorar credenciais anônimas.',
        icon: Icons.shield_outlined,
      ),
      ScenarioModel(
        id: 'scenario_hybrid_citadel',
        title: 'A Cidadela Híbrida: Bastion de IA',
        description:
            'Assistente inteligente de DevOps possui acesso direto à API de regras do Cloud Firewall da empresa.',
        category: ScenarioCategory.hybridCitadel,
        difficulty: 3,
        objectiveBlue: 'Monitorar a integridade do Core LLM e injetar micro-patches de blindagem semântica.',
        objectiveRed: 'Executar Prompt Injection DAN para que a IA abra a porta SSH para invasão.',
        icon: Icons.psychology_rounded,
      ),
      ScenarioModel(
        id: 'scenario_stolen_key',
        title: 'A Chave Roubada: Corrida Cripto',
        description:
            'Arquivo de credenciais foi vazado. Ambos os times possuem informações parciais da chave do cofre.',
        category: ScenarioCategory.hybridCitadel,
        difficulty: 2,
        objectiveBlue: 'Acionar rotação emergencial de segredos antes da quebra da chave.',
        objectiveRed: 'Combinar fragmentos parciais conhecidos via dicionário para abrir o cofre.',
        icon: Icons.key_rounded,
      ),
      ScenarioModel(
        id: 'scenario_vpn_mitm',
        title: 'Queda de VPN & Ataque MitM',
        description:
            'Tráfego remoto de desenvolvedores trafega via túnel com certificado raiz prestes a expirar.',
        category: ScenarioCategory.vpnMitM,
        difficulty: 2,
        objectiveBlue: 'Emitir novo certificado WireGuard e bloquear tráfego de rotas não criptografadas.',
        objectiveRed: 'Forçar desautenticação e capturar pacotes de texto claro fora do túnel.',
        icon: Icons.vpn_lock_rounded,
      ),
    ];
  }
}
