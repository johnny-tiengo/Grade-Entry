import 'package:mysql_client/mysql_client.dart';

import 'database.dart';
import '../models/fornecedor.dart';

class FornecedorDao {
  // 1. INSERIR Fornecedor
  Future<void> salvar(Fornecedor fornecedor) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var sql =
          "INSERT INTO fornecedor (razaoSocial, cnpj, endereco) VALUES (:razaoSocial, :cnpj, endereco);";
      await conn.execute(sql, {
        "razaoSocial": fornecedor.razaoSocial,
        "cnpj": fornecedor.cnpj,
        "endereco": fornecedor.endereco,
      });

      print("Fornecedor salvo com sucesso!");
    } catch (e) {
      print("Erro ao salvar Fornecedor: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  // 2. BUSCAR TODOS OS FORNECEDORES
  Future<List<Fornecedor>> buscarTodos() async {
    List<Fornecedor> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var result = await conn.execute("SELECT * FROM fornecedor;");

      for (var row in result.rows) {
        lista.add(
          Fornecedor(
            idfornecedor: int.tryParse(
              row.colByName("idfornecedor").toString(),
            ),
            razaoSocial: row.colByName("razaoSocial").toString(),
            cnpj: row.colByName("cnpj").toString(),
            endereco: row.colByName("endereco").toString(),
          ),
        );
      }
    } catch (e) {
      print(" Erro ao buscar Fornecedores: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }
}

Future<void> atualizar(Fornecedor fornecedor) async {
  MySQLConnection? conn;
  try {
    conn = await Database.abrirMySQL();

    var sql =
        "UPDATE fornecedor SET razaoSocial = :razaoSocial, cnpj = :cnpj, endereco = :endereco WHERE idfornecedor = :idfornecedor;";
    var result = await conn.execute(sql, {
      "idfornecedor": fornecedor.idfornecedor,
      "razaoSocial": fornecedor.razaoSocial,
      "cnpj": fornecedor.cnpj,
      "endereco": fornecedor.endereco,
    });

    if (result.affectedRows.toInt() > 0) {
      print(
        "Fornecedor com ID ${fornecedor.idfornecedor} atualizado com sucesso!",
      );
    } else {
      print("Nenhum cliente encontrado com o ID ${fornecedor.idfornecedor}.");
    }
  } catch (e) {
    print("Erro ao atualizar fornecedor: $e");
  } finally {
    if (conn != null && conn.connected) {
      await conn.close();
    }
  }
}
