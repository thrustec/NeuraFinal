// lib/app_theme.dart
// Uygulamanın tüm renk, yazı tipi ve stil tanımlarını içerir.

import 'package:flutter/material.dart';

class AppTheme {

  // -------------------------------------------------------
  // RENK PALETİ
  // Tüm renk sabitleri burada tanımlanır.
  // -------------------------------------------------------

  static const Color primary = Color(0xFF2563EB);       // Mavi (buton, aktif tab, ikon)
  static const Color primaryLight = Color(0xFFEFF6FF);  // Açık mavi arka plan
  static const Color primaryBorder = Color(0xFFBFDBFE); // Mavi border

  static const Color accent = Color(0xFFEF4444);        // Kırmızı vurgu (MS gibi hastalık başlıkları)
  static const Color accentOrange = Color(0xFFF97316);  // Turuncu vurgu (Parkinson vb.)

  static const Color success = Color(0xFF16A34A);       // Yeşil (iyileşme)
  static const Color danger = Color(0xFFDC2626);        // Kırmızı (kötüleşme)

  static const Color background = Color(0xFFFFFFFF);    // Sayfa arka planı
  static const Color surface = Color(0xFFF8FAFC);       // Kart arka planı
  static const Color divider = Color(0xFFE2E8F0);       // Ayırıcı çizgi rengi

  static const Color textPrimary = Color(0xFF0F172A);   // Ana yazı rengi
  static const Color textSecondary = Color(0xFF64748B); // İkincil yazı rengi
  static const Color textHint = Color(0xFF94A3B8);      // Placeholder rengi

  // -------------------------------------------------------
  // HEADER (ÜST BÖLÜM) DEKORASYONU
  // Sayfa başlık alanının arka plan ve alt kenarlık stili
  // -------------------------------------------------------
  static BoxDecoration get headerDecoration => const BoxDecoration(
    color: background,
    border: Border(bottom: BorderSide(color: divider, width: 1)),
  );

  // --- BUTON STİLLERİ ---
  // Mavi buton — ana aksiyon butonu (örn: "Analizi Görüntüle")
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
  // Outlined buton — ikincil aksiyon (örn: "PDF Raporu")
  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primary,
    side: const BorderSide(color: primary, width: 1.5),
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );

  // -------------------------------------------------------
  // KART DEKORASYONU
  // Hasta kartı, ölçüm kartı gibi beyaz kutucukların stili
  // -------------------------------------------------------
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: divider, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha:0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );


  // -------------------------------------------------------
  // INPUT (METİN ALANI) DEKORASYONU
  // Arama kutusu ve dropdown gibi form alanlarının stili
  // -------------------------------------------------------
  static InputDecoration inputDecoration(String label, {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: textHint, fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Varsayılan kenarlık
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      // Odaklanılmamış kenarlık
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: divider),
      ),
      // Odaklanılmış (tıklandığında) kenarlık — mavi vurgu
        focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  // -------------------------------------------------------
  // YAZI TİPİ STİLLERİ
  // -------------------------------------------------------

  // Bölüm etiketi
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  // Sayfa başlığı
  static const TextStyle pageTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  // Kart başlığı
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // Açıklama ve ikincil bilgiler
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );
}