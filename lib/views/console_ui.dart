import 'dart:io';
import 'package:intl/intl.dart';

/// Uma linha do menu: código digitado, texto exibido e ação executada.
class OpcaoMenu {
  final String codigo;
  final String texto;
  final Future<void> Function() acao;
  const OpcaoMenu(this.codigo, this.texto, this.acao);
}

/// Representa um campo de uma tabela que pode ser editado pelo menu.
class CampoEditavel {
  final String rotulo;
  final String coluna;
  final Object Function() ler;
  const CampoEditavel(this.rotulo, this.coluna, this.ler);
}

/// Base de todos os menus: mostra as opções, lê a escolha, valida a entrada
/// básica e repassa para o Service/DAO. Cada menu só declara título e opções.
abstract class ConsoleUI {
  String get titulo;
  List<OpcaoMenu> get opcoes;
  String get textoSaida => 'Voltar';

  Future<void> executar() async {
    clearTerminal();
    while (true) {
      print('\n--- $titulo ---');
      for (final o in opcoes) {
        print('${o.codigo}. ${o.texto}');
      }
      print('0. $textoSaida');

      final escolha = lerTexto('Escolha uma opção');
      if (escolha == '0') return;

      final achou = opcoes.where((o) => o.codigo == escolha);
      if (achou.isEmpty) {
        print('Opção inválida! Tente novamente.');
        continue;
      }
      try {
        await achou.first.acao();
      } on ArgumentError catch (e) {
        print('Não foi possível concluir: ${e.message}');
      } catch (e) {
        print('Erro: $e');
      }
    }
  }

  String lerTexto(String rotulo, {bool obrigatorio = true}) {
    while (true) {
      stdout.write('$rotulo: ');
      final v = (stdin.readLineSync() ?? '').trim();
      if (v.isNotEmpty || !obrigatorio) return v;
      print('Campo obrigatório!');
    }
  }

  int lerInt(String rotulo) {
    while (true) {
      final v = int.tryParse(lerTexto(rotulo));
      if (v != null) return v;
      print('Digite apenas números inteiros.');
    }
  }

  int? lerIntOpcional(String rotulo) {
    final texto = lerTexto(rotulo, obrigatorio: false);
    if (texto.isEmpty) return null;
    return int.tryParse(texto);
  }

  /// Lê data e hora separadas (como no main original) e devolve DateTime.
  DateTime lerDataHora(String rotulo) {
    final formato = DateFormat('dd/MM/yyyy HH:mm');
    while (true) {
      final data = lerTexto('$rotulo - data (dd/MM/aaaa)');
      final hora = lerTexto('$rotulo - hora (HH:mm)');
      try {
        return formato.parseStrict('$data $hora');
      } on FormatException {
        print('Data/hora inválida!');
      }
    }
  }

  bool confirmar([String pergunta = 'Deseja continuar?']) =>
      lerTexto('$pergunta [1] SIM [2] NÃO') == '1';

  /// Exibe uma lista numerada de [CampoEditavel] e retorna o campo escolhido.
  CampoEditavel? escolherCampoEditavel(List<CampoEditavel> campos) {
    for (var i = 0; i < campos.length; i++) {
      print('${i + 1} - ${campos[i].rotulo}');
    }
    final n = lerInt('QUAL CAMPO DESEJA ALTERAR');
    if (n < 1 || n > campos.length) {
      print('Opção inválida!');
      return null;
    }
    return campos[n - 1];
  }

  void clearTerminal() {
    // \x1B[2J = limpa a tela visível
    // \x1B[0;0H = volta o cursor para linha 1, coluna 1
    // \x1B[3J = apaga todo o buffer de rolagem (scrollback)
    stdout.write('\x1B[2J\x1B[0;0H\x1B[3J');
  }
}
