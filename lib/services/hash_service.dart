import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

/// Responsável por proteger as senhas antes de irem para o banco.
///
/// Usa bcrypt: cada hash tem um salt aleatório embutido e o cálculo é
/// propositalmente lento, o que dificulta ataques de força bruta e
/// inviabiliza tabelas de hashes prontos (rainbow tables).
class HashService {
  /// Custo do bcrypt (2^10 iterações). Valores maiores = mais seguro e mais lento.
  static const int _custo = 10;

  static final RegExp _regexSha256 = RegExp(r'^[a-f0-9]{64}$');

  /// Gera o hash bcrypt de uma senha. A mesma senha gera hashes diferentes a cada chamada.
  static String gerarHash(String senha) {
    return BCrypt.hashpw(senha, BCrypt.gensalt(logRounds: _custo));
  }

  /// Confere se a senha digitada corresponde ao hash bcrypt salvo.
  static bool verificar(String senha, String hash) {
    if (!ehBcrypt(hash)) return false;
    try {
      return BCrypt.checkpw(senha, hash);
    } catch (_) {
      return false;
    }
  }

  /// Indica se o valor salvo já é um hash bcrypt (ex: "$2a$10$...").
  static bool ehBcrypt(String valor) {
    return RegExp(r'^\$2[aby]?\$\d{2}\$').hasMatch(valor);
  }

  /// Indica se o valor salvo está no formato antigo (SHA-256 sem salt, 64 caracteres hex).
  static bool ehSha256Legado(String valor) {
    return _regexSha256.hasMatch(valor.toLowerCase());
  }

  /// Confere uma senha contra um hash SHA-256 antigo. Usado apenas para
  /// migrar usuários que ainda têm o formato antigo no banco.
  static bool verificarSha256Legado(String senha, String hashSha256) {
    final calculado = sha256.convert(utf8.encode(senha.trim())).toString();
    return calculado == hashSha256.toLowerCase();
  }
}
