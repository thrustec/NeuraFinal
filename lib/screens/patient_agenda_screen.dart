// Sıla Özer
// lib/views/patient_agenda_screen.dart
// API bağlantısı: AgendaService → Supabase REST (toplantilar + toplantiIstekleri)
// UI değişmedi, sadece mock_data → API ile değiştirildi

import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/agenda_item.dart';
import '../models/patient.dart';
import '../services/agenda_service.dart';

class PatientAgendaScreen extends StatefulWidget {
  final Patient patient;

  const PatientAgendaScreen({super.key, required this.patient});

  @override
  State<PatientAgendaScreen> createState() => _PatientAgendaScreenState();
}

class _PatientAgendaScreenState extends State<PatientAgendaScreen> {
  final AgendaService _agendaService = AgendaService();

  int _selectedDayIndex = 0;

  // Mevcut haftanın Pazartesi günü (API sorgusu için başlangıç noktası)
  late DateTime _haftaBaslangic;

  // API'dan gelen tüm haftalık toplantılar
  List<AgendaItem> _weeklyItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Bu haftanın Pazartesi'sini hesapla
    final now = DateTime.now();
    _haftaBaslangic = now.subtract(Duration(days: now.weekday - 1));
    _haftaBaslangic = DateTime(
        _haftaBaslangic.year, _haftaBaslangic.month, _haftaBaslangic.day);

    // Başlangıçta bugünün indexini seç (0=Pazartesi)
    _selectedDayIndex = now.weekday - 1;

    _loadWeeklyAgenda();
  }

  // AgendaService → GET /toplantilar?hastaId=eq.:id&baslangicZamani=gte.:...
  Future<void> _loadWeeklyAgenda() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _agendaService.getWeeklyAgenda(
        hastaId: widget.patient.hastaId,
        haftaBaslangic: _haftaBaslangic,
      );
      if (!mounted) return;
      setState(() {
        _weeklyItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Program yüklenemedi. Lütfen tekrar deneyin.';
      });
    }
  }

  // Seçili güne göre filtrele — API'dan tüm hafta geliyor, gün burada filtreleniyor
  List<AgendaItem> _getFilteredItems() {
    return _weeklyItems
        .where((item) => item.dayIndex == _selectedDayIndex)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildHorizontalCalendar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Yükleniyor
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Hata
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(_error!, style: AppTheme.bodyText),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadWeeklyAgenda,
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Tekrar Dene"),
            ),
          ],
        ),
      );
    }
    // Veri
    final currentItems = _getFilteredItems();
    return currentItems.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: currentItems.length,
      itemBuilder: (context, index) =>
          _buildFullAgendaCard(currentItems[index]),
    );
  }

  // --- ÜST BAŞLIK ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 16, left: 20),
      decoration: AppTheme.headerDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Günlük Programım", style: AppTheme.pageTitle),
          const SizedBox(height: 4),
          Text(
            widget.patient.tamAd,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- YATAY TAKVİM ---
  // _haftaBaslangic'tan itibaren 7 gün gösterir
  Widget _buildHorizontalCalendar() {
    const List<String> gunler = [
      "Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"
    ];
    return Container(
      height: 90,
      decoration: const BoxDecoration(color: AppTheme.surface),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gunler.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedDayIndex == index;
          // Gerçek tarih numarası (_haftaBaslangic + index gün)
          final gunTarihi = _haftaBaslangic.add(Duration(days: index));
          // O günde bu hastanın toplantısı var mı?
          final bool hasItems =
          _weeklyItems.any((item) => item.dayIndex == index);

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gunler[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${gunTarihi.day}",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  // O günde toplantı varsa mavi nokta
                  if (hasItems && !isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- RANDEVU KARTI ---
  Widget _buildFullAgendaCard(AgendaItem item) {
    return Opacity(
      opacity: item.tamamlandiMi ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // baslangicZamani → "HH:mm"
                    Text(
                      item.saat,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildBadge(
                        item.kategori, AppTheme.primaryLight, AppTheme.primary),
                  ],
                ),
                // durum veya "TAMAMLANDI"
                _buildBadge(
                  item.tamamlandiMi ? "TAMAMLANDI" : item.durum,
                  item.tamamlandiMi
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.surface,
                  item.tamamlandiMi
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                ),
              ],
            ),
            const Divider(height: 24, color: AppTheme.divider),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.baslik, style: AppTheme.cardTitle),
                      const SizedBox(height: 4),
                      // hastalikAdi → patient.tani
                      Text(
                        "Tanı: ${widget.patient.tani}",
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // TİK BUTONU: Randevu dışında görünür
                    if (item.kategori != "Randevu")
                      _buildIconButton(
                        item.tamamlandiMi ? Icons.undo : Icons.check,
                        AppTheme.success,
                            () => setState(
                                () => item.tamamlandiMi = !item.tamamlandiMi),
                      ),

                    if (item.kategori == "Randevu")
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.lock_clock_outlined,
                            color: AppTheme.textHint, size: 20),
                      ),

                    const SizedBox(width: 8),

                    // İPTAL BUTONU
                    _buildIconButton(Icons.close, AppTheme.danger, () {
                      _showCancelDialog(item);
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.aciklama, style: AppTheme.bodyText),
          ],
        ),
      ),
    );
  }

  // --- İPTAL ONAY DİYALOGU ---
  // AgendaService.cancelAppointment → PATCH /toplantiIstekleri
  void _showCancelDialog(AgendaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            item.kategori == "Randevu" ? "Randevu İptali" : "İşlemi İptal Et"),
        content: Text(
          "${item.baslik} kaydını iptal etmek istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // API'da durumu 'İptal' olarak güncelle
                await _agendaService.cancelAppointment(
                  toplantiId: item.toplantiId,
                  hastaId: item.hastaId,
                );
                // UI'dan kaldır
                setState(() => _weeklyItems.remove(item));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("İptal talebi iletildi.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("İptal işlemi başarısız oldu.")),
                  );
                }
              }
            },
            child:
            const Text("Evet", style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 60, color: AppTheme.textHint),
          SizedBox(height: 16),
          Text("Bugün için planlanan program yok.", style: AppTheme.bodyText),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}