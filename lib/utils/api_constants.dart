// lib/utils/api_constants.dart
// Supabase bağlantı sabitleri

class ApiConstants {
  // Supabase proje URL'i ve Anon Key
  static const String supabaseUrl = 'https://griteunvazwekosffmjo.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyaXRldW52YXp3ZWtvc2ZmbWpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1OTA3OTksImV4cCI6MjA5MTE2Njc5OX0.q67C45Tve77Sj9hP0NRpXXIaSS1esajX3IE-TBZ-wIU';

  // Supabase REST API base URL (neura schema için)
  static const String baseUrl = '$supabaseUrl/rest/v1';

  // Tablo endpoint'leri (neura schema — Supabase'de search_path ile ayarlı)
  static const String hastalar = '/hastalar';
  static const String degerlendirmeler = '/degerlendirmeler';
  static const String degerlendirmeTestSonuclari = '/degerlendirmeTestSonuclari';
  static const String testler = '/testler';
  static const String testMetrikleri = '/testMetrikleri';
  static const String toplantilar = '/toplantilar';
  static const String toplantiIstekleri = '/toplantiIstekleri';
  static const String kullanicilar = '/kullanicilar';
  static const String hastaliklar = '/hastaliklar';
  static const String schema = 'neura';
}