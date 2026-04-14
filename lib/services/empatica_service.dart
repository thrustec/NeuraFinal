import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/biyo_sensor_model.dart';
import '../models/evaluation_model.dart';

// ─────────────────────────────────────────────────────────────
// API hazır olduğunda USE_MOCK_DATA = false yap
// ─────────────────────────────────────────────────────────────
const bool USE_MOCK_DATA = true;
const String BASE_URL = 'https://neuraapp-api.onrender.com/api';
// ─────────────────────────────────────────────────────────────

class EmpaticaService {

  // Hastanın Empatica sensör verilerini getirir
  // Endpoint: GET /biyosensor?hastaId={hastaId}
  static Future<List<BiyoSensorVeri>> getBiyoSensorVerileri(
      int hastaId) async {
    if (USE_MOCK_DATA) return _mockBiyoSensor(hastaId);

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/biyosensor?hastaId=$hastaId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste.map((j) => BiyoSensorVeri.fromJson(j)).toList();
      }
      throw Exception('Sensör verileri yüklenemedi.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Hastanın değerlendirme geçmişini getirir
  // Endpoint: GET /degerlendirmeler?hastaId={hastaId}
  static Future<List<Evaluation>> getDegerlendirmeler(
      int hastaId) async {
    if (USE_MOCK_DATA) return _mockDegerlendirmeler(hastaId);

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/degerlendirmeler?hastaId=$hastaId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste.map((j) => Evaluation.fromJson(j)).toList();
      }
      throw Exception('Değerlendirmeler yüklenemedi.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // ─── MOCK DATA ──────────────────────────────────────────────

  static Future<List<BiyoSensorVeri>> _mockBiyoSensor(
      int hastaId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Her hasta için farklı ama gerçekçi veriler
    final veriler = {
      1: [ // Ayşe Kaya
        BiyoSensorVeri(veriId: 1, hastaId: 1,
            olcumZamani: '2026-03-20T09:00:00',
            kalpAtisHizi: 72.0, eda: 4.2, sicaklik: 36.5,
            ivmeX: 0.1, ivmeY: 0.0, ivmeZ: 9.8,
            kanOksijeni: 98.0, uykuEvresi: 'Uyanık'),
        BiyoSensorVeri(veriId: 2, hastaId: 1,
            olcumZamani: '2026-03-20T10:30:00',
            kalpAtisHizi: 85.0, eda: 6.1, sicaklik: 36.7,
            ivmeX: 0.3, ivmeY: 0.1, ivmeZ: 9.7,
            kanOksijeni: 97.5, uykuEvresi: 'Uyanık'),
        BiyoSensorVeri(veriId: 3, hastaId: 1,
            olcumZamani: '2026-03-20T14:00:00',
            kalpAtisHizi: 68.0, eda: 3.5, sicaklik: 36.4,
            ivmeX: 0.0, ivmeY: 0.0, ivmeZ: 9.8,
            kanOksijeni: 98.5, uykuEvresi: 'Dinleniyor'),
        BiyoSensorVeri(veriId: 4, hastaId: 1,
            olcumZamani: '2026-03-21T08:00:00',
            kalpAtisHizi: 75.0, eda: 4.8, sicaklik: 36.6,
            ivmeX: 0.2, ivmeY: 0.1, ivmeZ: 9.7,
            kanOksijeni: 98.0, uykuEvresi: 'Uyanık'),
      ],
      2: [ // Mehmet Demir
        BiyoSensorVeri(veriId: 5, hastaId: 2,
            olcumZamani: '2026-03-19T11:00:00',
            kalpAtisHizi: 78.0, eda: 5.3, sicaklik: 36.8,
            ivmeX: 0.5, ivmeY: 0.3, ivmeZ: 9.6,
            kanOksijeni: 96.5, uykuEvresi: 'Uyanık'),
        BiyoSensorVeri(veriId: 6, hastaId: 2,
            olcumZamani: '2026-03-19T15:00:00',
            kalpAtisHizi: 92.0, eda: 7.2, sicaklik: 37.0,
            ivmeX: 0.8, ivmeY: 0.4, ivmeZ: 9.5,
            kanOksijeni: 96.0, uykuEvresi: 'Aktif'),
        BiyoSensorVeri(veriId: 7, hastaId: 2,
            olcumZamani: '2026-03-20T09:30:00',
            kalpAtisHizi: 70.0, eda: 4.0, sicaklik: 36.6,
            ivmeX: 0.1, ivmeY: 0.1, ivmeZ: 9.8,
            kanOksijeni: 97.0, uykuEvresi: 'Dinleniyor'),
      ],
      3: [ // Fatma Şahin
        BiyoSensorVeri(veriId: 8, hastaId: 3,
            olcumZamani: '2026-03-18T10:00:00',
            kalpAtisHizi: 65.0, eda: 3.1, sicaklik: 36.3,
            ivmeX: 0.0, ivmeY: 0.0, ivmeZ: 9.8,
            kanOksijeni: 99.0, uykuEvresi: 'Dinleniyor'),
        BiyoSensorVeri(veriId: 9, hastaId: 3,
            olcumZamani: '2026-03-18T14:30:00',
            kalpAtisHizi: 71.0, eda: 3.8, sicaklik: 36.5,
            ivmeX: 0.1, ivmeY: 0.0, ivmeZ: 9.8,
            kanOksijeni: 98.5, uykuEvresi: 'Uyanık'),
      ],
    };

    return veriler[hastaId] ?? [];
  }

  static Future<List<Evaluation>> _mockDegerlendirmeler(
      int hastaId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final degerlendirmeler = {
      1: [
        Evaluation(degerlendirmeId: 1, hastaId: 1,
            degerlendirmeTarihi: '2026-03-10T00:00:00',
            hastalikAdi: 'Multiple Skleroz',
            notlar: 'Hasta stabil görünüyor.',
            klinisyenNotlari: 'İlaç dozajı güncellendi, takip önerildi.',
            kullanilanIlaclar: 'Interferon beta-1a',
            hikaye: 'İlk belirtiler 2018 yılında başladı.'),
        Evaluation(degerlendirmeId: 2, hastaId: 1,
            degerlendirmeTarihi: '2025-12-05T00:00:00',
            hastalikAdi: 'Multiple Skleroz',
            notlar: 'Hafif alevlenme gözlemlendi.',
            klinisyenNotlari: 'Kortikosteroid tedavisi başlandı.',
            kullanilanIlaclar: 'Interferon beta-1a, Metilprednizolon',
            hikaye: null),
      ],
      2: [
        Evaluation(degerlendirmeId: 3, hastaId: 2,
            degerlendirmeTarihi: '2026-02-20T00:00:00',
            hastalikAdi: 'Parkinson',
            notlar: 'Tremor sıklığı azaldı.',
            klinisyenNotlari: 'Fizyoterapi seansları düzenli devam ediyor.',
            kullanilanIlaclar: 'Levodopa/Karbidopa',
            hikaye: 'İlk tremor belirtisi 2020 yılında sağ elde.'),
        Evaluation(degerlendirmeId: 4, hastaId: 2,
            degerlendirmeTarihi: '2025-10-15T00:00:00',
            hastalikAdi: 'Parkinson',
            notlar: 'Yürüyüş analizi yapıldı.',
            klinisyenNotlari: 'İlaç saatleri yeniden düzenlendi.',
            kullanilanIlaclar: 'Levodopa/Karbidopa',
            hikaye: null),
      ],
      3: [
        Evaluation(degerlendirmeId: 5, hastaId: 3,
            degerlendirmeTarihi: '2026-03-01T00:00:00',
            hastalikAdi: 'ALS',
            notlar: 'Kas gücü kaybı takip ediliyor.',
            klinisyenNotlari: 'Rehabilitasyon programı oluşturuldu.',
            kullanilanIlaclar: 'Riluzol',
            hikaye: 'Ağızda konuşma bozukluğuyla başladı.'),
      ],
    };

    return degerlendirmeler[hastaId] ?? [];
  }
}