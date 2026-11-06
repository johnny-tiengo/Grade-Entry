import 'package:grade_entry/models/usuario.dart';
import 'package:grade_entry/repositories/usuario_dao.dart';
import 'package:grade_entry/services/auth_service.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuUsuario extends ConsoleUI {
  final UsuarioDao _usuarioDao;

  MenuUsuario([UsuarioDao? dao]) : _usuarioDao = dao ?? UsuarioDao();

  @override
  String get titulo => 'GERENCIAMENTO DE USUÁRIOS [ADMIN]';

  @override
  List<OpcaoMenu> get opcoes => [
        OpcaoMenu('1', 'Cadastrar Novo Usuário', _cadastrarUsuario),
        OpcaoMenu('2', 'Listar Usuários Cadastrados', _listarUsuarios),
        OpcaoMenu('3', 'Alterar Cargo / Perfil de Usuário', _alterarCargoUsuario),
        OpcaoMenu('4', 'Excluir Usuário', _excluirUsuario),
      ];

  /// Método único para escolha de Cargo/Perfil (evita duplicação no cadastro e edição).
  String? _escolherPerfil() {
    print('\nEscolha o Cargo/Perfil:');
    print('1. Admin');
    print('2. Assistente');
    print('3. Supervisor');
    print('4. Almoxarife');
    final opcao = lerTexto('Opção');
    return switch (opcao) {
      '1' => 'Admin',
      '2' => 'Assistente',
      '3' => 'Supervisor',
      '4' => 'Almoxarife',
      _ => null,
    };
  }

  Future<void> _cadastrarUsuario() async {
    print('\n--- NOVO CADASTRO DE USUÁRIO ---');
    final nome = lerTexto('Nome completo');
    final login = lerTexto('Login (nome de usuário para acesso)');
    final senha = lerTexto('Senha');
    final equipe = lerIntOpcional('Equipe (ID - opcional)');

    final perfil = _escolherPerfil();
    if (perfil == null) {
      print('[!] Opção inválida de perfil. Operação cancelada.');
      return;
    }

    final novoUsuario = Usuario(
      nome: nome,
      login: login,
      senha: senha,
      perfil: perfil,
      equipe: equipe,
    );

    print('Salvando usuário no banco de dados...');
    final sucesso = await _usuarioDao.salvar(novoUsuario);
    if (sucesso) {
      print("[OK] Usuário '$login' cadastrado com sucesso!");
    } else {
      print('[ERRO] Falha ao cadastrar usuário. Verifique se o login já existe.');
    }
  }

  Future<void> _listarUsuarios() async {
    clearTerminal();
    print('\n--- LISTA DE USUÁRIOS NO BANCO DE DADOS ---');
    final lista = await _usuarioDao.buscarTodos();
    if (lista.isEmpty) {
      print('Nenhum usuário encontrado no banco de dados.');
      return;
    }
    lista.forEach(print);
  }

  Future<void> _alterarCargoUsuario() async {
    print('\n--- ALTERAR CARGO / PERFIL ---');
    final id = lerInt('Digite o ID do usuário que deseja alterar');
    final usuario = await _usuarioDao.buscarPorId(id);
    if (usuario == null) {
      print('[!] Usuário não encontrado no banco com o ID $id.');
      return;
    }

    print('Usuário selecionado: ${usuario.nome} | Cargo atual: ${usuario.perfil}');
    final novoCargo = _escolherPerfil();
    if (novoCargo == null) {
      print('[!] Opção inválida. Nenhuma alteração realizada.');
      return;
    }

    final sucesso = await _usuarioDao.atualizarCargo(id, novoCargo);
    if (sucesso) {
      print("[OK] Cargo de '${usuario.nome}' alterado com sucesso para '$novoCargo'!");
    } else {
      print('[ERRO] Falha ao atualizar cargo no banco de dados.');
    }
  }

  Future<void> _excluirUsuario() async {
    print('\n--- EXCLUIR USUÁRIO ---');
    final id = lerInt('Digite o ID do usuário que deseja excluir');

    if (AuthService.usuarioLogado?.id == id) {
      print('[!] Você não pode excluir a sua própria conta logada no momento!');
      return;
    }

    if (!confirmar('Tem certeza que deseja excluir o usuário ID $id?')) {
      print('Operação cancelada.');
      return;
    }

    final sucesso = await _usuarioDao.apagar(id);
    if (sucesso) {
      print('[OK] Usuário ID $id excluído com sucesso!');
    } else {
      print('[ERRO] Falha ao excluir usuário no banco.');
    }
  }
}

