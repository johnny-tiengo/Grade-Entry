class Usuario {
  int? id;
  String login;
  String senha;
  String nome;
  String perfil; // Admin, Assistente, Supervisor, Almoxarife
  int? equipe;

  Usuario({
    this.id,
    required this.login,
    required this.senha,
    required this.nome,
    required this.perfil,
    required this.equipe,
  });

  @override
  String toString() {
    String idStr = id != null ? "[$id] " : "";
    return "${idStr}Login: $login | Nome: $nome | Cargo/Perfil: $perfil";
  }
}
