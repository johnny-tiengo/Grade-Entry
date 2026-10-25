

import 'package:grade_entry/services/csv_service.dart';

import '../models/nota_fiscal.dart';
import '../repositories/nota_fiscal_dao.dart';
import 'dart:io';


void main() async {
  var nfDao = NotaFiscalDao();
  bool executando = true;

  print("=========================================");
  print("       SISTEMA DE CADASTRO DE NFs        ");
  print("=========================================");

  while (executando) {
    print("\n--- MENU PRINCIPAL ---");
    print("1. Cadastrar Nova NF");
    print("2. Listar Notas Fiscais Cadastradas");
    print("3. Atualizar Registros de Nota Fiscal");
    print("4. Excluir Cadastro de Nota Fiscal");
    print("5. Sair");
    print("10. Gerar arquivo CSV do banco");
    stdout.write("Escolha uma opção: ");

    String? opcao = stdin.readLineSync();

    switch (opcao) {
      case '1':
        print("\n--- NOVO CADASTRO ---");
        stdout.write("Digite o Numero da Nota: ");
        String numNota = stdin.readLineSync() ?? "";
        int numeroNota = int.parse(numNota);

        stdout.write("Digite o Numero do Pedido: ");
        String numPedido = stdin.readLineSync() ??  "";
        int numeroPedido = int.parse(numPedido);

        stdout.write("Digite a Chave de Acesso: ");
        String chaveAcesso = stdin.readLineSync() ?? "";

        stdout.write("Digite a Data de Recebimento: ");
        String dataReceb = stdin.readLineSync() ?? "";
        DateTime dataRecebimento = DateTime.parse(dataReceb);

        stdout.write("Digite o Fornecedor: ");
        String fornecedor = stdin.readLineSync() ?? "";

        stdout.write("Digite o Recebedor: ");
        String recebedor = stdin.readLineSync() ?? "";

        stdout.write("Digite o Centro de Custo: ");
        String centroCusto = stdin.readLineSync() ?? "";

        stdout.write("Digite quem vai dar a entrada: ");
        String assistLog = stdin.readLineSync() ?? "";
        int assistenteLog = int.parse(assistLog);

        stdout.write("Digite quem é o Supervisor: ");
        String supervLog = stdin.readLineSync() ?? "";
        int supervisorLog = int.parse(supervLog);

        stdout.write("Digite quem é o Almoxarife: ");
        String almoxLog = stdin.readLineSync() ?? "";
        int almoxarifeLog = int.parse(almoxLog);

        stdout.write("Digite que dia Cadastrou: ");
        String dataCad = stdin.readLineSync() ?? "";
        DateTime dataCadastro = DateTime.parse(dataCad);

        stdout.write("Digite que dia Finalizou: ");
        String dataFinaliz = stdin.readLineSync() ?? "";
        DateTime dataFinalizacao = DateTime.parse(dataFinaliz);

        if (chaveAcesso.trim().isEmpty || fornecedor.trim().isEmpty || recebedor.trim().isEmpty || centroCusto.trim().isEmpty) {
          print("Nenhum dos campos podem ser vazios!");
          break;
        }

        var novaNF = NotaFiscal(numeroNota: numeroNota, numeroPedido: numeroPedido, chaveAcesso: chaveAcesso,
        dataRecebimento: dataRecebimento, fornecedor: fornecedor, recebedor: recebedor, centroCusto: centroCusto,
        assistenteLog: assistenteLog, supervisorLog:supervisorLog, almoxarifeLog:almoxarifeLog, dataFinalizacao:dataFinalizacao);
        print("Salvando no banco de dados...");
        await nfDao.salvar(novaNF);
        break;

      case '2':
        print("\n--- LISTA DE NOTAS FISCAIS ---");
        var notasFiscais = await nfDao.buscarTodos();

        if (notasFiscais.isEmpty) {
          print("Nenhuma Nota Fiscal foi encontrada no banco de dados.");
        } else {
          for (var c in notasFiscais) {
            print(c);
          }
        }
        break;

      case '3':
        stdout.write("Digite o ID da Nota Fiscal que deseja alterar: ");
        int idAtt = int.parse(stdin.readLineSync()!);
        stdout.write(
        "1 - NUMERO DA NOTA\n" // numeroNota
        "2 - DATA DE RECEBIMENTO\n" // dataRecebimento
        "3 - RECEBEDOR\n" // recebedor
        "4 - NUMERO DO PEDIDO\n" // numeroPedido
        "5 - CHAVE DE ACESSO\n" // chaveAcesso
        "6 - STATUS DA NOTA\n" // statusNota
        "7 - FORNECEDOR\n" // fornecesor
        "8 - CENTRO DE CUSTO\n" // centroCusto
        "QUAL CAMPO DESEJA ALTERAR: ");
        int idCol = int.parse(stdin.readLineSync()!);

        switch(idCol){
          case 1:
          stdout.write("Qual o novo número da nota: ");
          int attCampo = int.parse(stdin.readLineSync()!);
          String colunaDB = "numeroNota";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 2:
          stdout.write("Qual a Data de Recebimento: ");
          DateTime attCampo =  DateTime.parse(stdin.readLineSync()!);
          String colunaDB = "dataRecebimento";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 3:
          stdout.write("Qual o novo Recebedor: ");
          String attCampo = stdin.readLineSync()!;
          String colunaDB = "recebedor";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 4:
          stdout.write("Qual o novo número do pedido: ");
          int attCampo = int.parse(stdin.readLineSync()!);
          String colunaDB = "numeroPedido";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 5:
          stdout.write("Qual a nova chave de acesso: ");
          String attCampo = stdin.readLineSync()!;
          String colunaDB = "chaveAcesso";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 6:
          String attCampo;
          stdout.write("Qual o novo status da nota:\n"
          "1 [ABERTO] ou 2[FECHADO]: ");
          int attAux = int.parse(stdin.readLineSync()!);
          if (attAux == 1){
            attCampo = 'aberto';
          }else if(attAux == 2){
            attCampo = 'fechado';
          }else{
            print("OPÇÃO INVALIDA!!!");
            break;
          }
          String colunaDB = "statusNota";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 7:
          stdout.write("Qual o novo Fornecedor: ");
          String attCampo = stdin.readLineSync()!;
          String colunaDB = "fornecedor";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          case 8:
          stdout.write("Qual o novo Centro de Custo: ");
          String attCampo = stdin.readLineSync()!;
          String colunaDB = "centroCusto";
          await nfDao.atualizar(idAtt,colunaDB,attCampo);
          break;
          
          default:
          print("Opção inválida! Tente novamente. ");
        }

      case '4':
      stdout.write("Qual o ID da Nota Fiscal deseja deletar os registros: ");
      int idDel = int.parse(stdin.readLineSync()!);
      await nfDao.apagarNota(idDel);
      break;


      case '5':
        executando = false;
        print("\nEncerrando o programa... Até logo!");
        break;

      case '10':
        await gerarCSV();

      default:
        print("Opção inválida! Tente novamente.");
    }
  }
}