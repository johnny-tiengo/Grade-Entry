import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/centro_custo_dao.dart';
import 'package:grade_entry/repositories/fornecedor_dao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuNotaFiscal extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  final FornecedorDao _fornecedorDao;
  final CentroCustoDao _centroCustoDao;

  MenuNotaFiscal(
    this.sessao,
    this.service, {
    FornecedorDao? fornecedorDao,
    CentroCustoDao? centroCustoDao,
  })  : _fornecedorDao = fornecedorDao ?? FornecedorDao(),
        _centroCustoDao = centroCustoDao ?? CentroCustoDao();

  @override
  String get titulo => 'NOTAS FISCAIS (${sessao.username})';

  @override
  List<OpcaoMenu> get opcoes => [
        if (!sessao.ehAlmoxarife)
          OpcaoMenu('1', 'Cadastrar nova NF', _cadastrar),
        OpcaoMenu('2', 'Listar NFs', _listar),
        OpcaoMenu('3', 'Buscar NF pelo número', _buscar),
        if (!sessao.ehAlmoxarife) OpcaoMenu('4', 'Editar NF', _editar),
        if (sessao.ehAssistente || sessao.ehAlmoxarife)
          OpcaoMenu('5', 'Pedir revisão ao supervisor', _pedirRevisao),
        if (sessao.ehAssistente || sessao.ehAdmin)
          OpcaoMenu('6', 'Concluir inclusão de NF', _concluirInclusao),
        if (sessao.ehAlmoxarife || sessao.ehAdmin)
          OpcaoMenu('7', 'Incluir nota no estoque', _incluirNoEstoque),
        if (sessao.ehAdmin) OpcaoMenu('8', 'Excluir NF', _excluir),
      ];

  Future<String> _selecionarFornecedor() async {
    print('\n--- FORNECEDORES DISPONÍVEIS ---');
    final fornecedores = await _fornecedorDao.buscarTodos();
    if (fornecedores.isEmpty) {
      print('Nenhum fornecedor cadastrado.');
    } else {
      fornecedores.forEach(print);
    }
    return lerInt('ID do Fornecedor').toString();
  }

  Future<String> _selecionarCentroCusto() async {
    print('\n--- CENTROS DE CUSTO DISPONÍVEIS ---');
    final centros = await _centroCustoDao.buscarTodos();
    if (centros.isEmpty) {
      print('Nenhum centro de custo cadastrado.');
    } else {
      centros.forEach(print);
    }
    return lerInt('ID do Centro de Custo').toString();
  }

  Future<void> _cadastrar() async {
    print('\n--- NOVO CADASTRO ---');
    if (!confirmar()) {
      print('Operação cancelada.');
      return;
    }
    clearTerminal();
    final numeroNota = lerInt('Número da Nota');
    final numeroPedido = lerInt('Número do Pedido');
    final chave = lerTexto('Chave de Acesso');
    final data = lerDataHora('Recebimento');
    final fornecedor = await _selecionarFornecedor();
    final recebedor = lerTexto('Recebedor');
    final centroCusto = await _selecionarCentroCusto();
    // Assistente logado é automaticamente o responsável pela entrada.
    final usuario = sessao.ehAssistente
        ? sessao.usuarioId
        : lerInt('Quem vai dar a entrada (ID)');
    final equipe = sessao.equipe;

    await service.registrarEntrada(
      numeroNota: numeroNota,
      numeroPedido: numeroPedido,
      chaveAcesso: chave,
      dataRecebimento: data,
      fornecedor: fornecedor,
      recebedor: recebedor,
      centroCusto: centroCusto,
      usuario: usuario,
      equipe: equipe,
    );
  }

  Future<void> _listar() async {
    clearTerminal();
    print('\n--- LISTA DE NOTAS FISCAIS ---');
    final notas = await service.listar(sessao);
    if (notas.isEmpty) {
      print('Nenhuma Nota Fiscal foi encontrada para a sua equipe.');
      return;
    }
    notas.forEach(print);
  }

  Future<NotaFiscal?> _pedirNota() async {
    if (!confirmar()) {
      print('Operação cancelada.');
      return null;
    }
    final nota = await service.buscarPorNumero(
      lerInt('Número da Nota'),
      sessao,
    );
    if (nota == null) print('Nota não encontrada na sua equipe.');
    return nota;
  }

  Future<void> _buscar() async {
    final nota = await _pedirNota();
    if (nota != null) print(nota);
  }

  Future<void> _editar() async {
    final nota = await _pedirNota();
    if (nota == null) return;
    print(nota);

    final campo = escolherCampoEditavel([
      CampoEditavel('NUMERO DA NOTA', 'numeroNota', () => lerInt('Novo número da nota')),
      CampoEditavel('DATA DE RECEBIMENTO', 'dataRecebimento', () => lerDataHora('Novo recebimento')),
      CampoEditavel('RECEBEDOR', 'recebedor', () => lerTexto('Novo recebedor')),
      CampoEditavel('NUMERO DO PEDIDO', 'numeroPedido', () => lerInt('Novo número do pedido')),
      CampoEditavel('CHAVE DE ACESSO', 'chaveAcesso', () => lerTexto('Nova chave de acesso')),
      CampoEditavel('FORNECEDOR', 'fornecedor', () => ''),
      CampoEditavel('CENTRO DE CUSTO', 'centroCusto', () => ''),
    ]);
    if (campo == null) return;

    final Object novoValor;
    if (campo.coluna == 'fornecedor') {
      novoValor = await _selecionarFornecedor();
    } else if (campo.coluna == 'centroCusto') {
      novoValor = await _selecionarCentroCusto();
    } else {
      novoValor = campo.ler();
    }

    await service.atualizarCampo(nota, campo.coluna, novoValor);
    print('Campo atualizado!');
  }

  Future<void> _pedirRevisao() async {
    final nota = await _pedirNota();
    if (nota == null) return;
    await service.solicitarRevisao(nota, sessao);
    print('NF ${nota.numeroNota} enviada para revisão do supervisor (Estado: Pendente).');
  }

  Future<void> _concluirInclusao() async {
    clearTerminal();
    print('\n--- CONCLUIR INCLUSÃO DE NOTA FISCAL ---');
    final notasDisponiveis = await service.listarParaConcluirInclusao(sessao);
    if (notasDisponiveis.isEmpty) {
      print('Nenhuma NF com status "aberto" ou "revisada" disponível na sua equipe.');
      return;
    }
    notasDisponiveis.forEach(print);

    if (!confirmar('Deseja concluir a inclusão de uma nota?')) {
      print('Operação cancelada.');
      return;
    }
    final idNota = lerInt('Digite o ID da Nota que deseja concluir');
    await service.concluirInclusao(idNota, sessao);
    print('Inclusão concluída! Status da NF alterado para "agEntrada".');
  }

  Future<void> _incluirNoEstoque() async {
    clearTerminal();
    print('\n--- INCLUIR NOTA FISCAL NO ESTOQUE ---');
    final notasAguardando = await service.listarParaEstoque(sessao);
    if (notasAguardando.isEmpty) {
      print('Nenhuma NF com status "agEntrada" aguardando inclusão no estoque.');
      return;
    }
    notasAguardando.forEach(print);

    if (!confirmar('Deseja incluir uma nota no estoque?')) {
      print('Operação cancelada.');
      return;
    }
    final idNota = lerInt('Digite o ID da Nota que deseja incluir no estoque');
    await service.incluirNoEstoque(idNota, sessao);
    print('Nota incluída no estoque com sucesso! Status alterado para "fechado".');
  }

  Future<void> _excluir() async {
    final nota = await _pedirNota();
    if (nota == null) return;
    if (confirmar('Tem certeza que deseja apagar a NF ${nota.numeroNota}?')) {
      await service.excluir(nota);
      print('NF excluída.');
    }
  }
}
