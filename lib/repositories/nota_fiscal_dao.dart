import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/repositories/base_dao.dart';

class NotaFiscalDao extends BaseDao<NotaFiscal> {
  static const int limitePadraoListagem = 20;

  @override
  String get tabela => 'notafiscal';

  @override
  String get colunaId => 'idnotaFiscal';

  @override
  NotaFiscal mapear(ResultSetRow row) {
    return NotaFiscal(
      id: lerInt(row, 'idnotaFiscal'),
      numeroNota: int.parse(row.colByName('numeroNota')!),
      numeroPedido: int.parse(row.colByName('numeroPedido')!),
      chaveAcesso: lerTexto(row, 'chaveAcesso'),
      statusNota: row.colByName('statusNota'),
      dataRecebimento: DateTime.parse(row.colByName('dataRecebimento')!),
      dataCadastro: lerData(row, 'dataCadastro'),
      fornecedor: lerTexto(row, 'fornecedor'),
      recebedor: lerTexto(row, 'recebedor'),
      centroCusto: lerTexto(row, 'centroCusto'),
      dataFinalizacao: lerData(row, 'dataFinalizacao'),
      usuario: lerInt(row, 'usuario'),
      equipe: lerInt(row, 'equipe'),
    );
  }

  @override
  Map<String, dynamic> paraMapa(NotaFiscal nfAdd) => {
        'numeroNota': nfAdd.numeroNota,
        'chaveAcesso': nfAdd.chaveAcesso,
        'numeroPedido': nfAdd.numeroPedido,
        'dataRecebimento': nfAdd.dataRecebimento,
        'dataCadastro': nfAdd.dataCadastro,
        'fornecedor': nfAdd.fornecedor,
        'recebedor': nfAdd.recebedor,
        'centroCusto': nfAdd.centroCusto,
        'dataFinalizacao': nfAdd.dataFinalizacao,
        'statusNota': nfAdd.statusNota,
        'usuario': nfAdd.usuario,
        'equipe': nfAdd.equipe,
      };

  /// Lista as NFs da equipe priorizando as abertas (sem limite).
  /// Se houver menos de 20 abertas, completa com as fechadas/demais até 20.
  /// Se houver 20 ou mais abertas, retorna todas as abertas somente.
  Future<List<NotaFiscal>> listarPorEquipeComPrioridade(int? equipe) async {
    final filtroEquipe = equipe != null ? 'WHERE equipe = :equipe' : '';
    final params = equipe != null ? {'equipe': equipe} : null;

    final todasDaEquipe = await consultar(
      'SELECT * FROM $tabela $filtroEquipe ORDER BY $colunaId;',
      params,
    );

    final abertas = <NotaFiscal>[];
    final demais = <NotaFiscal>[];

    for (final nf in todasDaEquipe) {
      if ((nf.statusNota ?? '').toLowerCase() == 'aberto') {
        abertas.add(nf);
      } else {
        demais.add(nf);
      }
    }

    if (abertas.length >= limitePadraoListagem) {
      return abertas;
    }

    final faltam = limitePadraoListagem - abertas.length;
    return [
      ...abertas,
      ...demais.take(faltam),
    ];
  }

  /// Busca pelo número da Nota Fiscal (filtrando pela equipe se informada).
  Future<NotaFiscal?> buscarPorNumero(int numero, {int? equipe}) async {
    if (equipe != null) {
      final r = await consultar(
        'SELECT * FROM $tabela WHERE numeroNota = :n AND equipe = :equipe LIMIT 1;',
        {'n': numero, 'equipe': equipe},
      );
      return r.isEmpty ? null : r.first;
    }
    final r = await consultar(
      'SELECT * FROM $tabela WHERE numeroNota = :n LIMIT 1;',
      {'n': numero},
    );
    return r.isEmpty ? null : r.first;
  }

  /// Busca pelo ID da Nota Fiscal (filtrando pela equipe se informada).
  Future<NotaFiscal?> buscarPorIdDaEquipe(int id, {int? equipe}) async {
    if (equipe != null) {
      final r = await consultar(
        'SELECT * FROM $tabela WHERE $colunaId = :id AND equipe = :equipe LIMIT 1;',
        {'id': id, 'equipe': equipe},
      );
      return r.isEmpty ? null : r.first;
    }
    return buscarPorId(id);
  }

  /// Busca específica por status e opcionalmente por equipe.
  Future<List<NotaFiscal>> buscarPorStatus(String status, {int? equipe}) {
    if (equipe != null) {
      return consultar(
        'SELECT * FROM $tabela WHERE statusNota = :s AND equipe = :equipe ORDER BY $colunaId;',
        {'s': status, 'equipe': equipe},
      );
    }
    return consultar(
      'SELECT * FROM $tabela WHERE statusNota = :s ORDER BY $colunaId;',
      {'s': status},
    );
  }

  /// Busca NFs da equipe que estejam em qualquer um dos status informados.
  Future<List<NotaFiscal>> buscarPorListaDeStatus(
    List<String> listaStatus, {
    int? equipe,
  }) async {
    final filtroEquipe = equipe != null ? 'WHERE equipe = :equipe' : '';
    final params = equipe != null ? {'equipe': equipe} : null;
    final todas = await consultar(
      'SELECT * FROM $tabela $filtroEquipe ORDER BY $colunaId;',
      params,
    );
    final statusNormalizados =
        listaStatus.map((s) => s.toLowerCase()).toSet();
    return todas
        .where((nf) =>
            statusNormalizados.contains((nf.statusNota ?? '').toLowerCase()))
        .toList();
  }

  /// Mantém o nome `apagarNota` delegando para `apagar` da classe pai [BaseDao].
  Future<bool> apagarNota(int idDel) => apagar(idDel);
}
