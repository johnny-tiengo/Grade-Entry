import '../models/nota_fiscal.dart';
import '../models/sessao.dart';
import '../repositories/nota_fiscal_dao.dart';

/// Regras de negócio das NFs. Os menus só leem dados e chamam estes métodos.
class NotaFiscalService {
  static const statusAberto = 'aberto';
  static const statusRevisao = 'revisao';
  static const statusAgEntrada = 'agEntrada';
  static const statusFechado = 'fechado';

  final NotaFiscalDao _dao;
  NotaFiscalService(this._dao);

  /// registrarEntrada: valida e salva uma nova NF com status "aberto".
  Future<void> registrarEntrada({
    required int numeroNota,
    required int numeroPedido,
    required String chaveAcesso,
    required DateTime dataRecebimento,
    required String fornecedor,
    required String recebedor,
    required String centroCusto,
    required int usuario,
    required int? equipe,
  }) async {
    if (!RegExp(r'^\d{44}$').hasMatch(chaveAcesso)) {
      throw ArgumentError('A chave de acesso deve ter 44 dígitos.');
    }
    if (await buscarPorNumero(numeroNota) != null) {
      throw ArgumentError('Já existe uma NF com o número $numeroNota.');
    }
    await _dao.salvar(
      NotaFiscal(
        numeroNota: numeroNota,
        numeroPedido: numeroPedido,
        chaveAcesso: chaveAcesso,
        dataRecebimento: dataRecebimento,
        dataCadastro: DateTime.now(),
        statusNota: statusAberto,
        fornecedor: fornecedor,
        recebedor: recebedor,
        centroCusto: centroCusto,
        usuario: usuario,
        equipe: equipe,
      ),
    );
  }

  Future<List<NotaFiscal>> listar() => _dao.buscarTodos();

  Future<NotaFiscal?> buscarPorNumero(int numero) =>
      _dao.buscarPorNumero(numero);

  Future<List<NotaFiscal>> listarEmRevisao(Sessao quem) =>
      _dao.buscarEmRevisao(equipe: quem.equipe);

  /// Lista NFs com status 'aberto' para o assistente aprovar.
  Future<List<NotaFiscal>> listarParaAprovacaoAssistente(Sessao quem) =>
      _dao.buscarParaAprovacaoAssistente(equipe: quem.equipe);

  /// Lista NFs com status 'agEntrada' para o almoxarife consultar/aprovar.
  Future<List<NotaFiscal>> listarAguardandoEntrada(Sessao quem) =>
      _dao.buscarAguardandoEntrada(equipe: quem.equipe);

  Future<void> atualizarCampo(
    NotaFiscal nota,
    String coluna,
    Object valor,
  ) async {
    if (nota.statusNota == statusFechado) {
      throw ArgumentError('NF fechada não pode ser editada.');
    }
    await _dao.atualizar(nota.id!, coluna, valor);
  }

  Future<void> excluir(NotaFiscal nota) => _dao.apagarNota(nota.id!);

  /// Assistente ou Almoxarife da equipe responsável pede revisão de uma NF.
  /// Vai para a tabela 'revisao' com estado "Pendente", levando usuario, equipe e perfil_usuario.
  Future<void> solicitarRevisao(NotaFiscal nota, Sessao quem) async {
    if (quem.equipe != null && nota.equipe != quem.equipe) {
      throw ArgumentError(
        'Só a equipe responsável por esta NF pode pedir revisão.',
      );
    }
    if (nota.statusNota != statusAberto && nota.statusNota != statusAgEntrada) {
      throw ArgumentError(
        'Só NFs com status "aberto" ou "agEntrada" podem ir para revisão.',
      );
    }
    await _dao.registrarPedidoRevisao(
      idNota: nota.id!,
      usuarioId: quem.usuarioId,
      equipe: quem.equipe,
      perfilUsuario: quem.nomePerfil,
    );
  }

  /// Supervisor aprova (na tabela revisao muda estado para 'Em análise' e NF fica 'aberto')
  /// ou libera/devolve (na tabela revisao muda estado para 'Liberado' e NF fica 'aberto').
  Future<void> decidirRevisao(
    NotaFiscal nota,
    Sessao quem, {
    required bool aprovar,
  }) async {
    if (!quem.ehSupervisor && !quem.ehAdmin) {
      throw ArgumentError(
        'Apenas supervisor pode decidir uma revisão.',
      );
    }
    if (quem.equipe != null && nota.equipe != quem.equipe) {
      throw ArgumentError(
        'Só o supervisor pode decidir a revisão desta NF.',
      );
    }
    if (nota.statusNota != statusRevisao) {
      throw ArgumentError('Esta NF não está em revisão.');
    }
    await _dao.concluirRevisaoSupervisor(
      idNota: nota.id!,
      novoEstadoRevisao: aprovar ? 'Em análise' : 'Liberado',
    );
  }

  /// Assistente aprova seu trabalho na NF ('aberto' -> 'agEntrada').
  Future<void> aprovarTrabalhoAssistente(NotaFiscal nota, Sessao quem) async {
    if (!quem.ehAssistente && !quem.ehAdmin) {
      throw ArgumentError(
        'Apenas assistente ou admin pode aprovar a NF para aguardando entrada.',
      );
    }
    if (quem.equipe != null && nota.equipe != quem.equipe) {
      throw ArgumentError(
        'Só a equipe responsável por esta NF pode aprová-la.',
      );
    }
    if (nota.statusNota != statusAberto) {
      throw ArgumentError(
        'Apenas NFs com status "aberto" podem ser enviadas para "agEntrada".',
      );
    }
    await _dao.atualizar(nota.id!, 'statusNota', statusAgEntrada);
  }

  /// Almoxarife aprova a entrada da NF no estoque ('agEntrada' -> 'fechado' + vincula estoque + dataFinalizacao).
  Future<void> aprovarEntradaAlmoxarife(
    NotaFiscal nota,
    int idEstoque,
    Sessao quem,
  ) async {
    if (!quem.ehAlmoxarife && !quem.ehAdmin) {
      throw ArgumentError(
        'Apenas almoxarife pode dar entrada no estoque.',
      );
    }
    if (quem.equipe != null && nota.equipe != quem.equipe) {
      throw ArgumentError(
        'Só a equipe responsável por esta NF pode dar entrada no estoque.',
      );
    }
    if (nota.statusNota != statusAgEntrada) {
      throw ArgumentError(
        'Apenas Notas Fiscais aprovadas pelo Assistente podem ir para o estoque.',
      );
    }
    await _dao.fecharNotaComEstoque(nota.id!, idEstoque, DateTime.now());
  }
}
