import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/chat_message.dart';

/// Widget tático de Chat de Equipe e Global (inspirado em Warcraft 3 e League of Legends).
///
/// Apresenta dois estados integrados:
/// 1. Stream Pasivo / HUD Overlay: Mensagens recentes flutuando com fundo translúcido e tags coloridas.
/// 2. Terminal Interativo: Painel expandido com histórico rolável, macros de comunicação rápida,
///    seletor de canais ([EQUIPE] / [TODOS]) e caixa de entrada de texto focável.
class TacticalTeamChatWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final void Function(String text, ChatChannel channel) onSendMessage;
  final bool initialExpanded;
  final VoidCallback? onExpandChanged;

  const TacticalTeamChatWidget({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.initialExpanded = false,
    this.onExpandChanged,
  });

  @override
  State<TacticalTeamChatWidget> createState() => TacticalTeamChatWidgetState();
}

class TacticalTeamChatWidgetState extends State<TacticalTeamChatWidget> {
  late bool _isExpanded;
  bool get isExpanded => _isExpanded;
  ChatChannel _activeChannel = ChatChannel.team;
  ChatChannel? _filterChannel; // null = Todas
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Macros táticas de comunicação rápida (Quick Chat)
  static const List<String> _quickMacros = [
    '🛡️ Defender o Mainframe!',
    '⚡ Economizem Bits para combo!',
    '🚀 Preparando envio na próxima wave!',
    '⚠️ Cuidado com leaks no setor!',
    'gg wp!',
  ];

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant TacticalTeamChatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Método público para abrir o chat externamente (ex: tecla Enter do teclado)
  void openChat({ChatChannel channel = ChatChannel.team}) {
    setState(() {
      _isExpanded = true;
      _activeChannel = channel;
    });
    widget.onExpandChanged?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _scrollToBottom();
    });
  }

  /// Método público para fechar o chat externamente (ex: tecla Escape do teclado)
  void closeChat() {
    setState(() {
      _isExpanded = false;
    });
    _focusNode.unfocus();
    widget.onExpandChanged?.call();
  }

  /// Alterna o estado expandido/colapsado
  void toggleChat() {
    if (_isExpanded) {
      closeChat();
    } else {
      openChat(channel: _activeChannel);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Envia a mensagem digitada no chat ou fecha o terminal se o campo estiver vazio
  /// seguindo o padrão de teclado de jogos de estratégia (Enter para enviar e fechar).
  void submitCurrentMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      closeChat();
      return;
    }

    widget.onSendMessage(text, _activeChannel);
    _textController.clear();
    _scrollToBottom();
    closeChat();
  }

  void _handleSendMessage() {
    submitCurrentMessage();
  }

  void _handleQuickMacro(String macro) {
    widget.onSendMessage(macro, _activeChannel);
    _scrollToBottom();
  }

  void _toggleChannel() {
    setState(() {
      _activeChannel =
          _activeChannel == ChatChannel.team ? ChatChannel.all : ChatChannel.team;
    });
  }

  List<ChatMessage> get _filteredMessages {
    if (_filterChannel == null) return widget.messages;
    return widget.messages.where((m) => m.channel == _filterChannel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final chatWidth = (screenSize.width * 0.38).clamp(320.0, 440.0);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.bottomLeft,
      child: _isExpanded
          ? _buildExpandedTerminal(chatWidth)
          : _buildPassiveStreamHud(chatWidth),
    );
  }

  // --- 1. Stream Passivo / HUD Overlay (Modo Idle) ---
  Widget _buildPassiveStreamHud(double width) {
    final recentMessages = widget.messages.length > 4
        ? widget.messages.sublist(widget.messages.length - 4)
        : widget.messages;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xBE0A0E17), // Fundo translúcido escuro
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Histórico de mensagens recentes translúcidas
          if (recentMessages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Nenhuma mensagem recente.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                ),
              ),
            )
          else
            ...recentMessages.map((msg) => _buildStreamMessageItem(msg)),

          const SizedBox(height: 6),

          // Barra inferior de acionamento do Chat (Padrão Warcraft 3 / LoL)
          InkWell(
            onTap: () => openChat(channel: _activeChannel),
            borderRadius: BorderRadius.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: AppColors.blueTeam.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: AppColors.blueTeam,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'CHAT [Enter]',
                    style: TextStyle(
                      color: AppColors.blueTeam,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pressione Enter para conversar...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamMessageItem(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChannelBadge(msg.channel, isSmall: true),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                children: [
                  if (!msg.isSystem) ...[
                    TextSpan(
                      text: '${msg.senderName}: ',
                      style: TextStyle(
                        color: msg.senderColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  TextSpan(
                    text: msg.text,
                    style: TextStyle(
                      color: msg.isSystem
                          ? AppColors.cpuClock
                          : AppColors.textPrimary,
                      fontWeight:
                          msg.isSystem ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Terminal Interativo Expandido (Modo Digitação) ---
  Widget _buildExpandedTerminal(double width) {
    final messages = _filteredMessages;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): submitCurrentMessage,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): submitCurrentMessage,
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): submitCurrentMessage,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, shift: true): submitCurrentMessage,
        const SingleActivator(LogicalKeyboardKey.escape): closeChat,
      },
      child: Container(
        width: width,
        height: 310,
        decoration: BoxDecoration(
          color: AppColors.cardSurface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.blueTeam.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blueTeam.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 2.1. Cabeçalho Tático com Filtros
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.zero,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.bandwidth,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Flexible(
                          child: Text(
                            'CHAT TÁTICO',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Filtros de Canal
                  _buildFilterChip(null, 'ALL'),
                  const SizedBox(width: 3),
                  _buildFilterChip(ChatChannel.team, 'TIME'),
                  const SizedBox(width: 3),
                  _buildFilterChip(ChatChannel.all, 'TODOS'),
                  const SizedBox(width: 6),

                  // Botão Fechar / Minimizar
                  InkWell(
                    onTap: closeChat,
                    borderRadius: BorderRadius.zero,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2.2. Lista de Mensagens do Chat
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma mensagem neste canal.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildExpandedMessageItem(msg);
                      },
                    ),
            ),

            // 2.3. Barra de Macros Rápidos (Quick Chat Chips)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickMacros.length,
                separatorBuilder: (_, __) => const SizedBox(width: 5),
                itemBuilder: (context, idx) {
                  final macro = _quickMacros[idx];
                  return Center(
                    child: InkWell(
                      onTap: () => _handleQuickMacro(macro),
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          macro,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2.4. Barra Inferior de Entrada (Input Row)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.zero,
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.8),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Seletor de Canal com Toggle ([EQUIPE] <-> [TODOS])
                  InkWell(
                    onTap: _toggleChannel,
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: _activeChannel.tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: _activeChannel.tagColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _activeChannel.tag,
                            style: TextStyle(
                              color: _activeChannel.tagColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: _activeChannel.tagColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Campo de Texto Monospace com Hotkeys
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: _activeChannel == ChatChannel.team
                            ? 'Mensagem para a Equipe... (/all para todos)'
                            : 'Mensagem para Todos (Global)...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 7),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: _activeChannel.tagColor),
                        ),
                        fillColor: AppColors.background,
                        filled: true,
                      ),
                      onSubmitted: (_) => submitCurrentMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Botão Enviar com estilo retilíneo
                  InkWell(
                    onTap: submitCurrentMessage,
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: _activeChannel.tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: _activeChannel.tagColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: _activeChannel.tagColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMessageItem(ChatMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: msg.isSystem
            ? AppColors.cpuClock.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.zero,
        border: msg.isSystem
            ? Border.all(color: AppColors.cpuClock.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '[${msg.formattedTime}]',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 5),
              _buildChannelBadge(msg.channel, isSmall: true),
              const SizedBox(width: 5),
              if (!msg.isSystem) ...[
                Text(
                  msg.senderName,
                  style: TextStyle(
                    color: msg.senderColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isSystem ? AppColors.cpuClock : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: msg.isSystem ? FontWeight.w600 : FontWeight.normal,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelBadge(ChatChannel channel, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 5 : 7,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: channel.tagColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: channel.tagColor.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Text(
        channel.tag,
        style: TextStyle(
          color: channel.tagColor,
          fontSize: isSmall ? 10.5 : 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildFilterChip(ChatChannel? channel, String label) {
    final isSelected = _filterChannel == channel;
    return InkWell(
      onTap: () => setState(() => _filterChannel = channel),
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blueTeam.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.blueTeam : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.blueTeam : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
