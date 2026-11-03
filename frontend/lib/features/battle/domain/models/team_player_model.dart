import 'package:flutter/material.dart';
import 'bastion_node.dart';

/// Quadrante ocupado pelo jogador no tabuleiro top-down 7x10.
enum BoardQuadrant {
  topLeft,
  bottomLeft,
  topRight,
  bottomRight,
}

extension BoardQuadrantExtension on BoardQuadrant {
  String get label {
    switch (this) {
      case BoardQuadrant.topLeft:
        return 'Top-Left';
      case BoardQuadrant.bottomLeft:
        return 'Bottom-Left';
      case BoardQuadrant.topRight:
        return 'Top-Right';
      case BoardQuadrant.bottomRight:
        return 'Bottom-Right';
    }
  }
}

/// Status em tempo real do setor do jogador na wave atual.
enum PlayerWaveStatus {
  inCombat,       // Em combate ativo no setor 7x10
  waveCleared,    // Setor limpo! Unidades movendo-se para defender o Mainframe
  leakingThreats, // Sofrendo vazamento (leak)! Ameaças avançando ao Mainframe
}

extension PlayerWaveStatusExtension on PlayerWaveStatus {
  String get label {
    switch (this) {
      case PlayerWaveStatus.inCombat:
        return 'EM COMBATE';
      case PlayerWaveStatus.waveCleared:
        return 'WAVE LIMPA';
      case PlayerWaveStatus.leakingThreats:
        return 'VAZAMENTO (LEAK)';
    }
  }

  Color get statusColor {
    switch (this) {
      case PlayerWaveStatus.inCombat:
        return const Color(0xFFFFCC00); // Amarelo alerta
      case PlayerWaveStatus.waveCleared:
        return const Color(0xFF00FF66); // Verde seguro
      case PlayerWaveStatus.leakingThreats:
        return const Color(0xFFFF3366); // Vermelho perigo
    }
  }
}

/// Representa um dos 4 jogadores de uma equipe no tabuleiro tático.
class TeamPlayerModel {
  final String id;
  final String name;
  final String teamId;
  final BoardQuadrant quadrant;
  final Color color;
  final int tokens;
  final int bits;
  final int minersCount;
  final PlayerWaveStatus waveStatus;
  final int activeThreatsCount;
  final Map<String, BastionNode> nodes;

  const TeamPlayerModel({
    required this.id,
    required this.name,
    required this.teamId,
    required this.quadrant,
    required this.color,
    this.tokens = 120,
    this.bits = 0,
    this.minersCount = 1,
    this.waveStatus = PlayerWaveStatus.inCombat,
    this.activeThreatsCount = 0,
    this.nodes = const {},
  });

  TeamPlayerModel copyWith({
    String? id,
    String? name,
    String? teamId,
    BoardQuadrant? quadrant,
    Color? color,
    int? tokens,
    int? bits,
    int? minersCount,
    PlayerWaveStatus? waveStatus,
    int? activeThreatsCount,
    Map<String, BastionNode>? nodes,
  }) {
    return TeamPlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      quadrant: quadrant ?? this.quadrant,
      color: color ?? this.color,
      tokens: tokens ?? this.tokens,
      bits: bits ?? this.bits,
      minersCount: minersCount ?? this.minersCount,
      waveStatus: waveStatus ?? this.waveStatus,
      activeThreatsCount: activeThreatsCount ?? this.activeThreatsCount,
      nodes: nodes ?? this.nodes,
    );
  }

  /// Retorna os 4 jogadores padrão do Time Aliado (Blue Team) com as cores canônicas
  static List<TeamPlayerModel> initialBlueTeam() => const [
        TeamPlayerModel(
          id: 'player_blue_1',
          name: 'Jogador 1',
          teamId: 'team_blue',
          quadrant: BoardQuadrant.topLeft,
          color: Color(0xFF00F0FF), // Ciano Neon
        ),
        TeamPlayerModel(
          id: 'player_blue_2',
          name: 'Jogador 2',
          teamId: 'team_blue',
          quadrant: BoardQuadrant.bottomLeft,
          color: Color(0xFF9D00FF), // Púrpura Neon
          nodes: {
            'node_j2_1': BastionNode(
              id: 'node_j2_1',
              name: 'Firewall',
              type: BastionNodeType.firewall,
              gridX: 1,
              gridY: 1,
              tokenCost: 40,
            ),
          },
        ),
        TeamPlayerModel(
          id: 'player_blue_3',
          name: 'Jogador 3',
          teamId: 'team_blue',
          quadrant: BoardQuadrant.topRight,
          color: Color(0xFF00FF66), // Esmeralda Neon
          nodes: {
            'node_j3_1': BastionNode(
              id: 'node_j3_1',
              name: 'Proxy',
              type: BastionNodeType.proxy,
              gridX: 2,
              gridY: 2,
              tokenCost: 50,
            ),
          },
        ),
        TeamPlayerModel(
          id: 'player_blue_4',
          name: 'Jogador 4',
          teamId: 'team_blue',
          quadrant: BoardQuadrant.bottomRight,
          color: Color(0xFFFFCC00), // Âmbar Dourado
          nodes: {
            'node_j4_1': BastionNode(
              id: 'node_j4_1',
              name: 'IDS',
              type: BastionNodeType.ids,
              gridX: 1,
              gridY: 2,
              tokenCost: 65,
            ),
          },
        ),
      ];

  /// Retorna os 4 jogadores padrão do Time Adversário (Red Team) com as cores canônicas
  static List<TeamPlayerModel> initialRedTeam() => const [
        TeamPlayerModel(
          id: 'player_red_1',
          name: 'Jogador 1',
          teamId: 'team_red',
          quadrant: BoardQuadrant.topLeft,
          color: Color(0xFFFF3366), // Carmim Neon
        ),
        TeamPlayerModel(
          id: 'player_red_2',
          name: 'Jogador 2',
          teamId: 'team_red',
          quadrant: BoardQuadrant.bottomLeft,
          color: Color(0xFFFF6600), // Laranja Neon
        ),
        TeamPlayerModel(
          id: 'player_red_3',
          name: 'Jogador 3',
          teamId: 'team_red',
          quadrant: BoardQuadrant.topRight,
          color: Color(0xFFFF0099), // Magenta Neon
        ),
        TeamPlayerModel(
          id: 'player_red_4',
          name: 'Jogador 4',
          teamId: 'team_red',
          quadrant: BoardQuadrant.bottomRight,
          color: Color(0xFFE6FF00), // Amarelo Ácido
        ),
      ];
}
