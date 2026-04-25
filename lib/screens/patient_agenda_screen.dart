import 'package:flutter/material.dart';
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
  late DateTime _haftaBaslangic;
  List<AgendaItem> _weeklyItems = [];
  bool _isLoading = true;
  String? _error;

  // --- NeuraApp Hasta Teması ---
  static const Color kPrimary = Color(0xFF2563EB); // Hasta Mavisi
  static const Color kBackground = Color(0xFFF8F9FC);
  static const Color kSurface = Colors.white;
  static const Color kTextDark = Color(0xFF1E293B);
  static const Color kTextGrey = Color(0xFF64748B);
  static const Color kTextHint = Color(0xFF94A3B8);
  static const Color kDanger = Color(0xFFEF4444);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kDivider = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _haftaBaslangic = now.subtract(Duration(days: now.weekday - 1));
    _haftaBaslangic = DateTime(
        _haftaBaslangic.year, _haftaBaslangic.month, _haftaBaslangic.day);

    _selectedDayIndex = now.weekday - 1;
    _loadWeeklyAgenda();
  }

  // --- MANTIK (LOGIC) KISMI: DEĞİŞMEDİ ---
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

  List<AgendaItem> _getFilteredItems() {
    return _weeklyItems
        .where((item) => item.dayIndex == _selectedDayIndex)
        .toList();
  }

  void _showCancelDialog(AgendaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item.kategori == "Randevu" ? "Randevu İptali" : "İşlemi İptal Et",
          style: const TextStyle(fontWeight: FontWeight.bold, color: kTextDark),
        ),
        content: Text(
          "${item.baslik} kaydını iptal etmek istediğinize emin misiniz?",
          style: const TextStyle(color: kTextGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: kTextGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _agendaService.cancelAppointment(
                  toplantiId: item.toplantiId,
                  hastaId: item.hastaId,
                );
                setState(() => _weeklyItems.remove(item));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("İptal talebi iletildi."), backgroundColor: kTextDark),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("İptal işlemi başarısız oldu."), backgroundColor: kDanger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- UI KISMI: NEURAAPP TEMASI EKLENDİ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ajanda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
      ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 56, color: kTextHint),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: kTextGrey, fontSize: 15)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadWeeklyAgenda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                label: const Text("Tekrar Dene", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final currentItems = _getFilteredItems();
    return currentItems.isEmpty
        ? _buildEmptyState()
        : RefreshIndicator(
      onRefresh: _loadWeeklyAgenda,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: currentItems.length,
        itemBuilder: (context, index) => _buildFullAgendaCard(currentItems[index]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: kPrimary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Günlük Programım", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            widget.patient.tamAd,
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    const List<String> gunler = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8),
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: gunler.length,
        itemBuilder: (context, index) {
          final bool isSelected = _selectedDayIndex == index;
          final gunTarihi = _haftaBaslangic.add(Duration(days: index));
          final bool hasItems = _weeklyItems.any((item) => item.dayIndex == index);

          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? kPrimary : kDivider),
                boxShadow: isSelected
                    ? [BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    gunler[index],
                    style: TextStyle(color: isSelected ? Colors.white70 : kTextGrey, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${gunTarihi.day}",
                    style: TextStyle(color: isSelected ? Colors.white : kTextDark, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  if (hasItems && !isSelected)
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
                    ),
                  if (hasItems && isSelected)
                    Container(
                      width: 6, height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullAgendaCard(AgendaItem item) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: item.tamamlandiMi ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDivider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: kPrimary),
                    const SizedBox(width: 6),
                    Text(item.saat, style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 12),
                    _buildBadge(item.kategori, kPrimary.withOpacity(0.1), kPrimary),
                  ],
                ),
                _buildBadge(
                  item.tamamlandiMi ? "TAMAMLANDI" : item.durum,
                  item.tamamlandiMi ? kSuccess.withOpacity(0.1) : const Color(0xFFF1F5F9),
                  item.tamamlandiMi ? kSuccess : kTextGrey,
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: kDivider),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
                      const SizedBox(height: 4),
                      Text("Tanı: ${widget.patient.tani}", style: const TextStyle(color: kTextGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (item.kategori != "Randevu")
                      _buildIconButton(
                        item.tamamlandiMi ? Icons.undo : Icons.check,
                        item.tamamlandiMi ? kTextGrey : kSuccess,
                            () => setState(() => item.tamamlandiMi = !item.tamamlandiMi),
                      ),
                    if (item.kategori == "Randevu")
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.lock_clock_outlined, color: kTextHint, size: 22),
                      ),
                    const SizedBox(width: 8),
                    _buildIconButton(Icons.close, kDanger, () => _showCancelDialog(item)),
                  ],
                ),
              ],
            ),
            if (item.aciklama.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Text(item.aciklama, style: const TextStyle(color: kTextGrey, fontSize: 13, height: 1.4)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: kPrimary.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_outlined, size: 56, color: kPrimary),
          ),
          const SizedBox(height: 20),
          const Text("Harika!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 8),
          const Text("Bugün için planlanan bir programınız yok.", style: TextStyle(color: kTextGrey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(text.toUpperCase(), style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}