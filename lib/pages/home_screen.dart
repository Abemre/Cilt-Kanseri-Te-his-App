import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/db_service.dart';
import '../services/weather_service.dart';
import '../main.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DBService();
  final _weatherService = WeatherService();

  double? _uvIndex;
  bool _isLoadingUv = true;
  String _lastScanDate = '';
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load UV Index
    final uv = await _weatherService.getUvIndex();
    
    // Load Last Scan Data
    final history = await _dbService.getHistory();
    String dateStr = 'Henüz tarama yok';
    int streak = 0;

    if (history.isNotEmpty) {
      dateStr = history.first['scan_date'] ?? '';
      streak = history.length; // Basit bir streak mantığı (toplam tarama)
    }

    if (mounted) {
      setState(() {
        _uvIndex = uv;
        _isLoadingUv = false;
        _lastScanDate = dateStr;
        _streak = streak;
      });
    }
  }

  Color _getUvColor(double uv) {
    if (uv <= 2) return AppColors.success;
    if (uv <= 5) return const Color(0xFFFFCC00); // Sarı
    if (uv <= 7) return const Color(0xFFFF9500); // Turuncu
    if (uv <= 10) return AppColors.danger; // Kırmızı
    return const Color(0xFFB10DC9); // Mor (Aşırı)
  }

  String _getUvText(double uv) {
    if (uv <= 2) return 'Düşük';
    if (uv <= 5) return 'Orta';
    if (uv <= 7) return 'Yüksek';
    if (uv <= 10) return 'Çok Yüksek';
    return 'Aşırı';
  }

  String _getUvAdvice(double uv) {
    if (uv <= 2) return 'Güneş kremi sürmek için harika bir gün.';
    if (uv <= 5) return 'Dışarı çıkarken güneş kremi sürmeyi unutmayın.';
    if (uv <= 7) return 'Gölgede kalın, şapka takın ve yüksek faktörlü krem sürün.';
    return 'Zorunlu olmadıkça dışarı çıkmayın. Güneş çok tehlikeli!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          Text('DermaAI Dashboard',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd MMMM yyyy').format(DateTime.now()),
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
                  // 1. UV İndeksi Kartı
                  _buildUvCard(isDark),
                  const SizedBox(height: 16),

                  // 2. İstatistikler / Hızlı Özet
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          isDark: isDark,
                          title: 'Son Tarama',
                          value: _lastScanDate.contains(' ') ? _lastScanDate.split(' ')[0] : _lastScanDate,
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          isDark: isDark,
                          title: 'Toplam Tarama',
                          value: '$_streak',
                          icon: Icons.local_fire_department_rounded,
                          color: const Color(0xFFFF9500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Hızlı Eylem Butonu
                  GestureDetector(
                    onTap: () => widget.onNavigate(1), // Scan ekranına git
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF0066CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Yeni Tarama Başlat',
                                    style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('Yapay zeka ile lekenizi analiz edin.',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUvCard(bool isDark) {
    if (_isLoadingUv) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_uvIndex == null) {
      return Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled_rounded, color: Colors.grey.shade500, size: 40),
            const SizedBox(height: 12),
            Text('UV İndeksi alınamadı.',
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Konum izni verdiğinizden emin olun.',
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
            TextButton(onPressed: _loadData, child: const Text('Tekrar Dene'))
          ],
        ),
      );
    }

    final uvColor = _getUvColor(_uvIndex!);
    final uvText = _getUvText(_uvIndex!);
    final uvAdvice = _getUvAdvice(_uvIndex!);

    return Container(
      decoration: BoxDecoration(
        color: uvColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uvColor.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Sol Kısım: Derece
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: uvColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wb_sunny_rounded, color: uvColor, size: 36),
              ),
              const SizedBox(height: 12),
              Text(_uvIndex!.toStringAsFixed(1),
                  style: GoogleFonts.inter(color: uvColor, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(width: 20),
          
          // Sağ Kısım: Detay
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: uvColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('UV: $uvText',
                      style: GoogleFonts.inter(color: uvColor, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
                Text('Güneş Koruma Önerisi',
                    style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(uvAdvice,
                    style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required bool isDark,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}
