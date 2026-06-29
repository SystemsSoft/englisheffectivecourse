import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import '../app_theme.dart';

// ─── Model (mesma estrutura do WordOfTheDay) ──────────────────────────────────
class _WordData {
  final String word;
  final String phonetic;
  final List<_Meaning> meanings;
  final String? audioUrl;

  const _WordData({
    required this.word,
    required this.phonetic,
    required this.meanings,
    this.audioUrl,
  });

  factory _WordData.fromJson(List<dynamic> json) {
    final entry = json[0] as Map<String, dynamic>;
    final word = entry['word'] as String? ?? '';

    String phonetic = entry['phonetic'] as String? ?? '';
    if (phonetic.isEmpty) {
      for (final p in (entry['phonetics'] as List? ?? [])) {
        final t = (p as Map)['text'] as String? ?? '';
        if (t.isNotEmpty) { phonetic = t; break; }
      }
    }

    String? audioUrl;
    for (final p in (entry['phonetics'] as List? ?? [])) {
      final a = (p as Map)['audio'] as String? ?? '';
      if (a.isNotEmpty) { audioUrl = a; break; }
    }

    final meanings = <_Meaning>[];
    for (final m in (entry['meanings'] as List? ?? [])) {
      final map = m as Map<String, dynamic>;
      final pos = map['partOfSpeech'] as String? ?? '';
      final defs = <_Definition>[];
      for (final d in (map['definitions'] as List? ?? [])) {
        final dm = d as Map<String, dynamic>;
        defs.add(_Definition(
          definition: dm['definition'] as String? ?? '',
          example: dm['example'] as String?,
        ));
      }
      if (defs.isNotEmpty) meanings.add(_Meaning(partOfSpeech: pos, definitions: defs));
    }

    return _WordData(word: word, phonetic: phonetic, meanings: meanings, audioUrl: audioUrl);
  }
}

class _Meaning {
  final String partOfSpeech;
  final List<_Definition> definitions;
  const _Meaning({required this.partOfSpeech, required this.definitions});
}

class _Definition {
  final String definition;
  final String? example;
  const _Definition({required this.definition, this.example});
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _controller = TextEditingController();
  _WordData? _wordData;
  bool _loading = false;
  String? _error;
  bool _playing = false;
  String? _notFound;
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _search([String? query]) async {
    final word = (query ?? _controller.text).trim().toLowerCase();
    if (word.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _error = null; _notFound = null; _wordData = null; });
    try {
      final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        setState(() { _wordData = _WordData.fromJson(json as List); _loading = false; });
      } else if (response.statusCode == 404) {
        setState(() { _notFound = 'No results found for "$word".'; _loading = false; });
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Dictionary',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.menu_book_rounded, color: Colors.white70, size: 28),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ── Campo de busca dentro do header ───────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x221A2150), blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          onSubmitted: _search,
                          style: const TextStyle(color: AppColors.navyBlue, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search a word in English...',
                            hintStyle: const TextStyle(color: Color(0xFF9EA3C8), fontSize: 14),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyBlue),
                            suffixIcon: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.navyBlue, strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded,
                                        color: AppColors.navyBlue),
                                    onPressed: _search,
                                  ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: _buildBody(textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.navyBlue));
    }
    if (_error != null) {
      return _CenterMessage(
        icon: Icons.wifi_off_rounded,
        message: _error!,
        action: TextButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_notFound != null) {
      return _CenterMessage(
        icon: Icons.search_off_rounded,
        message: _notFound!,
      );
    }
    if (_wordData == null) {
      return _CenterMessage(
        icon: Icons.auto_stories_rounded,
        message: 'Type a word above to search\nthe English dictionary.',
        iconColor: const Color(0xFFB0B3CC),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card da palavra ──────────────────────────────────────────
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _wordData!.word,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_wordData!.phonetic.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _wordData!.phonetic,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_wordData!.audioUrl != null && _wordData!.audioUrl!.isNotEmpty)
                  GestureDetector(
                    onTap: _playAudio,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _playing
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Significados ─────────────────────────────────────────────
          ..._wordData!.meanings.take(3).map((meaning) => _MeaningCard(
                meaning: meaning,
                textTheme: textTheme,
              )),
        ],
      ),
    );
  }
}

// ─── Meaning Card ─────────────────────────────────────────────────────────────
class _MeaningCard extends StatelessWidget {
  final _Meaning meaning;
  final TextTheme textTheme;

  const _MeaningCard({required this.meaning, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Part of speech tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.navyBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meaning.partOfSpeech,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.navyBlue,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Até 3 definições por significado
          ...meaning.definitions.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final def = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5, right: 8),
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          def.definition,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.navyBlue,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (def.example != null && def.example!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        '"${def.example!}"',
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF767AA8),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  if (i < meaning.definitions.take(3).length - 1)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Divider(color: Color(0xFFF0F0F8), height: 1),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Center Message ───────────────────────────────────────────────────────────
class _CenterMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  final Color iconColor;

  const _CenterMessage({
    required this.icon,
    required this.message,
    this.action,
    this.iconColor = const Color(0xFFB0B3CC),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF767AA8), height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

