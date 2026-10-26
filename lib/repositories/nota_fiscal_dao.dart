// inserir(NotaFiscal nota) -> Executa o INSERT INTO...
// listarTodos() -> Executa o SELECT * FROM... e retorna uma lista de NotaFiscal.
// buscarPorNumero(String numero) -> SELECT ... WHERE numero = ...
// deletar(int id) -> DELETE FROM ...

import 'dart:io'; // Inputs

import 'package:mysql_client/mysql_client.dart';

import './database.dart';
import '../models/nota_fiscal.dart';

class NotaFiscalDao {
  // 1. INSERIR NF
  Future<void> salvar(NotaFiscal nfAdd) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var sql =
          "INSERT INTO notafiscal (numeroNota, chaveAcesso, numeroPedido, dataRecebimento, fornecedor, centroCusto, assistenteLog , supervisorLog, almoxarifeLog, dataFinalizacao, dataCadastro, recebedor, statusNota) "
          "VALUES (:numeroNota, :chaveAcesso, :numeroPedido, :dataRecebimento, :fornecedor, :centroCusto, :assistenteLog,:supervisorLog,:almoxarifeLog,:dataFinalizacao, :dataCadastro, :recebedor, :statusNota);";
      await conn.execute(sql, {
        "numeroNota": nfAdd.numeroNota,
        "chaveAcesso": nfAdd.chaveAcesso,
        "numeroPedido": nfAdd.numeroPedido,
        "dataRecebimento": nfAdd.dataRecebimento,
        "dataCadastro": nfAdd.dataCadastro,
        "fornecedor": nfAdd.fornecedor,
        "recebedor": nfAdd.recebedor,
        "centroCusto": nfAdd.centroCusto,
        "assistenteLog": nfAdd.assistenteLog,
        "supervisorLog": nfAdd.supervisorLog,
        "almoxarifeLog": nfAdd.almoxarifeLog,
        "dataFinalizacao": nfAdd.dataFinalizacao,
        "statusNota": nfAdd.statusNota,
      });

      print("Cliente salvo com sucesso!");
    } catch (e) {
      print("Erro ao salvar cliente: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  // 2. RETORNAR LISTA DE NOTAS FISCAIS
  Future<List<NotaFiscal>> buscarTodos() async {
    List<NotaFiscal> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var result = await conn.execute("SELECT * FROM notafiscal;");

      for (var row in result.rows) {
        lista.add(
          NotaFiscal(
            id: int.tryParse(row.colByName("idnotaFiscal").toString()),
            numeroNota: int.parse(row.colByName("numeroNota").toString()),
            dataRecebimento: DateTime.parse(
              row.colByName("dataRecebimento").toString(),
            ),
            dataCadastro: DateTime.parse(
              row.colByName("dataCadastro").toString(),
            ),
            recebedor: row.colByName("recebedor").toString(),
            numeroPedido: int.parse(row.colByName("numeroPedido").toString()),
            chaveAcesso: row.colByName("chaveAcesso").toString(),
            statusNota: row.colByName("statusNota").toString(),
            fornecedor: row.colByName("fornecedor").toString(),
            centroCusto: row.colByName("centroCusto").toString(),
            assistenteLog: int.parse(row.colByName("assistenteLog").toString()),
          ),
        );
      }
    } catch (e) {
      print(" Erro ao buscar NFs: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }

  // 3. ATUALIZAR CADASTRO
  Future<void> atualizar(int idAtt, String colunaDB, attCampo) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var sql =
          "UPDATE notafiscal SET $colunaDB = :attCampo WHERE idnotaFiscal = :idAtt";
      await conn.execute(sql, {"attCampo": attCampo, "idAtt": idAtt});
    } catch (e) {
      print("Erro ao tentar atualizar a NF: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  // 4. APAGAR REGISTRO
  Future<void> apagarNota(int idDel) async {
    MySQLConnection? conn;
    try {
      stdout.write(
        "Tem certeza que deseja apagar a NF:$idDel ? [1]SIM ,[2]NÃO :",
      );
      int confirm = int.parse(stdin.readLineSync()!);
      if (confirm == 2) {
        return;
      }
      conn = await Database.abrirMySQL();
      var sql = "DELETE FROM notafiscal WHERE idnotafiscal = :idDel";
      await conn.execute(sql, {"idDel": idDel});
    } catch (e) {
      print("Erro ao tentar apagar a NF: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }
}
