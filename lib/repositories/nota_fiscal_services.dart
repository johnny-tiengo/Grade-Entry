import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/revisao.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_dao.dart';
import 'package:grade_entry/repositories/revisao_dao.dart';

/// Regras de negócio das NFs. Os menus só leem dados e chamam estes métodos.
class NotaFiscalService {
  static const statusAberto = 'aberto';
  static const statusRevisao = 'revisao';
  static const statusRevisada = 'revisada';
  static const statusAgEntrada = 'agEntrada';
  static const statusFechado = 'fechado';

  final NotaFiscalDao _dao;
  final RevisaoDao _revisaoDao;

  NotaFiscalService(this._dao, [RevisaoDao? revisaoDao])
      : _revisaoDao = revisaoDao ?? RevisaoDao();

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
    if (await _dao.buscarPorNumero(numeroNota) != null) {
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

  /// Lista NFs filtradas pela equipe do usuário logado, com prioridade para abertas (limite 20).
  Future<List<NotaFiscal>> listar([Sessao? sessao]) =>
      _dao.listarPorEquipeComPrioridade(sessao?.equipe);

  /// Busca NF pelo número filtrando pela equipe da sessão.
  Future<NotaFiscal?> buscarPorNumero(int numero, [Sessao? sessao]) =>
      _dao.buscarPorNumero(numero, equipe: sessao?.equipe);

  /// Busca NF pelo ID filtrando pela equipe da sessão.
  Future<NotaFiscal?> buscarPorId(int id, [Sessao? sessao]) =>
      _dao.buscarPorIdDaEquipe(id, equipe: sessao?.equipe);

  Future<void> atualizarCampo(NotaFiscal nota, String coluna, Object valor) async {
    if (nota.statusNota == statusFechado) {
      throw ArgumentError('NF fechada não pode ser editada.');
    }
    await _dao.atualizar(nota.id!, coluna, valor);
  }

  Future<void> excluir(NotaFiscal nota) => _dao.apagarNota(nota.id!);

  /// Assistente e Almoxarife podem pedir revisão de uma NF.
  /// Insere registro na tabela `revisao` com estado = 'Pendente'.
  Future<void> solicitarRevisao(NotaFiscal nota, Sessao quem) async {
    if (!quem.ehAssistente && !quem.ehAlmoxarife && !quem.ehAdmin) {
      throw ArgumentError('Apenas assistente ou almoxarife pode solicitar revisão.');
    }
    await _revisaoDao.salvar(
      Revisao(
        estado: 'Pendente',
        notafiscalId: nota.id!,
        usuario: quem.usuarioId,
        equipe: quem.equipe ?? nota.equipe,
        perfilUsuario: quem.nomePerfil,
      ),
    );
    await _dao.atualizar(nota.id!, 'statusNota', statusRevisao);
  }

  /// Supervisor lista as revisões diretamente da tabela `revisao` (da sua equipe).
  Future<List<Revisao>> listarRevisoes(Sessao quem) =>
      _revisaoDao.listarPorEquipe(quem.equipe);

  /// Supervisor aprova (statusNota -> 'revisada') ou devolve (statusNota -> 'aberto').
  Future<void> decidirRevisao(
    NotaFiscal nota,
    Sessao quem, {
    required bool aprovar,
  }) async {
    if (!quem.ehSupervisor && !quem.ehAdmin) {
      throw ArgumentError('Apenas supervisor ou admin pode decidir uma revisão.');
    }
    if (aprovar) {
      await _dao.atualizar(nota.id!, 'statusNota', statusRevisada);
      await _revisaoDao.atualizarEstadoPorNota(nota.id!, 'Liberado');
    } else {
      await _dao.atualizar(nota.id!, 'statusNota', statusAberto);
      await _revisaoDao.atualizarEstadoPorNota(nota.id!, 'Em análise');
    }
  }

  /// Lista NFs da equipe do assistente que estão com status 'aberto' ou 'revisada'.
  Future<List<NotaFiscal>> listarParaConcluirInclusao(Sessao quem) =>
      _dao.buscarPorListaDeStatus(
        [statusAberto, statusRevisada],
        equipe: quem.equipe,
      );

  /// Assistente conclui a inclusão da NF trocando o statusNota para 'agEntrada'.
  Future<void> concluirInclusao(int idNota, Sessao quem) async {
    if (!quem.ehAssistente && !quem.ehAdmin) {
      throw ArgumentError('Apenas o assistente pode concluir a inclusão da NF.');
    }
    final nota = await buscarPorId(idNota, quem);
    if (nota == null) {
      throw ArgumentError('Nota Fiscal ID $idNota não encontrada na sua equipe.');
    }
    final st = (nota.statusNota ?? '').toLowerCase();
    if (st != statusAberto && st != statusRevisada) {
      throw ArgumentError(
        'Apenas notas com status "aberto" ou "revisada" podem ter a inclusão concluída (status atual: ${nota.statusNota}).',
      );
    }
    await _dao.atualizar(nota.id!, 'statusNota', statusAgEntrada);
  }

  /// Lista NFs da equipe do almoxarife que estão com status 'agEntrada'.
  Future<List<NotaFiscal>> listarParaEstoque(Sessao quem) =>
      _dao.buscarPorListaDeStatus(
        [statusAgEntrada],
        equipe: quem.equipe,
      );

  /// Almoxarife inclui a NF no estoque trocando o statusNota para 'fechado'.
  Future<void> incluirNoEstoque(int idNota, Sessao quem) async {
    if (!quem.ehAlmoxarife && !quem.ehAdmin) {
      throw ArgumentError('Apenas o almoxarife pode incluir a nota no estoque.');
    }
    final nota = await buscarPorId(idNota, quem);
    if (nota == null) {
      throw ArgumentError('Nota Fiscal ID $idNota não encontrada na sua equipe.');
    }
    if ((nota.statusNota ?? '').toLowerCase() != statusAgEntrada.toLowerCase()) {
      throw ArgumentError(
        'Apenas notas com status "agEntrada" podem ser incluídas no estoque (status atual: ${nota.statusNota}).',
      );
    }
    await _dao.atualizar(nota.id!, 'dataFinalizacao', DateTime.now());
    await _dao.atualizar(nota.id!, 'statusNota', statusFechado);
  }
}
