import 'package:mysql_client/mysql_client.dart';
import './database.dart';
import '../models/usuario.dart';
import '../services/hash_service.dart';


class UsuarioDao {
  /// Cria a tabela usuario se ela não existir e insere os registros padrão caso vazia
  // Future<void> inicializarTabela() async {
  //   MySQLConnection? conn;
  //   try {
  //     conn = await Database.abrirMySQL();
  //     await conn.execute('''
  //       CREATE TABLE IF NOT EXISTS usuario (
  //         id INT AUTO_INCREMENT PRIMARY KEY,
  //         nome VARCHAR(100) NOT NULL,
  //         login VARCHAR(50) NOT NULL UNIQUE,
  //         senha VARCHAR(100) NOT NULL,
  //         perfil VARCHAR(50) NOT NULL
  //       );
  //     ''');

  //     var res = await conn.execute("SELECT COUNT(*) AS total FROM usuario;");
  //     int total = 0;
  //     if (res.rows.isNotEmpty) {
  //       total = int.tryParse(res.rows.first.colByName("total").toString()) ?? 0;
  //     }

  //     if (total == 0) {
  //       await conn.execute('''
  //         INSERT INTO usuario (nome, login, senha, perfil) VALUES
  //         ('Administrador', 'admin', '123', 'Admin'),
  //         ('Assistente Logística', 'assistente', '123', 'Assistente'),
  //         ('Supervisor Logística', 'supervisor', '123', 'Supervisor'),
  //         ('Almoxarife', 'almoxarife', '123', 'Almoxarife');
  //       ''');
  //     }
  //   } catch (e) {
  //     // Se não conseguir conectar ao banco, continua com aviso
  //   } finally {
  //     if (conn != null && conn.connected) {
  //       await conn.close();
  //     }
  //   }
  // }

  /// Autentica um usuário no banco de dados MySQL.
  /// Busca apenas pelo login e confere a senha em Dart com bcrypt
  /// (o salt aleatório impede comparar o hash direto no SQL).
  /// Senhas antigas (texto puro ou SHA-256) são convertidas para bcrypt
  /// automaticamente no primeiro login válido.
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
      bool precisaMigrar = false;

      if (!senhaCorreta && !HashService.ehBcrypt(senhaSalva)) {
        if (HashService.ehSha256Legado(senhaSalva)) {
          // Formato antigo: SHA-256 sem salt
          senhaCorreta = HashService.verificarSha256Legado(senha, senhaSalva);
        } else {
          // Formato legado: senha salva em texto puro
          senhaCorreta = senhaSalva == senha.trim();
        }
        precisaMigrar = senhaCorreta;
      }

      if (!senhaCorreta) return null;

      if (precisaMigrar && id != null) {
        await conn.execute(
          "UPDATE usuario SET senha = :hash WHERE id = :id;",
          {"hash": HashService.gerarHash(senha.trim()), "id": id},
        );
      }

      return Usuario(
        equipe: int.tryParse(row.colByName("equipe").toString()),
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
      await conn.execute(
        "INSERT INTO usuario (nome, login, senha, perfil) VALUES (:nome, :login, :senha, :perfil);",
        {
          "nome": usuario.nome.trim(),
          "login": usuario.login.trim().toLowerCase(),
          "senha": HashService.gerarHash(usuario.senha),
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
            equipe: int.tryParse(row.colByName("equipe").toString()),
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
          nome: row.colByName("nome").toString(),
          login: row.colByName("login").toString(),
          senha: row.colByName("senha").toString(),
          perfil: row.colByName("perfil").toString(),
          equipe: int.tryParse(row.colByName("equipe").toString()),
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
