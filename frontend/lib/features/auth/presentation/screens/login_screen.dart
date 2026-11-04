import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../../../core/utils/password_validator.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/services/auth_service.dart';

/// Tela de Autenticação Tática (Login / Cadastro) com estética Cyberpunk Neon.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final UserRole _selectedRole = UserRole.blueTeam;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (_isRegisterMode && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _errorMessage = null;
    });

    final auth = AuthService.instance;

    if (_isRegisterMode) {
      final strength = PasswordValidator.analyze(_passwordController.text);
      if (!strength.isValid) {
        setState(() {
          _errorMessage = strength.errorMessage ??
              'A senha deve possuir no mínimo 8 caracteres, maiúsculas, minúsculas, números e símbolos especiais.';
        });
        return;
      }

      setState(() => _isLoading = true);
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
        context.go('/lobby');
      }
    } else {
      final loginValidation =
          PasswordValidator.validateLogin(_passwordController.text);
      if (!loginValidation.isValid) {
        setState(() {
          _errorMessage = loginValidation.errorMessage;
        });
        return;
      }

      setState(() => _isLoading = true);
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
        context.go('/lobby');
      }
    }
  }

  void _quickDemoLogin(UserRole role) {
    AuthService.instance.loginDemo(role);
    context.go('/lobby');
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _selectedRole == UserRole.blueTeam
        ? AppColors.blueTeam
        : AppColors.redTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Alternar Tela Cheia',
                  icon: const Icon(Icons.fullscreen_rounded,
                      color: AppColors.textPrimary, size: 22),
                  onPressed: () {
                    FullscreenHelper.toggleFullscreen();
                    setState(() {});
                  },
                ),
                IconButton(
                  tooltip: 'Configurações do Sistema',
                  icon: const Icon(Icons.settings_rounded,
                      color: AppColors.blueTeam, size: 22),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: activeColor.withValues(alpha: 0.6), width: 1.5),
                    boxShadow:
                        AppColors.neonGlow(activeColor, blur: 20, spread: 1),
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
                        child: Icon(Icons.terminal_rounded,
                            size: 36, color: activeColor),
                      ),
                      const SizedBox(height: 16),
                      Text('CYBER ARENA', style: AppTypography.displayMedium),
                      const SizedBox(height: 6),
                      Text(
                        'UM JOGO DE ESTRATÉGIA CIBERNÉTICA',
                        textAlign: TextAlign.center,
                        style: AppTypography.codeSmall.copyWith(
                            color: AppColors.textSecondary, letterSpacing: 1),
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
                                onTap: () => setState(() {
                                  _isRegisterMode = false;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isRegisterMode
                                        ? activeColor.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    border: !_isRegisterMode
                                        ? Border.all(color: activeColor)
                                        : null,
                                  ),
                                  child: Text(
                                    'LOGIN',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.codeMedium.copyWith(
                                      color: !_isRegisterMode
                                          ? activeColor
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _isRegisterMode = true;
                                  _errorMessage = null;
                                }),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isRegisterMode
                                        ? activeColor.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    border: _isRegisterMode
                                        ? Border.all(color: activeColor)
                                        : null,
                                  ),
                                  child: Text(
                                    'CADASTRO',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.codeMedium.copyWith(
                                      color: _isRegisterMode
                                          ? activeColor
                                          : AppColors.textMuted,
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

                      // Campos de Entrada
                      if (_isRegisterMode) ...[
                        _buildTextField(
                          controller: _usernameController,
                          label: 'NOME',
                          hintText: 'ex: Operador Ghost',
                          icon: Icons.person_outline_rounded,
                          activeColor: activeColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: 'EMAIL',
                        hintText: 'operador@cyberarena.com',
                        icon: Icons.email_outlined,
                        activeColor: activeColor,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'SENHA',
                        hintText: _isRegisterMode
                            ? 'Mín. 8 carac. (A-Z, a-z, 0-9, !@#)'
                            : 'Digite sua senha tática',
                        icon: Icons.lock_outline_rounded,
                        activeColor: activeColor,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),

                      // Medidor de Força Tática de Senha (Apenas no Modo Cadastro)
                      if (_isRegisterMode) ...[
                        const SizedBox(height: 10),
                        _buildPasswordStrengthMeter(activeColor),
                      ],

                      // Alerta de Erro (OWASP A07: sem enumeração de usuário)
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.redTeam.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.redTeam),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppColors.redTeam, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.redTeam),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _handleAuth,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: AppColors.background,
                                      strokeWidth: 2),
                                )
                              : Text(
                                  _isRegisterMode ? 'CADASTRAR' : 'ENTRAR',
                                  style: AppTypography.codeMedium.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      if (kDebugMode) ...[
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 14),

                        // Acessos Rápidos de Demonstração (Apenas em Debug/Desenvolvimento)
                        Text('ACESSO RÁPIDO DE DESENVOLVEDOR:',
                            style:
                                AppTypography.codeSmall.copyWith(fontSize: 10)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.blueTeam, width: 1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () =>
                                    _quickDemoLogin(UserRole.blueTeam),
                                child: Text(
                                  'DEMO BLUE 🛡️',
                                  style: AppTypography.codeSmall
                                      .copyWith(color: AppColors.blueTeam),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.redTeam, width: 1),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onPressed: () =>
                                    _quickDemoLogin(UserRole.redTeam),
                                child: Text(
                                  'DEMO RED ⚔️',
                                  style: AppTypography.codeSmall
                                      .copyWith(color: AppColors.redTeam),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color activeColor,
    String? hintText,
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
            hintText: hintText,
            hintStyle: AppTypography.codeMedium
                .copyWith(color: AppColors.textMuted.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: activeColor, size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.cardSurface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildPasswordStrengthMeter(Color activeColor) {
    final password = _passwordController.text;
    final strength = PasswordValidator.analyze(password);
    final hasText = password.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasText ? strength.color.withValues(alpha: 0.5) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    strength.isValid
                        ? Icons.verified_user_rounded
                        : Icons.security_rounded,
                    color: hasText ? strength.color : AppColors.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CRIPTO-FORÇA: ${hasText ? strength.label : "DIGITE A SENHA"}',
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: hasText ? strength.color : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (hasText ? strength.color : AppColors.textMuted)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasText ? strength.color : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${strength.score}/5',
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: hasText ? strength.color : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: hasText ? strength.progress : 0.05,
              minHeight: 4,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                hasText ? strength.color : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: strength.requirements.map((req) {
              final isMet = req.isMet && hasText;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMet
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 12,
                    color: isMet ? AppColors.bandwidth : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    req.label,
                    style: AppTypography.codeSmall.copyWith(
                      fontSize: 10,
                      color: isMet ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
