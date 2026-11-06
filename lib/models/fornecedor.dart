class Fornecedor {
  int? idFornecedor;
  String razaoSocial;
  String cnpj;
  String endereco;

  Fornecedor({
    this.idFornecedor,
    required this.razaoSocial,
    required this.cnpj,
    required this.endereco,
  });

  @override
  String toString() {
    final idStr = idFornecedor != null ? '[$idFornecedor] ' : '';
    return '${idStr}Razão Social: $razaoSocial | CNPJ: $cnpj | Endereço: $endereco';
  }
}

