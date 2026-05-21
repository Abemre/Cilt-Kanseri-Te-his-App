import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../main.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker    = ImagePicker();
  final _aiService = AiService();
  final _dbService = DBService();

  File?   _image;
  String  _result  = '';
  double  _score   = 0.0;
  bool    _isLoading = false;

  double  _patientAge       = 30.0;
  bool    _isMale           = true;
  String  _selectedBodyPart = 'Gövde';
  final List<String> _bodyParts = [
    'Baş/Boyun', 'Gövde', 'Sağ Kol', 'Sol Kol', 'Sağ Bacak', 'Sol Bacak'
  ];

  // Animasyonlu risk sayacı
  late AnimationController _resultAnimCtrl;
  late Animation<double>   _resultScaleAnim;

  @override
  void initState() {
    super.initState();
    _aiService.loadModel();
    _resultAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultScaleAnim = CurvedAnimation(
      parent: _resultAnimCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _resultAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null) {
      setState(() {
        _image     = File(pickedFile.path);
        _isLoading = true;
        _result    = '';
      });

      var res = await _aiService.predictMultiModal(_image!, _patientAge, _isMale);

      setState(() {
        _result    = res['label'];
        _score     = res['risk_score'];
        _isLoading = false;
      });

      _resultAnimCtrl.reset();
      _resultAnimCtrl.forward();

      try {
        await _dbService.insertScan(
          pickedFile.path,
          res['label'],
          res['risk_score'],
          DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
          _selectedBodyPart,
        );
      } catch (e) {
        debugPrint('DB kayıt hatası: $e');
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isRiskli = _result.contains('Riskli');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── SliverAppBar ───────────────────────────────────────────────
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Merhaba 👋',
                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Yeni Tarama',
                                  style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
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
                  // 1. Klinik Veri Kartı
                  _buildSection(
                    title: 'Hasta Bilgileri',
                    icon: Icons.person_outline_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yaş
                        _buildLabel('Yaş'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
                                  thumbColor: AppColors.primary,
                                  overlayColor: AppColors.primary.withValues(alpha: 0.15),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  value: _patientAge,
                                  min: 0, max: 100, divisions: 100,
                                  onChanged: (v) => setState(() => _patientAge = v),
                                ),
                              ),
                            ),
                            _buildBadge(_patientAge.round().toString(), AppColors.primary),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cinsiyet
                        _buildLabel('Cinsiyet'),
                        const SizedBox(height: 10),
                        Row(children: [
                          _buildToggleChip('Erkek', Icons.male_rounded, _isMale, AppColors.primary,
                              () => setState(() => _isMale = true)),
                          const SizedBox(width: 10),
                          _buildToggleChip('Kadın', Icons.female_rounded, !_isMale, const Color(0xFFFF2D92),
                              () => setState(() => _isMale = false)),
                        ]),
                        const SizedBox(height: 16),

                        // Vücut bölgesi
                        _buildLabel('Vücut Bölgesi'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _bodyParts.map((part) {
                            final sel = _selectedBodyPart == part;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedBodyPart = part),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel ? AppColors.primary : Colors.white12,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(part,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                      color: sel ? AppColors.primary : Colors.white54,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Fotoğraf Alanı
                  _buildSection(
                    title: 'Leke Fotoğrafı',
                    icon: Icons.camera_alt_outlined,
                    child: Column(
                      children: [
                        // Fotoğraf görüntüleme / placeholder
                        GestureDetector(
                          onTap: () => _showSourceSheet(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                color: _image != null ? AppColors.primary.withValues(alpha: 0.6) : Colors.white12,
                                width: 1.5,
                              ),
                            ),
                            child: _image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_rounded,
                                            size: 36, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 14),
                                      Text('Fotoğraf eklemek için dokunun',
                                          style: GoogleFonts.inter(
                                              color: Colors.white38,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text('Kamera veya Galeriden seçebilirsiniz',
                                          style: GoogleFonts.inter(
                                              color: Colors.white24, fontSize: 12)),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.file(_image!, fit: BoxFit.cover,
                                        width: double.infinity, height: 220),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Kamera / Galeri Butonları
                        Row(children: [
                          Expanded(
                            child: _buildActionButton(
                              label: 'Kamera',
                              icon: Icons.camera_alt_rounded,
                              isPrimary: true,
                              onPressed: () => pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              label: 'Galeri',
                              icon: Icons.photo_library_rounded,
                              isPrimary: false,
                              onPressed: () => pickImage(ImageSource.gallery),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Analiz / Sonuç Alanı
                  if (_isLoading)
                    _buildSection(
                      title: 'Analiz Ediliyor',
                      icon: Icons.psychology_outlined,
                      child: Column(children: [
                        Lottie.asset('assets/scan_anim.json', width: 160, height: 160),
                        Text(
                          'Yapay Zeka analiz yapıyor...',
                          style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                      ]),
                    )
                  else if (_result.isNotEmpty)
                    ScaleTransition(
                      scale: _resultScaleAnim,
                      child: _buildResultCard(isRiskli),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Fotoğraf Kaynak Seçimi ─────────────────────────────────────────────────
  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Fotoğraf Kaynağı Seç',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _buildSheetButton(
                  'Kamera', Icons.camera_alt_rounded, AppColors.primary,
                  () { Navigator.pop(context); pickImage(ImageSource.camera); },
                )),
                const SizedBox(width: 14),
                Expanded(child: _buildSheetButton(
                  'Galeri', Icons.photo_library_rounded, const Color(0xFF30D158),
                  () { Navigator.pop(context); pickImage(ImageSource.gallery); },
                )),
              ]),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Sonuç Kartı ─────────────────────────────────────────────────────────────
  Widget _buildResultCard(bool isRiskli) {
    final color  = isRiskli ? AppColors.danger : AppColors.success;
    final bgColor = isRiskli
        ? AppColors.danger.withValues(alpha: 0.08)
        : AppColors.success.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // İkon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRiskli ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              size: 40, color: color,
            ),
          ),
          const SizedBox(height: 16),

          Text(_result,
              style: GoogleFonts.inter(
                  fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 12),

          // Risk oranı
          _buildRiskBar(_score, color),
          const SizedBox(height: 20),

          // Butonlar
          if (isRiskli) ...[
            _buildResultButton(
              label: 'Yakındaki Dermatologları Bul',
              icon: Icons.local_hospital_rounded,
              color: AppColors.danger,
              onPressed: () async {
                final Uri url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=dermatolog+hastanesi+klinik');
                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                  if (mounted) _showSnack('Haritalar açılamadı', isError: true);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
          _buildResultButton(
            label: 'Bana 1 Ay Sonra Hatırlat',
            icon: Icons.notifications_active_rounded,
            color: AppColors.primary,
            onPressed: () async {
              await NotificationService().requestPermissions();
              await NotificationService().scheduleReminder(_selectedBodyPart);
              if (mounted) {
                _showSnack('$_selectedBodyPart için 1 ay sonrasına hatırlatıcı kuruldu!');
              }
            },
          ),

          const SizedBox(height: 16),
          Text(
            'Bu sonuçlar bir yapay zeka modelinin tahminidir, tıbbi teşhis niteliği taşımaz. Şüpheli durumlarda mutlaka bir dermatoloğa başvurunuz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white30, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBar(double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Kanser Riski',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            Text('%${(score * 100).toStringAsFixed(1)}',
                style: GoogleFonts.inter(
                    color: color, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── Ortak Yardımcı Widgetlar ──────────────────────────────────────────────
  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Divider(color: isDark ? AppColors.borderDark : Colors.grey.shade200,
              height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500));

  Widget _buildBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _buildToggleChip(String label, IconData icon, bool selected,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? color : Colors.white38, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                    color: selected ? color : Colors.white38,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0066CC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white12),
          boxShadow: isPrimary
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}