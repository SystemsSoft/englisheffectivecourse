import 'dart:convert';
import 'dart:math';
// dart:html é a API nativa do browser — funciona de forma confiável
// em Flutter web release builds sem depender de platform channels.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/flashcard_model.dart';
import 'services/flashcard_service.dart';
import 'viewmodels/user_viewmodel.dart';
import 'app_theme.dart';

// ─── Banco de flashcards fixos (iniciante) ────────────────────────────────────
const _builtinCards = [
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

const _kCustomCardsKey = 'custom_flashcards';

class _CardData {
  final String? remoteId; // id do backend (null = ainda não sincronizado)
  final String word;
  final String type;
  final String definition;
  final String example;
  final bool isCustom;

  const _CardData(this.word, this.type, this.definition, this.example,
      {this.isCustom = false, this.remoteId});

  Map<String, dynamic> toJson() => {
        'remoteId': remoteId,
        'word': word,
        'type': type,
        'definition': definition,
        'example': example,
      };

  factory _CardData.fromJson(Map<String, dynamic> j) => _CardData(
        j['word'] as String,
        j['type'] as String,
        j['definition'] as String,
        j['example'] as String? ?? '',
        isCustom: true,
        remoteId: j['remoteId'] as String?,
      );

  factory _CardData.fromDto(FlashcardDto dto) => _CardData(
        dto.word,
        dto.type,
        dto.definition,
        dto.example,
        isCustom: true,
        remoteId: dto.id,
      );
}

// ─── Cache local via localStorage do browser (sem platform channels) ─────────
Future<List<_CardData>> _loadCachedCards() async {
  try {
    final raw = html.window.localStorage[_kCustomCardsKey];
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _CardData.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print('[FC] _loadCachedCards erro: $e');
    return [];
  }
}

Future<void> _cacheCards(List<_CardData> cards) async {
  try {
    html.window.localStorage[_kCustomCardsKey] =
        jsonEncode(cards.map((c) => c.toJson()).toList());
    print('[FC] _cacheCards: ${cards.length} cards salvos no localStorage');
  } catch (e) {
    print('[FC] _cacheCards erro (ignorado): $e');
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final _service = FlashcardService();

  List<_CardData> _customCards = [];
  List<_CardData> _deck = [];
  int _index = 0;
  int _know = 0;
  int _dontKnow = 0;
  bool _finished = false;
  bool _loaded = false;
  String? _loadError;

  // 0 = Play, 1 = My Cards
  int _tab = 0;


  @override
  void initState() {
    super.initState();
    print('[FC] initState — agendando _loadCards via addPostFrameCallback');
    // Carrega após o primeiro frame para ter acesso ao context/provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[FC] postFrameCallback disparado — chamando _loadCards');
      _loadCards();
    });
  }

  Future<void> _loadCards() async {
    print('[FC] _loadCards iniciado');
    UserViewModel userVM;
    try {
      userVM = context.read<UserViewModel>();
    } catch (e, st) {
      print('[FC] ERRO ao ler UserViewModel: $e\n$st');
      return;
    }
    final user = userVM.user;
    print('[FC] user: ${user == null ? "null (não logado)" : "logado: ${user.name} / ${user.className}"}');

    if (user == null) {
      // Sem usuário logado — usa somente cache local
      print('[FC] Sem usuário — carregando cache local');
      try {
        final cached = await _loadCachedCards();
        print('[FC] Cache local carregado: ${cached.length} cards');
        if (!mounted) { print('[FC] widget desmontado após cache'); return; }
        setState(() {
          _customCards = cached;
          _loaded = true;
          _buildDeck();
        });
        print('[FC] setState concluído (sem usuário) — deck: ${_deck.length} cards');
      } catch (e, st) {
        print('[FC] ERRO ao carregar cache local: $e\n$st');
        if (!mounted) return;
        setState(() { _loaded = true; _buildDeck(); });
      }
      return;
    }

    try {
      print('[FC] Buscando flashcards do servidor...');
      final dtos = await _service.fetchAll(
        studentName: user.name,
        className: user.className,
      );
      print('[FC] fetchAll retornou ${dtos.length} DTOs');
      final cards = dtos.map(_CardData.fromDto).toList();

      // Cache em try/catch separado: falha aqui NÃO descarta os cards buscados
      await _cacheCards(cards);

      if (!mounted) { print('[FC] widget desmontado após fetchAll'); return; }
      setState(() {
        _customCards = cards;
        _loadError = null;
        _loaded = true;
        _buildDeck();
      });
      print('[FC] setState concluído (com servidor) — deck: ${_deck.length} cards');
    } catch (e, st) {
      print('[FC] ERRO no fetchAll: $e\n$st');
      // Fallback offline — _cacheCards já tem try/catch interno, então
      // _loadCachedCards também nunca vai lançar aqui
      final cached = await _loadCachedCards();
      print('[FC] Fallback cache: ${cached.length} cards');
      if (!mounted) { print('[FC] widget desmontado no fallback'); return; }
      setState(() {
        _customCards = cached;
        _loadError = 'Offline — showing cached cards.';
        _loaded = true;
        _buildDeck();
      });
      print('[FC] setState concluído (fallback offline) — deck: ${_deck.length} cards');
    }
  }

  void _buildDeck() {
    final before = _deck.length;
    _deck = [..._builtinCards, ..._customCards]..shuffle(Random());
    _index = 0;
    _know = 0;
    _dontKnow = 0;
    _finished = false;
    print('[FC] _buildDeck: builtins=${_builtinCards.length} custom=${_customCards.length} total=${_deck.length} (antes=$before)');
  }

  @override
  void dispose() {
    super.dispose();
  }


  void _answer(bool knew) {
    setState(() {
      if (knew) _know++; else _dontKnow++;
      if (_index + 1 >= _deck.length) {
        _finished = true;
      } else {
        _index++;
      }
    });
  }

  void _restart() {
    setState(() => _buildDeck());
  }

  Future<void> _addCard(_CardData card) async {
    final user = context.read<UserViewModel>().user;

    _CardData saved = card;
    if (user != null) {
      try {
        final dto = await _service.create(FlashcardDto(
          studentName: user.name,
          className: user.className,
          word: card.word,
          type: card.type,
          definition: card.definition,
          example: card.example,
        ));
        saved = _CardData.fromDto(dto);
      } catch (_) {
        // Salva localmente mesmo offline
      }
    }

    final updated = [..._customCards, saved];
    await _cacheCards(updated);
    setState(() {
      _customCards = updated;
      _buildDeck();
    });
  }

  Future<void> _deleteCard(int index) async {
    final card = _customCards[index];
    final user = context.read<UserViewModel>().user;

    if (user != null && card.remoteId != null) {
      try {
        await _service.delete(
          card.remoteId!,
          studentName: user.name,
          className: user.className,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover no servidor. Removido localmente.'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }

    final updated = [..._customCards]..removeAt(index);
    await _cacheCards(updated);
    setState(() {
      _customCards = updated;
      _buildDeck();
    });
  }

  void _showAddDialog() {
    final wordCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final defCtrl = TextEditingController();
    final exCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 4, height: 20,
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text('New Flashcard',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                  ],
                ),
                const SizedBox(height: 20),
                // Word
                _FormField(controller: wordCtrl, label: 'Word *', hint: 'e.g. Brave',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 12),
                // Type
                _FormField(controller: typeCtrl, label: 'Type', hint: 'e.g. adj., noun, verb'),
                const SizedBox(height: 12),
                // Definition
                _FormField(controller: defCtrl, label: 'Definition *', hint: 'e.g. Having courage...',
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 12),
                // Example
                _FormField(controller: exCtrl, label: 'Example sentence', hint: 'e.g. She was brave enough to speak.'),
                const SizedBox(height: 24),
                // Botão salvar
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(context);
                      _addCard(_CardData(
                        wordCtrl.text.trim(),
                        typeCtrl.text.trim().isEmpty ? 'word' : typeCtrl.text.trim(),
                        defCtrl.text.trim(),
                        exCtrl.text.trim(),
                        isCustom: true,
                      ));
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Save Card',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = _deck.length;
    print('[FC] build — _loaded=$_loaded _deck.length=$total _index=$_index _finished=$_finished _tab=$_tab _loadError=$_loadError');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text('Flashcards',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          // Botão adicionar card
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                            tooltip: 'Add card',
                            onPressed: _showAddDialog,
                          ),
                          IconButton(
                            icon: const Icon(Icons.shuffle_rounded, color: Colors.white70),
                            tooltip: 'Shuffle',
                            onPressed: _restart,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _TabButton(label: 'Play', icon: Icons.play_arrow_rounded,
                              selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                            const SizedBox(width: 10),
                            _TabButton(
                              label: 'My Cards (${_customCards.length})',
                              icon: Icons.bookmarks_rounded,
                              selected: _tab == 1,
                              onTap: () => setState(() => _tab = 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Barra de progresso (só no tab Play)
                      if (_tab == 0 && !_finished && _loaded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: total == 0 ? 0 : _index / total,
                                    backgroundColor: Colors.white24,
                                    color: Colors.white,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('$_index / $total',
                                style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ScorePill(icon: Icons.check_rounded, color: const Color(0xFF43A047), count: _know, label: 'Know'),
                            const SizedBox(width: 12),
                            _ScorePill(icon: Icons.close_rounded, color: AppColors.red, count: _dontKnow, label: 'Not yet'),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: !_loaded
                  ? const Center(child: CircularProgressIndicator(color: AppColors.navyBlue))
                  : Column(
                      children: [
                        // Banner offline
                        if (_loadError != null)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFFF3E0),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.wifi_off_rounded, color: Color(0xFFF57C00), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_loadError!,
                                    style: const TextStyle(color: Color(0xFFF57C00), fontSize: 12)),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() { _loaded = false; _loadError = null; _loadCards(); }),
                                  child: const Text('Retry', style: TextStyle(
                                    color: Color(0xFFF57C00), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _tab == 1
                              ? _MyCardsTab(
                                  customCards: _customCards,
                                  onDelete: _deleteCard,
                                  onAdd: _showAddDialog,
                                  textTheme: textTheme,
                                )
                              : _PlayTab(
                                  // key garante reset da animação a cada novo card
                                  key: ValueKey(_index),
                                  deck: _deck,
                                  index: _index,
                                  finished: _finished,
                                  know: _know,
                                  dontKnow: _dontKnow,
                                  onAnswer: _answer,
                                  onRestart: _restart,
                                  textTheme: textTheme,
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

// ─── Tab Button ───────────────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.navyBlue : Colors.white70),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.navyBlue : Colors.white70,
              )),
          ],
        ),
      ),
    );
  }
}

// ─── Play Tab ─────────────────────────────────────────────────────────────────
class _PlayTab extends StatefulWidget {
  final List<_CardData> deck;
  final int index;
  final bool finished;
  final int know, dontKnow;
  final VoidCallback onRestart;
  final void Function(bool) onAnswer;
  final TextTheme textTheme;

  const _PlayTab({
    super.key,
    required this.deck,
    required this.index,
    required this.finished,
    required this.know,
    required this.dontKnow,
    required this.onRestart,
    required this.onAnswer,
    required this.textTheme,
  });

  @override
  State<_PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<_PlayTab> {
  // Sem AnimationController, sem mixin, sem Transform 3D.
  // Apenas estado booleano — reveal via AnimatedSize (widget nativo Flutter).
  bool _revealed = false;

  void _reveal() {
    if (!_revealed) setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final index = widget.index;
    print('[PlayTab] build — deck.length=${deck.length} index=$index finished=${widget.finished} revealed=$_revealed');

    if (deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.style_rounded, size: 64, color: Color(0xFFB0B3CC)),
            const SizedBox(height: 16),
            Text('No cards yet!',
              style: widget.textTheme.titleMedium?.copyWith(
                color: AppColors.navyBlue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap + to add your first card.',
              style: widget.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF767AA8))),
          ],
        ),
      );
    }

    if (widget.finished) {
      return _ResultView(
        know: widget.know,
        dontKnow: widget.dontKnow,
        total: deck.length,
        onRestart: widget.onRestart,
        textTheme: widget.textTheme,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Hint ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _revealed ? 'How well did you know it?' : 'Tap the card to reveal the answer',
                  style: widget.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF9EA3C8)),
                ),
                if (deck[index].isCustom) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('My card',
                      style: widget.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF6A1B9A),
                        fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),

          // ── Flashcard unificado — reveal via AnimatedSize ────────────────────────────
          // Sem flip 3D, sem Transform, sem AnimationController.
          // AnimatedSize é um widget interno do Flutter: funciona em debug e release idênticos.
          _FlashCard(
            card: deck[index],
            revealed: _revealed,
            onTap: _reveal,
            textTheme: widget.textTheme,
          ),

          const SizedBox(height: 24),

          // ── Botões (aparecem após revelar) ───────────────────────────
          AnimatedOpacity(
            opacity: _revealed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AnswerButton(
                  label: "Don't know",
                  icon: Icons.close_rounded,
                  color: AppColors.red,
                  onTap: _revealed ? () => widget.onAnswer(false) : null,
                ),
                const SizedBox(width: 16),
                _AnswerButton(
                  label: 'I know it!',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF43A047),
                  onTap: _revealed ? () => widget.onAnswer(true) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─── My Cards Tab ─────────────────────────────────────────────────────────────
class _MyCardsTab extends StatelessWidget {
  final List<_CardData> customCards;
  final void Function(int) onDelete;
  final VoidCallback onAdd;
  final TextTheme textTheme;

  const _MyCardsTab({
    required this.customCards, required this.onDelete,
    required this.onAdd, required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (customCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmarks_outlined, size: 64, color: Color(0xFFB0B3CC)),
              const SizedBox(height: 16),
              Text("You haven't added any cards yet.",
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.navyBlue, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tap + to create your first custom flashcard.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: const Color(0xFF767AA8), height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Text('${customCards.length} card${customCards.length == 1 ? '' : 's'} created',
                style: textTheme.bodySmall?.copyWith(color: const Color(0xFF767AA8))),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: AppColors.navyBlue),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: customCards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final card = customCards[i];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x101A2150), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.style_rounded, color: Color(0xFF6A1B9A), size: 22),
                  ),
                  title: Text(card.word,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
                  subtitle: Text(card.definition,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: const Color(0xFF767AA8))),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete card?'),
                          content: Text('Remove "${card.word}" from your cards?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: AppColors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) onDelete(i);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Form Field helper ────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.navyBlue, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF767AA8), fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFB0B3CC), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8EAF6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// ─── Flashcard unificado — reveal via AnimatedSize ────────────────────────────
// Sem flip 3D, sem Transform, sem AnimationController.
// AnimatedSize é um widget interno do Flutter: funciona em debug e release idênticos.
class _FlashCard extends StatelessWidget {
  final _CardData card;
  final bool revealed;
  final VoidCallback onTap;
  final TextTheme textTheme;

  const _FlashCard({
    super.key,
    required this.card,
    required this.revealed,
    required this.onTap,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isCustom = card.isCustom;
    print('[FlashCard] build — word="${card.word}" revealed=$revealed isCustom=$isCustom');
    final gradient = isCustom
        ? const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isCustom
                  ? const Color(0xFF6A1B9A)
                  : const Color(0xFF1A2150)).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(right: -30, top: -30,
                child: Container(width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)))),
              Positioned(left: -20, bottom: -20,
                child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04)))),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Palavra (sempre visível) ────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, revealed ? 16 : 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(card.type,
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white70, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 14),
                        Text(card.word,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                        if (!revealed) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.touch_app_rounded,
                                color: Colors.white38, size: 16),
                              const SizedBox(width: 4),
                              Text('tap to reveal',
                                style: textTheme.labelSmall
                                    ?.copyWith(color: Colors.white38)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Definição desce com AnimatedSize ────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    child: revealed
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    width: 3, height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.white70,
                                      borderRadius: BorderRadius.circular(2))),
                                  const SizedBox(width: 8),
                                  Text('Definition',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4)),
                                ]),
                                const SizedBox(height: 8),
                                Text(card.definition,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white, height: 1.5)),
                                if (card.example.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text('"${card.example}"',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white60,
                                      fontStyle: FontStyle.italic,
                                      height: 1.4)),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox(width: double.infinity, height: 0),
                  ),
                ],
              ),
            ],
          ),
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

  const _AnswerButton({required this.label, required this.icon, required this.color, this.onTap});

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
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
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

  const _ScorePill({required this.icon, required this.color, required this.count, required this.label});

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
          Text('$count $label',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Resultado final ──────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final int know, dontKnow, total;
  final VoidCallback onRestart;
  final TextTheme textTheme;

  const _ResultView({
    required this.know, required this.dontKnow, required this.total,
    required this.onRestart, required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (know / total * 100).round();
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
          Text(msg,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.navyBlue),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x101A2150), blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                Text('$pct%',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: pct >= 80
                        ? const Color(0xFF43A047)
                        : pct >= 50 ? const Color(0xFFF9A825) : AppColors.red)),
                Text('score', style: textTheme.bodySmall?.copyWith(color: const Color(0xFF767AA8))),
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
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2150), Color(0xFF3D4FA0)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x441A2150), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: ElevatedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Play Again',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
  final String value, label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF767AA8))),
      ],
    );
  }
}

