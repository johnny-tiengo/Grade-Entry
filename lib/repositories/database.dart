//Uma classe para gerenciar a conexão (abrir e fechar conexão com o MySQL de forma segura).
import 'package:mysql_client/mysql_client.dart';

class Database {
  static const String _host = "localhost";
  static const int _port = 3306;
  static const String _user = "root";
  static const String _password = "mysql";
  static const String _dbName = "gradeentry";

  /// Método centralizado para abrir conexões
  static Future<MySQLConnection> abrirMySQL() async {
    var conn = await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _user,
      password: _password,
      databaseName: _dbName,
      secure: true, 
    );

    await conn.connect();
    return conn;
  }
}