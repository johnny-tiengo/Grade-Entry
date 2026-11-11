/*import 'package:grade_entry/views/main.dart' as app;

void main(List<String> arguments) async {
  app.main();
}*/
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_dao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/menus/menu_principal.dart';
import 'package:grade_entry/services/auth_service.dart';

Perfil perfilDe(String texto) {
  final p = texto.trim().toLowerCase();
  if (p == 'admin') return Perfil.admin;
  if (p == 'supervisor') return Perfil.supervisor;
  if (p == 'almoxarife') return Perfil.almoxarife;
  if (p == 'visitante') return Perfil.visitante;
  return Perfil.assistente;
}

Future<void> main() async {

  var usuario = await AuthService.realizarLoginTerminal();
  if (usuario == null) {
    print("Acesso negado. Encerrando o sistema...");
    return;
  }
  
  // autenticar, ele só precisa montar uma Sessao com id, username e perfil.
  //const sessao = Sessao(usuarioId: 1, username: 'admin', perfil: Perfil.admin);
  final sessao = Sessao(
    usuarioId: usuario.id!,
    username: usuario.nome,
    perfil: perfilDe(usuario.perfil),
    equipe: usuario.equipe,
    //perfil: usuario.id == 1 ? Perfil.admin : Perfil.assistente,
     // Ajuste conforme necessário
  );

  final service = NotaFiscalService(NotaFiscalDao());


  await MenuPrincipal(
    sessao,
    service,
    abrirCadastroUsuario: () async {
      // Aqui você pode implementar a lógica para abrir o menu de cadastro de usuários
      print('Abrindo menu de cadastro de usuários...');
     await AuthService.menuGerenciarUsuarios();

    },
   
  ).executar();

  print('\nEncerrando o programa... Até logo!');
}

