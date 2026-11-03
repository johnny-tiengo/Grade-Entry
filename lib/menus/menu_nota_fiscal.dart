import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';

class _CampoEditavel {
  final String rotulo;
  final String coluna;
  final Object Function() ler;
  const _CampoEditavel(this.rotulo, this.coluna, this.ler);
}

class MenuNotaFiscal extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  MenuNotaFiscal(this.sessao, this.service);

  @override
  String get titulo => 'NOTAS FISCAIS (${sessao.username})';

  @override
  List<OpcaoMenu> get opcoes => [
        if(!sessao.ehAlmoxarife)
        OpcaoMenu('1', 'Cadastrar nova NF', _cadastrar),
        OpcaoMenu('2', 'Listar NFs', _listar),
        OpcaoMenu('3', 'Buscar NF pelo número', _buscar),
        if(!sessao.ehAlmoxarife)
        OpcaoMenu('4', 'Editar NF', _editar),
        if(!sessao.ehSupervisor)
        OpcaoMenu('5', 'Pedir revisão ao supervisor', _pedirRevisao),
        if (sessao.ehAdmin) OpcaoMenu('6', 'Excluir NF', _excluir),
      ];

  Future<void> _cadastrar() async {
    print('\n--- NOVO CADASTRO ---');
    final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }
    final numeroNota = lerInt('Número da Nota');
    final numeroPedido = lerInt('Número do Pedido');
    final chave = lerTexto('Chave de Acesso');
    final data = lerDataHora('Recebimento');
    final fornecedor = lerTexto('Fornecedor');
    final recebedor = lerTexto('Recebedor');
    final centroCusto = lerTexto('Centro de Custo');
    // Assistente logado é automaticamente o responsável pela entrada.
    final assistente =
        sessao.ehAssistente ? sessao.usuarioId : lerInt('Quem vai dar a entrada (ID)');
    final supervisor = lerInt('Supervisor (ID)');
    final almoxarife = lerInt('Almoxarife (ID)');

    await service.registrarEntrada(
      numeroNota: numeroNota,
      numeroPedido: numeroPedido,
      chaveAcesso: chave,
      dataRecebimento: data,
      fornecedor: fornecedor,
      recebedor: recebedor,
      centroCusto: centroCusto,
      assistenteLog: assistente,
      supervisorLog: supervisor,
      almoxarifeLog: almoxarife,
    );
  }

  Future<void> _listar() async {
    print('\n--- LISTA DE NOTAS FISCAIS ---');
    final notas = await service.listar();
    if (notas.isEmpty) {
      print('Nenhuma Nota Fiscal foi encontrada no banco de dados.');
      return;
    }
    notas.forEach(print);
  }

  Future<NotaFiscal?> _pedirNota() async {
    final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return null;
    }
    final nota = await service.buscarPorNumero(lerInt('Número da Nota'));
    if (nota == null) print('Nota não encontrada.');
    return nota;
  }

  Future<void> _buscar() async {
    final nota = await _pedirNota();
    if (nota != null) print(nota);
  }

  Future<void> _editar() async {
    final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }
    final nota = await _pedirNota();
    if (nota == null) return;
    print(nota);

    final campos = <_CampoEditavel>[
      _CampoEditavel('NUMERO DA NOTA', 'numeroNota', () => lerInt('Novo número da nota')),
      _CampoEditavel('DATA DE RECEBIMENTO', 'dataRecebimento', () => lerDataHora('Novo recebimento')),
      _CampoEditavel('RECEBEDOR', 'recebedor', () => lerTexto('Novo recebedor')),
      _CampoEditavel('NUMERO DO PEDIDO', 'numeroPedido', () => lerInt('Novo número do pedido')),
      _CampoEditavel('CHAVE DE ACESSO', 'chaveAcesso', () => lerTexto('Nova chave de acesso')),
      _CampoEditavel('FORNECEDOR', 'fornecedor', () => lerTexto('Novo fornecedor')),
      _CampoEditavel('CENTRO DE CUSTO', 'centroCusto', () => lerTexto('Novo centro de custo')),
    ];
    for (var i = 0; i < campos.length; i++) {
      print('${i + 1} - ${campos[i].rotulo}');
    }
    final n = lerInt('QUAL CAMPO DESEJA ALTERAR');
    if (n < 1 || n > campos.length) {
      print('Opção inválida!');
      return;
    }
    final campo = campos[n - 1];
    await service.atualizarCampo(nota, campo.coluna, campo.ler());
    print('Campo atualizado!');
  }

  Future<void> _pedirRevisao() async {
    final nota = await _pedirNota();
    if (nota == null) return;
    await service.solicitarRevisao(nota, sessao);
    print('NF ${nota.numeroNota} enviada para revisão do supervisor.');
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
