class Revisao {
  int? idrevisao;
  String estado; // Ex.: 'Pendente', 'Em análise', 'Liberado'
  int notafiscalId; // Coluna: notafiscal_idnotaFiscal
  int usuario;
  int? equipe;
  String perfilUsuario; // Coluna: perfil_usuario

  Revisao({
    this.idrevisao,
    this.estado = 'Pendente',
    required this.notafiscalId,
    required this.usuario,
    required this.equipe,
    required this.perfilUsuario,
  });

  @override
  String toString() {
    final idStr = idrevisao != null ? '[$idrevisao] ' : '';
    return '${idStr}NF ID: $notafiscalId | Estado: $estado | Solicitante ID: $usuario ($perfilUsuario) | Equipe: ${equipe ?? "-"}';
  }
}

