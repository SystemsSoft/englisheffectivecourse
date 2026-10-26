import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'app_theme.dart';
import 'widgets/ui_kit.dart';

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
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPageBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final hPadding = pagePadding(constraints.maxWidth);
            final isWide = constraints.maxWidth >= 860;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Word of the Day',
                    subtitle: dateStr,
                    icon: Icons.auto_stories_rounded,
                    actions: [
                      GlassIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reload',
                        onPressed: _fetch,
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: ContentConstrained(
                    maxWidth: 1040,
                    padding: EdgeInsets.fromLTRB(hPadding, 24, hPadding, 40),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _loading
                          ? const Padding(
                              key: ValueKey('loading'),
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.navyBlue),
                              ),
                            )
                          : _error != null
                              ? MessageCard(
                                  key: const ValueKey('error'),
                                  icon: Icons.wifi_off_rounded,
                                  iconColor: AppColors.red,
                                  title: 'Oops!',
                                  subtitle: _error!,
                                  actionLabel: 'Try again',
                                  actionIcon: Icons.refresh_rounded,
                                  onAction: _fetch,
                                )
                              : _WordCard(
                                  key: const ValueKey('word'),
                                  data: _wordData!,
                                  playing: _playing,
                                  onPlay: _playAudio,
                                  isWide: isWide,
                                ),
                    ),
                  ),
                ),
              ],
            );
          },
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
  final bool isWide;

  const _WordCard({
    super.key,
    required this.data,
    required this.playing,
    required this.onPlay,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ── Palavra principal ──────────────────────────────────────────
    final hero = FadeSlideIn(
      child: _WordHero(data: data, playing: playing, onPlay: onPlay, isWide: isWide),
    );

    final details = [
      // ── Definição ──────────────────────────────────────────────
      FadeSlideIn(
        delay: const Duration(milliseconds: 120),
        child: _SectionCard(
          icon: Icons.menu_book_rounded,
          iconColor: AppColors.navyBlue,
          title: 'Definition',
          content: data.definition,
          textTheme: textTheme,
        ),
      ),

      if (data.example != null && data.example!.isNotEmpty) ...[
        const SizedBox(height: 14),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: _SectionCard(
            icon: Icons.format_quote_rounded,
            iconColor: AppColors.red,
            title: 'Example',
            content: '"${data.example!}"',
            textTheme: textTheme,
            contentColor: const Color(0xFF44476A),
            italic: true,
          ),
        ),
      ],

      const SizedBox(height: 14),

      // ── Dica de estudo ─────────────────────────────────────────
      FadeSlideIn(
        delay: const Duration(milliseconds: 280),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9A825).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFF9A825), size: 20),
              ),
              const SizedBox(width: 12),
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
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: hero),
          const SizedBox(width: 24),
          Expanded(
            flex: 6,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: details),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [hero, const SizedBox(height: 20), ...details],
    );
  }
}

// ─── Destaque da palavra ──────────────────────────────────────────────────────
class _WordHero extends StatelessWidget {
  final _WordData data;
  final bool playing;
  final VoidCallback onPlay;
  final bool isWide;

  const _WordHero({
    required this.data,
    required this.playing,
    required this.onPlay,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAudio = data.audioUrl != null && data.audioUrl!.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x441A2150), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: -40, top: -40, child: GlowCircle(size: 160, alpha: 0.07)),
          const Positioned(left: -30, bottom: -30, child: GlowCircle(size: 110, alpha: 0.05)),
          Padding(
            padding: EdgeInsets.all(isWide ? 32 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TODAY',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: isWide ? 28 : 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          alignment: Alignment.centerLeft,
                          child: child,
                        ),
                        child: Text(
                          data.word,
                          style: (isWide ? textTheme.displaySmall : textTheme.headlineMedium)
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    if (hasAudio) _AudioButton(playing: playing, onTap: onPlay),
                  ],
                ),
                if (data.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    data.phonetic,
                    style: textTheme.titleMedium?.copyWith(color: Colors.white60),
                  ),
                ],
                const SizedBox(height: 16),
                if (data.partOfSpeech.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data.partOfSpeech,
                      style: textTheme.labelMedium
                          ?.copyWith(color: Colors.white, letterSpacing: 0.5),
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

// ─── Botão de áudio com pulso enquanto toca ──────────────────────────────────
class _AudioButton extends StatefulWidget {
  final bool playing;
  final VoidCallback onTap;

  const _AudioButton({required this.playing, required this.onTap});

  @override
  State<_AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<_AudioButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(covariant _AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.playing && _pulse.isAnimating) {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Listen',
      child: PressableScale(
        onTap: widget.playing ? null : widget.onTap,
        pressedScale: 0.88,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Onda que se expande enquanto o áudio toca
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Container(
                  width: 48 + 12 * _pulse.value,
                  height: 48 + 12 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.redLight.withValues(
                      alpha: widget.playing ? 0.35 * (1 - _pulse.value) : 0,
                    ),
                  ),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.red, AppColors.redLight]),
                  boxShadow: [
                    BoxShadow(color: Color(0x55C8102E), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(
                  widget.playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
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
    return AppCard(
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
