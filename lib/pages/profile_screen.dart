import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  
  // Örnek ayar durumları (gerçekte shared_preferences ile tutulabilir)
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _hapticEnabled = true;

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = _user?.email ?? 'Bilinmeyen Kullanıcı';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 110,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.bgDark,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.fadeTitle],
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D1117), Color(0xFF0A1628)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Profil & Ayarlar',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Hesabınızı ve tercihlerinizi yönetin',
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── İçerik ────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  
                  // 1. Kullanıcı Kartı
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF0066CC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bilgiler
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kayıtlı E-posta',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Ayarlar Başlığı
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Uygulama Tercihleri',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // 3. Ayarlar Listesi
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          isDark: isDark,
                          icon: Icons.notifications_active_rounded,
                          color: AppColors.success,
                          title: 'Bildirimler',
                          subtitle: 'Aylık tarama hatırlatıcıları',
                          value: _notificationsEnabled,
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                            if (val) HapticFeedback.lightImpact();
                          },
                        ),
                        Divider(color: isDark ? AppColors.borderDark : Colors.grey.shade100, height: 1),
                        _buildSettingTile(
                          isDark: isDark,
                          icon: Icons.dark_mode_rounded,
                          color: const Color(0xFFB10DC9),
                          title: 'Koyu Tema',
                          subtitle: 'Sadece UI görünümü',
                          value: _darkModeEnabled,
                          onChanged: (val) {
                            setState(() => _darkModeEnabled = val);
                            if (val) HapticFeedback.lightImpact();
                          },
                        ),
                        Divider(color: isDark ? AppColors.borderDark : Colors.grey.shade100, height: 1),
                        _buildSettingTile(
                          isDark: isDark,
                          icon: Icons.vibration_rounded,
                          color: const Color(0xFFFF9500),
                          title: 'Titreşim (Haptic)',
                          subtitle: 'Butonlarda hafif titreşim',
                          value: _hapticEnabled,
                          onChanged: (val) {
                            setState(() => _hapticEnabled = val);
                            if (val) HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. Çıkış Butonu
                  GestureDetector(
                    onTap: () {
                      if (_hapticEnabled) HapticFeedback.mediumImpact();
                      _logout();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Hesaptan Çıkış Yap',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'DermaAI v1.0.0',
                      style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  )
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
