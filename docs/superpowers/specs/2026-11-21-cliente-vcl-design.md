# delphi-vcl-client — design

Data: 2026-11-21 · Autor: Kauê Lessa (com Claude Code)

## Intenção

Cliente desktop VCL do ecossistema `delphi-horse-api` (o README da API já anuncia "um cliente desktop (VCL) e um app mobile (FireMonkey) consumindo esta API"). Peça do portfólio público de um Desenvolvedor Delphi Sênior: o código precisa ser limpo, em camadas, testado e servir de vitrine, no mesmo padrão dos repositórios `delphi-horse-api` e `delphi-emissor-nfe`.

O sistema cobre **todas** as funcionalidades da API e mostra, ao lado dela, a separação cliente/servidor: o desktop não acessa banco nenhum.

## Objetivos

- Consumir todos os endpoints da API (tabela abaixo), com tratamento claro dos erros que ela devolve.
- Interface clara e moderna (estilo "app web": fundo claro, cartões brancos arredondados, botões em tons pastel).
- Rastreabilidade local: log da aplicação e log HTTP com os JSONs de envio e resposta.
- Testes DUnitX das regras do cliente sem precisar da API no ar.

## Não objetivos

- Banco de dados local. Os dados pertencem à API, que já cria o banco e as tabelas sozinha (`Infra.Migracao` da API). As regras de migração do `CLAUDE.md` continuam valendo **do lado da API**.
- Modo offline / cache de clientes e produtos: a API controla estoque numa transação; pedido montado com dados velhos venderia o que não tem.
- Alterar a API além do filtro de busca descrito em "Pré-requisito na API".
- Cadastro de usuários (a API não tem esses endpoints; o usuário vem do seed da API).

## Antiobjetivos (seria um fracasso mesmo funcionando)

- Senha ou token gravados em texto puro em qualquer arquivo ou log.
- Tela congelando enquanto espera a API.
- Mensagem de erro técnica crua ("HTTP 422", stack trace) para o usuário.
- Regra de negócio duplicada no cliente divergindo da API (a API é a fonte da verdade).

## Restrições

- Delphi 13 (RAD Studio), VCL, Win32.
- **DevExpress VCL 26.1.5** como preferência para a UI (mesma regra dos outros projetos).
- Sem dependências externas além de RTL/VCL/DevExpress (sem Boss neste projeto).
- `.pas`/`.dpr` com acento em UTF-8 com BOM; `.dfm` com `#nnn` para não ASCII.
- Nada de credencial, caminho de máquina ou dado real versionado: `config.example.ini` com valores fictícios.

## Contrato da API consumido

Base padrão `http://localhost:9000`. Todas as rotas, exceto `/health` e `/auth/login`, exigem `Authorization: Bearer <token>`. Erros vêm como `{ "erro": "mensagem" }` com status 400, 401, 404, 422 ou 500.

| Método | Rota | Uso no cliente |
|---|---|---|
| GET | `/health` → `{ "status": "ok" }` | indicador online/offline |
| POST | `/auth/login` `{login, senha}` → `{token, tipo, expiraEm}` | login (token vale 60 min, sem renovação) |
| GET | `/clientes?pagina&limite` → `{dados, pagina, limite, total}` | lista de clientes |
| GET | `/clientes/:id` | edição |
| POST / PUT | `/clientes[/:id]` `{nome, documento, email, telefone}` | cadastro / edição |
| DELETE | `/clientes/:id` | inativar (exclusão lógica; some das listas) |
| GET | `/produtos?pagina&limite` | lista de produtos |
| GET | `/produtos/:id` | edição |
| POST / PUT | `/produtos[/:id]` `{descricao, preco, estoque}` | cadastro / edição; o PUT com `estoque` é o ajuste de estoque (valor absoluto) |
| DELETE | `/produtos/:id` | inativar |
| GET | `/pedidos?pagina&limite[&clienteId]` | lista de pedidos, filtro por cliente |
| GET | `/pedidos/:id` | detalhe com itens |
| POST | `/pedidos` `{clienteId, itens:[{produtoId, quantidade}]}` | criar (API baixa estoque) |
| PATCH | `/pedidos/:id/cancelar` | cancelar (só `ABERTO`; API devolve estoque) |

Pedido: `{id, cliente:{id,nome}, data (ISO 8601), status (ABERTO/CANCELADO), valorTotal, itens:[{id, produtoId, descricao, quantidade, precoUnitario, valorTotal}]}`. Limite máximo de página: 100. Exemplos válidos e inválidos em `delphi-horse-api/docs/exemplos/`.

Limitações da API que o cliente respeita: listas não trazem campo "ativo" (inativos não aparecem); não há reativação. A falta de filtro de texto é resolvida pelo pré-requisito abaixo.

## Pré-requisito na API (decidido)

Antes do cliente, uma tarefa pequena no repositório `delphi-horse-api`: parâmetro opcional `?busca=` em `GET /clientes` (por nome ou documento) e `GET /produtos` (por descrição), combinável com `pagina`/`limite`, filtrado no SQL com parâmetro (nunca concatenado), coberto por testes DUnitX e documentado no README da API (tabela de endpoints e seção de listagens). Sem `busca`, o comportamento atual não muda. O `total` da resposta passa a refletir o filtro.

Chamada minha (ajustável por quem constrói): nome/descrição com "contém" sem diferenciar maiúsculas; documento comparado só pelos caracteres alfanuméricos, para `529.982.247-25` e `52998224725` acharem o mesmo cliente.

## Funcionalidades

1. **Login**: usuário e senha; "Lembrar usuário" e, opcionalmente, "Lembrar senha". Perfil de API escolhido na própria tela.
2. **Situação da API**: indicador na barra de status, consultando `/health` periodicamente.
3. **Clientes**: lista paginada com busca por nome ou documento (via API); cadastrar, editar, inativar (com confirmação).
4. **Produtos**: lista paginada com busca por descrição (via API); cadastrar, editar (inclui estoque), inativar.
5. **Pedidos**: lista paginada com filtro por cliente; detalhe com itens; novo pedido (escolher cliente e produtos por busca na API e quantidades, ver total); cancelar pedido aberto (com confirmação).
6. **Sessão expirada**: qualquer 401 fora do login pede a senha de novo (diálogo de relogin) e repete a requisição, sem perder o que estava na tela.
7. **Erros**: 400/404/422 mostram a mensagem `erro` da API como aviso; 500 e falha de conexão mostram mensagem amigável e vão para o log.

## O que fica salvo localmente (sem banco)

| Dado | Onde | Observação |
|---|---|---|
| Perfis de API (nome + URL), timeout, opções de log | `config.ini` ao lado do exe (com `config.example.ini` versionado) | configuração da instalação |
| Log da aplicação | `logs\AAAA-MM-DD.log` | um arquivo por dia |
| Log HTTP | `logs\http\AAAA-MM-DD.log` | uma entrada por chamada: método, rota, status, tempo, JSON enviado e recebido; **senha e token mascarados**; liga/desliga no `config.ini` |
| Login lembrado, último perfil usado | `%APPDATA%\DelphiVclClient\usuario.ini` | por usuário do Windows |
| Senha lembrada | mesmo arquivo, cifrada com **DPAPI** (`CryptProtectData`, escopo do usuário) | só com a opção marcada; nunca em texto puro |
| Preferências de tela | `%APPDATA%\DelphiVclClient\` | posição das janelas, layout dos grids (recurso nativo do DevExpress), itens por página |
| Rascunho do pedido | `%APPDATA%\DelphiVclClient\rascunho-pedido.json` | gravado a cada alteração do pedido em digitação; oferecido de volta ao abrir "Novo pedido"; apagado ao enviar com sucesso ou descartar |

## Visual (escolhido: "B · Cartões em tons pastel")

- Fundo da janela cinza bem claro; conteúdo em **cartão branco** com cantos arredondados (≈10–12px) e sombra leve.
- **Menu em abas no topo** (Pedidos · Clientes · Produtos), marca "Vendas" à esquerda.
- Campos com fundo levemente acinzentado e cantos arredondados.
- **Botões em tons pastel por função**: azul-claro para Novo, verde-claro para Editar/Salvar, vermelho-claro para Inativar/Cancelar.
- Base: DevExpress com skin clara arredondada (WXI) e paleta ajustada; `TdxLayoutControl` nos forms; `TcxGrid` nas listas.

Esboço da tela de lista:

```
 Vendas   Pedidos   [Clientes]   Produtos                    ● API online
 ┌─────────────────────────────────────────────────────────────────────┐
 │ [ Buscar...            ]            (Inativar) (Editar) (+ Novo)   │
 │ Nome              CPF/CNPJ             E-mail                       │
 │ Maria Souza       529.982.247-25       maria@exemplo.com            │
 │ ...                                                                 │
 │                                   ‹ 1 2 3 ›   20 por página  57 no total │
 └─────────────────────────────────────────────────────────────────────┘
```

## Abordagens consideradas (comunicação com a API)

1. **Componentes REST nativos** (`TRESTClient`/`TRESTRequest`/`TRESTResponse`): conhecidos, mas acoplam o código aos componentes, dificultam testar sem a API e espalham o log HTTP.
2. **Cliente HTTP próprio sobre `TNetHTTPClient`** — **escolhida**: interface `IHttpClient` pequena, única unit que faz HTTP, anexa token e grava o log mascarado; camada `Api.*` converte JSON ↔ model com `System.JSON` e erros em exceções; testes com HTTP falso que devolve os JSONs de exemplo da API. Sem dependências externas; melhor vitrine de arquitetura.
3. **RESTRequest4Delphi via Boss**: sintaxe fluente, mas adiciona dependência externa e mostra menos do próprio trabalho.

## Arquitetura (decidida)

Camadas em `src/`, espelhando os outros projetos, com `Api/` no lugar de `Repositories/`:

- `Views/` — forms e frames VCL/DevExpress. Só interface.
- `Controllers/` — recebem ações das telas, chamam Services, devolvem dados para exibição.
- `Services/` — regras do cliente (validação de campos obrigatórios antes de enviar, montagem do pedido e total, rascunho, sessão).
- `Api/` — único lugar que conhece rotas e JSON (`Api.Auth`, `Api.Cliente`, `Api.Produto`, `Api.Pedido`, `Api.Health`), sobre `IHttpClient`.
- `Models/` — Cliente, Produto, Pedido, ItemPedido, Pagina<T>, Sessao.
- `Infra/` — `IHttpClient` + implementação `TNetHTTPClient`, config, log (app e HTTP), DPAPI, preferências.

Interfaces em todas as fronteiras (`IClienteApi`, `IPedidoService`…) para DUnitX com fakes. Exceções tipadas a partir do status: `EApiValidacao` (400/422), `EApiNaoEncontrado` (404), `EApiNaoAutorizado` (401), `EApiIndisponivel` (conexão/timeout/500).

Chamadas à API fora da thread principal (`TTask`), com retorno à tela por `TThread.Queue`, indicador de carregando e botões desabilitados durante a chamada.

## Repositório

Novo repositório `delphi-vcl-client` no GitHub do autor, com `CLAUDE.md` (mesmas regras de estilo, segurança, UTF-8+BOM, DevExpress), `README.md` com roadmap, `config.example.ini`, `tests/` (DUnitX) e `docs/screenshots/`. `CLAUDE.local.md` e `config.ini` nunca versionados (o primeiro via `.git/info/exclude`).

## Testes (mínimo esperado)

- Conversão JSON ↔ model de cada recurso, incluindo página (`dados/pagina/limite/total`) e datas ISO 8601.
- Mapeamento status HTTP → exceção e leitura do `{ "erro" }`.
- Mascaramento de senha e token no log HTTP.
- Montagem do pedido: total, produto repetido soma quantidade em vez de duplicar a linha (a API rejeita repetido), quantidade > 0.
- Rascunho: salvar, restaurar, descartar.
- Fluxo de 401: relogin e repetição da chamada (com HTTP falso).
- DPAPI: cifrar e decifrar ida e volta.

## Deixado para quem constrói

- Telas: o Claude Code gera os `.pas` **e os `.dfm`** (autorizado pelo autor, como no emissor), validando cada form carregado em runtime; o autor ajusta depois no RAD Studio. Registrar essa exceção no `CLAUDE.md` do projeto.
- Componente exato do menu em abas e de cada tela (respeitando DevExpress 26.1.5 e o visual acima).
- Como obter os botões coloridos por função na skin escolhida (cores do `TcxButton`, paleta customizada, ou skin elements); validar na 26.1.5 e, se algo não for possível, aproximar mantendo os tons pastel.
- Intervalo do `/health` (sugestão 30 s), timeout HTTP (sugestão 15 s), retenção de logs.
- Nomes exatos de units/forms dentro do padrão `<Camada>.<Entidade>.pas`.
- Formato numérico do JSON sempre com ponto decimal, independente das configurações regionais.

## Decisões do autor nesta conversa

- Sem banco local; o que for local fica em arquivos e `.ini` (tabela acima).
- Visual "B · Cartões em tons pastel".
- Comunicação pela abordagem 2 (cliente HTTP próprio).
- Busca resolvida na API (`?busca=`), como pré-requisito.
- `.dfm` gerados pelo Claude Code.
- Nome do repositório: `delphi-vcl-client`.
