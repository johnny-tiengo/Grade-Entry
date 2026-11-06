import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/models/usuario.dart';
import 'package:grade_entry/repositories/base_dao.dart';

class UsuarioDao extends BaseDao<Usuario> {
  @override
  String get tabela => 'usuario';

  @override
  String get colunaId => 'id';

  @override
  Usuario mapear(ResultSetRow row) {
    return Usuario(
      id: lerInt(row, 'id'),
      nome: lerTexto(row, 'nome'),
      login: lerTexto(row, 'login'),
      senha: lerTexto(row, 'senha'),
      perfil: lerTexto(row, 'perfil'),
      equipe: lerInt(row, 'equipe'),
    );
  }

  @override
  Map<String, dynamic> paraMapa(Usuario usuario) => {
        'nome': usuario.nome.trim(),
        'login': usuario.login.trim().toLowerCase(),
        'senha': usuario.senha.trim(),
        'perfil': usuario.perfil.trim(),
        'equipe': usuario.equipe,
      };

  /// Autentica um usuário no banco de dados MySQL reutilizando [consultar].
  Future<Usuario?> autenticar(String login, String senha) async {
    final r = await consultar(
      'SELECT * FROM $tabela WHERE LOWER(login) = :login AND senha = :senha LIMIT 1;',
      {
        'login': login.trim().toLowerCase(),
        'senha': senha.trim(),
      },
    );
    return r.isEmpty ? null : r.first;
  }

  /// Atualiza o cargo/perfil de um usuário reutilizando [atualizar] de [BaseDao].
  Future<bool> atualizarCargo(int id, String novoPerfil) =>
      atualizar(id, 'perfil', novoPerfil);
}
