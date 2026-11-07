class Fornecedor {
  int? idfornecedor;
  String razaoSocial;
  String cnpj;
  String endereco;

  Fornecedor({
    this.idfornecedor,
    required this.razaoSocial,
    required this.cnpj,
    required this.endereco
  });

@override
String toString(){
  return "[$idfornecedor] Razão Social: $razaoSocial | CNPJ: $cnpj | Endereço: $endereco";
}

}