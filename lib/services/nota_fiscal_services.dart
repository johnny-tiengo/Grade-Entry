// Valida se o número da nota já existe antes de salvar.
// Valida se o valor é positivo ou se a data é válida.
// Chama o NotaFiscalRepository quando os dados estiverem prontos.

// registrarEntrada(...): Valida obrigatoriedade da chave de acesso, confere fornecedor e valida data de recebimento.
// atualizarEtapaJira(notaId, numeroJira, statusJira): Aplica a regra de negócio do documento (por exemplo: impedir avanço para o I-Manager se o status estiver como "Aguardando solicitante").
// confirmarEntradaImanager(notaId): Marca a nota como integrada e dispara a liberação para consulta do almoxarifado.
// vincularAnexoPdf(notaId, caminhoArquivo): Associa o comprovante/PDF à nota.

