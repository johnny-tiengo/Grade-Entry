import 'package:grade_entry/menus/menu_centro_custo.dart';
import 'package:grade_entry/menus/menu_fornecedor.dart';
import 'package:grade_entry/menus/menu_nota_fiscal.dart';
import 'package:grade_entry/menus/menu_supervisor.dart';
import 'package:grade_entry/menus/menu_usuario.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/services/csv_service.dart';
import 'package:grade_entry/views/console_ui.dart';

/// Menu raiz. As opções mudam conforme o perfil de quem logou.
class MenuPrincipal extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  final Future<void> Function()? abrirCadastroUsuario;

  MenuPrincipal(this.sessao, this.service, {this.abrirCadastroUsuario});

  @override
  String get titulo => 'MENU PRINCIPAL (${sessao.username})';

  @override
  String get textoSaida => 'Sair';

  @override
  List<OpcaoMenu> get opcoes => [
        OpcaoMenu(
          '1',
          'Notas Fiscais',
          () => MenuNotaFiscal(sessao, service).executar(),
        ),
        OpcaoMenu(
          '2',
          'Fornecedores',
          () => MenuFornecedor(sessao).executar(),
        ),
        OpcaoMenu(
          '3',
          'Centros de Custo',
          () => MenuCentroCusto(sessao).executar(),
        ),
        if (sessao.ehSupervisor || sessao.ehAdmin)
          OpcaoMenu(
            '4',
            'Revisão de notas',
            () => MenuSupervisor(sessao, service).executar(),
          ),
        if (sessao.ehAdmin || sessao.ehSupervisor)
          OpcaoMenu(
            '5',
            'Gerenciar usuários',
            abrirCadastroUsuario ?? () => MenuUsuario().executar(),
          ),
        if (sessao.ehAdmin)
          OpcaoMenu('6', 'Gerar arquivo CSV do banco', gerarCSV),
      ];
}
