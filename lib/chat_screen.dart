import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  final Logger logger = Logger(printer: PrettyPrinter());
    bool  isloading = false;


  void _sendMessage() {
    String userMessage = _controller.text.trim();
    if (userMessage.isNotEmpty) {
      setState(() {
        _chatMessages.insert(0, {"sender": "user", "message": userMessage});
      });
      _controller.clear();
      _getBotResponse(userMessage);
    }
  }

  Future<void> _getBotResponse(String message) async {
    const String url = 'https://openrouter.ai/api/v1/chat/completions';
    const String apiKey = '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';
    setState(() {
       isloading = true;
    });
   

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-r1:free',
          'messages': [{'role': 'user', 'content': message}]
        }),
      );
      setState(() {
        isloading = false;
      });
     
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logger.d(data);
        setState(() {
          _chatMessages.insert(0, {
            "sender": "bot",
            "message": data['choices'][0]['message']['content'].trim()
          });
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Erreur lors de la requête : $e');
      setState(() {
        _chatMessages.insert(0, {"sender": "bot", "message": "Erreur de réponse du bot."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat IA'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                bool isUser = _chatMessages[index]["sender"] == "user";
                return Column(
                  children: [
                    Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _chatMessages[index]["message"]!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    if (index == 0 && isloading) 
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
