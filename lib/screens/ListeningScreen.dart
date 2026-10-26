import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:audio_session/audio_session.dart';
import '../app_theme.dart';
import '../widgets/ui_kit.dart';
import '../services/media_session_service.dart';
import '../services/radio_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de Rádio
// ─────────────────────────────────────────────────────────────────────────────
class _RadioStation {
  final String flag;
  final String country;
  final String name;
  final String description;
  final String url;
  final Color accentColor;

  const _RadioStation({
    required this.flag,
    required this.country,
    required this.name,
    required this.description,
    required this.url,
    required this.accentColor,
  });
}

const _stations = [
  _RadioStation(
    flag: '🇺🇸',
    country: 'Estados Unidos',
    name: 'NPR – National Public Radio',
    description:
        '🎙️ Curiosidade: O sotaque americano padrão (General American) é o mais ensinado no mundo por ser neutro e claro. Repare na pronúncia do "R" forte no final das palavras (ex: "car", "water"). Você encontrará entrevistas, documentários e notícias com fala precisa — ideal para iniciantes e intermediários.',
    url: 'https://npr-ice.streamguys1.com/live.mp3',
    accentColor: Color(0xFF1565C0),
  ),
  _RadioStation(
    flag: '🇬🇧',
    country: 'Reino Unido',
    name: 'BBC World Service',
    description:
        '🎙️ Curiosidade: O sotaque britânico RP (Received Pronunciation) é famoso por "engolir" o R no meio das palavras — "car" vira "cah". Também usam vocabulário único: "lift" (elevador), "flat" (apartamento), "lorry" (caminhão). Excelente para treinar inglês formal e expandir vocabulário.',
    url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
    accentColor: Color(0xFFC62828),
  ),
  _RadioStation(
    flag: '🇨🇦',
    country: 'Canadá',
    name: 'CKNW 980 – News Talk Vancouver',
    description:
        '🎙️ Curiosidade: O canadense tem o fenômeno chamado "Canadian Raising" — as vogais em palavras como "about" e "house" soam diferente do americano, quase como "aboot". Fora isso, misturam vocabulário britânico e americano. Ótimo para distinguir sutilezas do inglês norte-americano.',
    url: 'https://live.leanstream.co/CKNWAM-MP3',
    accentColor: Color(0xFFB71C1C),
  ),
  _RadioStation(
    flag: '🇦🇺',
    country: 'Austrália',
    name: 'ABC News Radio',
    description:
        '🎙️ Curiosidade: O australiano transforma vogais longas — "today" soa como "to-die", "mate" quase como "mite". Eles também adoram encurtar palavras: "afternoon" vira "arvo", "biscuit" vira "biccy". Um desafio real para o ouvido! Ideal para alunos que querem se preparar para situações do mundo real.',
    url: 'https://live-radio01.mediahubaustralia.com/PBW/mp3/',
    accentColor: Color(0xFF1B5E20),
  ),
  _RadioStation(
    flag: '🇮🇪',
    country: 'Irlanda',
    name: 'RTÉ Radio 1',
    description:
        '🎙️ Curiosidade: O irlandês tem uma musicalidade única herdada do gaélico — a entonação sobe e desce diferente de qualquer outro sotaque. Palavras como "film" podem soar como "fillum" e o "th" às vezes vira "t" ou "d". Você encontrará debates culturais, humor e uma riqueza de expressões idiomáticas típicas da ilha.',
    url: 'https://icecast2.rte.ie/radio1',
    accentColor: Color(0xFF2E7D32),
  ),
  _RadioStation(
    flag: '🇳🇿',
    country: 'Nova Zelândia',
    name: 'RNZ National – Radio New Zealand',
    description:
        '🎙️ Curiosidade: O sotaque neozelandês (Kiwi) é famoso por transformar a vogal "i" curta em algo parecido com "u" — "fish and chips" soa como "fush and chups". Também é o sotaque mais próximo do britânico fora do Reino Unido. Você encontrará programas sobre cultura Māori, natureza e entrevistas com sotaque autêntico.',
    url: 'https://radionz.streamguys1.com/national/national/national/national-mainstream/chunks.m3u8',
    accentColor: Color(0xFF4A148C),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Tela principal de Listening
// ─────────────────────────────────────────────────────────────────────────────
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final RadioPlayer _player = RadioPlayer();
  int? _playingIndex;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    // Configura a sessão de áudio para continuar em segundo plano
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  @override
  void dispose() {
    clearMediaSession();
    _player.dispose();
    super.dispose();
  }

  void _updateLockScreenControls(int index) {
    final station = _stations[index];
    updateMediaSession(station.name, station.country);

    // Registra ações de play/pause da tela de bloqueio
    setMediaActionHandler('play', () {
      _player.play();
      setMediaPlaybackState('playing');
      if (mounted) setState(() {});
    });
    setMediaActionHandler('pause', () {
      _player.pause();
      setMediaPlaybackState('paused');
      if (mounted) setState(() {});
    });
    setMediaActionHandler('stop', () {
      _player.stop();
      clearMediaSession();
      if (mounted) setState(() { _playingIndex = null; });
    });
  }

  Future<void> _toggle(int index) async {
    // Se já está tocando a mesma estação → pausa
    if (_playingIndex == index && _player.playing) {
      await _player.pause();
      setMediaPlaybackState('paused');
      setState(() {});
      return;
    }

    // Se retomando a mesma estação já carregada → play
    if (_playingIndex == index && !_player.playing) {
      await _player.play();
      setMediaPlaybackState('playing');
      setState(() {});
      return;
    }

    // Nova estação → carregar e tocar
    setState(() {
      _isLoading = true;
      _playingIndex = index;
      _errorMessage = null;
    });

    try {
      await _player.stop();

      await _player.setUrl(_stations[index].url);

      // Configura controles da tela de bloqueio antes de iniciar
      _updateLockScreenControls(index);

      // Inicia o play sem aguardar — deixa o stream monitorar
      _player.play().catchError((e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Não foi possível conectar à rádio. Verifique a internet.';
            _playingIndex = null;
          });
          clearMediaSession();
        }
      });

      // Remove o loading SOMENTE quando o player confirmar que está tocando
      _player.playingStream
          .firstWhere((playing) => playing)
          .timeout(const Duration(seconds: 25))
          .then((_) {
            if (mounted) {
              setState(() => _isLoading = false);
              setMediaPlaybackState('playing');
            }
          })
          .catchError((_) {
            // Timeout ou erro: esconde o loading mas mantém o player tentando
            if (mounted) setState(() => _isLoading = false);
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Não foi possível conectar à rádio. Verifique a internet.';
          _playingIndex = null;
        });
        clearMediaSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kPageBackground,
        extendBody: true,
        // ── Mini player flutuante (visível apenas com uma rádio selecionada)
        bottomNavigationBar: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: _playingIndex == null
              ? const SizedBox.shrink(key: ValueKey('none'))
              : _buildMiniPlayer(),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final hPadding = pagePadding(width);
            final columns = gridColumnsFor(width);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header
                SliverToBoxAdapter(
                  child: AppPageHeader(
                    title: 'Praticar Listening',
                    subtitle: '${_stations.length} rádios ao vivo · ${_stations.length} países',
                    icon: Icons.headphones_rounded,
                    bottom: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final s in _stations) _FlagChip(flag: s.flag)],
                    ),
                  ),
                ),

                // ── Mensagem de erro
                SliverToBoxAdapter(
                  child: ContentConstrained(
                    padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 0),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: _errorMessage == null
                          ? const SizedBox(width: double.infinity)
                          : _ErrorBanner(
                              message: _errorMessage!,
                              onClose: () => setState(() => _errorMessage = null),
                            ),
                    ),
                  ),
                ),

                // ── Título
                SliverToBoxAdapter(
                  child: ContentConstrained(
                    padding: EdgeInsets.fromLTRB(hPadding, 12, hPadding, 14),
                    child: const FadeSlideIn(
                      delay: Duration(milliseconds: 150),
                      child: SectionTitle(title: 'Escolha um sotaque', trailing: 'Toque para ouvir'),
                    ),
                  ),
                ),

                // ── Lista de rádios
                SliverToBoxAdapter(
                  child: ContentConstrained(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: ResponsiveGrid(
                      columns: columns,
                      children: [
                        for (var i = 0; i < _stations.length; i++)
                          FadeSlideIn(
                            delay: staggerDelay(i, baseMs: 200),
                            child: _StationCard(
                              station: _stations[i],
                              isPlaying: _playingIndex == i && _player.playing,
                              isLoading: _isLoading && _playingIndex == i,
                              onTap: () => _toggle(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Espaço para o mini player
                SliverToBoxAdapter(child: SizedBox(height: _playingIndex == null ? 32 : 120)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final station = _stations[_playingIndex!];
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      key: ValueKey(_playingIndex),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyBlue, AppColors.navyBlueLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: const [
                BoxShadow(color: Color(0x401A2150), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(station.flag, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _EqualizerBars(
                            active: !_isLoading && _player.playing,
                            color: AppColors.redLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isLoading ? 'CONECTANDO...' : 'AO VIVO',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        station.name,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : StreamBuilder<bool>(
                        stream: _player.playingStream,
                        builder: (context, snap) {
                          final playing = snap.data ?? _player.playing;
                          return PressableScale(
                            onTap: () => _toggle(_playingIndex!),
                            pressedScale: 0.85,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.red, AppColors.redLight],
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  key: ValueKey(playing),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bandeira em chip translúcido (header)
// ─────────────────────────────────────────────────────────────────────────────
class _FlagChip extends StatelessWidget {
  final String flag;

  const _FlagChip({required this.flag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 18)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Aviso de erro com botão de fechar
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded, color: AppColors.red, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barrinhas de equalizador animadas (indicam áudio tocando)
// ─────────────────────────────────────────────────────────────────────────────
class _EqualizerBars extends StatefulWidget {
  final bool active;
  final Color color;

  const _EqualizerBars({super.key, required this.active, required this.color});

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const phases = [0.0, 0.35, 0.7];
    return SizedBox(
      width: 14,
      height: 12,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final phase in phases)
              Container(
                width: 3,
                height: widget.active
                    ? 3 + 9 * (0.5 + 0.5 * _wave((_controller.value + phase) % 1))
                    : 3,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Onda triangular suave entre -1 e 1
  double _wave(double t) => t < 0.5 ? 4 * t - 1 : 3 - 4 * t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de cada estação de rádio
// ─────────────────────────────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  final _RadioStation station;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = isPlaying || isLoading;

    return AppCard(
      onTap: onTap,
      accent: station.accentColor,
      selected: active,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bandeira + estado de reprodução
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: active
                      ? station.accentColor
                      : station.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : isPlaying
                            ? const _EqualizerBars(
                                key: ValueKey('playing'),
                                active: true,
                                color: Colors.white,
                              )
                            : Text(
                                station.flag,
                                key: const ValueKey('flag'),
                                style: const TextStyle(fontSize: 32),
                              ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.country.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: station.accentColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPlaying)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: station.accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 7, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'AO VIVO',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Descrição
          Text(
            station.description,
            style: textTheme.bodySmall?.copyWith(color: kMutedColor, height: 1.5),
          ),
          const SizedBox(height: 14),

          // Ação
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: station.accentColor.withValues(alpha: active ? 0.14 : 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: station.accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isLoading
                      ? 'Conectando...'
                      : isPlaying
                          ? 'Pausar rádio'
                          : 'Ouvir ao vivo',
                  style: textTheme.labelMedium?.copyWith(
                    color: station.accentColor,
                    fontWeight: FontWeight.w700,
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
