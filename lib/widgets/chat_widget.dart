import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String message)? onSend;
  final Function(List<XFile> files)? onFilesPicked;

  const ChatInputWidget({
    super.key,
    this.onSend,
    this.onFilesPicked,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFiles() async {
    final List<XFile> files = await _picker.pickMultiImage(); // Only images
    if (files.isNotEmpty && widget.onFilesPicked != null) {
      widget.onFilesPicked!(files);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && widget.onSend != null) {
      widget.onSend!(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Smiley icon
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset(
              'assets/Smiley.png',
              width: 24,
              height: 24,
            ),
          ),

          // Message input
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14, color: Color(0xFF8A8894)),
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                border: InputBorder.none,
              ),
            ),
          ),

          // Paperclip (file/image picker)
          IconButton(
            icon: Image.asset(
              'assets/Paperclip.png',
              width: 24,
              height: 24,
            ),
            onPressed: _pickFiles,
          ),

          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Image.asset(
                'assets/send.png',
                width: 20,
                height: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
