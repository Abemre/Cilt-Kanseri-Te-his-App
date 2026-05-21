import 'package:supabase_flutter/supabase_flutter.dart';

class DBService {
  final _supabase = Supabase.instance.client;

  Future<void> insertScan(String imageUrl, String resultLabel, double riskScore, String date, String bodyPart) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('scans').insert({
      'user_id': user.id,
      'image_url': imageUrl,
      'result_label': resultLabel,
      'risk_score': riskScore,
      'scan_date': date,
      'body_part': bodyPart,
    });
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
     final user = _supabase.auth.currentUser;
     if (user == null) return [];
    return await _supabase.from('scans').select().order('created_at', ascending: false);
  }

  Future<void> deleteScan(int id) async {
    await _supabase.from('scans').delete().eq('id', id);
  }
}