import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'app_theme.dart';

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
        'Inglês americano clássico. Programas de entrevistas, documentários e notícias com fala clara e fluente. Ideal para todos os níveis.',
    url: 'https://npr-ice.streamguys1.com/live.mp3',
    accentColor: Color(0xFF1565C0),
  ),
  _RadioStation(
    flag: '🇬🇧',
    country: 'Reino Unido',
    name: 'BBC World Service',
    description:
        'O sotaque britânico mais famoso do mundo. Cobertura global de notícias, debates e cultura. Perfeito para treinar o inglês formal britânico.',
    url: 'http://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
    accentColor: Color(0xFFC62828),
  ),
  _RadioStation(
    flag: '🇨🇦',
    country: 'Canadá',
    name: 'CKNW 980 – News Talk Vancouver',
    description:
        'Uma das maiores rádios de notícias e debates do Canadá. Inglês canadense autêntico com entrevistas, política e cultura. Transmitido via LeanStream (plataforma oficial canadense).',
    url: 'https://live.leanstream.co/CKNWAM-MP3',
    accentColor: Color(0xFFB71C1C),
  ),
  _RadioStation(
    flag: '🇦🇺',
    country: 'Austrália',
    name: 'ABC News Radio',
    description:
        'O sotaque "Aussie" com sua entonação única e vogais características. Ótimo desafio para alunos intermediários e avançados.',
    url: 'http://live-radio01.mediahubaustralia.com/PBW/mp3/',
    accentColor: Color(0xFF1B5E20),
  ),
  _RadioStation(
    flag: '🇮🇪',
    country: 'Irlanda',
    name: 'RTÉ Radio 1',
    description:
        'O rico sotaque irlandês com sua musicalidade própria. Debates sociais, artes e cultura que fogem completamente do padrão americano.',
    url: 'https://icecast2.rte.ie/radio1',
    accentColor: Color(0xFF2E7D32),
  ),
  _RadioStation(
    flag: '🇳🇿',
    country: 'Nova Zelândia',
    name: 'RNZ National – Radio New Zealand',
    description:
        'O sotaque "Kiwi" autêntico da rádio pública oficial da Nova Zelândia. Notícias, entrevistas e programas culturais com a pronúncia neozelandesa característica.',
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
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(int index) async {
    // Se já está tocando a mesma estação → pausa
    if (_playingIndex == index && _player.playing) {
      await _player.pause();
      setState(() {});
      return;
    }

    // Se retomando a mesma estação já carregada → play
    if (_playingIndex == index && !_player.playing) {
      await _player.play();
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
      await _player.play();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Não foi possível conectar à rádio. Verifique a internet.';
        _playingIndex = null;
      });
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

