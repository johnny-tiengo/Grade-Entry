class CentroCusto {
  int? idcentroCusto;
  String nome;

  CentroCusto({
    this.idcentroCusto,
    required this.nome,
  });

  @override
  String toString() {
    final idStr = idcentroCusto != null ? '[$idcentroCusto] ' : '';
    return '${idStr}Centro de Custo: $nome';
  }
}

