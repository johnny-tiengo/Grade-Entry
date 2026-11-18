import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/services/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuSupervisor extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  MenuSupervisor(this.sessao, this.service);

  @override
  String get titulo => 'REVISÃO DE NOTAS (SUPERVISOR)';

  @override
  List<OpcaoMenu> get opcoes => [
        OpcaoMenu('Ver NFs em revisão', _listar),
        OpcaoMenu('Aprovar NF (fechar)', () => _decidir(aprovar: true)),
        OpcaoMenu('Devolver NF (reabrir)', () => _decidir(aprovar: false)),
      ];

  Future<void> _listar() async {
    final notas = await service.listarEmRevisao(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF aguardando revisão.');
      return;
    }
    notas.forEach(print);
  }

  Future<void> _decidir({required bool aprovar}) async {
   
    final notas = await service.listarEmRevisao(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF aguardando revisão.');
      return;}
       notas.forEach(print);

    //  final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    // if (escolha != '1') {
    //   print('Operação cancelada.');
    //   return;
    // }
    final nota = await service.buscarPorNumero(lerInt('Número da Nota'));
    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }
    await service.decidirRevisao(nota, sessao, aprovar: aprovar);
    if(!aprovar){
      
    };
    print(
      aprovar
          ? 'Revisão aprovada: Nota Fiscal aprovada para Entrada.'
          : 'NF Encerrada.',
    );
  }
}
