import 'package:mysql_client/mysql_client.dart';

import 'database.dart';
import '../models/estoque.dart';

class EstoqueDao {
  // 1. INSERIR Estoque
  Future<void> salvar(Estoque estoque) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var sql =
          "INSERT INTO estoque (nome, codigo, equipe) VALUES (:nome, :codigo, :equipe);";
      await conn.execute(sql, {
        "nome": estoque.nome,
        "codigo": estoque.codigo,
        "equipe": estoque.equipe,
      });

      print("Estoque salvo com sucesso!");
    } catch (e) {
      print("Erro ao salvar Estoque: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  // 2. BUSCAR TODOS OS ESTOQUES
  Future<List<Estoque>> buscarTodos() async {
    List<Estoque> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var result = await conn.execute("SELECT * FROM estoque;");

      for (var row in result.rows) {
        lista.add(
          Estoque(
            idestoque: int.tryParse(row.colByName("idestoque") ?? ''),
            nome: row.colByName("nome") ?? '',
            codigo: row.colByName("codigo") ?? '',
            equipe: int.tryParse(row.colByName("equipe") ?? ''),
          ),
        );
      }
    } catch (e) {
      print("Erro ao buscar Estoques: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }

  // 3. BUSCAR ESTOQUES POR EQUIPE
  Future<List<Estoque>> buscarPorEquipe(int? equipe) async {
    if (equipe == null) return buscarTodos();

    List<Estoque> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var result = await conn.execute(
        "SELECT * FROM estoque WHERE equipe = :equipe;",
        {"equipe": equipe},
      );

      for (var row in result.rows) {
        lista.add(
          Estoque(
            idestoque: int.tryParse(row.colByName("idestoque") ?? ''),
            nome: row.colByName("nome") ?? '',
            codigo: row.colByName("codigo") ?? '',
            equipe: int.tryParse(row.colByName("equipe") ?? ''),
          ),
        );
      }
    } catch (e) {
      print("Erro ao buscar Estoques da equipe: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }

  // 4. ATUALIZAR ESTOQUE
  Future<void> atualizar(Estoque estoque) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var sql =
          "UPDATE estoque SET nome = :nome, codigo = :codigo, equipe = :equipe WHERE idestoque = :idestoque;";
      var result = await conn.execute(sql, {
        "idestoque": estoque.idestoque,
        "nome": estoque.nome,
        "codigo": estoque.codigo,
        "equipe": estoque.equipe,
      });

      if (result.affectedRows.toInt() > 0) {
        print("Estoque com ID ${estoque.idestoque} atualizado com sucesso!");
      } else {
        print("Nenhum estoque encontrado com o ID ${estoque.idestoque}.");
      }
    } catch (e) {
      print("Erro ao atualizar Estoque: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }
}
