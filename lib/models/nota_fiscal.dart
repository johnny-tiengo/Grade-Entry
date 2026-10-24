class NotaFiscal{
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
  int? assistenteLog;
  int? supervisorLog;
  int? almoxarifeLog;
  DateTime? dataFinalizacao;

  NotaFiscal({this.id,
            required this.numeroNota, //
            required this.numeroPedido,
            required this.chaveAcesso,
            required this.dataRecebimento, //
            this.dataCadastro,
            this.statusNota, //
            required this.fornecedor,
            required this.recebedor, //
            required this.centroCusto,
            this.assistenteLog,
            this.supervisorLog,
            this.almoxarifeLog,
            this.dataFinalizacao,            
            });

@override
String toString(){
  return "[$id] Nº Nota:$numeroNota | Recebimento:$dataRecebimento | Recebedor:$recebedor | Status:$statusNota | assistentemysql:$dataCadastro";
  }
}