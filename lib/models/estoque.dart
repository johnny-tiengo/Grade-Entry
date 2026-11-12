class Estoque {
  int? idestoque;
  int? equipe;
  String nome;
  String codigo;

  Estoque({
    this.idestoque,
    required this.nome,
    required this.codigo,
    required this.equipe
  });

@override
String toString(){
  return "[$idestoque] Nome: $nome | Código do Estoque: $codigo";
}

}