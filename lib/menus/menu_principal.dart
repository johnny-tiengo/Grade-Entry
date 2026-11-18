import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/services/csv_service.dart';
import 'package:grade_entry/services/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';
import 'package:grade_entry/menus/menu_nota_fiscal.dart';
import 'package:grade_entry/menus/menu_supervisor.dart';
import 'package:grade_entry/menus/menu_sla.dart';

/// Menu raiz. As opções mudam conforme o perfil de quem logou.
class MenuPrincipal extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;

  /// Menu de cadastro de usuários feito pelo outro integrante.
  /// Basta passar a função que abre ele (ex.: () => MenuUsuario().executar()).
  final Future<void> Function()? abrirCadastroUsuario;

  MenuPrincipal(this.sessao, this.service, {this.abrirCadastroUsuario});

  @override
  String get titulo => 'MENU PRINCIPAL (${sessao.username})';

  @override
  String get textoSaida => 'Sair';

  @override
  List<OpcaoMenu> get opcoes => sessao.ehVisitante
      // Visitante: acesso somente à busca de NF pelo número.
      ? [
          OpcaoMenu(
            'Buscar NF pelo número',
            () => MenuNotaFiscal(sessao, service).buscar(),
          ),
        ]
      : [
          OpcaoMenu(
           'Notas Fiscais',
            () => MenuNotaFiscal(sessao, service).executar(),
          ),
          if (sessao.ehSupervisor || sessao.ehAdmin)
            OpcaoMenu(
              'Revisão de notas',
              () => MenuSupervisor(sessao, service).executar(),
            ),
          if (sessao.ehAdmin)
            OpcaoMenu('Cadastrar usuário', abrirCadastroUsuario!),
          if (sessao.ehAdmin)
            OpcaoMenu('Gerar arquivo CSV do banco', gerarCSV),
          OpcaoMenu(
            'Controle de SLA (72h)',
            () => MenuSla(sessao, service).executar(),
          ),
        ];
}
