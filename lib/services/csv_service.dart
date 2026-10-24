import '../repositories/nota_fiscal_dao.dart';
import 'dart:io';

Future<void> gerarCSV() async{
  var nfDao = NotaFiscalDao();

  File arquivo = File("backup/BACKUP_DB.csv");

  try {
    await arquivo.create(recursive: true);
    print("Arquivo de Backup cirado com sucesso em: ${arquivo.path}");
  } catch (e) {
    print("Erro ao tentar criar o arquivo: $e");
  }

  var notasFiscais = await nfDao.buscarTodos();
  if(arquivo.existsSync()){
    for (var linha in notasFiscais) {
      print("L $linha");
    }
  }

}