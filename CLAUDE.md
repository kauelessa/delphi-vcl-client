# CLAUDE.md

Instruções para o Claude Code neste repositório.

## Sobre o projeto

Cliente desktop VCL da API [`delphi-horse-api`](https://github.com/kauelessa/delphi-horse-api): login com JWT, clientes, produtos e pedidos, consumindo todos os endpoints da API. Faz parte do portfólio público de Kauê Lessa (Desenvolvedor Delphi Sênior), então o código deve ser limpo, bem organizado e servir de vitrine de boas práticas.

O cliente **não tem banco de dados**: os dados pertencem à API, que cria o próprio banco e as tabelas. O que fica na máquina são arquivos (`config.ini`, logs, preferências e rascunho do pedido).

## Ambiente

- Delphi / RAD Studio 13 (Community Edition ou superior), VCL Win32. A compilação e o design de forms são feitos no RAD Studio; o Claude Code edita `.pas`, `.dpr`, `.dfm` e documentação pelo VS Code.
- **Exceção autorizada pelo autor:** o Claude Code pode criar e editar `.dfm` neste projeto, validando cada form carregado em runtime antes de entregar. `.dproj` e `.res` continuam sem edição manual; se uma unit nova entrar no projeto, atualize o `uses` do `.dpr` e avise para conferir no RAD Studio.
- Codificação: todo `.pas` e `.dpr` com caractere não ASCII deve ser salvo em **UTF-8 com BOM** (sem o BOM o compilador lê como ANSI e corrompe os acentos). Nos `.dfm`, caracteres não ASCII ficam como `#nnn` (`'Situa'#231#227'o'`), como o RAD Studio grava.
- Para rodar, a API precisa estar no ar (por padrão em `http://localhost:9000`).

## Interface (UI)

- Sempre dar preferência aos componentes do **DevExpress VCL Controls v26.1.5**: `TcxGrid`, `TcxTextEdit`, `TcxMaskEdit`, `TcxCurrencyEdit`, `TcxSpinEdit`, `TcxComboBox`, `TdxLayoutControl`, `TcxPageControl`, `TdxStatusBar`, `TdxSkinController`.
- Usar componentes padrão da VCL apenas quando não houver equivalente DevExpress adequado, explicando o motivo.
- Visual: fundo cinza bem claro, conteúdo em cartões brancos arredondados, menu em abas no topo e botões em tons pastel por função (azul novo, verde editar, vermelho inativar/cancelar). Skin base `WXI`.
- Nenhuma chamada à API na thread principal: usar `ExecutarAsync` (`Infra.Async`) com indicador de carregando e botões desabilitados durante a chamada.
- Usar apenas recursos e APIs disponíveis na versão 26.1.5; se algo depender de outra versão, avisar antes.

## Segurança (obrigatório)

- **Nunca** versionar `config.ini`, senhas, tokens ou dados reais. `config.example.ini` só com valores fictícios.
- Senha lembrada só cifrada com DPAPI (`Infra.Dpapi`), nunca em texto puro.
- O log HTTP sempre passa por `MascararSegredos` (senha e token viram `***`) e nunca grava o cabeçalho `Authorization`.

## Arquitetura

Camadas, em `src/`:

- `Views/` — forms e frames VCL/DevExpress. Apenas interface.
- `Controllers/` — recebem ações das telas, chamam os Services e devolvem dados para exibição.
- `Services/` — regras do cliente: validação de campos obrigatórios, sessão, pedido em digitação e rascunho. As regras de negócio (CPF/CNPJ, estoque, preço) são da API; não duplicar.
- `Api/` — único lugar que conhece rotas e JSON da API, sobre `IHttpClient`. Converte respostas em models e erros (`{ "erro": ... }` + status HTTP) em exceções de `Infra.Excecoes`.
- `Models/` — entidades e DTOs (Cliente, Produto, Pedido, ItemPedido, Pagina, Sessao).
- `Infra/` — HTTP (`IHttpClient`), configuração, logs, DPAPI, preferências e execução assíncrona.

Use interfaces em todas as fronteiras (`IClienteApi`, `IPedidoService`) para permitir testes com DUnitX.

## Padrões de código

- Nomes de units: `<Camada>.<Entidade>.pas` (ex.: `View.Clientes.pas`, `Service.Pedido.pas`, `Api.Produto.pas`).
- Classes com prefixo `T`, interfaces com `I`, campos privados com `F`, parâmetros com `A`, variáveis locais com `L`.
- Identificadores em português para o domínio (Cliente, Produto, Pedido); termos técnicos podem ficar em inglês.
- Sempre liberar objetos com `try..finally` ou usar interfaces com contagem de referência.
- Valores monetários com `Currency`; JSON sempre com ponto decimal, independente da configuração regional.

## Testes

- DUnitX em `tests/`. A camada `Api/` e os Services são testados com `THttpFake` (`tests/Test.Fakes.pas`), sem a API no ar.
- Toda regra nova em Service ou conversão nova de JSON deve ter teste.

## Git

- Commits pequenos, em português, no imperativo: `Adiciona tela de pedidos`, `Corrige paginação de clientes`.
- Ao concluir uma funcionalidade, marcar o item no roadmap do `README.md` e adicionar prints em `docs/screenshots/`.
