import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';
import 'lobby_panel.dart';

/// Painel da Lista de Amigos do usuário (sem dados fixos/hardcoded).
class FriendsPartyPanel extends StatelessWidget {
  final List<LobbyFriend> friends;
  final List<String> partyMembers;
  final int maxSlots;
  final ValueChanged<LobbyFriend> onInviteFriend;
  final ValueChanged<int>? onRemovePartyMember;
  final ValueChanged<String>? onAddFriend;

  const FriendsPartyPanel({
    super.key,
    required this.friends,
    this.partyMembers = const [],
    this.maxSlots = 4,
    required this.onInviteFriend,
    this.onRemovePartyMember,
    this.onAddFriend,
  });

  void _showAddFriendDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.bandwidth, width: 1.0),
          ),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: AppColors.bandwidth, size: 20),
              const SizedBox(width: 8),
              Text(
                'ADICIONAR AMIGO',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insira o nickname ou identificador do operador:',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: CyberSentinel_01',
                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.cardSurface,
                  prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: AppColors.bandwidth),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.bandwidth),
                  ),
                ),
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    onAddFriend?.call(val.trim());
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCELAR',
                style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bandwidth,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                final val = controller.text.trim();
                if (val.isNotEmpty) {
                  onAddFriend?.call(val);
                  Navigator.of(dialogContext).pop();
                }
              },
              child: Text(
                'ADICIONAR',
                style: AppTypography.codeSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = friends.where((f) => f.status == FriendStatus.online).length;

    return LobbyPanel(
      title: 'AMIGOS',
      icon: Icons.people_alt_rounded,
      accentColor: AppColors.bandwidth,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bandwidth.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$onlineCount ONLINE',
              style: AppTypography.codeSmall.copyWith(
                color: AppColors.bandwidth,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Adicionar Amigo',
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.bandwidth),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (friends.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 32,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'NENHUM AMIGO CONECTADO',
                    style: AppTypography.codeSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adicione colegas de equipe pelo nickname para convidá-los.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showAddFriendDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.bandwidth),
                    label: Text(
                      'ADICIONAR AMIGO',
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.bandwidth,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.bandwidth),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friends.length.clamp(0, 6),
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final friend = friends[index];
                final inParty = partyMembers.contains(friend.name);
                final canInvite = friend.canInvite && !inParty && partyMembers.length < maxSlots;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.cardSurface,
                            child: Text(
                              friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: friend.status.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.name,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              friend.activity ?? friend.status.label,
                              style: AppTypography.codeSmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (inParty)
                        Text(
                          'NA SALA',
                          style: AppTypography.codeSmall.copyWith(
                            color: AppColors.bandwidth,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        SizedBox(
                          height: 26,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: canInvite ? AppColors.bandwidth : AppColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: canInvite ? () => onInviteFriend(friend) : null,
                            child: Text(
                              'CONVIDAR',
                              style: AppTypography.codeSmall.copyWith(
                                fontSize: 8,
                                color: canInvite ? AppColors.bandwidth : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Alias para o novo nome do componente
typedef FriendsPanel = FriendsPartyPanel;
