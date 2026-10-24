import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:promptsec_arena_front/game/components/data_packet_component.dart';

/// Serviço responsável pelo escalonamento e geração de ondas de ataque (Wave Spawner).
class WaveSpawnerService {
  int currentWave = 1;
  final int totalWaves = 3;

  int packetsSpawnedInWave = 0;
  int aliveEnemies = 0;
  double _spawnTimer = 0.0;
  double _clientTimer = 0.0;

  bool _isWaveFinished = false;

  int get totalPacketsInCurrentWave {
    switch (currentWave) {
      case 1:
        return 8; // Onda 1: 8 Scanners
      case 2:
        return 14; // Onda 2: 14 SYN Floods
      case 3:
        return 18; // Onda 3: 17 Suportes + 1 Boss Zero-Day
      default:
        return 10;
    }
  }

  double get spawnInterval {
    switch (currentWave) {
      case 1:
        return 1.8;
      case 2:
        return 0.9;
      case 3:
        return 1.2;
      default:
        return 1.5;
    }
  }

  void startWave(int waveNumber) {
    currentWave = waveNumber;
    packetsSpawnedInWave = 0;
    aliveEnemies = 0;
    _spawnTimer = 0.0;
    _clientTimer = 0.0;
    _isWaveFinished = false;
    debugPrint(
        '[WaveSpawner] Iniciando Onda $currentWave com $totalPacketsInCurrentWave pacotes');
  }

  void update({
    required double dt,
    required double lane1X,
    required double lane2X,
    required double startY,
    required void Function(DataPacketComponent packet) onSpawnPacket,
    required void Function(int completedWave) onWaveCompleted,
  }) {
    if (_isWaveFinished) return;

    // 1. Spawner de Tráfego Legítimo de Clientes (Pacotes Verdes HTTPS)
    _clientTimer += dt;
    if (_clientTimer >= 3.5) {
      _clientTimer = 0.0;
      final laneX = Random().nextBool() ? lane1X : lane2X;
      final clientPacket = DataPacketComponent(
        startPosition: Vector2(laneX, startY),
        origin: PacketOrigin.clientTraffic,
        subtype: PacketSubtype.clientHttps,
        direction: Vector2(0, 1),
        speed: 100.0,
        damage: 0,
        maxHealth: 50.0,
      );
      onSpawnPacket(clientPacket);
    }

    // 2. Spawner de Pacotes Inimigos de Ataque (Red Team)
    if (packetsSpawnedInWave < totalPacketsInCurrentWave) {
      _spawnTimer += dt;
      if (_spawnTimer >= spawnInterval) {
        _spawnTimer = 0.0;
        packetsSpawnedInWave++;
        aliveEnemies++;

        final isLane1 = (packetsSpawnedInWave % 2) == 1;
        final targetX = isLane1 ? lane1X : lane2X;

        final DataPacketComponent enemyPacket;

        // Se for a Onda 3 e o pacote for o número 12, gera o Boss Zero-Day!
        if (currentWave == 3 && packetsSpawnedInWave == 12) {
          enemyPacket = DataPacketComponent(
            startPosition: Vector2(targetX, startY),
            origin: PacketOrigin.redExploit,
            subtype: PacketSubtype.zeroDayPayload,
            direction: Vector2(0, 1),
            speed: 65.0,
            maxHealth: 350.0,
            damage: 40.0, // Dano massivo ao Core
            onDestroyed: (_) => aliveEnemies--,
            onReachedEnd: (_) => aliveEnemies--,
          );
        } else if (currentWave == 2 ||
            (currentWave == 3 && packetsSpawnedInWave % 3 == 0)) {
          // Pacote SYN Flood (rápido e frágil)
          enemyPacket = DataPacketComponent(
            startPosition: Vector2(targetX, startY),
            origin: PacketOrigin.redExploit,
            subtype: PacketSubtype.synFlood,
            direction: Vector2(0, 1),
            speed: 180.0,
            maxHealth: 30.0,
            damage: 10.0,
            onDestroyed: (_) => aliveEnemies--,
            onReachedEnd: (_) => aliveEnemies--,
          );
        } else {
          // Pacote Port Scanner padrão
          enemyPacket = DataPacketComponent(
            startPosition: Vector2(targetX, startY),
            origin: PacketOrigin.redExploit,
            subtype: PacketSubtype.portScanner,
            direction: Vector2(0, 1),
            speed: 125.0,
            maxHealth: 60.0,
            damage: 20.0,
            onDestroyed: (_) => aliveEnemies--,
            onReachedEnd: (_) => aliveEnemies--,
          );
        }

        onSpawnPacket(enemyPacket);
      }
    } else if (aliveEnemies <= 0 && !_isWaveFinished) {
      // Todos os pacotes da onda foram derrotados ou alcançaram o fim
      _isWaveFinished = true;
      debugPrint('[WaveSpawner] Onda $currentWave CONCLUÍDA com sucesso!');
      onWaveCompleted(currentWave);
    }
  }

  void reset() {
    startWave(1);
  }
}
