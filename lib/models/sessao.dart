import 'package:grade_entry/models/usuario.dart';

/// Mínimo que os menus precisam saber de quem logou.
enum Perfil { assistente, supervisor, almoxarife, admin }

class Sessao {
  final int usuarioId;
  final String username;
  final Perfil perfil;
  final int? equipe;

  const Sessao({
    required this.usuarioId,
    required this.username,
    required this.perfil,
    required this.equipe,
  });

  /// Converte um [Usuario] autenticado no banco em uma [Sessao] tipada.
  factory Sessao.fromUsuario(Usuario u) {
    final perfilNormalizado = switch (u.perfil.trim().toLowerCase()) {
      'admin' => Perfil.admin,
      'supervisor' => Perfil.supervisor,
      'almoxarife' => Perfil.almoxarife,
      _ => Perfil.assistente,
    };
    return Sessao(
      usuarioId: u.id ?? 0,
      username: u.nome,
      perfil: perfilNormalizado,
      equipe: u.equipe,
    );
  }

  bool get ehAdmin => perfil == Perfil.admin;
  bool get ehAssistente => perfil == Perfil.assistente;
  bool get ehSupervisor => perfil == Perfil.supervisor;
  bool get ehAlmoxarife => perfil == Perfil.almoxarife;

  /// Retorna o nome do perfil com inicial maiúscula para gravar no banco (ex.: 'Assistente').
  String get nomePerfil => switch (perfil) {
        Perfil.admin => 'Admin',
        Perfil.assistente => 'Assistente',
        Perfil.supervisor => 'Supervisor',
        Perfil.almoxarife => 'Almoxarife',
      };
}
