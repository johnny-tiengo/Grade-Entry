/// Mínimo que os menus precisam saber de quem logou.
/// O login (auth_service.dart) só precisa criar uma Sessao depois de autenticar.
/// Se vocês já tiverem um model de usuário, pode apagar este arquivo e
/// adaptar os 3 getters abaixo.
enum Perfil { assistente, supervisor, almoxarife, admin, visitante }

class Sessao {
  final int usuarioId;
  final String username;
  final String perfil;
  final int? equipe;
  const Sessao({
    required this.usuarioId,
    required this.username,
    required this.perfil,
    required this.equipe,
  });

  bool get ehAdmin => perfil == Perfil.admin;
  bool get ehAssistente => perfil == Perfil.assistente;
  bool get ehSupervisor => perfil == Perfil.supervisor;
  bool get ehAlmoxarife => perfil == Perfil.almoxarife;
  bool get ehVisitante => perfil == Perfil.visitante;

}
