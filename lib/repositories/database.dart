//Uma classe para gerenciar a conexão (abrir e fechar conexão com o MySQL de forma segura).
import 'package:mysql_client/mysql_client.dart';
import 'package:dotenv/dotenv.dart';

class Database {
  static final _env = DotEnv(includePlatformEnvironment: true)..load();

  static String get _host => _env['DB_HOST'] ?? 'localhost';
  static int get _port => int.tryParse(_env['DB_PORT'] ?? '3306') ?? 3306;
  static String get _user => _env['DB_USER'] ?? 'root';
  static String get _password => _env['DB_PASSWORD'] ?? '';
  static String get _dbName => _env['DB_NAME'] ?? 'gradeentry';

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
