import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class AiService {
  Interpreter? _interpreter;

  // Modeli RAM'e yükleme
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/skin_cancer_v7_bigdata_TESTED.tflite');
      print('✅ V7 Grandmaster Yapay Zeka Motoru Hazır!');
    } catch (e) {
      print('❌ Model Yükleme Hatası: $e');
    }
  }

  // Çift girdili (Resim + Klinik Veri) analiz fonksiyonu
  Future<Map<String, dynamic>> predictMultiModal(File imageFile, double age, bool isMale) async {
    if (_interpreter == null) {
      return {'label': 'Hata: Model Yüklenmedi', 'risk_score': 0.0};
    }

    try {
      // 1. Resmi Oku ve Bozuk Olma İhtimaline Karşı Kontrol Et
      var imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        return {'label': 'Hata: Resim Okunamadı', 'risk_score': 0.0};
      }

      // Resmi 300x300 Boyutuna Küçült (EfficientNetB3 gereksinimi)
      img.Image resizedImage = img.copyResize(originalImage, width: 300, height: 300);

      // 2. Resmi 4 Boyutlu Matrise Çevir: [1, 300, 300, 3]
      var inputImage = List.generate(1, (i) => List.generate(300, (y) => List.generate(300, (x) => List.filled(3, 0.0))));
      
      for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 300; x++) {
          var pixel = resizedImage.getPixel(x, y);
          // 2. GÜNCELLEME: Pikselleri 255'e bölerek (Normalize) 0-1 aralığına çekiyoruz!
          inputImage[0][y][x][0] = pixel.r / 255.0; // Red
          inputImage[0][y][x][1] = pixel.g / 255.0; // Green
          inputImage[0][y][x][2] = pixel.b / 255.0; // Blue
        }
      }

      // 3. Meta Veriyi Hazırla (Yaş Norm ve Cinsiyet)
      double ageNorm = age / 100.0;
      double genderVal = isMale ? 1.0 : 0.0;
      var inputMeta = [[ageNorm, genderVal]];

      // 4. Modele Verileri Gönder
      List<Object> inputs = [inputImage, inputMeta];
      
      var output = List.generate(1, (i) => List.filled(1, 0.0));
      Map<int, Object> outputs = {0: output};
      
      _interpreter!.runForMultipleInputs(inputs, outputs);

      // 5. Çıktıyı Al ve YENİ Eşik Değeriyle (0.48) Yorumla
      double riskScore = output[0][0];
      // 3. GÜNCELLEME: Test setinden çıkan optimal karar eşiği 0.48
      String label = riskScore >= 0.48 ? 'Riskli' : 'İyi Huylu';

      return {
        'label': label,
        'risk_score': riskScore,
      };
    } catch (e) {
      print('❌ Analiz Motoru Çöktü: $e');
      return {'label': 'Analiz Başarısız', 'risk_score': 0.0};
    }
  }
}