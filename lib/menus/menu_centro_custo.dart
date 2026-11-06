import 'package:grade_entry/models/centro_custo.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/centro_custo_dao.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuCentroCusto extends ConsoleUI {
  final Sessao sessao;
  final CentroCustoDao _dao;

  MenuCentroCusto(this.sessao, [CentroCustoDao? dao])
      : _dao = dao ?? CentroCustoDao();

  @override
  String get titulo => 'CENTROS DE CUSTO (${sessao.username})';

  @override
  List<OpcaoMenu> get opcoes => [
        if (sessao.ehAdmin)
          OpcaoMenu('1', 'Cadastrar Centro de Custo', _cadastrar),
        OpcaoMenu('2', 'Listar Centros de Custo', _listar),
        if (sessao.ehAdmin)
          OpcaoMenu('3', 'Editar Centro de Custo', _editar),
        if (sessao.ehAdmin)
          OpcaoMenu('4', 'Excluir Centro de Custo', _excluir),
      ];

  Future<void> _cadastrar() async {
    print('\n--- NOVO CADASTRO DE CENTRO DE CUSTO ---');
    if (!confirmar()) {
      print('Operação cancelada.');
      return;
    }
    final nome = lerTexto('Nome do Centro de Custo (ex.: 556421 - Sudeste MG)');
    await _dao.salvar(CentroCusto(nome: nome));
  }

  Future<void> _listar() async {
    clearTerminal();
    print('\n--- LISTA DE CENTROS DE CUSTO ---');
    final lista = await _dao.buscarTodos();
    if (lista.isEmpty) {
      print('Nenhum centro de custo encontrado no banco de dados.');
      return;
    }
    lista.forEach(print);
  }

  Future<CentroCusto?> _pedirCentroCusto() async {
    if (!confirmar()) {
      print('Operação cancelada.');
      return null;
    }
    final cc = await _dao.buscarPorId(lerInt('ID do Centro de Custo'));
    if (cc == null) print('Centro de Custo não encontrado.');
    return cc;
  }

  Future<void> _editar() async {
    final cc = await _pedirCentroCusto();
    if (cc == null) return;
    print(cc);

    final campo = escolherCampoEditavel([
      CampoEditavel('NOME', 'nome', () => lerTexto('Novo Nome do Centro de Custo')),
    ]);
    if (campo == null) return;

    await _dao.atualizar(cc.idcentroCusto!, campo.coluna, campo.ler());
    print('Centro de Custo atualizado!');
  }

  Future<void> _excluir() async {
    final cc = await _pedirCentroCusto();
    if (cc == null) return;
    if (confirmar('Tem certeza que deseja excluir o Centro de Custo "${cc.nome}"?')) {
      await _dao.apagar(cc.idcentroCusto!);
      print('Centro de Custo excluído.');
    }
  }
}
