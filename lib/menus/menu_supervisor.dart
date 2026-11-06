import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuSupervisor extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  MenuSupervisor(this.sessao, this.service);

  @override
  String get titulo => 'REVISÃO DE NOTAS (SUPERVISOR)';

  @override
  List<OpcaoMenu> get opcoes => [
        OpcaoMenu('1', 'Ver NFs em revisão', _listar),
        OpcaoMenu('2', 'Aprovar NF (marcar como revisada)', () => _decidir(aprovar: true)),
        OpcaoMenu('3', 'Devolver NF (reabrir)', () => _decidir(aprovar: false)),
      ];

  Future<void> _listar() async {
    clearTerminal();
    print('\n--- REVISÕES CADASTRADAS NO BANCO ---');
    final revisoes = await service.listarRevisoes(sessao);
    if (revisoes.isEmpty) {
      print('Nenhuma NF aguardando revisão na tabela de revisão.');
      return;
    }
    revisoes.forEach(print);
  }

  Future<void> _decidir({required bool aprovar}) async {
    if (!confirmar()) {
      print('Operação cancelada.');
      return;
    }
    final numeroOuId = lerInt('ID ou Número da Nota');
    var nota = await service.buscarPorId(numeroOuId, sessao);
    nota ??= await service.buscarPorNumero(numeroOuId, sessao);

    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }
    await service.decidirRevisao(nota, sessao, aprovar: aprovar);
    print(
      aprovar
          ? 'NF aprovada na revisão (status alterado para "revisada").'
          : 'NF devolvida (status alterado para "aberto").',
    );
  }
}
