import '../models/aluno_ia_model.dart';
import '../models/user_model.dart';
import '../utils/ulid.dart';
import 'aluno_ia_service.dart';
import 'megan_user_id_store.dart';

/// Resolve o userId (ULID) do aluno na Megan e garante que o cadastro
/// exista no backend — usado tanto pela tela de chamada quanto pela tela
/// de perfil, para não duplicar essa lógica.
class MeganUserResolver {
  MeganUserResolver({
    AlunoIaService? alunoIaService,
    MeganUserIdStore? userIdStore,
  })  : _alunoIaService = alunoIaService ?? AlunoIaService(),
        _userIdStore = userIdStore ?? MeganUserIdStore();

  final AlunoIaService _alunoIaService;
  final MeganUserIdStore _userIdStore;

  /// Prioridade: ulid já vindo do login > ulid salvo localmente > gera um
  /// novo e cria o cadastro automaticamente no backend.
  Future<(String userId, AlunoIaDto aluno)> resolve(User user) async {
    var userId = (user.ulid != null && user.ulid!.isNotEmpty)
        ? user.ulid
        : await _userIdStore.getUserId(user.email);

    AlunoIaDto? aluno;
    if (userId != null) {
      aluno = await _alunoIaService.getAluno(userId);
    }

    if (aluno == null) {
      userId ??= Ulid.generate();
      aluno = await _alunoIaService.criarAluno(AlunoIaDto(
        userId: userId,
        nome: user.name,
        email: user.email,
        stripeCustomerId: '',
        planoAtivo: '',
        moduloAtual: 'module1',
        missaoAtual: '1',
        ultimaSessao: '',
      ));
      await _userIdStore.saveUserId(user.email, userId);
    }

    return (userId!, aluno);
  }
}
