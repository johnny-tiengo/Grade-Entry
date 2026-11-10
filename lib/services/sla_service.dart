import 'package:grade_entry/models/nota_fiscal.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/nota_fiscal_dao.dart';

class SlaService {
  static const int limiteHorasSla = 72;

  static const List<String> setoresPossiveis = [
    'Logística',
    'Compras',
    'Fiscal',
    'Cadastro',
    'Financeiro',
  ];

  final NotaFiscalDao _dao;

  SlaService([NotaFiscalDao? dao]) : _dao = dao ?? NotaFiscalDao();

  // Calcula o tempo decorrido desde a dataRecebimento até a dataFinalizacao (ou até agora, se aberta).
  Duration calcularSLA(NotaFiscal nota) {
    final DateTime inicio = nota.dataRecebimento;
    final DateTime fim = nota.dataFinalizacao ?? DateTime.now();
    return fim.difference(inicio);
  }

  // Verifica se uma NF específica estourou as 72h de SLA.
  bool estourouSLA(NotaFiscal nota) {
    return calcularSLA(nota).inHours >= limiteHorasSla;
  }

  // Lista todas as NFs da equipe do usuário que estouraram 72h e ainda NÃO possuem setor/motivo preenchido.
  Future<List<NotaFiscal>> listarPendentesJustificativa(Sessao quem) {
    return _dao.buscarSlaEstouradoPendente(equipe: quem.equipe);
  }

  // Lista todas as NFs da equipe do usuário que estouraram 72h (incluindo as já justificadas).
  Future<List<NotaFiscal>> listarTodasEstouradas(Sessao quem) {
    return _dao.buscarTodasSlaEstourado(equipe: quem.equipe);
  }

  // Salva o setor responsável e o motivo da demora para uma NF com SLA estourado.
  Future<void> justificarAtraso({
    required NotaFiscal nota,
    required Sessao quem,
    required String setor,
    required String motivo,
  }) async {
    if (quem.equipe != null && nota.equipe != quem.equipe) {
      throw ArgumentError(
        'Só a equipe responsável por esta NF (Equipe ${nota.equipe}) pode justificar o SLA.',
      );
    }
    if (!estourouSLA(nota)) {
      throw ArgumentError(
        'A NF ${nota.numeroNota} ainda está dentro do prazo de $limiteHorasSla horas.',
      );
    }
    if (!setoresPossiveis.contains(setor)) {
      throw ArgumentError(
        'Setor inválido. Escolha entre: ${setoresPossiveis.join(", ")}.',
      );
    }
    if (motivo.trim().isEmpty) {
      throw ArgumentError('O motivo do atraso não pode ser vazio.');
    }

    await _dao.registrarJustificativaSla(nota.id!, setor, motivo.trim());
  }
}
