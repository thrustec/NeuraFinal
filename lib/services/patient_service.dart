import 'dart:convert'; // API adresi değişirse tüm dosyaları değişmek yerine sadece service dosyasını güncelleriz o yüzden ayrı dosya oluşturdum
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

// ─────────────────────────────────────────────────────────────
// API hazır olduğunda USE_MOCK_DATA = false yap
// ─────────────────────────────────────────────────────────────
const bool USE_MOCK_DATA = false;
const String BASE_URL = 'https://neuraapp-api.onrender.com/api';
// ─────────────────────────────────────────────────────────────

class PatientService {
  // Uygulama kapanana kadar güncellemeleri bellekte tutar
  // API bağlandığında bu listeye gerek kalmaz
  static List<Patient>? _bellekListesi;

  static Future<List<Patient>> getHastalar({String? aramaMetni}) async {
    if (USE_MOCK_DATA) return _mockHastalar(aramaMetni: aramaMetni);

    try {
      final url = (aramaMetni != null && aramaMetni.isNotEmpty)
          ? '$BASE_URL/hastalar?ara=$aramaMetni'
          : '$BASE_URL/hastalar';
      final response = await http.get(Uri.parse(url),
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final List<dynamic> liste = json.decode(response.body);
        return liste.map((j) => Patient.fromJson(j)).toList();
      }
      throw Exception('Hastalar yüklenemedi. Kod: ${response.statusCode}');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // try catch kullandık çünkü sunucu çökmesi, int gitmesi gibi durumlarda hata fırlatmalar çok olası
  // uygulamanın error yiyip kapanmasını önlemek için try catch kullandık
  // sunucudan bulunamadı veya sunucu hatası dönerse bunu manuel olarak fırlatıp
  // arayüzdeki hata ekranının tetiklenmesi sağlanıyor
  static Future<Patient> getHastaById(int hastaId) async {
    if (USE_MOCK_DATA) {
      final liste = await _mockHastalar();
      return liste.firstWhere((h) => h.hastaId == hastaId);
    }
    try {
      final response = await http.get(
          Uri.parse('$BASE_URL/hastalar/$hastaId'),
          headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return Patient.fromJson(json.decode(response.body));
      }
      throw Exception('Hasta bulunamadı.');
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Güncellenen alanlar (klinisyen değiştirebilir):
  //   hastalikAdi      → degerlendirmeler tablosu (hastalikId üzerinden)
  //   boy, kilo        → hastalar tablosu
  //   klinisyenNotlari → degerlendirmeler tablosu
  static Future<bool> hastaGuncelle(
      int hastaId, Map<String, dynamic> data) async {
    if (USE_MOCK_DATA) {
      await Future.delayed(const Duration(milliseconds: 600));

      // Değişikliği bellekteki listede güncelle
      if (_bellekListesi != null) {
        final index =
        _bellekListesi!.indexWhere((h) => h.hastaId == hastaId);
        if (index != -1) {
          final mevcut = _bellekListesi![index];
          _bellekListesi![index] = mevcut.copyWith(
            boy:             data['boy'],
            kilo:            data['kilo'],
            klinisyenNotlari: data['klinisyenNotlari'],
          );
        }
      }
      return true;
    }

    try {
      final response = await http.patch( //post ya da put kullanmadık çünkü sadece değişen verileri göndermek ve kaydın kısmi güncellenmesi iin en doğru HTTP metodu PATCHdir
          Uri.parse('$BASE_URL/hastalar/$hastaId'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Güncelleme başarısız: $e');
    }
  }

  // ─── MOCK DATA ──────────────────────────────────────────────
  static Future<List<Patient>> _mockHastalar(
      {String? aramaMetni}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // İlk açılışta listeyi oluştur, sonraki çağrılarda bellekten al
    _bellekListesi ??= [
      Patient(
        hastaId: 1,
        kullaniciId: 101,
        ad: 'Merve',
        soyad: 'Gündoğdu',
        eposta: 'merve.gundogdu@neuraapp.com',
        cinsiyetAdi: 'Kadın',
        medeniDurumAdi: 'Bekar',
        egitimDurumAdi: 'Lisans',
        meslekAdi: 'Öğrenci',
        dogumTarihi: '2003-10-13',
        telefonNo: '0506 555 2355',
        adres: 'İstanbul',
        boy: 172.0,
        kilo: 55.0,
        hastalikAdi: 'Multiple Skleroz',
        notlar: 'Düzenli takip gerekiyor.',
        klinisyenNotlari:
        'Son değerlendirmede iyileşme gözlemlendi. '
            'İlaç dozajı güncellendi.',
      ),
      Patient(
        hastaId: 2,
        kullaniciId: 102,
        ad: 'Eda',
        soyad: 'Akın',
        eposta: 'eda.akın@neuraapp.com',
        cinsiyetAdi: 'Kadın',
        medeniDurumAdi: 'Evli',
        egitimDurumAdi: 'Lise',
        meslekAdi: 'Mühendis',
        dogumTarihi: '1975-11-22',
        telefonNo: '0545 333 4455',
        adres: 'Ankara',
        boy: 168.0,
        kilo: 62.0,
        hastalikAdi: 'Parkinson',
        notlar: 'İlaç dozajı kontrol edilmeli.',
        klinisyenNotlari:
        'Tremor sıklığı azaldı. Fizyoterapi '
            'seansları düzenli devam ediyor.',
      ),
      Patient(
        hastaId: 3,
        kullaniciId: 103,
        ad: 'Mehmet',
        soyad: 'Kantar',
        eposta: 'mehmet@neuraapp.com',
        cinsiyetAdi: 'Erkek',
        medeniDurumAdi: 'Bekar',
        egitimDurumAdi: 'Yüksek Lisans',
        meslekAdi: 'Doktor',
        dogumTarihi: '1990-03-08',
        telefonNo: '0555 666 7788',
        adres: 'İzmir',
        boy: 180.0,
        kilo: 80.0,
        hastalikAdi: 'ALS',
        notlar: 'Fizyoterapi programına başlandı.',
        klinisyenNotlari:
        'Kas gücü kaybı takip ediliyor. '
            'Rehabilitasyon programı oluşturuldu.',
      ),
    ];

    var liste = List<Patient>.from(_bellekListesi!);

    if (aramaMetni != null && aramaMetni.isNotEmpty) {
      final q = aramaMetni.toLowerCase();
      liste = liste
          .where((h) =>
      h.tamAd.toLowerCase().contains(q) ||
          h.hastaId.toString().contains(q))
          .toList();
    }

    return liste;
  }
}