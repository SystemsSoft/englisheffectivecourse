import 'package:shared_preferences/shared_preferences.dart';

/// Persiste localmente o userId (ULID) do aluno na Megan, associado ao
/// e-mail de login — assim, ao reabrir o app, reutilizamos o mesmo cadastro
/// em vez de criar um novo a cada vez.
class MeganUserIdStore {
  static String _key(String email) => 'megan_user_id_$email';

  Future<String?> getUserId(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(email));
  }

  Future<void> saveUserId(String email, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(email), userId);
  }
}
