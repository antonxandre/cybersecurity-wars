import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/services/auth_service.dart';

/// Tela de Autenticação Tática (Login / Cadastro) com estética Cyberpunk Neon.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'operador@promptsec.arena');
  final _passwordController = TextEditingController(text: 'CyberSec@2026');
  final _usernameController = TextEditingController(text: 'Operador Ghost');

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.blueTeam;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = AuthService.instance;

    if (_isRegisterMode) {
      final res = await auth.register(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!res.success) {
        setState(() => _errorMessage = res.errorMessage);
      } else {
        context.go('/hub');
      }
    } else {
      final res = await auth.login(
        email: _emailController.text,
        password: _passwordController.text,
        fallbackRole: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!res.success) {
        setState(() => _errorMessage = res.errorMessage);
      } else {
        context.go('/hub');
      }
    }
  }

  void _quickDemoLogin(UserRole role) {
    AuthService.instance.loginDemo(role);
    context.go('/hub');
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _selectedRole == UserRole.blueTeam ? AppColors.blueTeam : AppColors.redTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeColor.withOpacity(0.6), width: 1.5),
                boxShadow: AppColors.neonGlow(activeColor, blur: 20, spread: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo e Cabeçalho Tático
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor),
                    ),
                    child: Icon(Icons.terminal_rounded, size: 36, color: activeColor),
                  ),
                  const SizedBox(height: 16),
                  Text('PROMPTSEC ARENA', style: AppTypography.displayMedium),
                  const SizedBox(height: 6),
                  Text(
                    'PLATAFORMA TÁTICA DE CIBERSEGURANÇA',
                    textAlign: TextAlign.center,
                    style: AppTypography.codeSmall.copyWith(color: AppColors.textSecondary, letterSpacing: 1),
                  ),
                  const SizedBox(height: 24),

                  // Alternador Login / Cadastro
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegisterMode ? activeColor.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: !_isRegisterMode ? Border.all(color: activeColor) : null,
                              ),
                              child: Text(
                                'LOGIN',
                                textAlign: TextAlign.center,
                                style: AppTypography.codeMedium.copyWith(
                                  color: !_isRegisterMode ? activeColor : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isRegisterMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegisterMode ? activeColor.withOpacity(0.2) : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                border: _isRegisterMode ? Border.all(color: activeColor) : null,
                              ),
                              child: Text(
                                'CADASTRO',
                                textAlign: TextAlign.center,
                                style: AppTypography.codeMedium.copyWith(
                                  color: _isRegisterMode ? activeColor : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Seletor de Equipe (Red vs Blue)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('EQUIPE DE COMBATE:', style: AppTypography.codeSmall),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _selectedRole == UserRole.blueTeam
                                ? AppColors.blueTeam.withOpacity(0.15)
                                : AppColors.cardSurface,
                            side: BorderSide(
                              color: _selectedRole == UserRole.blueTeam ? AppColors.blueTeam : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          onPressed: () => setState(() => _selectedRole = UserRole.blueTeam),
                          icon: const Icon(Icons.shield_rounded, color: AppColors.blueTeam, size: 16),
                          label: Text(
                            'BLUE TEAM',
                            style: AppTypography.codeSmall.copyWith(
                              color: _selectedRole == UserRole.blueTeam ? AppColors.blueTeam : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _selectedRole == UserRole.redTeam
                                ? AppColors.redTeam.withOpacity(0.15)
                                : AppColors.cardSurface,
                            side: BorderSide(
                              color: _selectedRole == UserRole.redTeam ? AppColors.redTeam : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          onPressed: () => setState(() => _selectedRole = UserRole.redTeam),
                          icon: const Icon(Icons.flash_on_rounded, color: AppColors.redTeam, size: 16),
                          label: Text(
                            'RED TEAM',
                            style: AppTypography.codeSmall.copyWith(
                              color: _selectedRole == UserRole.redTeam ? AppColors.redTeam : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Campos de Entrada
                  if (_isRegisterMode) ...[
                    _buildTextField(
                      controller: _usernameController,
                      label: 'NOME DO OPERADOR',
                      icon: Icons.person_outline_rounded,
                      activeColor: activeColor,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildTextField(
                    controller: _emailController,
                    label: 'EMAIL CORPORATIVO',
                    icon: Icons.email_outlined,
                    activeColor: activeColor,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'CHAVE DE ACESSO / SENHA',
                    icon: Icons.lock_outline_rounded,
                    activeColor: activeColor,
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // Alerta de Erro (OWASP A07: sem enumeração de usuário)
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.redTeam.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.redTeam),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.redTeam, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.redTeam),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botão Primário de Login/Cadastro
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: AppColors.background,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleAuth,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: AppColors.background, strokeWidth: 2),
                            )
                          : Text(
                              _isRegisterMode ? 'CADASTRAR E AUTORIZAR' : 'CONECTAR AO PERÍMETRO',
                              style: AppTypography.codeMedium.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 14),

                  // Acessos Rápidos de Demonstração (1-Clique)
                  Text('ACESSO RÁPIDO DE DESENVOLVEDOR:', style: AppTypography.codeSmall.copyWith(fontSize: 10)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.blueTeam, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _quickDemoLogin(UserRole.blueTeam),
                          child: Text(
                            'DEMO BLUE 🛡️',
                            style: AppTypography.codeSmall.copyWith(color: AppColors.blueTeam),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.redTeam, width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _quickDemoLogin(UserRole.redTeam),
                          child: Text(
                            'DEMO RED ⚔️',
                            style: AppTypography.codeSmall.copyWith(color: AppColors.redTeam),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color activeColor,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.codeSmall.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AppTypography.codeMedium,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: activeColor, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: activeColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
