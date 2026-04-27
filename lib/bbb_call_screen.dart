import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class BbbCallScreen extends StatefulWidget {
  final int toplantiId;
  final String userFullName;
  final bool isModerator;

  const BbbCallScreen({
    super.key,
    required this.toplantiId,
    required this.userFullName,
    this.isModerator = false,
  });

  @override
  State<BbbCallScreen> createState() => _BbbCallScreenState();
}

class _BbbCallScreenState extends State<BbbCallScreen> {
  bool isLoading = false;
  bool isPageLoading = true;
  String? errorText;

  String meetingName = '';
  String meetingId = '';

  @override
  void initState() {
    super.initState();
    loadMeetingFromSupabase();
  }

  Future<void> loadMeetingFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .schema('neura')
          .from('toplantilar')
          .select()
          .eq('toplantiId', widget.toplantiId)
          .single();

      setState(() {
        meetingName = data['baslik'] ?? 'Toplantı';
        meetingId = 'toplanti-${data['toplantiId']}';
        isPageLoading = false;
      });
    } catch (e) {
      setState(() {
        errorText = 'Toplantı bilgisi alınamadı.';
        isPageLoading = false;
      });
    }
  }

  Future<void> startVideoCall() async {
    try {
      setState(() {
        isLoading = true;
        errorText = null;
      });

      final uri = Uri.parse(
          'http://localhost:3000/api/bbb/create-join'      );

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meetingId': meetingId,
          'meetingName': meetingName,
          'fullName': widget.userFullName,
          'isModerator': widget.isModerator,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final joinUrl = data['joinUrl'] as String?;

      if (joinUrl == null || joinUrl.isEmpty) {
        throw Exception('Join link alınamadı.');
      }

      final launchUri = Uri.parse(joinUrl);

      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Bağlantı açılamadı.');
      }
    } catch (e) {
      setState(() {
        errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);
    const background = Color(0xFFF5F7FB);
    const cardColor = Colors.white;
    const borderColor = Color(0xFFE5E7EB);
    const lightBlue = Color(0xFFEAF2FF);
    const textDark = Color(0xFF1F2937);
    const textMuted = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Görüntülü Görüşme',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      body: SafeArea(
        child: isPageLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.video_call_outlined,
                      color: primaryBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BigBlueButton Görüşmesi',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu sayfa görüntülü görüşmeyi başlatmak için kullanılır.',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _infoRow('Toplantı Adı', meetingName),
                  const SizedBox(height: 12),
                  _infoRow('Kullanıcı', widget.userFullName),
                  const SizedBox(height: 12),
                  _infoRow('Meeting ID', meetingId),
                  const SizedBox(height: 12),
                  _infoRow(
                    'Rol',
                    widget.isModerator
                        ? 'Moderatör'
                        : 'Katılımcı',
                  ),
                  const Spacer(),
                  if (errorText != null) ...[
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : startVideoCall,
                      icon: isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.videocam_outlined),
                      label: Text(
                        isLoading
                            ? 'Bağlanılıyor...'
                            : 'Görüntülü Aramayı Başlat',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}