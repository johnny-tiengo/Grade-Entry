import 'package:mysql_client/mysql_client.dart';

import './database.dart';
import '../models/usuario.dart';
import '../services/hash_service.dart';

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
        // Cada usuário recebe seu próprio hash (salt diferente para cada um)
        final padroes = [
          ['Administrador', 'admin', 'Admin'],
          ['Assistente Logística', 'assistente', 'Assistente'],
          ['Supervisor Logística', 'supervisor', 'Supervisor'],
          ['Almoxarife', 'almoxarife', 'Almoxarife'],
        ];
        for (var p in padroes) {
          await conn.execute(
            "INSERT INTO usuario (nome, login, senha, perfil) VALUES (:nome, :login, :senha, :perfil);",
            {
              "nome": p[0],
              "login": p[1],
              "senha": HashService.gerarHash('123'),
              "perfil": p[2],
            },
          );
        }
      } else {
        // Migra senhas legadas em texto puro para bcrypt.
        // Hashes SHA-256 antigos não podem ser revertidos: eles são
        // convertidos para bcrypt no próximo login bem-sucedido do usuário.
        var usuarios = await conn.execute("SELECT id, senha FROM usuario;");
        for (var row in usuarios.rows) {
          final senhaSalva = row.colByName("senha").toString();
          if (HashService.ehBcrypt(senhaSalva) ||
              HashService.ehSha256Legado(senhaSalva)) {
            continue;
          }
          final id = int.tryParse(row.colByName("id").toString());
          if (id != null) {
            await conn.execute(
              "UPDATE usuario SET senha = :hash WHERE id = :id;",
              {"hash": HashService.gerarHash(senhaSalva), "id": id},
            );
          }
        }
      }
    } catch (e) {
      // Se não conseguir conectar ao banco, continua com aviso
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
  }

  /// Autentica um usuário no banco de dados MySQL.
  /// Busca apenas pelo login e confere a senha em Dart com bcrypt
  /// (o salt aleatório impede comparar o hash direto no SQL).
  Future<Usuario?> autenticar(String login, String senha) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();

      var res = await conn.execute(
        "SELECT * FROM usuario WHERE LOWER(login) = :login LIMIT 1;",
        {"login": login.trim().toLowerCase()},
      );

      if (res.rows.isEmpty) return null;

      var row = res.rows.first;
      final senhaSalva = row.colByName("senha").toString();
      final id = int.tryParse(row.colByName("id").toString());

      bool senhaCorreta = HashService.verificar(senha, senhaSalva);

      // Usuário ainda com hash SHA-256 antigo: confere no formato antigo
      // e, se a senha estiver certa, converte para bcrypt na hora.
      if (!senhaCorreta &&
          HashService.ehSha256Legado(senhaSalva) &&
          HashService.verificarSha256Legado(senha, senhaSalva)) {
        senhaCorreta = true;
        if (id != null) {
          await conn.execute(
            "UPDATE usuario SET senha = :hash WHERE id = :id;",
            {"hash": HashService.gerarHash(senha.trim()), "id": id},
          );
        }
      }

      if (!senhaCorreta) return null;

      return Usuario(
        id: id,
        nome: row.colByName("nome").toString(),
        login: row.colByName("login").toString(),
        senha: '', // o hash não precisa circular pelo sistema após o login
        perfil: row.colByName("perfil").toString(),
      );
    } catch (e) {
      print("Aviso: Falha ao consultar usuário no banco: $e");
    } finally {
      if (conn != null && conn.connected) {
        await conn.close();
      }
    }
    return null;
  }

  /// Cadastra um novo usuário no banco de dados.
  /// Recebe a senha em texto puro e é o ÚNICO ponto que aplica o hash.
  Future<bool> salvar(Usuario usuario) async {
    MySQLConnection? conn;
    try {
      conn = await Database.abrirMySQL();
      final senhaFinal = HashService.gerarHash(usuario.senha);

      await conn.execute(
        "INSERT INTO usuario (nome, login, senha, perfil) VALUES (:nome, :login, :senha, :perfil);",
        {
          "nome": usuario.nome.trim(),
          "login": usuario.login.trim().toLowerCase(),
          "senha": senhaFinal,
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
