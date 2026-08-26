import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';
import '../services/radio_player.dart';
import '../models/chat_message.dart';
import '../app_theme.dart';

class TalkToMegamScreen extends StatefulWidget {
  const TalkToMegamScreen({super.key});

  @override
  State<TalkToMegamScreen> createState() => _TalkToMegamScreenState();
}

class _TalkToMegamScreenState extends State<TalkToMegamScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final TTSService _serverTts = TTSService();
  final RadioPlayer _audioPlayer = RadioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _messages.add(ChatMessage(
      text: "Hello! I am Megam, your English tutor. How can I help you today?",
      isUser: false,
    ));
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    // Configurações para uma fala natural e calma de tutor
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    // Tenta selecionar motores de alta fidelidade
    var voices = await _flutterTts.getVoices;
    try {
      var femaleVoice = voices.firstWhere(
        (v) {
          final name = v["name"].toString().toLowerCase();
          final locale = v["locale"].toString().toLowerCase();

          // No Android, procuramos 'network' ou 'neural' (vozes processadas na nuvem pela Google)
          // No iOS, vozes como 'samantha' ou 'enhanced'
          return locale.contains("en-us") && (
            name.contains("network") ||
            name.contains("neural") ||
            name.contains("samantha") ||
            name.contains("enhanced") ||
            name.contains("premium")
          );
        },
        orElse: () => voices.firstWhere(
          (v) => v["locale"].toString().toLowerCase().contains("en-us"),
          orElse: () => voices.first,
        ),
      );
      await _flutterTts.setVoice({"name": femaleVoice["name"], "locale": femaleVoice["locale"]});
    } catch (e) {
      print("Erro ao selecionar voz: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    // Pega apenas o que vem ANTES do marcador '---' para garantir que fale apenas inglês
    String englishText = text.split("---").first.trim();

    // Remove emojis e caracteres especiais que o TTS costuma ler em voz alta
    String cleanText = englishText.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F018}-\u{1F093}]', unicode: true), '');

    if (cleanText.isNotEmpty) {
      try {
        // Tenta usar o áudio gerado pelo servidor (Edge-TTS + S3)
        final url = await _serverTts.getAudioUrl(cleanText);
        if (url != null) {
          await _audioPlayer.setUrl(url);
          await _audioPlayer.play();
        } else {
          // Fallback para o TTS local do dispositivo se o servidor falhar
          await _flutterTts.speak(cleanText);
        }
      } catch (e) {
        print("Erro ao processar áudio do servidor: $e");
        await _flutterTts.speak(cleanText);
      }
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final response = await _geminiService.sendMessage(text);

      setState(() {
        _messages.add(ChatMessage(text: response.text, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();

      // Megam fala o texto em inglês
      _speak(response.text);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fale com a Megam"),
        backgroundColor: AppColors.navyBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF4F6FB),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyBlue),
              ),
            _InputArea(controller: _controller, onSend: _sendMessage, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.navyBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : AppColors.navyBlue, fontSize: 15),
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  const _InputArea({required this.controller, required this.onSend, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Pratique seu inglês...",
                filled: true,
                fillColor: const Color(0xFFF0F2F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.red,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: isLoading ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
