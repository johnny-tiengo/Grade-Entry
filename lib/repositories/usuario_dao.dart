import 'package:mysql_client/mysql_client.dart';

import './database.dart';
import '../models/usuario.dart';

class UsuarioDao {
  /// Cria a tabela usuario se ela não existir e insere os registros padrão caso vazia
  Future<void> inicializarTabela() async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS usuario (
          id INT AUTO_INCREMENT PRIMARY KEY,
          nome VARCHAR(100) NOT NULL,
          login VARCHAR(50) NOT NULL UNIQUE,
          senha VARCHAR(100) NOT NULL,
          perfil VARCHAR(50) NOT NULL
        );
      ''');

      var res = await conn.execute("SELECT COUNT(*) AS total FROM usuario;");
      int total = 0;
      if (res.rows.isNotEmpty) {
        total = int.tryParse(res.rows.first.colByName("total").toString()) ?? 0;
      }

      if (total == 0) {
        await conn.execute('''
          INSERT INTO usuario (nome, login, senha, perfil) VALUES
          ('Administrador', 'admin', '123', 'Admin'),
          ('Assistente Logística', 'assistente', '123', 'Assistente'),
          ('Supervisor Logística', 'supervisor', '123', 'Supervisor'),
          ('Almoxarife', 'almoxarife', '123', 'Almoxarife');
        ''');
      }
    } catch (e) {
      // Se não conseguir conectar ao banco, continua com aviso
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  /// Autentica um usuário no banco de dados MySQL
  Future<Usuario?> autenticar(String login, String senha) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var res = await conn.execute(
        "SELECT * FROM usuario WHERE LOWER(login) = :login AND senha = :senha LIMIT 1;",
        {
          "login": login.trim().toLowerCase(),
          "senha": senha.trim(),
        },
      );

      if (res.rows.isNotEmpty) {
        var row = res.rows.first;
        return Usuario(
          id: int.tryParse(row.colByName("id").toString()),
          nome: row.colByName("nome").toString(),
          login: row.colByName("login").toString(),
          senha: row.colByName("senha").toString(),
          perfil: row.colByName("perfil").toString(),
        );
      }
    } catch (e) {
      print("Aviso: Falha ao consultar usuário no banco: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return null;
  }

  /// Cadastra um novo usuário no banco de dados
  Future<bool> salvar(Usuario usuario) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute(
        "INSERT INTO usuario (nome, login, senha, perfil) VALUES (:nome, :login, :senha, :perfil);",
        {
          "nome": usuario.nome.trim(),
          "login": usuario.login.trim().toLowerCase(),
          "senha": usuario.senha.trim(),
          "perfil": usuario.perfil.trim(),
        },
      );
      return true;
    } catch (e) {
      print("Erro ao cadastrar usuário no banco: $e");
      return false;
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  /// Retorna todos os usuários cadastrados
  Future<List<Usuario>> buscarTodos() async {
    List<Usuario> lista = [];
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var res = await conn.execute("SELECT * FROM usuario ORDER BY id;");

      for (var row in res.rows) {
        lista.add(
          Usuario(
            id: int.tryParse(row.colByName("id").toString()),
            nome: row.colByName("nome").toString(),
            login: row.colByName("login").toString(),
            senha: row.colByName("senha").toString(),
            perfil: row.colByName("perfil").toString(),
          ),
        );
      }
    } catch (e) {
      print("Erro ao listar usuários do banco: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return lista;
  }

  /// Busca usuário por ID
  Future<Usuario?> buscarPorId(int id) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      var res = await conn.execute(
        "SELECT * FROM usuario WHERE id = :id LIMIT 1;",
        {"id": id},
      );

      if (res.rows.isNotEmpty) {
        var row = res.rows.first;
        return Usuario(
          id: int.tryParse(row.colByName("id").toString()),
          nome: row.colByName("nome").toString(),
          login: row.colByName("login").toString(),
          senha: row.colByName("senha").toString(),
          perfil: row.colByName("perfil").toString(),
        );
      }
    } catch (e) {
      print("Erro ao buscar usuário: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return null;
  }

  /// Atualiza o cargo/perfil de um usuário
  Future<bool> atualizarCargo(int id, String novoPerfil) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute(
        "UPDATE usuario SET perfil = :perfil WHERE id = :id;",
        {"perfil": novoPerfil, "id": id},
      );
      return true;
    } catch (e) {
      print("Erro ao atualizar cargo no banco: $e");
      return false;
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  /// Remove um usuário pelo ID
  Future<bool> apagar(int id) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      await conn.execute("DELETE FROM usuario WHERE id = :id;", {"id": id});
      return true;
    } catch (e) {
      print("Erro ao excluir usuário no banco: $e");
      return false;
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }
}
