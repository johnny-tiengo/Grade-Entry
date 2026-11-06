import 'package:grade_entry/menus/menu_principal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_dao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/services/auth_service.dart';

Future<void> main() async {
  final usuario = await AuthService.realizarLoginTerminal();
  if (usuario == null) {
    print('Acesso negado. Encerrando o sistema...');
    return;
  }

  final sessao = Sessao.fromUsuario(usuario);
  final service = NotaFiscalService(NotaFiscalDao());

  await MenuPrincipal(
    sessao,
    service,
    abrirCadastroUsuario: AuthService.menuGerenciarUsuarios,
  ).executar();

  AuthService.deslogar();
  print('\nEncerrando o programa... Até logo, ${usuario.nome}!');
}
