import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  List<dynamic> meetings = [];
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMeetings();
  }

  Future<void> fetchMeetings() async {
    try {
      final response = await SupabaseService.client
          .schema('neura')
          .from('toplantilar')
          .select();

      setState(() {
        meetings = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
          child: Text(
            'Hata: $errorMessage',
            style: const TextStyle(fontSize: 16),
          ),
        )
            : meetings.isEmpty
            ? const Center(
          child: Text(
            'Bağlantı başarılı. Ama toplantilar tablosu boş.',
            style: TextStyle(fontSize: 16),
          ),
        )
            : ListView.builder(
          itemCount: meetings.length,
          itemBuilder: (context, index) {
            final item = meetings[index];
            return Card(
              child: ListTile(
                title: Text(item['baslik']?.toString() ?? 'Başlıksız'),
                subtitle: Text(
                  'Hasta ID: ${item['hastaId']} | Klinisyen ID: ${item['klinisyenId']}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}