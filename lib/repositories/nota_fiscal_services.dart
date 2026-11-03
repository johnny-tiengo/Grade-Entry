import '../models/nota_fiscal.dart';
import '../models/sessao.dart';
import '../repositories/nota_fiscal_dao.dart';

/// Regras de negócio das NFs. Os menus só leem dados e chamam estes métodos.
class NotaFiscalService {
  static const statusAberto = 'aberto';
  static const statusRevisao = 'revisao'; // novo: precisa caber na coluna statusNota
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
    required int assistenteLog,
    required int supervisorLog,
    required int almoxarifeLog,
  }) async {
    if (!RegExp(r'^\d{44}$').hasMatch(chaveAcesso)) {
      throw ArgumentError('A chave de acesso deve ter 44 dígitos.');
    }
    if (await buscarPorNumero(numeroNota) != null) {
      throw ArgumentError('Já existe uma NF com o número $numeroNota.');
    }
    await _dao.salvar(NotaFiscal(
      numeroNota: numeroNota,
      numeroPedido: numeroPedido,
      chaveAcesso: chaveAcesso,
      dataRecebimento: dataRecebimento,
      dataCadastro: DateTime.now(),
      statusNota: statusAberto,
      fornecedor: fornecedor,
      recebedor: recebedor,
      centroCusto: centroCusto,
      assistenteLog: assistenteLog,
      supervisorLog: supervisorLog,
      almoxarifeLog: almoxarifeLog,
    ));
  }

  Future<List<NotaFiscal>> listar() => _dao.buscarTodos();

  Future<NotaFiscal?> buscarPorNumero(int numero) => _dao.buscarPorNumero(numero);

  Future<List<NotaFiscal>> listarEmRevisao() => _dao.buscarPorStatus(statusRevisao);

  Future<void> atualizarCampo(NotaFiscal nota, String coluna, Object valor) async {
    if (nota.statusNota == statusFechado) {
      throw ArgumentError('NF fechada não pode ser editada.');
    }
    await _dao.atualizar(nota.id!, coluna, valor);
  }

  Future<void> excluir(NotaFiscal nota) => _dao.apagarNota(nota.id!);

  /// Só o assistente que deu a entrada pode pedir revisão de uma NF aberta.
  Future<void> solicitarRevisao(NotaFiscal nota, Sessao quem) async {
    if (nota.assistenteLog != quem.usuarioId) {
      throw ArgumentError('Só o assistente responsável por esta NF pode pedir revisão.');
    }
    if (nota.statusNota != statusAberto) {
      throw ArgumentError('Só NFs com status "aberto" podem ir para revisão.');
    }
    await _dao.atualizar(nota.id!, 'statusNota', statusRevisao);
  }

  /// Supervisor aprova (fechado + dataFinalizacao) ou devolve (aberto).
  Future<void> decidirRevisao(NotaFiscal nota, Sessao quem, {required bool aprovar}) async {
    if (!quem.ehSupervisor && !quem.ehAdmin) {
      throw ArgumentError('Apenas supervisor ou admin pode decidir uma revisão.');
    }
    if (nota.statusNota != statusRevisao) {
      throw ArgumentError('Esta NF não está em revisão.');
    }
    if (aprovar) {
      await _dao.atualizar(nota.id!, 'dataFinalizacao', DateTime.now());
      await _dao.atualizar(nota.id!, 'statusNota', statusFechado);
    } else {
      await _dao.atualizar(nota.id!, 'statusNota', statusAberto);
    }
  }
}
