import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/models/fornecedor.dart';
import 'package:grade_entry/repositories/base_dao.dart';

class FornecedorDao extends BaseDao<Fornecedor> {
  @override
  String get tabela => 'fornecedor';

  @override
  String get colunaId => 'idfornecedor';

  @override
  Fornecedor mapear(ResultSetRow row) {
    return Fornecedor(
      idFornecedor: lerInt(row, 'idfornecedor'),
      razaoSocial: lerTexto(row, 'razaoSocial'),
      cnpj: lerTexto(row, 'cnpj'),
      endereco: lerTexto(row, 'endereco'),
    );
  }

  @override
  Map<String, dynamic> paraMapa(Fornecedor f) => {
        'razaoSocial': f.razaoSocial.trim(),
        'cnpj': f.cnpj.trim(),
        'endereco': f.endereco.trim(),
      };

  /// Busca específica por CNPJ.
  Future<Fornecedor?> buscarPorCnpj(String cnpj) async {
    final r = await consultar(
      'SELECT * FROM $tabela WHERE cnpj = :cnpj LIMIT 1;',
      {'cnpj': cnpj.trim()},
    );
    return r.isEmpty ? null : r.first;
  }
}
