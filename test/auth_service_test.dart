import 'package:grade_entry/services/auth_service.dart';
import 'package:grade_entry/services/hash_service.dart';
import 'package:test/test.dart';

void main() {
  group('AuthService - Autenticação e Perfis', () {
    test('Deve autenticar o admin com credenciais válidas', () async {
      final usuario = await AuthService.autenticar('admin', '123');
      expect(usuario, isNotNull);
      expect(usuario!.login.toLowerCase(), 'admin');
      expect(usuario.perfil.toLowerCase(), 'admin');
    });

    test('Deve autenticar ignorando maiúsculas/minúsculas no login', () async {
      final usuario = await AuthService.autenticar('ADMIN', '123');
      expect(usuario, isNotNull);
      expect(usuario!.login.toLowerCase(), 'admin');
    });

    test('Não deve autenticar com senha incorreta', () async {
      final usuario = await AuthService.autenticar('admin', 'senhaErrada');
      expect(usuario, isNull);
    });

    test('Não deve autenticar com usuário inexistente', () async {
      final usuario = await AuthService.autenticar('inexistente', '123');
      expect(usuario, isNull);
    });

    test('Deve autenticar outros perfis (assistente, almoxarife, supervisor)', () async {
      final assistente = await AuthService.autenticar('assistente', '123');
      final almoxarife = await AuthService.autenticar('almoxarife', '123');
      final supervisor = await AuthService.autenticar('supervisor', '123');

      expect(assistente?.perfil.toLowerCase(), 'assistente');
      expect(almoxarife?.perfil.toLowerCase(), 'almoxarife');
      expect(supervisor?.perfil.toLowerCase(), 'supervisor');
    });

    test('Hash bcrypt não deve ser igual à senha e deve ter formato bcrypt', () {
      final hash = HashService.gerarHash('123');
      expect(hash, isNot(equals('123')));
      expect(HashService.ehBcrypt(hash), isTrue);
      expect(hash.length, equals(60));
    });

    test('A mesma senha deve gerar hashes diferentes (salt aleatório)', () {
      final hash1 = HashService.gerarHash('123');
      final hash2 = HashService.gerarHash('123');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verificar deve aceitar a senha certa e recusar a errada', () {
      final hash = HashService.gerarHash('minhaSenha');
      expect(HashService.verificar('minhaSenha', hash), isTrue);
      expect(HashService.verificar('outraSenha', hash), isFalse);
    });

    test('Não deve autenticar digitando o hash no lugar da senha', () async {
      final hashDoAdmin = AuthService.usuariosPadrao
          .firstWhere((u) => u.login == 'admin')
          .senha;
      final usuario = await AuthService.autenticar('admin', hashDoAdmin);
      expect(usuario, isNull);
    });

    test('Deve reconhecer e validar hash SHA-256 legado (para migração)', () {
      const sha256De123 =
          'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3';
      expect(HashService.ehSha256Legado(sha256De123), isTrue);
      expect(HashService.verificarSha256Legado('123', sha256De123), isTrue);
      expect(HashService.verificarSha256Legado('errada', sha256De123), isFalse);
    });

    test('Usuários padrão em memória devem armazenar senha em hash bcrypt', () {
      for (var u in AuthService.usuariosPadrao) {
        expect(u.senha, isNot(equals('123')));
        expect(HashService.ehBcrypt(u.senha), isTrue);
      }
    });
  });
}
