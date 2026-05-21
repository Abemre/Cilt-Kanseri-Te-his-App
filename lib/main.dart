import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/auth_screen.dart';
import 'pages/home_screen.dart';
import 'pages/profile_screen.dart';
import 'pages/scan_screen.dart';
import 'pages/history_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await Supabase.initialize(
    url: 'https://xuxocsxhtdawpfxligtg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh1eG9jc3hodGRhd3BmeGxpZ3RnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MjU1MjAsImV4cCI6MjA5MTUwMTUyMH0.DIU_qCK33PX2-eJ39ybdIA9l9xTm8U5rgFW7IkpVzts',
  );

  await NotificationService().init();

  runApp(const SkinCancerApp());
}

// ─── Design Tokens ────────────────────────────────────────────────────────────
class AppColors {
  static const primary    = Color(0xFF0A84FF);
  static const success    = Color(0xFF30D158);
  static const danger     = Color(0xFFFF453A);
  static const bgDark     = Color(0xFF0D1117);
  static const cardDark   = Color(0xFF161B22);
  static const borderDark = Color(0xFF30363D);
  static const bgLight    = Color(0xFFF4F6FA);
  static const cardLight  = Color(0xFFFFFFFF);
}

class SkinCancerApp extends StatelessWidget {
  const SkinCancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme();

    return MaterialApp(
      title: 'DermaAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.success,
          error: AppColors.danger,
          surface: AppColors.cardLight,
        ),
        textTheme: textTheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.success,
          error: AppColors.danger,
          surface: AppColors.cardDark,
        ),
        textTheme: textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const AuthScreen(),
    );
  }
}

// ─── Main Navigator ────────────────────────────────────────────────────────────
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});
  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  
  late final List<Widget> _screens = [
    HomeScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
    const ScanScreen(), 
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Ana Sayfa'),
                _buildNavItem(1, Icons.document_scanner_rounded, Icons.document_scanner_outlined, 'Tarama'),
                _buildNavItem(2, Icons.history_rounded, Icons.history_outlined, 'Geçmiş'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0066CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  key: ValueKey(isSelected),
                  color: isSelected ? Colors.white : Colors.grey,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}