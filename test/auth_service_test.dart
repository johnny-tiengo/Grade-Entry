import 'package:grade_entry/services/auth_service.dart';
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
  });
}
