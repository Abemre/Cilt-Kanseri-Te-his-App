import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/db_service.dart';
import '../main.dart';
import 'scan_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dbService = DBService();
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var res = await _dbService.getHistory();
    if (mounted) {
      setState(() {
        _data    = res;
        _loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    await _dbService.deleteScan(id);
    _load();
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
            // ── SliverAppBar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 130,
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
                          Text('Tarama Geçmişi',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('Tüm taramalarınız ve risk trendleri',
                              style: GoogleFonts.inter(
                                  color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                ),
              )
            else if (_data.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.history_rounded,
                            size: 56, color: AppColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text('Henüz tarama yok',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('İlk taramanızı yaparak başlayın',
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Özet kartları
                    _buildSummaryRow(),
                    const SizedBox(height: 16),

                    // Grafik
                    if (_data.length >= 2) ...[
                      _buildChartCard(),
                      const SizedBox(height: 16),
                    ],

                    // Başlık
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Tüm Taramalar',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),

                    // Kart listesi
                    ..._data.map((rec) => _buildScanCard(rec)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Özet Satırı ────────────────────────────────────────────────────────────
  Widget _buildSummaryRow() {
    final totalScans  = _data.length;
    final riskyScans  = _data.where((r) => r['result_label'].toString().contains('Riskli')).length;
    final avgRisk     = _data.isEmpty
        ? 0.0
        : _data.map((r) => (r['risk_score'] as double) * 100).reduce((a, b) => a + b) / _data.length;

    return Row(children: [
      _buildStatCard('Toplam', '$totalScans', Icons.document_scanner_rounded, AppColors.primary),
      const SizedBox(width: 10),
      _buildStatCard('Riskli', '$riskyScans', Icons.warning_amber_rounded, AppColors.danger),
      const SizedBox(width: 10),
      _buildStatCard('Ort. Risk', '%${avgRisk.toStringAsFixed(0)}', Icons.analytics_rounded, const Color(0xFFFF9F0A)),
    ]);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── Grafik Kartı ───────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    List<Map<String, dynamic>> chronData = _data.reversed.toList();
    List<FlSpot> spots = List.generate(chronData.length, (i) {
      return FlSpot(i.toDouble(), (chronData[i]['risk_score'] as double) * 100);
    });

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Text('Risk Trendi',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        '%${value.toInt()}',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.5,
                        color: AppColors.primary,
                        strokeColor: AppColors.bgDark,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  // ── Tarama Kartı ───────────────────────────────────────────────────────────
  Widget _buildScanCard(Map<String, dynamic> rec) {
    final isRiskli = rec['result_label'].toString().contains('Riskli');
    final color    = isRiskli ? AppColors.danger : AppColors.success;
    final score    = (rec['risk_score'] as double) * 100;

    return Dismissible(
      key: Key('scan_${rec['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 26),
      ),
      onDismissed: (_) => _delete(rec['id'] as int),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ScanDetailScreen(scanData: rec),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Fotoğraf (Hero ile)
                Hero(
                  tag: 'scan_image_${rec['id']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(rec['image_url']),
                      width: 68, height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.broken_image_rounded,
                            color: Colors.white24, size: 28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(rec['result_label'],
                              style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (rec['body_part'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(rec['body_part'],
                                  style: GoogleFonts.inter(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Mini risk bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 4,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text('Risk: %${score.toStringAsFixed(1)}',
                              style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text(rec['scan_date'],
                              style: GoogleFonts.inter(
                                  color: Colors.white24, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}