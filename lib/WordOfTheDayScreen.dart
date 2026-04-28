import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'app_theme.dart';

// ─── Palavras usadas como seed diário ─────────────────────────────────────────
const _words = [
  'serendipity', 'eloquent', 'resilience', 'ambiguous', 'pragmatic',
  'diligent', 'versatile', 'articulate', 'perseverance', 'nuance',
  'accountability', 'empathy', 'initiative', 'collaborate', 'innovative',
  'confident', 'consistent', 'motivate', 'accomplish', 'proficient',
  'fluent', 'acquire', 'dedicate', 'challenge', 'overcome',
  'curious', 'patience', 'discipline', 'enthusiasm', 'commitment',
];

String _wordForToday() {
  final now = DateTime.now();
  final index = (now.year * 365 + now.month * 31 + now.day) % _words.length;
  return _words[index];
}

// ─── Model ────────────────────────────────────────────────────────────────────
class _WordData {
  final String word;
  final String phonetic;
  final String partOfSpeech;
  final String definition;
  final String? example;
  final String? audioUrl;

  const _WordData({
    required this.word,
    required this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.audioUrl,
  });

  factory _WordData.fromJson(List<dynamic> json) {
    final entry = json[0] as Map<String, dynamic>;
    final word = entry['word'] as String? ?? '';

    String phonetic = entry['phonetic'] as String? ?? '';
    if (phonetic.isEmpty) {
      final phonetics = entry['phonetics'] as List<dynamic>? ?? [];
      for (final p in phonetics) {
        final t = (p as Map)['text'] as String? ?? '';
        if (t.isNotEmpty) { phonetic = t; break; }
      }
    }

    String? audioUrl;
    final phonetics = entry['phonetics'] as List<dynamic>? ?? [];
    for (final p in phonetics) {
      final a = (p as Map)['audio'] as String? ?? '';
      if (a.isNotEmpty) { audioUrl = a; break; }
    }

    final meanings = entry['meanings'] as List<dynamic>? ?? [];
    String partOfSpeech = '';
    String definition = '';
    String? example;
    if (meanings.isNotEmpty) {
      final meaning = meanings[0] as Map<String, dynamic>;
      partOfSpeech = meaning['partOfSpeech'] as String? ?? '';
      final defs = meaning['definitions'] as List<dynamic>? ?? [];
      if (defs.isNotEmpty) {
        final def = defs[0] as Map<String, dynamic>;
        definition = def['definition'] as String? ?? '';
        example = def['example'] as String?;
      }
    }

    return _WordData(
      word: word,
      phonetic: phonetic,
      partOfSpeech: partOfSpeech,
      definition: definition,
      example: example,
      audioUrl: audioUrl,
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class WordOfTheDayScreen extends StatefulWidget {
  const WordOfTheDayScreen({super.key});

  @override
  State<WordOfTheDayScreen> createState() => _WordOfTheDayScreenState();
}

class _WordOfTheDayScreenState extends State<WordOfTheDayScreen> {
  _WordData? _wordData;
  bool _loading = true;
  String? _error;
  bool _playing = false;
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _fetch();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final word = _wordForToday();
      final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() {
          _wordData = _WordData.fromJson(json as List<dynamic>);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Could not load word. Try again later.'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'No connection. Check your internet.'; _loading = false; });
    }
  }

  Future<void> _playAudio() async {
    final url = _wordData?.audioUrl;
    if (url == null || url.isEmpty) return;
    try {
      setState(() => _playing = true);
      final fullUrl = url.startsWith('//') ? 'https:$url' : url;
      await _player.setUrl(fullUrl);
      await _player.play();
      await _player.playerStateStream.firstWhere(
        (s) => s.processingState == ProcessingState.completed,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A2150), Color(0xFF2B3A7A), Color(0xFF3D4FA0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [BoxShadow(color: Color(0x441A2150), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 24, 28),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Word of the Day',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.auto_stories_rounded, color: Colors.white70, size: 30),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.navyBlue))
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _fetch)
                      : _WordCard(
                          data: _wordData!,
                          playing: _playing,
                          onPlay: _playAudio,
                          textTheme: textTheme,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Word Card ────────────────────────────────────────────────────────────────
class _WordCard extends StatelessWidget {
  final _WordData data;
  final bool playing;
  final VoidCallback onPlay;
  final TextTheme textTheme;

  const _WordCard({
    required this.data,
    required this.playing,
    required this.onPlay,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Palavra principal ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x441A2150), blurRadius: 18, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        data.word,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (data.audioUrl != null && data.audioUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: onPlay,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: playing
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.volume_up_rounded,
                                  color: Colors.white, size: 24),
                        ),
                      ),
                  ],
                ),
                if (data.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    data.phonetic,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white60),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.partOfSpeech,
                    style: textTheme.labelSmall
                        ?.copyWith(color: Colors.white70, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Definição ──────────────────────────────────────────────
          _SectionCard(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.navyBlue,
            title: 'Definition',
            content: data.definition,
            textTheme: textTheme,
          ),

          if (data.example != null && data.example!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              icon: Icons.format_quote_rounded,
              iconColor: AppColors.red,
              title: 'Example',
              content: '"${data.example!}"',
              textTheme: textTheme,
              contentColor: const Color(0xFF44476A),
              italic: true,
            ),
          ],

          const SizedBox(height: 28),

          // ── Dica de estudo ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF9A825), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Study Tip: Try to use this word in a sentence today. '
                    'Writing it down helps your brain remember it faster!',
                    style: textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5D4037),
                      height: 1.5,
                    ),
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

// ─── Section Card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final TextTheme textTheme;
  final Color contentColor;
  final bool italic;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.textTheme,
    this.contentColor = AppColors.navyBlue,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x101A2150), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: contentColor,
              height: 1.6,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFFB0B3CC)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF767AA8)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

