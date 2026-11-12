import 'package:intl/intl.dart'; // Usado para formatar data para padrão brasileiro

class NotaFiscal {
  int? id;
  int numeroNota;
  int numeroPedido;
  String chaveAcesso;
  String? statusNota; //Aprovado, EmAnalise, Cancelado...
  DateTime dataRecebimento;
  DateTime? dataCadastro;
  String fornecedor;
  String recebedor;
  String centroCusto;
  DateTime? dataFinalizacao;
  int? usuario;
  int? equipe;
  int? estoque;
  String? setorAtraso;
  String? motivoAtraso;

  NotaFiscal({
    this.id,
    required this.numeroNota, //
    required this.numeroPedido,
    required this.chaveAcesso,
    required this.dataRecebimento, //
    this.dataCadastro,
    this.statusNota, //
    required this.fornecedor,
    required this.recebedor, //
    required this.centroCusto,
    this.dataFinalizacao,
    this.equipe,
    this.usuario,
    this.estoque,
    this.setorAtraso,
    this.motivoAtraso,
  });

  // Método para retornar uma linha formatada com os dados da NF
  String toCsv() {
    return '$id,$numeroNota,$numeroPedido,$dataRecebimento,$dataCadastro,$recebedor,$chaveAcesso,$statusNota,$fornecedor,$centroCusto,$usuario,$equipe\n';
  }

  // Padrão brasileiro (24h)
  final DateFormat _formatoBr = DateFormat('dd/MM/yyyy HH:mm');

  @override
  String toString() {
    return "[$id] Nº Nota: $numeroNota | Recebimento: ${_formatoBr.format(dataRecebimento)} | Recebedor: $recebedor | Status: ${statusNota!.toUpperCase()} |";
  }
}
