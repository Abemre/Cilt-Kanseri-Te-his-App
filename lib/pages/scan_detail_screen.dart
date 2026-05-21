import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const ScanDetailScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRiskli = scanData['result_label'].toString().contains('Riskli');
    final color = isRiskli ? AppColors.danger : AppColors.success;
    final score = (scanData['risk_score'] as double) * 100;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero Görsel (SliverAppBar) ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              stretch: true,
              backgroundColor: AppColors.bgDark,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Hero(
                  tag: 'scan_image_${scanData['id']}',
                  child: Image.file(
                    File(scanData['image_url']),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.borderDark,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Detay İçeriği ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                transform: Matrix4.translationValues(0, -32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve Rozet
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tarama Sonucu',
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scanData['result_label'],
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isRiskli ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                  color: color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '%${score.toStringAsFixed(1)} Risk',
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Bilgi Kartları
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.calendar_today_rounded,
                            title: 'Tarih',
                            value: scanData['scan_date'],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            isDark: isDark,
                            icon: Icons.accessibility_new_rounded,
                            title: 'Bölge',
                            value: scanData['body_part'] ?? 'Belirtilmedi',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Açıklama Metni
                    Text(
                      'AI Değerlendirmesi',
                      style: GoogleFonts.inter(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                      ),
                      child: Text(
                        isRiskli
                            ? 'Yapay zeka bu lekenin dermatolojik olarak riskli olabileceğini tespit etti. Lütfen en kısa sürede bir uzmana (Dermatolog) görünün.'
                            : 'Yapay zeka bu lekede önemli bir risk tespit etmedi. Yine de lekenizde büyüme, kanama veya renk değişikliği olursa bir doktora başvurmayı unutmayın.',
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
