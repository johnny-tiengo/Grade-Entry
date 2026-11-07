import 'package:mysql_client/mysql_client.dart';
import '../models/centrocusto.dart';
import './database.dart';

class CentrocustoDao {
 
  // 1. INSERIR CENTRO DE CUSTO
  Future<void> salvar(CentroCusto centrocusto) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var sql = "INSERT INTO centrocusto (nome) VALUES (:nome);";
      await conn.execute(sql, {
        "nome": centrocusto.nome,
      });

      print("Centro de Custo salvo com sucesso!");
    } catch (e) {
      print("Erro ao salvar Centro de Custo: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  // 2. BUSCAR TODOS OS CENTRO DE CUSTO
  Future<List<CentroCusto>> buscarTodos() async {
    List<CentroCusto> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var result = await conn.execute("SELECT * FROM centrocusto;");

      for (var row in result.rows) {
        lista.add(CentroCusto(
          idcentroCusto: int.tryParse(row.colByName("idcentroCusto").toString()),
          nome: row.colByName("nome").toString(),
        ));
      }
    } catch (e) {
      print(" Erro ao buscar Centro de Custo: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }

  Future<void> atualizar(CentroCusto centroCusto) async {
  MySQLConnection? conn;
  try {
    conn = await Database.abrirMySQL();

    var sql =
        "UPDATE centrocusto SET nome = :nome WHERE idcentroCusto = :idcentroCusto;";
    var result = await conn.execute(sql, {
      "idcentroCusto": centroCusto.idcentroCusto,
      "nome": centroCusto.nome,
    });

    if (result.affectedRows.toInt() > 0) {
      print(
        "Centro de Custo com ID ${centroCusto.idcentroCusto} atualizado com sucesso!",
      );
    } else {
      print("Nenhum cliente encontrado com o ID ${centroCusto.idcentroCusto}.");
    }
  } catch (e) {
    print("Erro ao atualizar CentroCusto: $e");
  } finally {
    if (conn != null && conn.connected) {
      await conn.close();
    }
  }
}

}