class CentroCusto{
  int? idcentroCusto;
  String nome;

  CentroCusto({
    this.idcentroCusto, 
    required this.nome
    });

  @override
  String toString(){
    return "[$idcentroCusto] Nome: $nome";
  }

}