import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/models/revisao.dart';
import 'package:grade_entry/repositories/base_dao.dart';

class RevisaoDao extends BaseDao<Revisao> {
  @override
  String get tabela => 'revisao';

  @override
  String get colunaId => 'idrevisao';

  @override
  Revisao mapear(ResultSetRow row) {
    return Revisao(
      idrevisao: lerInt(row, 'idrevisao'),
      estado: lerTexto(row, 'estado'),
      notafiscalId: int.parse(row.colByName('notafiscal_idnotaFiscal')!),
      usuario: int.parse(row.colByName('usuario')!),
      equipe: lerInt(row, 'equipe'),
      perfilUsuario: lerTexto(row, 'perfil_usuario'),
    );
  }

  @override
  Map<String, dynamic> paraMapa(Revisao r) => {
        'estado': r.estado,
        'notafiscal_idnotaFiscal': r.notafiscalId,
        'usuario': r.usuario,
        'equipe': r.equipe,
        'perfil_usuario': r.perfilUsuario,
      };

  /// Lista as revisões filtrando pela equipe (se informada).
  Future<List<Revisao>> listarPorEquipe(int? equipe) {
    if (equipe == null) {
      return buscarTodos();
    }
    return consultar(
      'SELECT * FROM $tabela WHERE equipe = :equipe ORDER BY $colunaId;',
      {'equipe': equipe},
    );
  }

  /// Atualiza o estado da revisão vinculada a uma Nota Fiscal.
  Future<bool> atualizarEstadoPorNota(int idNotaFiscal, String novoEstado) =>
      executar(
        'UPDATE $tabela SET estado = :estado WHERE notafiscal_idnotaFiscal = :idNota;',
        {'estado': novoEstado, 'idNota': idNotaFiscal},
      );
}

