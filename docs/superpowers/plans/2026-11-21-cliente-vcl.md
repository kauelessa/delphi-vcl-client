# delphi-vcl-client Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o cliente desktop VCL que consome todos os endpoints da `delphi-horse-api`, depois de adicionar à API o filtro `?busca=` em clientes e produtos.

**Architecture:** Views → Controllers → Services → `Api.*` → `IHttpClient` (única unit com HTTP, sobre `TNetHTTPClient`). Sem banco local: configuração em `config.ini`, preferências/credenciais em `%APPDATA%\DelphiVclClient\`, logs em arquivo. Chamadas à API fora da thread da tela.

**Tech Stack:** Delphi 13 (BDS 37.0) VCL Win32, DevExpress VCL 26.1.5 (skin WXI), `System.Net.HttpClient`, `System.JSON`, DPAPI (`Winapi.Windows`/`CryptProtectData`), DUnitX.

**Spec:** `docs/superpowers/specs/2026-11-21-cliente-vcl-design.md` (neste repositório).

## Global Constraints

- Repositórios: API em `C:\Projetos\Portifolio\GitHub\delphi-horse-api\delphi-horse-api` (já existe); cliente em `C:\Projetos\Portifolio\GitHub\delphi-vcl-client`.
- Delphi 13 VCL **Win32**; UI com **DevExpress VCL 26.1.5**; nenhuma dependência externa além de RTL/VCL/DevExpress (sem Boss no cliente).
- `.pas`/`.dpr` com qualquer caractere não ASCII: **UTF-8 com BOM**. `.dfm`: ASCII puro, não ASCII como `#nnn` (ex.: `'Situa'#231#227'o'`). Fins de linha CRLF.
- Nunca versionar `config.ini`, senhas, tokens, dados reais. `config.example.ini` só com valores fictícios. `CLAUDE.local.md` vai em `.git/info/exclude`, nunca no `.gitignore`.
- URL padrão da API `http://localhost:9000`; token JWT dura 60 min, sem renovação; `limite` máximo 100, padrão 20.
- Erros da API: `{ "erro": "mensagem" }` com 400, 401, 404, 422, 500.
- `/health` a cada **30 s**; timeout HTTP **15 s**; retenção de logs **30 dias** (configuráveis).
- Log HTTP: senha e token **sempre mascarados** (`***`); cabeçalho `Authorization` nunca é logado.
- Senha lembrada só cifrada com **DPAPI** (escopo do usuário); arquivos do usuário em `%APPDATA%\DelphiVclClient\`.
- Nomes: units `<Camada>.<Entidade>.pas`; `T` classes, `I` interfaces, `F` campos, `A` parâmetros, `L` locais; domínio em português.
- Liberação com `try..finally` ou interfaces com contagem de referência. Valores monetários em `Currency`.
- Commits pequenos, em português, imperativo, terminando com a linha `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit/push só com autorização do Kauê (o plano aprovado autoriza os commits locais; push ao final de cada fase, confirmando antes).

## Review Focus

- Busca com acentos, espaços e símbolos (`São Paulo & Cia`, `50%`, `O'Brien`): a URL vai codificada e a API trata o texto literalmente (sem curinga, sem quebrar SQL). Testes na Task 1 e na Task 6.
- Token expira no meio do trabalho (salvar cliente, enviar pedido longo): pede a senha, repete a chamada uma vez, nada se perde; se o usuário cancelar o relogin, o rascunho do pedido continua salvo. Testes na Task 5 e na Task 7.
- API fora do ar ou lenta: mensagem amigável em até 15 s, tela nunca congela e os botões voltam a ficar habilitados. Teste na Task 3.
- Windows em pt-BR (vírgula decimal): preço `279,90` digitado sai no JSON como `279.9`, e `349.9` recebido aparece como `349,90`. Teste na Task 4.
- Resposta de erro que não é JSON (HTML de proxy, 502, corpo vazio): mensagem com o status HTTP, nunca erro de parse. Teste na Task 4.

---

## Ferramentas de verificação (fora dos repositórios)

O compilador de linha de comando já funciona nesta máquina (ver memória "ambiente-build-delphi"). Scripts ficam no scratchpad desta sessão (`<SCRATCH>` = `C:\Users\Kaue\AppData\Local\Temp\claude\d254274e393319df\c99cc785-a9e1-4aa3-82be-f81f9ea9a0f6\scratchpad`); se tiver sido apagado, recriar com o conteúdo abaixo.

`<SCRATCH>\build\compilar_cliente.bat`:

```bat
@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat" >nul
set P=C:\Projetos\Portifolio\GitHub\delphi-vcl-client
set DX=C:\DevExpress VCL Controls v26.1.5 for Delphi 13.2 Florence Full Source + DxAutoInstaller\DevExpress\Library\RS37\Win32
set DXS=C:\DevExpress VCL Controls v26.1.5 for Delphi 13.2 Florence Full Source + DxAutoInstaller\DevExpress\Library\Sources\Resources
set U=%P%\src\Models;%P%\src\Infra;%P%\src\Api;%P%\src\Services;%P%\src\Controllers;%P%\src\Views;%P%\tests;%BDS%\lib\win32\release;%BDS%\source\DUnitX;%DX%
dcc32 -B -Q -W+ -H+ -NSSystem;Vcl;Winapi;Data;Data.Win;System.Win;Vcl.Imaging;Xml -U"%U%" -I"%U%" -R"%U%;%DXS%;%BDS%\lib\win32\release" -E"%~dp0out_cliente" -NU"%~dp0out_cliente\dcu" %*
```

`<SCRATCH>\build\compilar_api_testes.bat`: igual, com `P=C:\Projetos\Portifolio\GitHub\delphi-horse-api\delphi-horse-api`, `U=%P%\src\Models;%P%\src\Infra;%P%\src\Repositories;%P%\src\Services;%P%\tests;%BDS%\lib\win32\release;%BDS%\source\DUnitX`, sem DevExpress, saída `out_api`.

Rodar testes (Git Bash): `cmd //c "<SCRATCH>\build\compilar_cliente.bat C:\Projetos\Portifolio\GitHub\delphi-vcl-client\tests\DelphiVclClientTests.dpr" && <SCRATCH>/build/out_cliente/DelphiVclClientTests.exe`. **Passou** = compilação sem `Error`/`Fatal`/`Warning`/`Hint` e saída com `Tests Failed  : 0` e `Tests Errored : 0`.

---

## Fase 1 — API (`delphi-horse-api`)

### Task 1: Filtro `?busca=` em clientes e produtos

**Files:**
- Modify: `src/Repositories/Repository.Cliente.pas` (`Listar`), `src/Repositories/Repository.Produto.pas` (`Listar`)
- Modify: `src/Services/Service.Cliente.pas`, `src/Services/Service.Produto.pas` (`Listar`)
- Modify: `src/Controllers/Controller.Cliente.pas`, `src/Controllers/Controller.Produto.pas` (ler `busca` da query)
- Modify: `tests/Tests.Fakes.pas`, `tests/Tests.Service.Cliente.pas`, `tests/Tests.Service.Produto.pas`
- Modify: `README.md` (tabela de endpoints + seção "Listagens paginadas")

**Interfaces:**
- Produces: `IClienteRepository.Listar(const APaginacao: TPaginacao; const ABusca: string; out ATotal: Integer): TObjectList<TCliente>`; idem `IProdutoRepository`; `IClienteService.Listar(const APaginacao: TPaginacao; const ABusca: string; out ATotal: Integer)`; idem `IProdutoService`. Query string: `GET /clientes?pagina=1&limite=20&busca=maria`.

Regras: busca vazia ou só espaços = comportamento atual. Cliente: `WHERE ATIVO = TRUE AND (NOME CONTAINING :BUSCA OR DOCUMENTO CONTAINING :DOCUMENTO)`; `:BUSCA` = texto aparado; `:DOCUMENTO` = `TDocumento.Normalizar(ABusca)`; se o normalizado for vazio, a condição de documento sai do SQL. Produto: `DESCRICAO CONTAINING :BUSCA`. O `COUNT(*)` usa o mesmo `WHERE` (o `total` reflete o filtro). Tudo por parâmetro, nunca concatenado. O Repository recebe só `ABusca` e ele mesmo chama `TDocumento.Normalizar` (Model já usado pelo Service), para a regra ficar num lugar só.

- [ ] **Step 1: Atualizar os fakes para a nova assinatura e gravar a última busca recebida** (`TClienteRepositoryFake.UltimaBusca: string`, idem produto) filtrando em memória por `ContainsText(Nome, ABusca)` ou documento normalizado contendo a busca normalizada.

- [ ] **Step 2: Escrever os testes que falham**

```pascal
procedure TTestsServiceCliente.Listar_ComBusca_RepassaAoRepositorio;
// seed fake: 'Maria Souza' 52998224725, 'João Lima' 11222333000181
LLista := FService.Listar(TPaginacao.Criar(1, 20), 'maria', LTotal);
Assert.AreEqual(1, LTotal); Assert.AreEqual('Maria Souza', LLista[0].Nome);
Assert.AreEqual('maria', FRepo.UltimaBusca);

procedure TTestsServiceCliente.Listar_BuscaPorDocumentoFormatado_Encontra;
LLista := FService.Listar(TPaginacao.Criar(1, 20), '529.982.247-25', LTotal);
Assert.AreEqual(1, LTotal);

procedure TTestsServiceCliente.Listar_BuscaVazia_TrazTodos;
FService.Listar(TPaginacao.Criar(1, 20), '   ', LTotal); Assert.AreEqual(2, LTotal);

procedure TTestsServiceProduto.Listar_ComBusca_FiltraPorDescricao;
// seed: 'Teclado mecânico', 'Mouse sem fio' → busca 'MOUSE' → 1 resultado
```

- [ ] **Step 3: Rodar os testes da API e ver falhar** — `cmd //c "<SCRATCH>\build\compilar_api_testes.bat C:\...\delphi-horse-api\tests\DelphiHorseApiTests.dpr"`. Esperado: erro de compilação (assinatura nova) ou falha nos 4 testes.

- [ ] **Step 4: Implementar** Repository (SQL acima), Service (repassa `ABusca`), Controller (`AReq.Query.Field('busca').AsString`, ausente = `''`).

- [ ] **Step 5: Rodar os testes e ver passar** (todos, não só os novos).

- [ ] **Step 6: Verificar contra o banco real** — `msbuild DelphiHorseApi.dproj /p:Config=Debug` (via `rsvars.bat`), subir o exe, e com `curl`: login `admin/admin123`; `GET /clientes?busca=maria` → só clientes com "maria" no nome e `total` coerente; `GET /clientes?busca=529.982.247-25` → o cliente do CPF (se existir no seed; senão cadastrar um); `GET /produtos?busca=S%C3%A3o%20Paulo%20%26%20Cia` → 200 sem erro; `GET /clientes?busca=%25` → 200 (o `%` é literal, não curinga). Encerrar a API.

- [ ] **Step 7: README da API** — linhas de `GET /clientes` e `GET /produtos` mencionam `busca`; seção "Listagens paginadas" ganha um parágrafo com o exemplo `?busca=` e a regra do documento.

- [ ] **Step 8: Commit** — `git add` dos arquivos acima; mensagem `Adiciona filtro de busca nas listagens de clientes e produtos`. Perguntar ao Kauê antes do push.

---

## Fase 2 — Cliente (`delphi-vcl-client`)

### Task 2: Repositório, projeto e base de testes

**Files:**
- Create: `.gitignore` (copiar do `delphi-emissor-nfe` e remover o que é só fiscal), `CLAUDE.md`, `README.md`, `config.example.ini`, `DelphiVclClient.dpr`, `tests/DelphiVclClientTests.dpr`, `docs/screenshots/.gitkeep`
- Create (local, não versionado): `CLAUDE.local.md` (copiar do emissor) + linha em `.git/info/exclude`
- Existing: `docs/superpowers/specs/...design.md`, `docs/superpowers/plans/...md`

**Interfaces:**
- Produces: projeto que compila vazio; runner DUnitX console idêntico ao do emissor (`tests/EmissorNFeTests.dpr` como modelo), saída com `Tests Found`.

- [ ] **Step 1: `git init` e arquivos-base.** `CLAUDE.md` adapta o do emissor: sobre o projeto (cliente da `delphi-horse-api`), ambiente, interface DevExpress, segurança (sem senhas/tokens versionados, log mascarado, DPAPI), arquitetura com `Api/` no lugar de `Repositories/` ("único lugar com HTTP/JSON"), **sem seção de banco** (explicar em uma linha que o banco é da API), exceção explícita autorizando o Claude Code a gerar `.dfm`, encoding UTF-8+BOM, padrões, testes, git. `README.md`: descrição, tecnologias, estrutura, como executar (subir a API antes), roadmap com os itens das Tasks 5–11 desmarcados.

- [ ] **Step 2: `config.example.ini`** (valores exatos):

```ini
[Api]
; perfis separados por vírgula; cada um tem a seção [Perfil.<nome>]
Perfis=Local,Servidor
TimeoutSegundos=15
[Perfil.Local]
Url=http://localhost:9000
[Perfil.Servidor]
Url=http://servidor.exemplo.com.br:9000
[Health]
IntervaloSegundos=30
[Log]
Pasta=.\logs
Http=1
RetencaoDias=30
```

- [ ] **Step 3: Compilar `DelphiVclClient.dpr` (form vazio temporário) e o runner de testes vazio** com `compilar_cliente.bat`. Esperado: sem erros; runner imprime `Tests Found   : 0`.

- [ ] **Step 4: Commit** `Cria projeto do cliente VCL com documentação inicial` (inclui spec e plano). Pedir ao Kauê para criar o repositório vazio **público** `delphi-vcl-client` no GitHub (o `gh` não está instalado); depois `git remote add origin https://github.com/kauelessa/delphi-vcl-client.git` e push com confirmação.

### Task 3: Infra — config, logs e HTTP

**Files:**
- Create: `src/Infra/Infra.Excecoes.pas`, `src/Infra/Infra.Config.pas`, `src/Infra/Infra.Log.pas`, `src/Infra/Infra.LogHttp.pas`, `src/Infra/Infra.Http.pas`
- Test: `tests/Test.LogHttp.pas`, `tests/Test.Config.pas`, `tests/Test.Http.pas`

**Interfaces:**
- Produces:
  - `Infra.Excecoes`: `EApi = class(Exception) Status: Integer`; `EApiValidacao`, `EApiNaoEncontrado`, `EApiNaoAutorizado`, `EApiIndisponivel` (todas herdam `EApi`); `EValidacao = class(Exception)` (validação local).
  - `Infra.Config`: `TPerfilApi = record Nome, Url: string end`; `TConfig` com `Perfis: TArray<TPerfilApi>`, `PerfilPorNome(const ANome: string): TPerfilApi` (inexistente → primeiro perfil), `TimeoutMs: Integer`, `IntervaloHealthMs: Integer`, `PastaLog: string`, `LogHttp: Boolean`, `RetencaoLogDias: Integer`; `constructor Create(const AArquivo: string)`; função global `Config: TConfig` (arquivo `config.ini` ao lado do exe). Sem arquivo/sem perfis → um perfil `Local` = `http://localhost:9000`.
  - `Infra.Log`: `ILog` (`Info`, `Erro`) / `TLogArquivo` como no emissor; `procedure LimparLogsAntigos(const APasta: string; ADias: Integer)` (apaga `*.log` com data de modificação mais antiga que `ADias`, inclusive em `http\`).
  - `Infra.LogHttp`: `function MascararSegredos(const AJson: string): string`; `ILogHttp.Registrar(const AMetodo, AUrl: string; AStatus, AMilissegundos: Integer; const AEnvio, AResposta: string)`; `TLogHttpArquivo.Create(const APasta: string; AAtivo: Boolean)` grava em `<pasta>\http\AAAA-MM-DD.log`, sempre passando envio e resposta por `MascararSegredos`.
  - `Infra.Http`: `THttpMetodo = (Get, Post, Put, Patch, Delete)` com `{$SCOPEDENUMS ON}`; `THttpResposta = record Status: Integer; Corpo: string end`; `IHttpClient.Executar(AMetodo: THttpMetodo; const AUrl, ACorpo, AToken: string): THttpResposta`; `TNetHttpClientAdapter.Create(ATimeoutMs: Integer; ALogHttp: ILogHttp)`. Corpo enviado como `application/json; charset=utf-8`, resposta lida como UTF-8. Falha de conexão/timeout → `EApiIndisponivel('Não foi possível falar com a API. Confira se ela está no ar e o endereço do perfil.')`. Status ≥ 400 **não** levanta aqui (quem interpreta é `Api.Base`).

- [ ] **Step 1: Testes que falham**

```pascal
// Test.LogHttp
Assert.AreEqual('{"login":"admin","senha":"***"}', MascararSegredos('{"login":"admin","senha":"admin123"}'));
Assert.AreEqual('{"token":"***","tipo":"Bearer"}', MascararSegredos('{"token":"eyJhb.x.y","tipo":"Bearer"}'));
Assert.AreEqual('nao e json', MascararSegredos('nao e json'));   // não JSON passa intacto
Assert.AreEqual('', MascararSegredos(''));
// Test.Config (ini temporário em TPath.GetTempPath)
// Perfis=Local,Servidor + seções → Length(Perfis)=2, Perfis[1].Url='http://servidor.exemplo.com.br:9000', TimeoutMs=15000
// arquivo inexistente → Length(Perfis)=1, Perfis[0].Url='http://localhost:9000', IntervaloHealthMs=30000
// PerfilPorNome('NaoExiste').Nome = 'Local'
// LimparLogsAntigos: cria 2 .log (um com FileSetDate de 40 dias atrás) → sobra 1
// Test.Http
LCli := TNetHttpClientAdapter.Create(2000, nil);
Assert.WillRaise(procedure begin LCli.Executar(THttpMetodo.Get, 'http://127.0.0.1:1/health', '', '') end, EApiIndisponivel);
```

- [ ] **Step 2: Rodar e ver falhar** (não compila).
- [ ] **Step 3: Implementar as cinco units** com as assinaturas acima. `MascararSegredos` percorre o JSON com `System.JSON` (objetos e arrays aninhados) e troca valores das chaves `senha`, `token`, `password` (sem diferenciar maiúsculas) por `"***"`; se não for JSON, devolve o texto.
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona infraestrutura de configuração, logs e HTTP`.

### Task 4: Api.Base e JSON

**Files:**
- Create: `src/Infra/Infra.Json.pas`, `src/Api/Api.Base.pas`
- Test: `tests/Test.Fakes.pas` (criar), `tests/Test.ApiBase.pas`, `tests/Test.Json.pas`

**Interfaces:**
- Consumes: `IHttpClient`, `THttpResposta`, exceções da Task 3.
- Produces:
  - `Infra.Json`: `function NumeroJson(AValor: Currency): TJSONNumber`; `function LerTexto(AObj: TJSONObject; const ANome: string): string` (ausente/null → `''`); `LerInteiro`; `LerCurrency`; `function LerDataHora(AObj: TJSONObject; const ANome: string): TDateTime` (ISO 8601 → hora local).
  - `Api.Base`: `ISessaoApi = interface function UrlBase: string; function Token: string; function Relogar: Boolean; end`; `TApiBase = class(TInterfacedObject)` com `constructor Create(AHttp: IHttpClient; ASessao: ISessaoApi)` e `protected function Enviar(AMetodo: THttpMetodo; const ARota: string; const ACorpo: string = ''): string` (monta `UrlBase + ARota`, anexa token, interpreta status, em 401 chama `ASessao.Relogar` **uma vez** e repete se `True`); `class procedure VerificarResposta(const AResposta: THttpResposta)` pública para teste.
  - Mapeamento: 2xx ok; 400/422 → `EApiValidacao(erro)`; 401 → `EApiNaoAutorizado(erro)`; 404 → `EApiNaoEncontrado(erro)`; 500 e demais ≥ 400 → `EApiIndisponivel('A API encontrou um erro inesperado (HTTP <status>). Tente novamente; se persistir, veja o log da API.')`. Corpo sem `erro` ou não JSON → mensagem `'A API respondeu HTTP <status> sem detalhes.'` na classe correspondente ao status.
  - `Test.Fakes`: `THttpFake = class(TInterfacedObject, IHttpClient)` com fila de respostas (`Enfileirar(AStatus: Integer; const ACorpo: string)`) e registro das chamadas (`Chamadas: TList<THttpChamada>` com Metodo, Url, Corpo, Token); `TSessaoFake = class(TInterfacedObject, ISessaoApi)` com `UrlBase='http://api.teste'`, `Token` mutável, `ResultadoRelogar: Boolean`, `VezesRelogar: Integer`.

- [ ] **Step 1: Testes que falham**

```pascal
// Test.Json — rodar com FormatSettings pt-BR forçado no Setup (DecimalSeparator := ',') e restaurado no TearDown
Assert.AreEqual('{"preco":279.9}', TJSONObject.Create.AddPair('preco', NumeroJson(279.90)).ToJSON);
Assert.AreEqual(Currency(349.9), LerCurrency(TJSONObject.ParseJSONValue('{"v":349.9}') as TJSONObject, 'v'));
Assert.AreEqual('', LerTexto(TJSONObject.ParseJSONValue('{"email":null}') as TJSONObject, 'email'));
// LerDataHora('2026-11-20T10:15:00.000-03:00') = EncodeDateTime(2026,11,20,10,15,0,0) quando o fuso local é -03:00 (comparar convertendo para UTC para não depender do fuso da máquina)
// Test.ApiBase
Assert.WillRaise(..VerificarResposta(Resp(422, '{"erro":"Estoque insuficiente"}'))..., EApiValidacao); // e Message = 'Estoque insuficiente'
// 404 → EApiNaoEncontrado; 401 → EApiNaoAutorizado
// 500 corpo '{"erro":"x"}' → EApiIndisponivel com Message contendo 'HTTP 500'
// 502 corpo '<html>Bad Gateway</html>' → EApiIndisponivel, Message = 'A API encontrou um erro inesperado (HTTP 502). ...'
// 422 corpo '' → EApiValidacao, Message = 'A API respondeu HTTP 422 sem detalhes.'
// Enviar_401EReloginOk_RepeteComTokenNovo: fila 401 depois 200; Relogar troca Token para 'novo' e devolve True → 2 chamadas, a 2ª com Token='novo', VezesRelogar=1
// Enviar_401EReloginCancelado_LevantaNaoAutorizado: ResultadoRelogar=False → EApiNaoAutorizado, 1 chamada
// Enviar_401Duas_Vezes_NaoEntraEmLaco: fila 401,401, Relogar True → EApiNaoAutorizado, VezesRelogar=1
```

- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar** `Infra.Json` (usar `TJSONNumber.Create(Double)` e `FormatSettings` invariante onde houver conversão texto↔número; datas com `ISO8601ToDate(..., False)`), `Api.Base` e `Test.Fakes`.
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona base da camada de API com tratamento de erros`.

### Task 5: Login, sessão, health e credenciais lembradas

**Files:**
- Create: `src/Models/Model.Sessao.pas`, `src/Api/Api.Auth.pas`, `src/Api/Api.Health.pas`, `src/Infra/Infra.Dpapi.pas`, `src/Infra/Infra.Preferencias.pas`, `src/Services/Service.Sessao.pas`
- Test: `tests/Test.Dpapi.pas`, `tests/Test.Sessao.pas`

**Interfaces:**
- Consumes: `IHttpClient`, `ISessaoApi`, `TPerfilApi`, `Infra.Json`, `THttpFake`.
- Produces:
  - `Model.Sessao`: `TTokenAcesso = record Token: string; ExpiraEm: TDateTime end`.
  - `Api.Auth`: `TAuthApi.Create(AHttp: IHttpClient)`; `IAuthApi.Login(const AUrlBase, ALogin, ASenha: string): TTokenAcesso` (POST `/auth/login` sem token; erros via `TApiBase.VerificarResposta`, **sem** relogin).
  - `Api.Health`: `THealthApi.Create(AHttp: IHttpClient)`; `IHealthApi.Online(const AUrlBase: string): Boolean` (GET `/health`; qualquer exceção ou status ≠ 200 → `False`; nunca levanta).
  - `Infra.Dpapi`: `function Proteger(const ATexto: string): string` (DPAPI usuário atual → Base64); `function Desproteger(const ABase64: string): string` (falha → `''`).
  - `Infra.Preferencias`: `TPreferenciasUsuario.Create(const AArquivo: string)`; `Ler(const ASecao, AChave, APadrao: string): string`; `Gravar(const ASecao, AChave, AValor: string)`; `Apagar(const ASecao, AChave: string)`; função global `Preferencias: TPreferenciasUsuario` (arquivo `%APPDATA%\DelphiVclClient\usuario.ini`, pasta criada se não existir). Seção `Login`: chaves `Usuario`, `Senha` (cifrada), `Perfil`.
  - `Service.Sessao`: `TCredenciaisLembradas = record Usuario, Senha, Perfil: string; LembrarUsuario, LembrarSenha: Boolean end`; `TPedirSenha = reference to function(const AUsuario: string; out ASenha: string): Boolean`; `ISessaoService = interface(ISessaoApi) procedure Entrar(const APerfil: TPerfilApi; const AUsuario, ASenha: string; ALembrarUsuario, ALembrarSenha: Boolean); function Lembradas: TCredenciaisLembradas; function Usuario: string; function Perfil: TPerfilApi; procedure DefinirPedirSenha(AFunc: TPedirSenha); procedure Sair; end`; `TSessaoService.Create(AAuth: IAuthApi; APreferencias: TPreferenciasUsuario)`. `Relogar`: chama `PedirSenha` (via `TThread.Synchronize` se não estiver na thread principal), faz `Login` de novo e troca o token; senha errada no relogin → pergunta de novo até cancelar; cancelar → `False`.

- [ ] **Step 1: Testes que falham**

```pascal
// Test.Dpapi
Assert.AreEqual('admin123', Desproteger(Proteger('admin123')));
Assert.AreNotEqual('admin123', Proteger('admin123'));
Assert.AreEqual('', Desproteger('lixo-que-nao-e-base64'));
// Test.Sessao (preferências num ini temporário; THttpFake responde o login)
// Entrar_LembrarUsuarioESenha_GravaSenhaCifrada: ini tem Usuario='admin', Senha<>'admin123', Lembradas.Senha='admin123'
// Entrar_SemLembrarSenha_ApagaSenhaAnterior: após Entrar(..., True, False) a chave Senha não existe
// Entrar_SemLembrarNada_NaoGravaUsuario
// Entrar_401_LevantaNaoAutorizadoComMensagemDaApi: fila 401 '{"erro":"Login ou senha inválidos."}'
// Entrar_GuardaTokenEUrl: Token='eyJ...', UrlBase=Perfil.Url
// Relogar_PedirSenhaCancelado_RetornaFalse
// Relogar_SenhaCerta_TrocaToken: fila login 200 com token 'novo' → Token='novo', True
```

- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar** (`CryptProtectData`/`CryptUnprotectData` com `CRYPTPROTECT_UI_FORBIDDEN`, liberando `pbData` com `LocalFree`; Base64 com `TNetEncoding.Base64`).
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona login, sessão e credenciais protegidas por DPAPI`.

### Task 6: Clientes e produtos (models, Api, Services)

**Files:**
- Create: `src/Models/Model.Pagina.pas`, `src/Models/Model.Cliente.pas`, `src/Models/Model.Produto.pas`, `src/Api/Api.Cliente.pas`, `src/Api/Api.Produto.pas`, `src/Services/Service.Cliente.pas`, `src/Services/Service.Produto.pas`
- Test: `tests/Test.ClienteProduto.pas`

**Interfaces:**
- Consumes: `TApiBase`, `ISessaoApi`, `Infra.Json`, `THttpFake`, `TSessaoFake`.
- Produces:
  - `TPagina<T: class> = class Dados: TObjectList<T>; Pagina, Limite, Total: Integer; function TotalPaginas: Integer end` (`TotalPaginas` mínimo 1).
  - `TCliente` (`Id: Integer; Nome, Documento, Email, Telefone: string`), `TProduto` (`Id: Integer; Descricao: string; Preco: Currency; Estoque: Integer`).
  - `IClienteApi`: `Listar(APagina, ALimite: Integer; const ABusca: string): TPagina<TCliente>`; `Obter(AId: Integer): TCliente`; `Criar(ACliente: TCliente): TCliente`; `Atualizar(ACliente: TCliente): TCliente`; `Inativar(AId: Integer)`. Rotas: `/clientes?pagina=&limite=[&busca=<TNetEncoding.URL.EncodeQuery>]`, `/clientes/<id>`. Corpo POST/PUT: `nome, documento, email, telefone` (vazios omitidos em `email`/`telefone`).
  - `IProdutoApi`: mesma forma com `TProduto`; corpo `descricao, preco, estoque`.
  - `IClienteService`/`IProdutoService`: mesmos métodos, validando antes de chamar a API: cliente sem `Nome` → `EValidacao('Informe o nome.')`, sem `Documento` → `EValidacao('Informe o CPF ou CNPJ.')`; produto sem `Descricao` → `EValidacao('Informe a descrição.')`. Nada além disso (regras de negócio são da API). Construtores: `TClienteApi.Create(AHttp, ASessao)` (herdado de `TApiBase`), `TClienteService.Create(AApi: IClienteApi)`; idem produto.

- [ ] **Step 1: Testes que falham**

```pascal
// Listar_ConvertePagina: fila 200 '{"dados":[{"id":1,"nome":"Maria Souza","documento":"52998224725","email":"maria@exemplo.com","telefone":""}],"pagina":2,"limite":20,"total":21}'
//   → Dados.Count=1, Pagina=2, Total=21, TotalPaginas=2, Dados[0].Email='maria@exemplo.com'
// Listar_BuscaComAcentoESimbolo_CodificaNaUrl: ABusca='São Paulo & Cia' → URL chamada = 'http://api.teste/clientes?pagina=1&limite=20&busca=S%C3%A3o%20Paulo%20%26%20Cia' (aceitar '+' no lugar de '%20' conforme o encoder; fixar o que TNetEncoding.URL produzir)
// Listar_SemBusca_NaoEnviaParametro: URL termina em 'limite=20'
// Criar_EnviaCorpoEDevolveComId: corpo enviado contém "nome":"Ana" e "documento":"39053344705"; resposta id=7 → Result.Id=7
// Produto_Criar_PrecoComVirgulaRegional_EnviaPonto: Preco=279.90 com DecimalSeparator=',' → corpo contém "preco":279.9
// Inativar_ChamaDelete: Metodo=Delete, URL '/clientes/3'
// Service_ClienteSemNome_NaoChamaApi: EValidacao e THttpFake.Chamadas.Count=0
// Service_ProdutoSemDescricao_LevantaValidacao
```

- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona clientes e produtos na camada de API`.

### Task 7: Pedidos, pedido em digitação e rascunho

**Files:**
- Create: `src/Models/Model.Pedido.pas`, `src/Api/Api.Pedido.pas`, `src/Services/Service.Pedido.pas`, `src/Services/Service.Rascunho.pas`
- Test: `tests/Test.Pedido.pas`

**Interfaces:**
- Consumes: Task 4–6.
- Produces:
  - `TStatusPedido = (Aberto, Cancelado)` (scoped; `'ABERTO'`/`'CANCELADO'`); `TItemPedido` (`Id, ProdutoId: Integer; Descricao: string; Quantidade: Integer; PrecoUnitario, ValorTotal: Currency`); `TPedido` (`Id, ClienteId: Integer; ClienteNome: string; Data: TDateTime; Status: TStatusPedido; ValorTotal: Currency; Itens: TObjectList<TItemPedido>`).
  - `TItemNovo = record ProdutoId, Quantidade: Integer end`.
  - `IPedidoApi`: `Listar(APagina, ALimite, AClienteId: Integer): TPagina<TPedido>` (`AClienteId = 0` → sem filtro); `Obter(AId: Integer): TPedido`; `Criar(AClienteId: Integer; const AItens: TArray<TItemNovo>): TPedido`; `Cancelar(AId: Integer): TPedido` (PATCH `/pedidos/<id>/cancelar`, a API responde o pedido).
  - `TPedidoEmDigitacao = class` com `ClienteId: Integer; ClienteNome: string; Itens: TObjectList<TItemDigitado>` (`TItemDigitado`: `ProdutoId, Quantidade: Integer; Descricao: string; PrecoUnitario: Currency`); `procedure AdicionarProduto(AProduto: TProduto; AQuantidade: Integer)` (repetido soma; `AQuantidade <= 0` → `EValidacao('A quantidade deve ser maior que zero.')`); `procedure AlterarQuantidade(AIndice, AQuantidade: Integer)` (mesma validação); `procedure RemoverItem(AIndice: Integer)`; `function Total: Currency` (prévia; a API é quem calcula o valor final); `function ParaJson: string`; `class function DeJson(const AJson: string): TPedidoEmDigitacao`.
  - `IRascunhoPedido`: `Salvar(APedido: TPedidoEmDigitacao)`, `Carregar: TPedidoEmDigitacao` (nenhum ou arquivo inválido → `nil`), `Descartar`, `Existe: Boolean`; `TRascunhoArquivo.Create(const AArquivo: string)` (padrão `%APPDATA%\DelphiVclClient\rascunho-pedido.json`).
  - `IPedidoService` (`TPedidoService.Create(AApi: IPedidoApi; ARascunho: IRascunhoPedido)`): `Listar`, `Obter`, `Cancelar` repassando; `function Rascunho: IRascunhoPedido`; `function Enviar(APedido: TPedidoEmDigitacao): TPedido` — sem cliente → `EValidacao('Escolha o cliente.')`; sem itens → `EValidacao('Adicione pelo menos um produto.')`; sucesso → `Rascunho.Descartar`; erro (inclusive relogin cancelado) → rascunho intacto e exceção propagada.

- [ ] **Step 1: Testes que falham**

```pascal
// AdicionarProduto_Repetido_SomaQuantidade: mesmo produto 2 + 3 → Itens.Count=1, Quantidade=5
// AdicionarProduto_QuantidadeZero_LevantaValidacao
// Total_SomaPrecoVezesQuantidade: 349.90 x 2 + 129.90 x 1 = 829.70
// Enviar_MontaCorpoDaApi: corpo = {"clienteId":1,"itens":[{"produtoId":1,"quantidade":2},{"produtoId":2,"quantidade":1}]}
// Enviar_Sucesso_DescartaRascunho: Rascunho.Existe=False
// Enviar_422_MantemRascunhoEPropagaMensagem: fila 422 '{"erro":"Estoque insuficiente para o produto Mouse sem fio."}' → EApiValidacao; Rascunho.Existe=True
// Enviar_401ReloginCancelado_MantemRascunho
// Rascunho_SalvarECarregar_IdaEVolta: ClienteNome='Maria Souza', 2 itens preservados
// Rascunho_ArquivoCorrompido_CarregaNil
// Listar_ConverteStatusEData: "status":"CANCELADO" → TStatusPedido.Cancelado
// Cancelar_UsaPatch: Metodo=Patch, URL '/pedidos/5/cancelar'
```

- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona pedidos e rascunho do pedido em digitação`.

### Task 8: Execução assíncrona e fábrica

**Files:**
- Create: `src/Infra/Infra.Async.pas`, `src/Controllers/Controller.Fabrica.pas`
- Test: `tests/Test.Async.pas`

**Interfaces:**
- Produces:
  - `Infra.Async`: `procedure ExecutarAsync(const AAcao: TProc; const ASucesso: TProc; const AErro: TProc<Exception>)` — roda `AAcao` em `TTask`; chama `ASucesso` ou `AErro` na thread principal via `TThread.Queue`; a exceção capturada é liberada depois de `AErro` (usar `AcquireExceptionObject`).
  - `TFabrica` (class methods): `Sessao: ISessaoService` (singleton), `Clientes: IClienteService`, `Produtos: IProdutoService`, `Pedidos: IPedidoService`, `Health: IHealthApi`, montando `TNetHttpClientAdapter(Config.TimeoutMs, TLogHttpArquivo(Config.PastaLog, Config.LogHttp))`.

- [ ] **Step 1: Teste que falha** — `ExecutarAsync_ErroChegaNaThreadPrincipal`: ação levanta `EApiIndisponivel('x')`; laço `while not LTerminou do CheckSynchronize(10)` com limite de 5 s; `AErro` recebe `E.Message='x'` e `TThread.CurrentThread.ThreadID = MainThreadID`. E `ExecutarAsync_SucessoNaThreadPrincipal`.
- [ ] **Step 2: Rodar e ver falhar.**
- [ ] **Step 3: Implementar.**
- [ ] **Step 4: Rodar e ver passar.**
- [ ] **Step 5: Commit** `Adiciona execução assíncrona e fábrica de serviços`.

### Task 9: Janela principal, visual e login

**Files:**
- Create: `src/Views/View.Principal.pas/.dfm`, `src/Views/View.Login.pas/.dfm`, `src/Views/View.Relogin.pas/.dfm`, `src/Views/View.Estilo.pas` (cores e fábrica de botões pastel), `src/Controllers/Controller.Principal.pas`, `src/Controllers/Controller.Login.pas`
- Modify: `DelphiVclClient.dpr`

**Interfaces:**
- Consumes: `TFabrica`, `ExecutarAsync`, `Config`, `Preferencias`, `LimparLogsAntigos`.
- Produces: `TfrmPrincipal.AbrirTela(AFrame: TFrameClass)` — telas das Tasks 10–12 são `TFrame` hospedados no cartão central; `View.Estilo`: `procedure EstilizarBotao(AButton: TcxButton; AFuncao: TFuncaoBotao)` com `TFuncaoBotao = (Novo, Editar, Perigo, Neutro)`; constantes de cor: fundo `$00F9F6F4` (#F4F6F9), cartão branco, Novo #E0E7FF/texto #4338CA, Editar #DCFCE7/#15803D, Perigo #FEE2E2/#B91C1C, marca #4F46E5.

- [ ] **Step 1: Spike de viabilidade do visual (descartável)** — num form de teste no scratchpad, com `TdxSkinController` skin `WXI`: (a) cartão branco com cantos arredondados sobre fundo #F4F6F9 (testar `TdxPanel`/`TcxGroupBox` com skin, ou `TdxLayoutControl` com grupo estilizado); (b) `TcxButton` em tons pastel: tentar nesta ordem `Colors` com skin ativa; `LookAndFeel.SkinName := ''` + `NativeStyle := False` + `Colors`; `OnCustomDraw` desenhando retângulo arredondado. Capturar PNG (como `Screens.dpr` do emissor) e escolher a primeira técnica que renderiza certo. Registrar a escolha em uma linha no `CLAUDE.md` (seção Interface).
- [ ] **Step 2: Implementar `View.Estilo`** com a técnica escolhida.
- [ ] **Step 3: Login** — perfil (`TcxComboBox` com os perfis), usuário, senha (`TcxTextEdit` com `PasswordChar`), "Lembrar usuário", "Lembrar senha" (só habilita com o primeiro), botão Entrar (Novo). Preenche com `Sessao.Lembradas`. Entrar roda `Sessao.Entrar` via `ExecutarAsync` com indicador e botão desabilitado; erro mostra a mensagem da exceção.
- [ ] **Step 4: Principal** — barra superior com marca "Vendas" e abas Pedidos · Clientes · Produtos; área cinza com o cartão central onde os frames entram; `TdxStatusBar` com perfil/usuário e indicador "● API online/offline" atualizado por `TTimer` (`Config.IntervaloHealthMs`, chamada via `ExecutarAsync`); posição e tamanho da janela salvos em `Preferencias` (seção `Janela`). `Application.OnException`: `EValidacao`/`EApiValidacao`/`EApiNaoEncontrado` → aviso; `EApiIndisponivel` → aviso + log; demais → erro + log.
- [ ] **Step 5: Relogin** — diálogo modal "Sua sessão expirou. Digite a senha de <usuário> para continuar." registrado via `Sessao.DefinirPedirSenha`.
- [ ] **Step 6: `.dpr`** — `LimparLogsAntigos` na abertura, login modal antes da principal (cancelar fecha o app).
- [ ] **Step 7: Verificar** — compilar; programa de checagem no scratchpad cria cada form (pega `EReadError` de `.dfm`) e salva PNG; conferir visual B e acentos. Com a API no ar (Task 1 Step 6), entrar com `admin/admin123`, marcar lembrar senha, fechar e abrir de novo (deve vir preenchido), conferir que `usuario.ini` não tem a senha em texto puro.
- [ ] **Step 8: Commit** `Adiciona janela principal, login e visual`.

### Task 10: Telas de clientes e produtos

**Files:**
- Create: `src/Views/View.ListaBase.pas/.dfm` (frame base: busca, grid, paginação, botões), `src/Views/View.Clientes.pas/.dfm`, `src/Views/View.ClienteEdicao.pas/.dfm`, `src/Views/View.Produtos.pas/.dfm`, `src/Views/View.ProdutoEdicao.pas/.dfm`, `src/Controllers/Controller.Cliente.pas`, `src/Controllers/Controller.Produto.pas`

**Interfaces:**
- Consumes: `IClienteService`, `IProdutoService`, `TPagina<T>`, `EstilizarBotao`, `ExecutarAsync`.
- Produces: `TfraListaBase` com `procedure Carregar(APagina: Integer)` virtual, `ItensPorPagina` (de `Preferencias`, seção `Telas`, chave `ItensPorPagina`, padrão 20, opções 20/50/100), barra "‹ anterior · página X de Y · próxima ›" e "N no total".

- [ ] **Step 1: Frame base** — busca com atraso de 400 ms após digitar (ou Enter) vai para a página 1; grid `TcxGrid` não vinculado (como no emissor) com "Nenhum registro"; botões Novo/Editar/Inativar com `EstilizarBotao`; tudo via `ExecutarAsync` com indicador e botões desabilitados durante a chamada. Se a página atual ficar vazia depois de inativar e não for a 1, recarrega a anterior.
- [ ] **Step 2: Clientes** — colunas Nome, CPF/CNPJ (formatado para exibir), E-mail, Telefone; edição modal com Nome, CPF/CNPJ, E-mail, Telefone; Inativar com confirmação "Inativar <nome>? Ele deixa de aparecer nas listas e em novos pedidos."
- [ ] **Step 3: Produtos** — colunas Descrição, Preço (`R$ #,##0.00`), Estoque; edição com Descrição, Preço (`TcxCurrencyEdit`), Estoque (`TcxSpinEdit`, mínimo 0); confirmação de inativação análoga.
- [ ] **Step 4: Preferência dos grids** — `StoreToIniFile`/`RestoreFromIniFile` do `TcxGridTableView` em `%APPDATA%\DelphiVclClient\grids.ini`.
- [ ] **Step 5: Verificar** com a API no ar: listar, buscar `maria`, buscar `São Paulo & Cia` (sem erro), cadastrar cliente com CPF inválido (mensagem 422 da API aparece como aviso), editar, inativar; produto com preço `279,90` grava `279.9` (conferir no log HTTP, que também deve mostrar o JSON mascarado no login). PNGs das telas.
- [ ] **Step 6: Commit** `Adiciona telas de clientes e produtos`.

### Task 11: Telas de pedidos

**Files:**
- Create: `src/Views/View.Pedidos.pas/.dfm`, `src/Views/View.PedidoDetalhe.pas/.dfm`, `src/Views/View.PedidoNovo.pas/.dfm`, `src/Views/View.Seletor.pas/.dfm` (busca e escolha de cliente ou produto), `src/Controllers/Controller.Pedido.pas`

**Interfaces:**
- Consumes: `IPedidoService`, `IClienteService`, `IProdutoService`, `IRascunhoPedido`, `TPedidoEmDigitacao`, `TfraListaBase`.
- Produces: `TfrmSeletor.EscolherCliente(out ACliente: TCliente): Boolean` e `EscolherProduto(out AProduto: TProduto): Boolean` (busca pela API, paginada; o chamador libera o objeto).

- [ ] **Step 1: Lista de pedidos** — herda `TfraListaBase` sem busca de texto, com filtro "Cliente" (seletor + limpar); colunas Nº, Data (`dd/mm/yyyy hh:nn`), Cliente, Status (etiqueta verde ABERTO / vermelha CANCELADO), Total; botões Novo pedido (Novo), Ver (Editar), Cancelar (Perigo, só habilitado para ABERTO, com confirmação "Cancelar o pedido Nº X? O estoque dos produtos volta.").
- [ ] **Step 2: Detalhe** — cabeçalho (cliente, data, status, total) e grid de itens (Produto, Qtd, Preço unit., Total).
- [ ] **Step 3: Novo pedido** — ao abrir, se `Rascunho.Existe`, perguntar "Há um pedido não enviado de <cliente> com N itens. Continuar de onde parou?" (Não → `Descartar`); escolher cliente (seletor); adicionar produto (seletor + quantidade); grid de itens com quantidade editável e remover; total ao vivo; cada alteração chama `Rascunho.Salvar`; Enviar (Novo) via `ExecutarAsync`; sucesso mostra "Pedido Nº X criado." e fecha; erro mostra a mensagem e mantém a tela.
- [ ] **Step 4: Verificar** com a API no ar: criar pedido válido; repetir produto (soma na linha); pedir quantidade acima do estoque (aviso 422 da API, rascunho preservado); fechar o app no meio de um pedido e reabrir (rascunho oferecido); cancelar um pedido aberto; filtrar por cliente. Para o relogin, reduzir `[JWT] ExpiracaoMinutos=1` no `config.ini` **da API**, esperar expirar e enviar um pedido: deve pedir a senha e concluir; voltar para 60 depois. PNGs.
- [ ] **Step 5: Commit** `Adiciona telas de pedidos`.

### Task 12: Fechamento — README, prints e revisão final

**Files:**
- Modify: `README.md`, `docs/screenshots/*.png`
- Modify (API): `README.md` da `delphi-horse-api` — seção do ecossistema aponta para o `delphi-vcl-client`.

- [ ] **Step 1: README do cliente** — como executar (subir a API, copiar `config.example.ini`, perfis), arquitetura (diagrama em texto das camadas e de `IHttpClient`), o que é salvo localmente e onde, segurança (DPAPI, log mascarado), testes, roadmap marcado com o que foi verificado de ponta a ponta.
- [ ] **Step 2: Prints** em `docs/screenshots/`: login, clientes, edição de produto, novo pedido, detalhe do pedido (dados do seed da API, fictícios).
- [ ] **Step 3: Rodar toda a suíte e compilar o app** — esperado: sem warnings/hints, `Tests Failed : 0`.
- [ ] **Step 4: Conferir que nada sensível entrou** — `git status --ignored` mostra `config.ini`, `CLAUDE.local.md`, `*.exe`, `*.dcu`, `logs/` como ignorados; `grep -ri "admin123\|masterkey\|eyJ"` nos arquivos versionados só acha exemplos de documentação intencionais.
- [ ] **Step 5: Commits** `Atualiza README com arquitetura e prints` (cliente) e `Aponta o cliente VCL no README` (API). Push dos dois repositórios com confirmação do Kauê.
