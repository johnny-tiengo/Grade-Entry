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
    var sink = arquivo.openWrite();
    
    // CABEÇALHO DO CSV DA NF
    sink.write('ID,NUMERO_NOTA,NUMERO_PEDIDO,DATA_RECEBIMENTO,DATA_CADASTRO,RECEBEDOR,CHAVE_ACESSO,STATUS,FORNECEDOR,CENTRO_CUSTO,ASSISTENTE_LOG\n');
    for (var nf in notasFiscais) {
      sink.write(nf.toCsv());
    }
    await sink.flush();
    await sink.close();
    print("CSV GERADO");
  }

}