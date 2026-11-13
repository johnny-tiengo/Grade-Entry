import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_services.dart';
import 'package:grade_entry/views/console_ui.dart';

import '../repositories/centrocusto_dao.dart';
import '../repositories/estoque_dao.dart';
import '../repositories/fornecedor_dao.dart';

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
  List<OpcaoMenu> get opcoes => sessao.ehVisitante
      ? [OpcaoMenu('Buscar NF pelo número', buscar)]
      : [
          if (!sessao.ehAlmoxarife)
            OpcaoMenu('Cadastrar nova NF', _cadastrar),

          OpcaoMenu('Listar NFs', _listar),
          OpcaoMenu('Buscar NF pelo número', buscar),
          if (!sessao.ehAlmoxarife) OpcaoMenu('Editar NF', _editar),
          if (!sessao.ehSupervisor)
            OpcaoMenu('Pedir revisão ao supervisor', _pedirRevisao),
          if (sessao.ehAdmin) OpcaoMenu('Excluir NF', _excluir),
        ];

  Future<void> _cadastrar() async {
    final ccDao = CentrocustoDao();
    final fDao = FornecedorDao();

    print('\n--- NOVO CADASTRO ---');
    final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }
    clearTerminal();
    final numeroNota = lerInt('Número da Nota');
    final numeroPedido = lerInt('Número do Pedido');
    final chave = lerTexto('Chave de Acesso');
    final data = lerDataHora('Recebimento');

    final fornecedores = await fDao.buscarTodos();
    print('Fornecedores disponíveis:');
    fornecedores.forEach(print);

    final fornecedor = lerTexto('Fornecedor');
    final recebedor = lerTexto('Recebedor');

    final centroDCusto = await ccDao.buscarTodos();
    print("Centro de Custo:");
    centroDCusto.forEach(print);

    final centroCusto = lerTexto('Centro de Custo');
    final usuario = sessao.usuarioId;
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

  /// Também usada pelo perfil Visitante, que só tem acesso a esta busca.
  Future<void> buscar() async {
    final nota = await _pedirNota();
    if (nota != null) print(nota);
  }

  Future<void> _editar() async {
    clearTerminal();
    print('\n--- LISTA DE NOTAS FISCAIS ---');
    final notas = await service.listar();
    if (notas.isEmpty) {
      print('Nenhuma Nota Fiscal foi encontrada no banco de dados.');
      return;
    }
    notas.forEach(print);
    
    final escolha = lerTexto('Deseja continuar? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }
    final nota = await _pedirNota();
    if (nota == null) return;
    print(nota);

    final campos = <_CampoEditavel>[
      _CampoEditavel(
        'NUMERO DA NOTA',
        'numeroNota',
        () => lerInt('Novo número da nota'),
      ),
      _CampoEditavel(
        'DATA DE RECEBIMENTO',
        'dataRecebimento',
        () => lerDataHora('Novo recebimento'),
      ),
      _CampoEditavel(
        'RECEBEDOR',
        'recebedor',
        () => lerTexto('Novo recebedor'),
      ),
      _CampoEditavel(
        'NUMERO DO PEDIDO',
        'numeroPedido',
        () => lerInt('Novo número do pedido'),
      ),
      _CampoEditavel(
        'CHAVE DE ACESSO',
        'chaveAcesso',
        () => lerTexto('Nova chave de acesso'),
      ),
      _CampoEditavel(
        'FORNECEDOR',
        'fornecedor',
        () => lerTexto('Novo fornecedor'),
      ),
      _CampoEditavel(
        'CENTRO DE CUSTO',
        'centroCusto',
        () => lerTexto('Novo centro de custo'),
      ),
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

  /// Assistente: exibe todas as NFs 'aberto' e aprova para 'agEntrada'.
  Future<void> _aprovarAssistente() async {
    clearTerminal();
    print('\n--- APROVAR NF PARA ENTRADA (STATUS: ABERTO) ---');
    final notas = await service.listarParaAprovacaoAssistente(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF com status "aberto" disponível para aprovação.');
      return;
    }
    for (final n in notas) {
      print(n);
    }

    final escolha = lerTexto('\nDeseja aprovar uma NF? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }

    final numero = lerInt('Digite o Número da Nota que deseja aprovar');
    final nota = await service.buscarPorNumero(numero);
    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }

    await service.aprovarTrabalhoAssistente(nota, sessao);
    print('NF ${nota.numeroNota} aprovada com sucesso! Status alterado para "agEntrada".');
  }

  /// Almoxarife: consulta apenas as NFs com status 'agEntrada'.
  Future<void> _listarAgEntrada() async {
    clearTerminal();
    print('\n--- NFs AGUARDANDO ENTRADA NO ESTOQUE (agEntrada) ---');
    final notas = await service.listarAguardandoEntrada(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF aguardando entrada no estoque no momento.');
      return;
    }
    for (final n in notas) {
      print(n);
    }
  }

  /// Almoxarife: exibe NFs 'agEntrada', seleciona a NF, exibe os estoques da equipe e fecha a NF.
  Future<void> _aprovarAlmoxarife() async {
    clearTerminal();
    print('\n--- DAR ENTRADA NO ESTOQUE E FECHAR NF (STATUS: agEntrada) ---');
    final notas = await service.listarAguardandoEntrada(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF com status "agEntrada" disponível para fechamento.');
      return;
    }
    for (final n in notas) {
      print(n);
    }

    final escolha = lerTexto('\nDeseja dar entrada em uma NF? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }

    final numero = lerInt('Digite o Número da Nota que deseja dar entrada');
    final nota = await service.buscarPorNumero(numero);
    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }

    final estoqueDao = EstoqueDao();
    final estoquesEquipe = await estoqueDao.buscarPorEquipe(sessao.equipe);
    if (estoquesEquipe.isEmpty) {
      print('Nenhum estoque cadastrado para a sua equipe (Equipe ${sessao.equipe}).');
      return;
    }

    print('\nEstoques disponíveis para a sua equipe:');
    for (final est in estoquesEquipe) {
      print(est);
    }

    final idEstoque = lerInt('Digite o ID do Estoque para vincular à NF');
    final estoqueSelecionado = estoquesEquipe.where((e) => e.idestoque == idEstoque);
    if (estoqueSelecionado.isEmpty) {
      print('Estoque inválido ou não pertence à sua equipe!');
      return;
    }

    await service.aprovarEntradaAlmoxarife(nota, idEstoque, sessao);
    print(
      'Entrada confirmada! NF ${nota.numeroNota} vinculada ao estoque "${estoqueSelecionado.first.nome}" e alterada para status "fechado".',
    );
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
