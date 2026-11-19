import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/services/nota_fiscal_services.dart';
import 'package:grade_entry/services/sla_service.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuSla extends ConsoleUI {
  final Sessao sessao;
  final NotaFiscalService service;
  final SlaService slaService;

  MenuSla(this.sessao, this.service, [SlaService? slaService])
    : slaService = slaService ?? SlaService();

  @override
  String get titulo =>
      'CONTROLE DE SLA - 72H (${sessao.username} | Equipe: ${sessao.equipe ?? "Todas"})';

  @override
  List<OpcaoMenu> get opcoes => [
    OpcaoMenu(
      'Ver NFs da equipe com SLA estourado (pendentes de justificativa)',
      _listarPendentes,
    ),
    OpcaoMenu(
      'Ver todas as NFs da equipe que estouraram o SLA (histórico)',
      _listarTodasEstouradas,
    ),
    OpcaoMenu(
      'Preencher motivo e setor de atraso (SLA > 72h)',
      _justificarAtraso,
    ),
    OpcaoMenu(
      'Consultar tempo de SLA de uma NF da equipe pelo número',
      _consultarNotaIndividual,
    ),
  ];

  void _exibirNotaComSla(NotaFiscal nota) {
    final duracao = slaService.calcularSLA(nota);
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    final setor = (nota.setorAtraso == null || nota.setorAtraso!.isEmpty)
        ? 'PENDENTE'
        : nota.setorAtraso!;
    final motivo = (nota.motivoAtraso == null || nota.motivoAtraso!.isEmpty)
        ? 'Não informado'
        : nota.motivoAtraso!;

    print(
      '$nota Equipe: ${nota.equipe ?? "-"} | Tempo SLA: ${horas}h ${minutos}min | Setor Atraso: $setor | Motivo: $motivo',
    );
  }

  Future<void> _listarPendentes() async {
    clearTerminal();
    print('\n--- NFs DA EQUIPE COM SLA ESTOURADO (> 72H) SEM JUSTIFICATIVA ---');
    final notas = await slaService.listarPendentesJustificativa(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF da sua equipe pendente de justificativa de SLA no momento.');
      return;
    }
    for (final nota in notas) {
      _exibirNotaComSla(nota);
    }
  }

  Future<void> _listarTodasEstouradas() async {
    clearTerminal();
    print('\n--- HISTÓRICO DE NFs DA EQUIPE COM SLA ESTOURADO (> 72H) ---');
    final notas = await slaService.listarTodasEstouradas(sessao);
    if (notas.isEmpty) {
      print('Nenhuma NF da sua equipe estourou o SLA de 72h até o momento.');
      return;
    }
    for (final nota in notas) {
      _exibirNotaComSla(nota);
    }
  }

  Future<void> _justificarAtraso() async {
    final pendentes = await slaService.listarPendentesJustificativa(sessao);
    if (pendentes.isEmpty) {
      print('\nNão há NFs da sua equipe com SLA estourado pendentes de justificativa.');
      return;
    }

    print('\n--- NFs DA EQUIPE AGUARDANDO JUSTIFICATIVA ---');
    for (final n in pendentes) {
      _exibirNotaComSla(n);
    }

    final escolha = lerTexto('\nDeseja justificar uma NF agora? [1] Sim [2] Não');
    if (escolha != '1') {
      print('Operação cancelada.');
      return;
    }

    final numeroNota = lerInt('Digite o Número da Nota');
    final nota = await service.buscarPorNumero(numeroNota);
    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }

    if (sessao.equipe != null && nota.equipe != sessao.equipe) {
      print('Acesso negado: a NF ${nota.numeroNota} pertence à Equipe ${nota.equipe}.');
      return;
    }

    print('\nSetores disponíveis:');
    for (var i = 0; i < SlaService.setoresPossiveis.length; i++) {
      print('${i + 1} - ${SlaService.setoresPossiveis[i]}');
    }

    final indiceSetor = lerInt('Escolha o número do setor responsável pelo atraso');
    if (indiceSetor < 1 || indiceSetor > SlaService.setoresPossiveis.length) {
      print('Opção de setor inválida!');
      return;
    }

    final setorEscolhido = SlaService.setoresPossiveis[indiceSetor - 1];
    final motivo = lerTexto('Digite o motivo da demora');

    await slaService.justificarAtraso(
      nota: nota,
      quem: sessao,
      setor: setorEscolhido,
      motivo: motivo,
    );

    print(
      'Justificativa registrada com sucesso para a NF ${nota.numeroNota} (Setor: $setorEscolhido)!',
    );
  }

  Future<void> _consultarNotaIndividual() async {
    final numeroNota = lerInt('Digite o Número da Nota');
    final nota = await service.buscarPorNumero(numeroNota);
    if (nota == null) {
      print('Nota não encontrada.');
      return;
    }

    if (sessao.equipe != null && nota.equipe != sessao.equipe) {
      print('Acesso negado: a NF ${nota.numeroNota} pertence à Equipe ${nota.equipe}.');
      return;
    }

    final duracao = slaService.calcularSLA(nota);
    final estourou = slaService.estourouSLA(nota);
    print('\n--- STATUS DE SLA DA NF ${nota.numeroNota} ---');
    _exibirNotaComSla(nota);
    print(
      'Situação: ${estourou ? "SLA ESTOURADO (${duracao.inHours - SlaService.limiteHorasSla}h além do limite de ${SlaService.limiteHorasSla}h)" : "DENTRO DO PRAZO (${SlaService.limiteHorasSla - duracao.inHours}h restantes)"}',
    );
  }
}
