import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'app_theme.dart';
import 'services/media_session_service.dart';

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
  final AudioPlayer _player = AudioPlayer();
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

      final originalUrl = _stations[index].url;
      // Adiciona o proxy de CORS apenas na Web
      final safeUrl = kIsWeb
          ? 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}'
          : originalUrl;

      await _player.setUrl(safeUrl);

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
      _player.playerStateStream
          .firstWhere((s) => s.playing)
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
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        body: Column(
          children: [
            // ── Header
            _buildHeader(context),

            // ── Mini player (visível apenas quando tocando)
            if (_playingIndex != null) _buildMiniPlayer(textTheme),

            // ── Lista de rádios
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: _stations.length,
                itemBuilder: (context, i) =>
                    _StationCard(
                      station: _stations[i],
                      isPlaying: _playingIndex == i && _player.playing,
                      isLoading: _isLoading && _playingIndex == i,
                      onTap: () => _toggle(i),
                      textTheme: textTheme,
                    ),
              ),
            ),

            // ── Mensagem de erro
            if (_errorMessage != null)
              Container(
                color: AppColors.red,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            textTheme.bodySmall?.copyWith(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _errorMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2150), Color(0xFF2B3A7A), Color(0xFF47569C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x441A2150), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // Titulo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.headphones_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Praticar Listening',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '6 rádios ao vivo · 6 países',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white60,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(TextTheme textTheme) {
    final station = _stations[_playingIndex!];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [station.accentColor, station.accentColor.withValues(alpha: 0.7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: station.accentColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(station.flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AO VIVO',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  station.name,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : StreamBuilder<PlayerState>(
                  stream: _player.playerStateStream,
                  builder: (context, snap) {
                    final playing = snap.data?.playing ?? false;
                    return IconButton(
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: () => _toggle(_playingIndex!),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de cada estação de rádio
// ─────────────────────────────────────────────────────────────────────────────
class _StationCard extends StatelessWidget {
  final _RadioStation station;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final TextTheme textTheme;

  const _StationCard({
    required this.station,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isPlaying
            ? Border.all(color: station.accentColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isPlaying
                ? station.accentColor.withValues(alpha: 0.18)
                : const Color(0x141A2150),
            blurRadius: isPlaying ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bandeira + botão play
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: station.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(station.flag,
                            style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                    if (isPlaying || isLoading)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: station.accentColor.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.pause_rounded,
                                  color: Colors.white, size: 26),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // País + badge AO VIVO
                      Row(
                        children: [
                          Text(
                            station.country,
                            style: textTheme.labelSmall?.copyWith(
                              color: station.accentColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          if (isPlaying)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: station.accentColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.circle,
                                      size: 7, color: Colors.white),
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
                      const SizedBox(height: 3),
                      // Nome da rádio
                      Text(
                        station.name,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyBlue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Descrição
                      Text(
                        station.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF767AA8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Botão
                      Row(
                        children: [
                          Icon(
                            isPlaying
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_outline_rounded,
                            size: 16,
                            color: station.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLoading
                                ? 'Conectando...'
                                : isPlaying
                                    ? 'Pausar rádio'
                                    : 'Ouvir ao vivo',
                            style: textTheme.labelSmall?.copyWith(
                              color: station.accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

