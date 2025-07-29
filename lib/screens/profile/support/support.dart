import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_appbar.dart';
import '../../../widgets/chat_widget.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  List<dynamic> messages = [];
  String? token;
  String? chatId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');

    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://api.junctionverse.com/support-chat/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        messages = data['messages'] ?? [];
        chatId = data['_id'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendMessage(String message) async {
    if (token == null) return;

    final uri = Uri.parse('https://api.junctionverse.com/support-chat');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token!';
    request.fields['chatId'] = chatId ?? '';
    request.fields['content'] = message;
    request.fields['type'] = 'text';

    final response = await request.send();

    if (response.statusCode == 200) {
      _loadChat(); // Refresh chat
    }
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/SupportTeam.png', width: 180),
            const SizedBox(height: 24),
            const Text(
              'Need Assistance?\nWe’re Here to Help',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.3,
                fontWeight: FontWeight.bold,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our team’s here for you, shoot your queries!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8894),
                height: 1.3,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map message) {
    final isSupport = message['senderType'] == 'admin';
    final text = message['content'] ?? '';
    final time = message['createdAt']?.toString().substring(11, 16) ?? '--:--';

    if (!isSupport) {
      // User message (Right side)
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text, style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    // Support message (Left side)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 6),
          child: Icon(Icons.support_agent, size: 18, color: Colors.orange),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Junction Support',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A8894)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Contact Support"),
      body: Column(
        children: [
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (messages.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
              ),
            ),
          ChatInputWidget(
            onSend: _sendMessage,
            onFilesPicked: (files) {
              // You can implement file/image support here later
              print('Files picked: ${files.map((f) => f.path)}');
            },
          )
        ],
      ),
    );
  }
}
