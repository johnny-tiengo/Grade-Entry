import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/repositories/database.dart';

/// Classe base abstrata para todos os DAOs (Data Access Objects) do sistema.
///
/// Aplica HIERARQUIA e POLIMORFISMO:
/// - Hierarquia: centraliza a abertura/fechamento de conexão MySQL e os comandos
///   CRUD padrão (`salvar`, `buscarTodos`, `buscarPorId`, `atualizar`, `apagar`).
/// - Polimorfismo: cada classe filha (`NotaFiscalDao`, `FornecedorDao`,
///   `CentroCustoDao`, `UsuarioDao`) sobrescreve (`@override`) apenas os dados
///   específicos da sua tabela (`tabela`, `colunaId`, `mapear` e `paraMapa`).
abstract class BaseDao<T> {
  /// Nome da tabela no MySQL (ex.: 'notafiscal', 'fornecedor', 'centrocusto').
  String get tabela;

  /// Nome da coluna de chave primária (ex.: 'idnotaFiscal', 'idfornecedor').
  String get colunaId;

  /// Converte uma linha retornada pelo MySQL ([ResultSetRow]) em um objeto [T].
  T mapear(ResultSetRow row);

  /// Converte um objeto [T] em um mapa `{"nomeColuna": valor}` para o INSERT.
  Map<String, dynamic> paraMapa(T item);

  // --- Helpers de leitura segura para as classes filhas usarem no mapear() ---

  int? lerInt(ResultSetRow row, String coluna) =>
      int.tryParse(row.colByName(coluna) ?? '');

  DateTime? lerData(ResultSetRow row, String coluna) =>
      DateTime.tryParse(row.colByName(coluna) ?? '');

  String lerTexto(ResultSetRow row, String coluna) =>
      row.colByName(coluna) ?? '';

  // --- Métodos centrais de banco (eliminam repetição de try/catch/finally) ---

  /// Executa um SELECT parametrizado e converte todas as linhas usando [mapear].
  Future<List<T>> consultar(String sql, [Map<String, dynamic>? params]) async {
    final lista = <T>[];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      final result = await conn.execute(sql, params);
      for (final row in result.rows) {
        lista.add(mapear(row));
      }
    } catch (e) {
      print('Erro ao consultar em $tabela: $e');
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
    return lista;
  }

  /// Executa um comando de escrita (INSERT, UPDATE, DELETE) de forma segura.
  Future<bool> executar(String sql, [Map<String, dynamic>? params]) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute(sql, params);
      return true;
    } catch (e) {
      print('Erro ao executar operação em $tabela: $e');
      return false;
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // --- Operações CRUD genéricas herdadas por todas as subclasses ---

  /// 1. CREATE: Monta e executa o INSERT automaticamente a partir de [paraMapa].
  Future<bool> salvar(T item) async {
    final dados = paraMapa(item);
    final colunas = dados.keys.join(', ');
    final marcadores = dados.keys.map((k) => ':$k').join(', ');
    final sql = 'INSERT INTO $tabela ($colunas) VALUES ($marcadores);';
    final ok = await executar(sql, dados);
    if (ok) print('Registro salvo em $tabela com sucesso!');
    return ok;
  }

  /// 2. READ (Todos): Lista todos os registros da tabela.
  Future<List<T>> buscarTodos() =>
      consultar('SELECT * FROM $tabela ORDER BY $colunaId;');

  /// 2.1 READ (Por ID): Busca um único registro pela chave primária [colunaId].
  Future<T?> buscarPorId(int id) async {
    final r = await consultar(
      'SELECT * FROM $tabela WHERE $colunaId = :id LIMIT 1;',
      {'id': id},
    );
    return r.isEmpty ? null : r.first;
  }

  /// 3. UPDATE: Atualiza uma coluna específica de um registro pelo seu ID.
  Future<bool> atualizar(int idAtt, String colunaDB, dynamic attCampo) =>
      executar(
        'UPDATE $tabela SET $colunaDB = :attCampo WHERE $colunaId = :idAtt;',
        {'attCampo': attCampo, 'idAtt': idAtt},
      );

  /// 4. DELETE: Remove um registro pelo seu ID.
  Future<bool> apagar(int idDel) => executar(
        'DELETE FROM $tabela WHERE $colunaId = :idDel;',
        {'idDel': idDel},
      );
}

