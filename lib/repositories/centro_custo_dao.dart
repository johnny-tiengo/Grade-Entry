import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/models/centro_custo.dart';
import 'package:grade_entry/repositories/base_dao.dart';

class CentroCustoDao extends BaseDao<CentroCusto> {
  @override
  String get tabela => 'centrocusto';

  @override
  String get colunaId => 'idcentroCusto';

  @override
  CentroCusto mapear(ResultSetRow row) {
    return CentroCusto(
      idcentroCusto: lerInt(row, 'idcentroCusto'),
      nome: lerTexto(row, 'nome'),
    );
  }

  @override
  Map<String, dynamic> paraMapa(CentroCusto cc) => {
        'nome': cc.nome.trim(),
      };
}

