import 'dart:io';
import 'package:grade_entry/menus/menu_usuario.dart';
import 'package:grade_entry/models/usuario.dart';
import 'package:grade_entry/repositories/usuario_dao.dart';

class AuthService {
  static final UsuarioDao _usuarioDao = UsuarioDao();

  static Usuario? usuarioLogado;

  /// Autentica o usuário pelo banco de dados MySQL.
  static Future<Usuario?> autenticar(String login, String senha) async {
    try {
      return await _usuarioDao.autenticar(login, senha);
    } catch (_) {
      return null;
    }
  }

  /// Exibe a tela de login simples no terminal.
  static Future<Usuario?> realizarLoginTerminal({int maxTentativas = 3}) async {
    int tentativas = maxTentativas;

    print('=========================================');
    print('       SISTEMA DE CADASTRO DE NFs        ');
    print('           ACESSO AO SISTEMA             ');
    print('=========================================');

    while (tentativas > 0) {
      stdout.write('Usuário: ');
      final login = stdin.readLineSync() ?? '';

      stdout.write('Senha: ');
      final senha = stdin.readLineSync() ?? '';

      final usuario = await autenticar(login, senha);

      if (usuario != null) {
        usuarioLogado = usuario;
        print('\n[OK] Login realizado com sucesso!');
        print('Bem-vindo(a), ${usuario.nome}!\n');
        return usuario;
      } else {
        tentativas--;
        print('\n[!] Usuário ou senha incorretos.');
        if (tentativas > 0) {
          print('Você ainda tem $tentativas tentativa(s).\n');
        } else {
          print('Limite de tentativas excedido!\n');
        }
      }
    }

    return null;
  }

  /// Abre o menu administrativo de usuários (reaproveitando a hierarquia [ConsoleUI]).
  static Future<void> menuGerenciarUsuarios() => MenuUsuario(_usuarioDao).executar();

  /// Encerra a sessão atual.
  static void deslogar() {
    usuarioLogado = null;
  }
}

typedef Login = AuthService;
