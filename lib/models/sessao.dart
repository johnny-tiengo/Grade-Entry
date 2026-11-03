/// Mínimo que os menus precisam saber de quem logou.
/// O login (auth_service.dart) só precisa criar uma Sessao depois de autenticar.
/// Se vocês já tiverem um model de usuário, pode apagar este arquivo e
/// adaptar os 3 getters abaixo.
enum Perfil { admin, assistente, supervisor, almoxarife }

class Sessao {
  final int usuarioId;
  final String username;
  final Perfil perfil;
  const Sessao({required this.usuarioId, required this.username, required this.perfil});

  bool get ehAdmin => perfil == Perfil.admin;
  bool get ehAssistente => perfil == Perfil.assistente;
  bool get ehSupervisor => perfil == Perfil.supervisor;
  bool get ehAlmoxarife => perfil == Perfil.almoxarife;
}
