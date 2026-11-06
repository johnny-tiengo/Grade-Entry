import 'package:grade_entry/models/fornecedor.dart';
import 'package:grade_entry/models/sessao.dart';
import 'package:grade_entry/repositories/fornecedor_dao.dart';
import 'package:grade_entry/views/console_ui.dart';

class MenuFornecedor extends ConsoleUI {
  final Sessao sessao;
  final FornecedorDao _dao;

  MenuFornecedor(this.sessao, [FornecedorDao? dao])
      : _dao = dao ?? FornecedorDao();

  @override
  String get titulo => 'FORNECEDORES (${sessao.username})';

  bool get _podeGerenciar => sessao.ehSupervisor || sessao.ehAdmin;

  @override
  List<OpcaoMenu> get opcoes => [
        if (_podeGerenciar)
          OpcaoMenu('1', 'Cadastrar Fornecedor', _cadastrar),
        OpcaoMenu('2', 'Listar Fornecedores', _listar),
        if (_podeGerenciar)
          OpcaoMenu('3', 'Editar Fornecedor', _editar),
        if (_podeGerenciar)
          OpcaoMenu('4', 'Excluir Fornecedor', _excluir),
      ];

  Future<void> _cadastrar() async {
    print('\n--- NOVO CADASTRO DE FORNECEDOR ---');
    if (!confirmar()) {
      print('Operação cancelada.');
      return;
    }
    final razaoSocial = lerTexto('Razão Social');
    final cnpj = lerTexto('CNPJ (14 dígitos)');
    final endereco = lerTexto('Endereço');

    if (!RegExp(r'^\d{14}$').hasMatch(cnpj)) {
      throw ArgumentError('O CNPJ deve conter exatamente 14 dígitos numéricos.');
    }
    if (await _dao.buscarPorCnpj(cnpj) != null) {
      throw ArgumentError('Já existe um fornecedor cadastrado com o CNPJ $cnpj.');
    }

    await _dao.salvar(
      Fornecedor(
        razaoSocial: razaoSocial,
        cnpj: cnpj,
        endereco: endereco,
      ),
    );
  }

  Future<void> _listar() async {
    clearTerminal();
    print('\n--- LISTA DE FORNECEDORES ---');
    final lista = await _dao.buscarTodos();
    if (lista.isEmpty) {
      print('Nenhum fornecedor encontrado no banco de dados.');
      return;
    }
    lista.forEach(print);
  }

  Future<Fornecedor?> _pedirFornecedor() async {
    if (!confirmar()) {
      print('Operação cancelada.');
      return null;
    }
    final f = await _dao.buscarPorId(lerInt('ID do Fornecedor'));
    if (f == null) print('Fornecedor não encontrado.');
    return f;
  }

  Future<void> _editar() async {
    final f = await _pedirFornecedor();
    if (f == null) return;
    print(f);

    final campo = escolherCampoEditavel([
      CampoEditavel('RAZÃO SOCIAL', 'razaoSocial', () => lerTexto('Nova Razão Social')),
      CampoEditavel('CNPJ', 'cnpj', () => lerTexto('Novo CNPJ')),
      CampoEditavel('ENDEREÇO', 'endereco', () => lerTexto('Novo Endereço')),
    ]);
    if (campo == null) return;

    await _dao.atualizar(f.idFornecedor!, campo.coluna, campo.ler());
    print('Fornecedor atualizado!');
  }

  Future<void> _excluir() async {
    final f = await _pedirFornecedor();
    if (f == null) return;
    if (confirmar('Tem certeza que deseja excluir o fornecedor "${f.razaoSocial}"?')) {
      await _dao.apagar(f.idFornecedor!);
      print('Fornecedor excluído.');
    }
  }
}
