import 'dart:io';
import '../models/usuario.dart';
import '../repositories/usuario_dao.dart';

// autenticar(usuario, senha)
// validarPermissao(usuario, acaoDesejada):
// Garante que apenas Assistentes/Admin cadastrem,
// Almoxarife apenas consulte liberações e
// Supervisor acesse relatórios.

class AuthService {
  static final UsuarioDao _usuarioDao = UsuarioDao();
  // // Usuários de contingência em memória caso o banco esteja indisponível
  // static final List<Usuario> usuariosPadrao = [
  //   Usuario(
  //     id: 1,
  //     login: 'admin',
  //     senha: '123',
  //     nome: 'Administrador',
  //     perfil: 'Admin',
  //   ),
  //   Usuario(
  //     id: 2,
  //     login: 'assistente',
  //     senha: '123',
  //     nome: 'Assistente Logística',
  //     perfil: 'Assistente',
  //   ),
  //   Usuario(
  //     id: 3,
  //     login: 'supervisor',
  //     senha: '123',
  //     nome: 'Supervisor Logística',
  //     perfil: 'Supervisor',
  //   ),
  //   Usuario(
  //     id: 4,
  //     login: 'almoxarife',
  //     senha: '123',
  //     nome: 'Almoxarife',
  //     perfil: 'Almoxarife',
  //   ),
  // ];

  static Usuario? usuarioLogado;
  /// Autentica o usuário pelo banco de dados (com contingência em memória)
  static Future<Usuario?> autenticar(String login, String senha) async {
    // 1. Tenta autenticar pelo banco de dados MySQL
    try {
      var usuarioBanco = await _usuarioDao.autenticar(login, senha);
      if (usuarioBanco != null) {
        return usuarioBanco;
      }
    } catch (_) {
      // Ignora erro e tenta contingência
    }

    // // 2. Se não encontrou no banco ou o banco falhou, tenta os usuários locais
    // try {
    //   return usuariosPadrao.firstWhere(
    //     (u) =>
    //         u.login.trim().toLowerCase() == login.trim().toLowerCase() &&
    //         u.senha == senha.trim(),
    //   );
    // } catch (_) {
    //   return null;
    // }
  }

  /// Exibe a tela de login simples no terminal
  static Future<Usuario?> realizarLoginTerminal({int maxTentativas = 3}) async {
    // Garante que a tabela exista e esteja populada no banco
    // await _usuarioDao.inicializarTabela();

    int tentativas = maxTentativas;

    print("=========================================");
    print("       SISTEMA DE CADASTRO DE NFs        ");
    print("           ACESSO AO SISTEMA             ");
    print("=========================================");

    while (tentativas > 0) {
      stdout.write("Usuário: ");
      String login = stdin.readLineSync() ?? "";

      stdout.write("Senha: ");
      String senha = stdin.readLineSync() ?? "";

      var usuario = await autenticar(login, senha);

      if (usuario != null) {
        usuarioLogado = usuario;
        print("\n[OK] Login realizado com sucesso!");
        print("Bem-vindo(a), ${usuario.nome}!\n");
        return usuario;
      } else {
        tentativas--;
        print("\n[!] Usuário ou senha incorretos.");
        if (tentativas > 0) {
          print("Você ainda tem $tentativas tentativa(s).\n");
        } else {
          print("Limite de tentativas excedido!\n");
        }
      }
    }

    return null;
  }

  /// Menu administrativo para gerenciamento de usuários (apenas Admin)
  static Future<void> menuGerenciarUsuarios() async {
    bool gerenciando = true;

    while (gerenciando) {
      print("\n=========================================");
      print("      GERENCIAMENTO DE USUÁRIOS [ADMIN]  ");
      print("=========================================");
      print("1. Cadastrar Novo Usuário");
      print("2. Listar Usuários Cadastrados");
      print("3. Alterar Cargo / Perfil de Usuário");
      print("4. Excluir Usuário");
      print("0. Voltar ao Menu Principal");
      stdout.write("Escolha uma opção: ");

      String? opcao = stdin.readLineSync();

      switch (opcao) {
        case '1':
          await _cadastrarUsuario();
          break;

        case '2':
          await _listarUsuarios();
          break;

        case '3':
          await _alterarCargoUsuario();
          break;

        case '4':
          await _excluirUsuario();
          break;

        case '0':
          gerenciando = false;
          print("Retornando ao menu principal...");
          break;

        default:
          print("Opção inválida! Tente novamente.");
      }
    }
  }

  /// Cadastra um novo usuário no banco de dados
  static Future<void> _cadastrarUsuario() async {
    print("\n--- NOVO CADASTRO DE USUÁRIO ---");
    stdout.write("Nome completo: ");
    String nome = (stdin.readLineSync() ?? "").trim();

    stdout.write("Login (nome de usuário para acesso): ");
    String login = (stdin.readLineSync() ?? "").trim();

    stdout.write("Senha: ");
    String senha = (stdin.readLineSync() ?? "").trim();

    stdout.write("Senha: ");
    int? equipe = int.tryParse(stdin.readLineSync().toString());

    if (nome.isEmpty || login.isEmpty || senha.isEmpty) {
      print("[!] Erro: Nome, login e senha são obrigatórios!");
      return;
    }

    print("\nEscolha o Cargo/Perfil:");
    print("1. Admin");
    print("2. Assistente");
    print("3. Supervisor");
    print("4. Almoxarife");
    stdout.write("Opção: ");
    String perfilOpcao = stdin.readLineSync() ?? "";

    String perfil;
    switch (perfilOpcao.trim()) {
      case '1':
        perfil = 'Admin';
        break;
      case '2':
        perfil = 'Assistente';
        break;
      case '3':
        perfil = 'Supervisor';
        break;
      case '4':
        perfil = 'Almoxarife';
        break;
      default:
        print("[!] Opção inválida de perfil. Operação cancelada.");
        return;
    }

    var novoUsuario = Usuario(
      nome: nome,
      login: login,
      senha: senha,
      perfil: perfil,
      equipe: equipe,
    );

    print("Salvando usuário no banco de dados...");
    bool sucesso = await _usuarioDao.salvar(novoUsuario);

    if (sucesso) {
      print("[OK] Usuário '$login' cadastrado com sucesso!");
    } else {
      print("[ERRO] Falha ao cadastrar usuário. Verifique se o login já existe.");
    }
  }

  /// Lista todos os usuários do banco de dados
  static Future<void> _listarUsuarios() async {
    print("\n--- LISTA DE USUÁRIOS NO BANCO DE DADOS ---");
    var lista = await _usuarioDao.buscarTodos();

    if (lista.isEmpty) {
      print("Nenhum usuário encontrado no banco de dados");
    }
  }

  /// Altera o cargo de um usuário existente
  static Future<void> _alterarCargoUsuario() async {
    print("\n--- ALTERAR CARGO / PERFIL ---");
    stdout.write("Digite o ID do usuário que deseja alterar: ");
    String? idStr = stdin.readLineSync();
    int? id = int.tryParse(idStr ?? "");

    if (id == null) {
      print("[!] ID inválido!");
      return;
    }

    var usuario = await _usuarioDao.buscarPorId(id);
    if (usuario == null) {
      print("[!] Usuário não encontrado no banco com o ID $id.");
      return;
    }

    print("Usuário selecionado: ${usuario.nome} | Cargo atual: ${usuario.perfil}");
    print("\nSelecione o novo cargo:");
    print("1. Admin");
    print("2. Assistente");
    print("3. Supervisor");
    print("4. Almoxarife");
    stdout.write("Opção: ");
    String cargoOpcao = stdin.readLineSync() ?? "";

    String novoCargo;
    switch (cargoOpcao.trim()) {
      case '1':
        novoCargo = 'Admin';
        break;
      case '2':
        novoCargo = 'Assistente';
        break;
      case '3':
        novoCargo = 'Supervisor';
        break;
      case '4':
        novoCargo = 'Almoxarife';
        break;
      default:
        print("[!] Opção inválida. Nenhuma alteração realizada.");
        return;
    }

    bool sucesso = await _usuarioDao.atualizarCargo(id, novoCargo);
    if (sucesso) {
      print("[OK] Cargo de '${usuario.nome}' alterado com sucesso para '$novoCargo'!");
    } else {
      print("[ERRO] Falha ao atualizar cargo no banco de dados.");
    }
  }

  /// Exclui um usuário do banco
  static Future<void> _excluirUsuario() async {
    print("\n--- EXCLUIR USUÁRIO ---");
    stdout.write("Digite o ID do usuário que deseja excluir: ");
    String? idStr = stdin.readLineSync();
    int? id = int.tryParse(idStr ?? "");

    if (id == null) {
      print("[!] ID inválido!");
      return;
    }

    if (usuarioLogado?.id == id) {
      print("[!] Você não pode excluir a sua própria conta logada no momento!");
      return;
    }

    stdout.write("Tem certeza que deseja excluir o usuário ID $id? [1] SIM / [2] NÃO: ");
    String confirm = stdin.readLineSync() ?? "";
    if (confirm.trim() != '1') {
      print("Operação cancelada.");
      return;
    }

    bool sucesso = await _usuarioDao.apagar(id);
    if (sucesso) {
      print("[OK] Usuário ID $id excluído com sucesso!");
    } else {
      print("[ERRO] Falha ao excluir usuário no banco.");
    }
  }

  /// Garante permissões de acordo com o perfil
  static bool validarPermissao(String acaoDesejada) {
    if (usuarioLogado == null) return false;
    if (usuarioLogado!.perfil.toLowerCase() == 'admin') return true;

    switch (acaoDesejada) {
      case 'cadastrar':
      case 'atualizar':
      case 'excluir':
        return usuarioLogado!.perfil.toLowerCase() == 'assistente';
      case 'consultar':
        return usuarioLogado!.perfil.toLowerCase() == 'assistente' ||
            usuarioLogado!.perfil.toLowerCase() == 'almoxarife' ||
            usuarioLogado!.perfil.toLowerCase() == 'supervisor';
      case 'relatorios':
      case 'csv':
        return usuarioLogado!.perfil.toLowerCase() == 'supervisor';
      default:
        return false;
    }
  }

  /// Encerra a sessão
  static void deslogar() {
    usuarioLogado = null;
  }
}

// Mantém compatibilidade com a classe Login caso necessário
typedef Login = AuthService;
