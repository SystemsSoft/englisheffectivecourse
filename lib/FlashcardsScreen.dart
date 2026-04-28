import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';

// ─── Banco de flashcards ──────────────────────────────────────────────────────
const _allCards = [
  _CardData('Hello',         'interj.', 'A greeting used when meeting someone.',                   'Hello! How are you today?'),
  _CardData('Goodbye',       'interj.', 'What you say when leaving someone.',                      'Goodbye! See you tomorrow.'),
  _CardData('Please',        'adv.',    'Used to make a request polite.',                          'Can I have some water, please?'),
  _CardData('Thank you',     'phrase',  'What you say to show gratitude.',                         'Thank you for your help!'),
  _CardData('Sorry',         'interj.', 'Used to apologize or express regret.',                    'Sorry, I didn\'t mean to be late.'),
  _CardData('Yes',           'adv.',    'Used to agree or confirm something.',                     'Yes, I understand the lesson.'),
  _CardData('No',            'adv.',    'Used to disagree or refuse.',                             'No, I don\'t speak Spanish.'),
  _CardData('Help',          'verb',    'To make it easier for someone to do something.',          'Can you help me with this exercise?'),
  _CardData('Understand',    'verb',    'To know the meaning of something.',                       'Do you understand the question?'),
  _CardData('Repeat',        'verb',    'To say or do something again.',                           'Could you repeat that, please?'),
  _CardData('Speak',         'verb',    'To say words; to talk.',                                  'I want to speak English fluently.'),
  _CardData('Listen',        'verb',    'To pay attention to a sound.',                            'Listen carefully to the teacher.'),
  _CardData('Read',          'verb',    'To look at and understand written words.',                'I read English books every day.'),
  _CardData('Write',         'verb',    'To put words on paper or screen.',                        'Write your name at the top of the page.'),
  _CardData('Learn',         'verb',    'To get knowledge or a new skill.',                        'I want to learn English this year.'),
  _CardData('Study',         'verb',    'To spend time learning about something.',                 'She studies English every morning.'),
  _CardData('Practice',      'verb',    'To do something regularly to get better.',                'Practice speaking every day.'),
  _CardData('Question',      'noun',    'Something you ask to get information.',                   'Do you have any questions?'),
  _CardData('Answer',        'noun',    'A reply to a question.',                                  'The answer to question 3 is correct.'),
  _CardData('Word',          'noun',    'A single unit of language.',                              'What does this word mean?'),
  _CardData('Sentence',      'noun',    'A group of words that expresses a complete idea.',        'Write a sentence using the new word.'),
  _CardData('Vocabulary',    'noun',    'All the words you know in a language.',                   'Reading books helps build your vocabulary.'),
  _CardData('Pronunciation', 'noun',    'The way a word is said out loud.',                        'Your pronunciation is getting much better!'),
  _CardData('Grammar',       'noun',    'The rules for how words are used in a language.',         'Good grammar makes your writing clearer.'),
  _CardData('Mistake',       'noun',    'Something done wrong; an error.',                         'Don\'t worry about mistakes — they help you learn.'),
  _CardData('Easy',          'adj.',    'Not difficult; simple to do or understand.',              'This exercise is easy for me now.'),
  _CardData('Difficult',     'adj.',    'Hard to do or understand.',                               'Pronunciation is difficult at first.'),
  _CardData('Slowly',        'adv.',    'At a slow speed.',                                        'Please speak more slowly, I\'m still learning.'),
  _CardData('Again',         'adv.',    'One more time.',                                          'Can you say that again, please?'),
  _CardData('Every day',     'phrase',  'On each day without missing.',                            'Practice a little every day and you will improve.'),
];

class _CardData {
  final String word;
  final String type;
  final String definition;
  final String example;
  const _CardData(this.word, this.type, this.definition, this.example);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late List<_CardData> _deck;
  int _index = 0;
  bool _flipped = false;
  bool _flipping = false;
  int _know = 0;
  int _dontKnow = 0;
  bool _finished = false;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _deck = List.from(_allCards)..shuffle(Random());
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() async {
    if (_flipping) return;
    _flipping = true;
    if (_flipped) {
      await _flipCtrl.reverse();
    } else {
      await _flipCtrl.forward();
    }
    setState(() => _flipped = !_flipped);
    _flipping = false;
  }

  void _answer(bool knew) async {
    if (_flipping) return;
    setState(() {
      if (knew) _know++; else _dontKnow++;
    });
    // Volta o card para frente antes de avançar
    if (_flipped) {
      _flipping = true;
      await _flipCtrl.reverse();
      _flipping = false;
    }
    setState(() {
      _flipped = false;
      if (_index + 1 >= _deck.length) {
        _finished = true;
      } else {
        _index++;
      }
    });
  }

  void _restart() {
    setState(() {
      _deck.shuffle(Random());
      _index = 0;
      _flipped = false;
      _know = 0;
      _dontKnow = 0;
      _finished = false;
      _flipCtrl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = _deck.length;

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
                          Expanded(
                            child: Text(
                              'Flashcards',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.shuffle_rounded, color: Colors.white70),
                            tooltip: 'Shuffle',
                            onPressed: _restart,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Barra de progresso
                      if (!_finished) ...[
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _index / total,
                                  backgroundColor: Colors.white24,
                                  color: Colors.white,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$_index / $total',
                              style: textTheme.labelSmall?.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Placar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ScorePill(icon: Icons.check_rounded, color: const Color(0xFF43A047), count: _know, label: 'Know'),
                            const SizedBox(width: 12),
                            _ScorePill(icon: Icons.close_rounded, color: AppColors.red, count: _dontKnow, label: 'Not yet'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: _finished
                  ? _ResultView(
                      know: _know,
                      dontKnow: _dontKnow,
                      total: total,
                      onRestart: _restart,
                      textTheme: textTheme,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Dica de toque
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Tap the card to reveal the answer',
                            style: textTheme.bodySmall?.copyWith(color: const Color(0xFF9EA3C8)),
                          ),
                        ),

                        // Card com flip 3D
                        GestureDetector(
                          onTap: _flip,
                          child: AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (_, __) {
                              final angle = _flipAnim.value * pi;
                              final showBack = angle > pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: showBack
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(pi),
                                        child: _CardBack(card: _deck[_index], textTheme: textTheme),
                                      )
                                    : _CardFront(card: _deck[_index], textTheme: textTheme),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Botões Sei / Não sei (só aparecem depois de virar)
                        AnimatedOpacity(
                          opacity: _flipped ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AnswerButton(
                                label: "Don't know",
                                icon: Icons.close_rounded,
                                color: AppColors.red,
                                onTap: _flipped ? () => _answer(false) : null,
                              ),
                              const SizedBox(width: 20),
                              _AnswerButton(
                                label: 'I know it!',
                                icon: Icons.check_rounded,
                                color: const Color(0xFF43A047),
                                onTap: _flipped ? () => _answer(true) : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Frente ──────────────────────────────────────────────────────────────
class _CardFront extends StatelessWidget {
  final _CardData card;
  final TextTheme textTheme;
  const _CardFront({required this.card, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x441A2150), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Ornamento circular
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20, bottom: -20,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.type,
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white70, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  card.word,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.touch_app_rounded, color: Colors.white38, size: 16),
                    const SizedBox(width: 4),
                    Text('tap to flip', style: textTheme.labelSmall?.copyWith(color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card Verso ───────────────────────────────────────────────────────────────
class _CardBack extends StatelessWidget {
  final _CardData card;
  final TextTheme textTheme;
  const _CardBack({required this.card, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x201A2150), blurRadius: 24, offset: Offset(0, 8)),
        ],
        border: Border.all(color: const Color(0xFFE8EAF6), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Definition',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.navyBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              card.definition,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.navyBlue, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Text(
              '"${card.example}"',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF767AA8),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botão de resposta ────────────────────────────────────────────────────────
class _AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Score Pill ───────────────────────────────────────────────────────────────
class _ScorePill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _ScorePill({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Resultado final ──────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final int know;
  final int dontKnow;
  final int total;
  final VoidCallback onRestart;
  final TextTheme textTheme;

  const _ResultView({
    required this.know,
    required this.dontKnow,
    required this.total,
    required this.onRestart,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (know / total * 100).round();
    final emoji = pct >= 80 ? '🎉' : pct >= 50 ? '💪' : '📚';
    final msg = pct >= 80
        ? 'Excellent work!'
        : pct >= 50
            ? 'Good progress, keep going!'
            : 'Keep studying, you\'ll get there!';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold, color: AppColors.navyBlue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x101A2150), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                // Percentual
                Text(
                  '$pct%',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: pct >= 80
                        ? const Color(0xFF43A047)
                        : pct >= 50
                            ? const Color(0xFFF9A825)
                            : AppColors.red,
                  ),
                ),
                Text(
                  'score',
                  style: textTheme.bodySmall?.copyWith(color: const Color(0xFF767AA8)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(value: '$know', label: 'Knew it', color: const Color(0xFF43A047)),
                    Container(width: 1, height: 40, color: const Color(0xFFE8EAF6)),
                    _StatItem(value: '$dontKnow', label: 'Not yet', color: AppColors.red),
                    Container(width: 1, height: 40, color: const Color(0xFFE8EAF6)),
                    _StatItem(value: '$total', label: 'Total', color: AppColors.navyBlue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Botão jogar de novo
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x441A2150), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Play Again',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF767AA8))),
      ],
    );
  }
}

