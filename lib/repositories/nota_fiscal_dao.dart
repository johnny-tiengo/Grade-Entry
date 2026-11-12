// inserir(NotaFiscal nota) -> Executa o INSERT INTO...
// listarTodos() -> Executa o SELECT * FROM... e retorna uma lista de NotaFiscal.
// buscarPorNumero(String numero) -> SELECT ... WHERE numero = ...
// deletar(int id) -> DELETE FROM ...
import 'package:mysql_client/mysql_client.dart';
import 'package:grade_entry/repositories/database.dart';
import 'package:grade_entry/models/nota_fiscal.dart';

class NotaFiscalDao {
  // Converte uma linha do banco em NotaFiscal (usado por todas as consultas)
  NotaFiscal _mapear(ResultSetRow row) {
    int? inteiro(String col) => int.tryParse(row.colByName(col) ?? '');
    DateTime? data(String col) => DateTime.tryParse(row.colByName(col) ?? '');

    return NotaFiscal(
      id: inteiro("idnotaFiscal"),
      numeroNota: int.parse(row.colByName("numeroNota")!),
      numeroPedido: int.parse(row.colByName("numeroPedido")!),
      chaveAcesso: row.colByName("chaveAcesso") ?? '',
      statusNota: row.colByName("statusNota"),
      dataRecebimento: DateTime.parse(row.colByName("dataRecebimento")!),
      dataCadastro: data("dataCadastro"),
      fornecedor: row.colByName("fornecedor") ?? '',
      recebedor: row.colByName("recebedor") ?? '',
      centroCusto: row.colByName("centroCusto") ?? '',
      dataFinalizacao: data("dataFinalizacao"),
      usuario: inteiro("usuario"),
      equipe: inteiro("equipe"),
      estoque: inteiro("estoque"),
      setorAtraso: row.colByName("setorAtraso"),
      motivoAtraso: row.colByName("motivoAtraso"),
    );
  }

  Future<List<NotaFiscal>> _consultar(String sql, [Map<String, dynamic>? params]) async {
    final lista = <NotaFiscal>[];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      final result = await conn.execute(sql, params);
      for (final row in result.rows) {
        lista.add(_mapear(row));
      }
    } catch (e) {
      print("Erro ao buscar NFs: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
    return lista;
  }

  // 1. INSERIR NF (igual ao original)
  Future<void> salvar(NotaFiscal nfAdd) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var sql =
          "INSERT INTO notafiscal (numeroNota, chaveAcesso, numeroPedido, dataRecebimento, fornecedor, centroCusto, equipe, usuario, dataFinalizacao, dataCadastro, recebedor, statusNota) "
          "VALUES (:numeroNota, :chaveAcesso, :numeroPedido, :dataRecebimento, :fornecedor, :centroCusto,:equipe , :usuario,:dataFinalizacao, :dataCadastro, :recebedor, :statusNota);";
      await conn.execute(sql, {
        "numeroNota": nfAdd.numeroNota,
        "chaveAcesso": nfAdd.chaveAcesso,
        "numeroPedido": nfAdd.numeroPedido,
        "dataRecebimento": nfAdd.dataRecebimento,
        "dataCadastro": nfAdd.dataCadastro,
        "fornecedor": nfAdd.fornecedor,
        "recebedor": nfAdd.recebedor,
        "centroCusto": nfAdd.centroCusto,
        "dataFinalizacao": nfAdd.dataFinalizacao,
        "statusNota": nfAdd.statusNota,
        "usuario": nfAdd.usuario,
        "equipe": nfAdd.equipe,
      });
      print("NF salva com sucesso!");
    } catch (e) {
      print("Erro ao salvar NF: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // 2. LISTAR TODAS
  Future<List<NotaFiscal>> buscarTodos() =>
      _consultar("SELECT * FROM notafiscal;");

  // NOVO: busca direto no banco pelo número da nota
  Future<NotaFiscal?> buscarPorNumero(int numero) async {
    final r = await _consultar(
        "SELECT * FROM notafiscal WHERE numeroNota = :n LIMIT 1;", {"n": numero});
    return r.isEmpty ? null : r.first;
  }

  // ------------------------------------------------------------------------------------
  // NOVO: usado pelo menu do supervisor (busca na tabela revisao + notafiscal)
  Future<List<NotaFiscal>> buscarPorStatus(String status) => _consultar(
      "SELECT * FROM notafiscal WHERE statusNota = :s;", {"s": status});

  // Busca NFs em revisão pendente para o supervisor (filtrando pela equipe se houver)
  Future<List<NotaFiscal>> buscarEmRevisao({int? equipe}) {
    if (equipe != null) {
      return _consultar(
        "SELECT nf.* FROM notafiscal nf "
        "INNER JOIN revisao r ON r.notafiscal_idnotaFiscal = nf.idnotaFiscal "
        "WHERE (nf.statusNota = 'revisao' OR r.estado = 'Pendente') "
        "AND nf.equipe = :equipe;",
        {"equipe": equipe},
      );
    }
    return _consultar(
      "SELECT nf.* FROM notafiscal nf "
      "INNER JOIN revisao r ON r.notafiscal_idnotaFiscal = nf.idnotaFiscal "
      "WHERE nf.statusNota = 'revisao' OR r.estado = 'Pendente';",
    );
  }

  // Registra o pedido de revisão na tabela 'revisao' com estado 'Pendente' e muda statusNota para 'revisao'
  Future<void> registrarPedidoRevisao({
    required int idNota,
    required int usuarioId,
    required int? equipe,
    required String perfilUsuario,
  }) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      // 1. Atualiza o status da NF para 'revisao'
      await conn.execute(
        "UPDATE notafiscal SET statusNota = 'revisao' WHERE idnotaFiscal = :id;",
        {"id": idNota},
      );

      // 2. Verifica se já existe registro dessa NF na tabela revisao
      final existente = await conn.execute(
        "SELECT idrevisao FROM revisao WHERE notafiscal_idnotaFiscal = :id LIMIT 1;",
        {"id": idNota},
      );

      if (existente.rows.isNotEmpty) {
        await conn.execute(
          "UPDATE revisao SET estado = 'Pendente', usuario = :usuario, equipe = :equipe, perfil_usuario = :perfil "
          "WHERE notafiscal_idnotaFiscal = :id;",
          {
            "usuario": usuarioId,
            "equipe": equipe,
            "perfil": perfilUsuario,
            "id": idNota,
          },
        );
      } else {
        await conn.execute(
          "INSERT INTO revisao (estado, notafiscal_idnotaFiscal, usuario, equipe, perfil_usuario) "
          "VALUES ('Pendente', :id, :usuario, :equipe, :perfil);",
          {
            "id": idNota,
            "usuario": usuarioId,
            "equipe": equipe,
            "perfil": perfilUsuario,
          },
        );
      }
    } catch (e) {
      print("Erro ao registrar pedido de revisão: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // Supervisor decide a revisão: atualiza o estado na tabela 'revisao' ('Em análise' ou 'Liberado') e volta a NF para 'aberto'
  Future<void> concluirRevisaoSupervisor({
    required int idNota,
    required String novoEstadoRevisao,
  }) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      await conn.execute(
        "UPDATE revisao SET estado = :estado WHERE notafiscal_idnotaFiscal = :id;",
        {"estado": novoEstadoRevisao, "id": idNota},
      );

      await conn.execute(
        "UPDATE notafiscal SET statusNota = 'aberto' WHERE idnotaFiscal = :id;",
        {"id": idNota},
      );
    } catch (e) {
      print("Erro ao atualizar revisão pelo supervisor: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // Busca NFs com status 'aberto' (para aprovação do assistente)
  Future<List<NotaFiscal>> buscarParaAprovacaoAssistente({int? equipe}) {
    if (equipe != null) {
      return _consultar(
        "SELECT * FROM notafiscal "
        "WHERE statusNota = 'aberto' AND equipe = :equipe;",
        {"equipe": equipe},
      );
    }
    return _consultar(
      "SELECT * FROM notafiscal WHERE statusNota = 'aberto';",
    );
  }

  // Busca NFs com status 'agEntrada' (para consulta e aprovação do almoxarife)
  Future<List<NotaFiscal>> buscarAguardandoEntrada({int? equipe}) {
    if (equipe != null) {
      return _consultar(
        "SELECT * FROM notafiscal "
        "WHERE statusNota = 'agEntrada' AND equipe = :equipe;",
        {"equipe": equipe},
      );
    }
    return _consultar(
      "SELECT * FROM notafiscal WHERE statusNota = 'agEntrada';",
    );
  }

  // Finaliza a NF pelo almoxarife (statusNota = 'fechado', vincula estoque e grava dataFinalizacao)
  Future<void> fecharNotaComEstoque(
    int idNota,
    int idEstoque,
    DateTime dataFinalizacao,
  ) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var sql =
          "UPDATE notafiscal SET statusNota = 'fechado', estoque = :estoque, dataFinalizacao = :dataFim "
          "WHERE idnotaFiscal = :id";
      await conn.execute(sql, {
        "estoque": idEstoque,
        "dataFim": dataFinalizacao,
        "id": idNota,
      });
    } catch (e) {
      print("Erro ao fechar NF e vincular ao estoque: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }
  //-------------------------------------------------------------------------------------

  // Busca NFs que estouraram o SLA de 72h (a partir de dataRecebimento) e ainda não têm setorAtraso preenchido
  Future<List<NotaFiscal>> buscarSlaEstouradoPendente({int? equipe}) {
    if (equipe != null) {
      return _consultar(
        "SELECT * FROM notafiscal "
        "WHERE TIMESTAMPDIFF(HOUR, dataRecebimento, COALESCE(dataFinalizacao, NOW())) >= 72 "
        "AND (setorAtraso IS NULL OR setorAtraso = '') "
        "AND equipe = :equipe;",
        {"equipe": equipe},
      );
    }
    return _consultar(
      "SELECT * FROM notafiscal "
      "WHERE TIMESTAMPDIFF(HOUR, dataRecebimento, COALESCE(dataFinalizacao, NOW())) >= 72 "
      "AND (setorAtraso IS NULL OR setorAtraso = '');",
    );
  }

  // Busca todas as NFs que estouraram o SLA de 72h (já justificadas ou não)
  Future<List<NotaFiscal>> buscarTodasSlaEstourado({int? equipe}) {
    if (equipe != null) {
      return _consultar(
        "SELECT * FROM notafiscal "
        "WHERE TIMESTAMPDIFF(HOUR, dataRecebimento, COALESCE(dataFinalizacao, NOW())) >= 72 "
        "AND equipe = :equipe;",
        {"equipe": equipe},
      );
    }
    return _consultar(
      "SELECT * FROM notafiscal "
      "WHERE TIMESTAMPDIFF(HOUR, dataRecebimento, COALESCE(dataFinalizacao, NOW())) >= 72;",
    );
  }

  // Registra o setor responsável e o motivo do atraso de SLA
  Future<void> registrarJustificativaSla(
    int idNota,
    String setor,
    String motivo,
  ) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var sql =
          "UPDATE notafiscal SET setorAtraso = :setor, motivoAtraso = :motivo WHERE idnotaFiscal = :id";
      await conn.execute(sql, {
        "setor": setor,
        "motivo": motivo,
        "id": idNota,
      });
    } catch (e) {
      print("Erro ao registrar justificativa de SLA: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // 3. ATUALIZAR (igual ao original)
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
      if (conn != null && conn.connected) await conn.close();
    }
  }

  // 4. APAGAR (a confirmação [1]SIM/[2]NÃO agora é feita no menu, não no DAO)
  Future<void> apagarNota(int idDel) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute(
          "DELETE FROM notafiscal WHERE idnotafiscal = :idDel", {"idDel": idDel});
    } catch (e) {
      print("Erro ao tentar apagar a NF: $e");
    } finally {
      if (conn != null && conn.connected) await conn.close();
    }
  }
}
