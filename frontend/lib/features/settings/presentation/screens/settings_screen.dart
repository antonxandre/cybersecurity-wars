import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/services/settings_service.dart';

enum SettingsCategory { video, audio, security, gameplay, system }

/// Tela de Configurações do Sistema Tático (Cyber Arena / CyberWars).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsCategory _selectedCategory = SettingsCategory.video;
  final SettingsService _settingsService = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    _settingsService.initialize();
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      if (AuthService.instance.isAuthenticated) {
        context.go('/lobby');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsService,
      builder: (context, _) {
        final settings = _settingsService.settings;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header Tático Superior
                _buildHeader(context),

                // Conteúdo Principal Responsivo
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;

                      if (isWide) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Menu lateral de abas (Sidebar)
                              SizedBox(
                                width: 260,
                                child: _buildCategorySidebar(),
                              ),
                              const SizedBox(width: 24),
                              // Painel de opções da aba selecionada
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: AppColors.borderGlow),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: _buildCategoryContent(settings),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Layout compacto para telas menores
                        return Column(
                          children: [
                            _buildCompactCategoryTabs(),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: _buildCategoryContent(settings),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border:
            Border(bottom: BorderSide(color: AppColors.borderGlow, width: 1.5)),
      ),
      child: Row(
        children: [
          // Botão Voltar
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blueTeam,
              side: const BorderSide(color: AppColors.blueTeam, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
            label: Text('RETORNAR',
                style: AppTypography.codeSmall
                    .copyWith(fontWeight: FontWeight.bold)),
            onPressed: _handleBack,
          ),
          const SizedBox(width: 16),

          // Ícone e Título
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blueTeam.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.blueTeam),
            ),
            child: const Icon(Icons.tune_rounded,
                color: AppColors.blueTeam, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('CONFIGURAÇÕES DO SISTEMA',
                      style: AppTypography.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bandwidth.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.bandwidth, width: 1),
                    ),
                    child: Text(
                      'TERMINAL v1.0',
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.bandwidth,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Personalize Vídeo, Áudio, Segurança DevSecOps e Jogabilidade',
                style: AppTypography.codeSmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),

          const Spacer(),

          // Botão Restaurar Padrões
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.redTeam,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(
              'RESTAURAR PADRÕES',
              style: AppTypography.codeSmall.copyWith(
                  color: AppColors.redTeam, fontWeight: FontWeight.bold),
            ),
            onPressed: _confirmResetToDefaults,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              'MÓDULOS DE CONTROLE',
              style: AppTypography.codeSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...SettingsCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            final (title, icon) = _getCategoryMeta(cat);

            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.cardSurface : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color:
                          isSelected ? AppColors.blueTeam : Colors.transparent,
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? AppColors.blueTeam
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.blueTeam),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: SettingsCategory.values.map((cat) {
          final isSelected = _selectedCategory == cat;
          final (title, icon) = _getCategoryMeta(cat);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              avatar: Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.black : AppColors.textSecondary),
              label: Text(title),
              labelStyle: AppTypography.codeSmall.copyWith(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selected: isSelected,
              selectedColor: AppColors.blueTeam,
              backgroundColor: AppColors.cardSurface,
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  (String, IconData) _getCategoryMeta(SettingsCategory cat) {
    return switch (cat) {
      SettingsCategory.video => ('Vídeo & Gráficos', Icons.monitor_rounded),
      SettingsCategory.audio => ('Áudio & Efeitos', Icons.volume_up_rounded),
      SettingsCategory.security => ('Segurança & IA', Icons.security_rounded),
      SettingsCategory.gameplay => (
          'Jogabilidade',
          Icons.sports_esports_rounded
        ),
      SettingsCategory.system => (
          'Sistema & OWASP',
          Icons.info_outline_rounded
        ),
    };
  }

  Widget _buildCategoryContent(dynamic settings) {
    return switch (_selectedCategory) {
      SettingsCategory.video => _buildVideoSettings(settings),
      SettingsCategory.audio => _buildAudioSettings(settings),
      SettingsCategory.security => _buildSecuritySettings(settings),
      SettingsCategory.gameplay => _buildGameplaySettings(settings),
      SettingsCategory.system => _buildSystemSettings(),
    };
  }

  // -------------------------------------------------------------------------
  // 1. TELA & VÍDEO
  // -------------------------------------------------------------------------
  Widget _buildVideoSettings(dynamic settings) {
    final isFullscreen = FullscreenHelper.isFullscreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'EXIBIÇÃO & DESEMPENHO VISUAL',
          'Configure a taxa de atualização, efeitos de brilho neon e modo de tela cheia.',
        ),
        const SizedBox(height: 16),

        // Destaque: Tela Cheia por Padrão
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.blueTeam.withValues(alpha: 0.5), width: 1.5),
            boxShadow:
                AppColors.neonGlow(AppColors.blueTeam, blur: 10, spread: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blueTeam.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen_rounded,
                        color: AppColors.blueTeam, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Tela Cheia por Padrão (Fullscreen)',
                                style: AppTypography.titleMedium),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: settings.fullscreenByDefault
                                    ? AppColors.bandwidth.withValues(alpha: 0.2)
                                    : AppColors.textMuted
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: settings.fullscreenByDefault
                                      ? AppColors.bandwidth
                                      : AppColors.textMuted,
                                ),
                              ),
                              child: Text(
                                settings.fullscreenByDefault
                                    ? 'PADRÃO ATIVADO'
                                    : 'MANUAL',
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 10,
                                  color: settings.fullscreenByDefault
                                      ? AppColors.bandwidth
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inicia a aplicação automaticamente em modo tela cheia imersivo para melhor visualização tática da Arena 2D.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.fullscreenByDefault,
                    activeThumbColor: AppColors.blueTeam,
                    activeTrackColor: AppColors.blueTeam.withValues(alpha: 0.3),
                    onChanged: (val) {
                      _settingsService.setFullscreenByDefault(val);
                    },
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFullscreen
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isFullscreen
                            ? AppColors.bandwidth
                            : AppColors.textSecondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFullscreen
                            ? 'Status Atual: Em Tela Cheia'
                            : 'Status Atual: Modo Janela',
                        style: AppTypography.codeSmall.copyWith(
                          color: isFullscreen
                              ? AppColors.bandwidth
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueTeam,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    icon: Icon(
                        isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        size: 18),
                    label: Text(
                      isFullscreen
                          ? 'SAIR DE TELA CHEIA'
                          : 'ENTRAR EM TELA CHEIA AGORA',
                      style: AppTypography.codeSmall
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      FullscreenHelper.toggleFullscreen();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Efeitos de Neon Glow & Bloom
        _buildSwitchTile(
          icon: Icons.auto_awesome_rounded,
          iconColor: AppColors.coreAi,
          title: 'Resplendor & Glow Neon Cyberpunk',
          description:
              'Habilita camadas dinâmicas de iluminação e sombras para feixes de laser e bastions.',
          value: settings.neonGlowEnabled,
          onChanged: (val) => _settingsService.setNeonGlow(val),
        ),

        // Grade Holográfica de Fundo
        _buildSwitchTile(
          icon: Icons.grid_4x4_rounded,
          iconColor: AppColors.bandwidth,
          title: 'Grade Holográfica de Rede Animada',
          description:
              'Exibe a malha de fluxo de pacotes SYN/ACK no plano de fundo panorâmico.',
          value: settings.animatedGridEnabled,
          onChanged: (val) => _settingsService.setAnimatedGrid(val),
        ),

        const SizedBox(height: 16),
        // Taxa de Quadros Alvo
        Text('Meta de Taxa de Quadros (Target FPS)',
            style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [30, 60, 120].map((fps) {
            final isSelected = settings.targetFps == fps;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => _settingsService.setTargetFps(fps),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.blueTeam.withValues(alpha: 0.15)
                        : AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.blueTeam : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$fps FPS',
                        style: AppTypography.codeMedium.copyWith(
                          color: isSelected
                              ? AppColors.blueTeam
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fps == 30
                            ? 'Econômico'
                            : (fps == 60 ? 'Competitivo' : 'Ultra Suave'),
                        style: AppTypography.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 2. ÁUDIO & EFEITOS
  // -------------------------------------------------------------------------
  Widget _buildAudioSettings(dynamic settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'SINTETIZADOR & MIXER DE ÁUDIO',
          'Ajuste o volume principal, efeitos de alerta tático e trilha sonora synthwave.',
        ),
        const SizedBox(height: 16),
        _buildSliderTile(
          icon: Icons.volume_up_rounded,
          iconColor: AppColors.blueTeam,
          title: 'Volume Geral (Master)',
          value: settings.masterVolume,
          onChanged: (val) => _settingsService.setMasterVolume(val),
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          icon: Icons.graphic_eq_rounded,
          iconColor: AppColors.bandwidth,
          title: 'Efeitos Sonoros Táticos (SFX)',
          subtitle:
              'Disparos de laser, propagação de malware, alertas de invasão de portas.',
          value: settings.sfxVolume,
          onChanged: (val) => _settingsService.setSfxVolume(val),
        ),
        const SizedBox(height: 12),
        _buildSliderTile(
          icon: Icons.music_note_rounded,
          iconColor: AppColors.coreAi,
          title: 'Trilha Sonora Synthwave / Cyberpunk (BGM)',
          subtitle: 'Música ambiente durante preparação e combate de ondas.',
          value: settings.bgmVolume,
          onChanged: (val) => _settingsService.setBgmVolume(val),
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          icon: Icons.vibration_rounded,
          iconColor: AppColors.cpuClock,
          title: 'Feedback Háptico / Vibração',
          description:
              'Vibração tátil em cliques e impactos no Mainframe em dispositivos móveis.',
          value: settings.hapticFeedback,
          onChanged: (val) => _settingsService.setHapticFeedback(val),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 3. SEGURANÇA & IA (OWASP Top 10:2025)
  // -------------------------------------------------------------------------
  Widget _buildSecuritySettings(dynamic settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'BLINDAGEM DEVSECOPS & SALVAGUARDAS LLM',
          'Configurações de isolamento semântico contra Injection (A03) e criptografia pós-quântica.',
        ),
        const SizedBox(height: 16),

        // Criptografia TLS
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_rounded,
                      color: AppColors.bandwidth, size: 20),
                  const SizedBox(width: 10),
                  Text('Suíte Criptográfica de Conexão TLS',
                      style: AppTypography.titleMedium),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bandwidth.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PQC ATIVO',
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.bandwidth,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Define o algoritmo de troca de chaves na negociação Nginx SSL/TLS com proteção quântica.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'PQC (X25519MLKEM768)',
                  'TLS 1.3 (ChaCha20-Poly1305)',
                  'TLS 1.3 (AES-256-GCM)',
                ].map((cipher) {
                  final isSelected = settings.tlsCipher == cipher;
                  return ChoiceChip(
                    label: Text(cipher),
                    labelStyle: AppTypography.codeSmall.copyWith(
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.bandwidth,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => _settingsService.setTlsCipher(cipher),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Delimitadores de Prompt (A03)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.code_rounded,
                      color: AppColors.coreAi, size: 20),
                  const SizedBox(width: 10),
                  Text('Delimitadores de Prompt (Anti Prompt Injection - A03)',
                      style: AppTypography.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Estrutura delimitadora enviada ao LLM para evitar fuga de contexto e extração de system prompt.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'XML Boundary (<rules>)',
                  'JSON Schema Strict',
                  'Markdown Triple-Fence',
                ].map((del) {
                  final isSelected = settings.promptDelimiter == del;
                  return ChoiceChip(
                    label: Text(del),
                    labelStyle: AppTypography.codeSmall.copyWith(
                      color: isSelected ? Colors.black : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.coreAi,
                    backgroundColor: AppColors.surface,
                    onSelected: (_) => _settingsService.setPromptDelimiter(del),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSwitchTile(
          icon: Icons.psychology_rounded,
          iconColor: AppColors.redTeam,
          title: 'Telemetria de Logprobs e Risco de Jailbreak',
          description:
              'Calcula o medidor de tensão adversarial ao vivo com base na incerteza das respostas do LLM.',
          value: settings.logprobsTelemetry,
          onChanged: (val) => _settingsService.setLogprobsTelemetry(val),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 4. JOGABILIDADE
  // -------------------------------------------------------------------------
  Widget _buildGameplaySettings(dynamic settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'MECÂNICAS & CONTROLES DA ARENA',
          'Ajuste o comportamento da câmera, atalhos de posicionamento e fluxo de turnos.',
        ),
        const SizedBox(height: 16),
        _buildSwitchTile(
          icon: Icons.pan_tool_rounded,
          iconColor: AppColors.blueTeam,
          title: 'Câmera Panorâmica Livre (Pan & Zoom)',
          description:
              'Permite arrastar a visão tática e navegar entre o seu Mainframe e a base inimiga.',
          value: settings.panoramicCamera,
          onChanged: (val) => _settingsService.setPanoramicCamera(val),
        ),
        _buildSwitchTile(
          icon: Icons.touch_app_rounded,
          iconColor: AppColors.bandwidth,
          title: 'Construção Rápida (1-Click Deploy)',
          description:
              'Posiciona o nó selecionado diretamente ao clicar na coordenada livre sem abrir modal.',
          value: settings.quickBuild,
          onChanged: (val) => _settingsService.setQuickBuild(val),
        ),
        _buildSwitchTile(
          icon: Icons.timer_outlined,
          iconColor: AppColors.cpuClock,
          title: 'Auto-Ready no Turno Zero',
          description:
              'Sinaliza status Pronto automaticamente caso o tempo de preparação chegue a 0.',
          value: settings.autoReadyZeroTurn,
          onChanged: (val) => _settingsService.setAutoReadyZeroTurn(val),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 5. SISTEMA & OWASP
  // -------------------------------------------------------------------------
  Widget _buildSystemSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'DIAGNÓSTICO DO SISTEMA & OWASP TOP 10:2025',
          'Conformidade dos eixos de infraestrutura, backend NestJS e frontend Flutter Web.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'EIXO 1: INFRAESTRUTURA CLOUD & HARDENING',
          items: [
            ('Servidor GCP', 'Ubuntu 24.04 LTS (e2-micro)'),
            (
              'Acesso Administrativo',
              'Ed25519 SSH Only (Root e Senhas desabilitados)'
            ),
            ('Fail2Ban SSH', 'Porta 22 | MaxRetry = 4 | BanTime = 24h'),
            (
              'Nginx Reverse Proxy',
              'TLS 1.3 + PQC X25519MLKEM768 | Portas 80, 443'
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'EIXO 2 & 3: MATRIZ DE SEGURANÇA OWASP 2025',
          items: [
            (
              'A01:2025 - Broken Access Control',
              'Route Guards declarativos + RBAC NestJS + Destruição de Sessão'
            ),
            (
              'A03:2025 - Injection',
              'Parametrização Prisma + Sanitização de tags + Delimitadores XML'
            ),
            (
              'A07:2025 - Identification Failures',
              'Argon2id hashing + Rate Limiting 5 req/min + Sem enumeração'
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'VERSIONAMENTO DE PACOTES',
          items: [
            ('Cyber Arena', 'v1.0.0+1 (CyberWars Hybrid TD)'),
            ('Engine Gráfica', 'Flame Engine 1.18.0 (Flutter Web)'),
            ('Roteamento', 'GoRouter 14.2.0'),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // AUXILIARES VISUAIS
  // -------------------------------------------------------------------------
  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                AppTypography.titleLarge.copyWith(color: AppColors.blueTeam)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        const Divider(color: AppColors.border),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final percentage = (value * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.bodySmall),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$percentage%',
                  style: AppTypography.codeMedium
                      .copyWith(color: iconColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: iconColor,
              inactiveTrackColor: AppColors.surface,
              thumbColor: iconColor,
              overlayColor: iconColor.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<(String, String)> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.codeSmall.copyWith(
                  color: AppColors.blueTeam, fontWeight: FontWeight.bold)),
          const Divider(color: AppColors.border, height: 16),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item.$1,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.$2,
                      style: AppTypography.codeSmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _confirmResetToDefaults() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.redTeam, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.redTeam),
            const SizedBox(width: 10),
            Text('RESTAURAR PADRÕES',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.redTeam)),
          ],
        ),
        content: Text(
          'Deseja restaurar todas as configurações de vídeo, áudio e jogabilidade para os valores de fábrica (incluindo Tela Cheia por padrão)?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            child: Text('CANCELAR',
                style: AppTypography.codeSmall
                    .copyWith(color: AppColors.textSecondary)),
            onPressed: () => Navigator.of(dialogCtx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redTeam,
              foregroundColor: Colors.white,
            ),
            child: Text('RESTAURAR',
                style: AppTypography.codeSmall
                    .copyWith(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _settingsService.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configurações restauradas com sucesso.'),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
