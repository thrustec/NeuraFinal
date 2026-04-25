import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/evaluation_provider.dart';
import '../patient_list_screen.dart';
import 'evaluation_form_screen.dart';

class EvaluationListScreen extends StatefulWidget {
  const EvaluationListScreen({super.key});

  @override
  State<EvaluationListScreen> createState() => _EvaluationListScreenState();
}

class _EvaluationListScreenState extends State<EvaluationListScreen> {
  static const _bg = Color(0xFFF5F7FB);
  static const _surface = Colors.white;
  static const _primary = Color(0xFF2563F6);
  static const _border = Color(0xFFDDE3EE);
  static const _textDark = Color(0xFF253043);
  static const _textMid = Color(0xFF6E778B);
  static const _textLight = Color(0xFF98A1B3);
  static const _success = Color(0xFF0A8C3B);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Widget _bottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Ana Sayfa'},
      {'icon': Icons.people_alt_outlined, 'label': 'Hastalar'},
      {'icon': Icons.person_add_outlined, 'label': 'Kayıt'},
      {'icon': Icons.assignment_outlined, 'label': 'Değerlendir'},
      {'icon': Icons.bar_chart_outlined, 'label': 'Raporlar'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final aktif = i == 3;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  if (i == 3) return;

                  if (i == 1) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientListScreen(),
                      ),
                    );
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu menü henüz bağlanmadı.'),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: aktif ? _primary : _textLight,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: aktif ? FontWeight.w700 : FontWeight.normal,
                          color: aktif ? _primary : _textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvaluationProvider>().loadEvaluations();
    });
  }
  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _textLight, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Hasta adına göre ara',
                hintStyle: TextStyle(
                  color: _textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_searchQuery.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.close_rounded, color: _textLight, size: 20),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Future<void> _openForm({bool isEdit = false}) async {
    final provider = context.read<EvaluationProvider>();
    if (!isEdit) provider.clearSelection();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: EvaluationFormScreen(isEdit: isEdit),
        ),
      ),
    );

    await provider.loadEvaluations();
  }

  Future<void> _deleteEvaluation(int id) async {
    final provider = context.read<EvaluationProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Değerlendirmeyi sil'),
        content: const Text(
          'Bu değerlendirmeyi silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ??
        false;

    if (!ok) return;

    await provider.delete(id);
    await provider.loadEvaluations();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Değerlendirme silindi')),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return 'AK';
    return parts.map((e) => e[0]).join().toUpperCase();
  }

  String _safeText(dynamic value, {String fallback = '—'}) {
    final text = value?.toString() ?? '';
    final trimmed = text.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _safeHastaAdi(dynamic value) {
    return _safeText(value, fallback: 'Bilinmeyen hasta');
  }

  String _resolveDiagnosis(dynamic ev) {
    String firstMeaningfulLine(String value) {
      for (final raw in value.split('\n')) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final lower = line.toLowerCase();
        if (lower == 'klinisyen notları' ||
            lower == 'semptomlar:' ||
            lower == 'hastalık:' ||
            lower == 'fonksiyonel:' ||
            lower == 'klinik tip:' ||
            lower == 'klinik tip') {
          continue;
        }
        return line;
      }
      return '';
    }

    final diagnosisText = (ev.diagnosis ?? '').toString().trim();
    if (diagnosisText.isNotEmpty) return diagnosisText;

    final hastalikAdi = (ev.hastalikAdi ?? '').toString().trim();
    if (hastalikAdi.isNotEmpty) return hastalikAdi;

    final candidates = [
      (ev.klinisyenNotlari ?? '').toString(),
      (ev.notlar ?? '').toString(),
      (ev.hikaye ?? '').toString(),
    ];

    for (final block in candidates) {
      final line = firstMeaningfulLine(block);
      if (line.isNotEmpty) return line;
    }

    return 'Tanı veya not bilgisi yok.';
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded, color: _textDark, size: 28),
      ),
      title: const Text(
        'Klinik Değerlendirmeler',
        style: TextStyle(
          color: _textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _textDark,
                size: 27,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4A4A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16, left: 6),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _primary,
            child: Text(
              'AK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: _border),
      ),
    );
  }

  Widget _topHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment_outlined, color: _primary),
          SizedBox(width: 10),
          Text(
            'Hasta Değerlendirmelerim',
            style: TextStyle(
              color: _textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.note_alt_outlined,
                color: _primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Henüz değerlendirme yok',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hasta kayıtlarını takip etmek için yeni bir değerlendirme oluşturun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Yeni Değerlendirme',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractPackedSection(String source, String title) {
    final text = source.trim();
    if (text.isEmpty) return '';

    final header = '$title:\n';
    final start = text.indexOf(header);
    if (start == -1) return '';

    final contentStart = start + header.length;
    final nextHeaders = [
      '\n\nSemptomlar:\n',
      '\n\nHastalık:\n',
      '\n\nKlinisyen Notları:\n',
      '\n\nFonksiyonel:\n',
      '\n\nKlinik tip:',
    ];

    int? end;
    for (final marker in nextHeaders) {
      final idx = text.indexOf(marker, contentStart);
      if (idx != -1 && (end == null || idx < end)) {
        end = idx;
      }
    }

    final result = end == null
        ? text.substring(contentStart)
        : text.substring(contentStart, end);
    return result.trim();
  }

  String _extractInlineValue(String source, String label) {
    if (source.trim().isEmpty) return '';
    final pattern = RegExp(
      '${RegExp.escape(label)}\\s*:\\s*(.+)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(source);
    if (match == null) return '';
    return (match.group(1) ?? '').trim();
  }

  int _savedSymptomCount(dynamic ev) {
    final notlar = (ev.notlar ?? '').toString().trim();
    if (notlar.isEmpty) return 0;

    final semptomlar = _extractPackedSection(notlar, 'Semptomlar');
    if (semptomlar.isEmpty) return 0;

    const labels = [
      'Motor',
      'Duyusal',
      'Emosyonel',
      'Kognitif',
      'Pulmoner',
      'Diğer',
    ];

    final uniqueSymptoms = <String>{};

    for (final rawLine in semptomlar.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matchedLabel = labels.cast<String?>().firstWhere(
            (label) => line.toLowerCase().startsWith('${label!.toLowerCase()}:'),
        orElse: () => null,
      );

      if (matchedLabel == null) continue;

      final value = line.substring(matchedLabel.length + 1).trim();
      if (value.isEmpty) continue;

      final lower = value.toLowerCase();
      final extraIndex = lower.indexOf('yeni bulgu:');
      final selectedPart = extraIndex == -1
          ? value
          : value.substring(0, extraIndex).trim();

      if (selectedPart.isEmpty) continue;

      final normalizedWhole = selectedPart.toLowerCase();
      if (normalizedWhole == 'yok' ||
          normalizedWhole == 'none' ||
          normalizedWhole == '-' ||
          normalizedWhole == 'seçilmedi' ||
          normalizedWhole == 'secilmedi' ||
          normalizedWhole == 'boş' ||
          normalizedWhole == 'bos') {
        continue;
      }

      for (final item in selectedPart.split(',')) {
        final symptom = item.trim();
        if (symptom.isEmpty) continue;
        final low = symptom.toLowerCase();
        if (low == 'yok' ||
            low == 'none' ||
            low == '-' ||
            low == 'seçilmedi' ||
            low == 'secilmedi' ||
            low == 'boş' ||
            low == 'bos') {
          continue;
        }
        uniqueSymptoms.add(symptom);
      }
    }

    return uniqueSymptoms.length;
  }

  Widget _card(EvaluationProvider provider, dynamic ev) {
    final previewText = _resolveDiagnosis(ev);
    final hastaAdi = _safeHastaAdi(ev.hastaAdSoyad);
    final olusturmaTarihi = ev.olusturmaTarihi as DateTime?;
    final symptomCount = _savedSymptomCount(ev);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _initials(hastaAdi),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hastaAdi,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(olusturmaTarihi),
                      style: const TextStyle(
                        color: _textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    provider.select(ev);
                    await _openForm(isEdit: true);
                  }
                  if (value == 'delete' && ev.id != null) {
                    await _deleteEvaluation(ev.id!);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Düzenle'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Sil'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              previewText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  symptomCount == 0
                      ? 'Semptom seçilmedi'
                      : '$symptomCount semptom',
                  style: const TextStyle(
                    color: _success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  provider.select(ev);
                  await _openForm(isEdit: true);
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: const Text('Aç'),
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => const _EvaluationSkeletonCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body: Consumer<EvaluationProvider>(
        builder: (context, provider, _) {
          final filteredEvaluations = provider.evaluations.where((ev) {
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) return true;

            final hastaAdi = _safeHastaAdi(ev.hastaAdSoyad).toLowerCase();
            return hastaAdi.contains(query);
          }).toList();

          if (provider.isListLoading && provider.evaluations.isEmpty) {
            return _loadingList();
          }

          if (provider.evaluations.isEmpty) {
            return Column(
              children: [
                _topHeader(),
                _searchBar(),
                Expanded(child: _emptyState()),
              ],
            );
          }

          return Column(
            children: [
              _topHeader(),
              _searchBar(),
              Expanded(
                child: filteredEvaluations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.search_off_rounded,
                                color: _textLight,
                                size: 42,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Aramaya uygun değerlendirme bulunamadı.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textMid,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _primary,
                        onRefresh: provider.refresh,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                          itemCount: filteredEvaluations.length,
                          itemBuilder: (_, i) {
                            final ev = filteredEvaluations[i];
                            return _card(provider, ev);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Değerlendirme',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _EvaluationSkeletonCard extends StatelessWidget {
  const _EvaluationSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
    );
  }
}