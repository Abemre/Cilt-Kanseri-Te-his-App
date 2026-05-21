import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading  = false;
  bool _isLogin    = true;
  bool _showPass   = false;
  final _supabase  = Supabase.instance.client;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    
    // Auto-login check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (_supabase.auth.currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => hasSeen ? const MainNavigator() : const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 0), // Hemen geç
        ),
      );
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showSnack('Lütfen tüm alanları doldurun.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => hasSeen ? const MainNavigator() : const OnboardingScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showSnack('Hata oluştu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Stack(
          children: [
            // ── Arka plan gradient + dekoratif daireler ──────────────────
            Positioned.fill(
              child: CustomPaint(painter: _BgPainter()),
            ),

            // ── İçerik ───────────────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: size.height - MediaQuery.of(context).padding.top,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(flex: 2),

                            // Logo & başlık
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFF0066CC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.health_and_safety_rounded,
                                    color: Colors.white, size: 48),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'DermaAI',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Yapay Zeka Destekli Cilt Tarama',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white54,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Form kartı
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: AppColors.borderDark),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _isLogin ? 'Giriş Yap' : 'Hesap Oluştur',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isLogin
                                        ? 'Hoş geldiniz! Devam etmek için giriş yapın.'
                                        : 'Ücretsiz hesabınızı oluşturun.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Email
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: 'E-posta adresi',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 14),

                                  // Şifre
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: 'Şifre',
                                    icon: Icons.lock_outline_rounded,
                                    obscure: !_showPass,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() => _showPass = !_showPass),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Giriş butonu
                                  _isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 28, height: 28,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        )
                                      : _buildPrimaryButton(
                                          label: _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                                          onPressed: _auth,
                                        ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Geçiş linki
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin ? 'Hesabın yok mu? ' : 'Zaten hesabın var mı? ',
                                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isLogin = !_isLogin);
                                    _animCtrl.reset();
                                    _animCtrl.forward();
                                  },
                                  child: Text(
                                    _isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String label, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF0066CC)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Arka plan dekoratif daireler ─────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Üst sağ parlak daire
    paint.color = AppColors.primary.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width + 60, -60), 200, paint);

    paint.color = AppColors.primary.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width + 30, -30), 280, paint);

    // Alt sol
    paint.color = const Color(0xFF0066CC).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(-80, size.height + 80), 220, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}