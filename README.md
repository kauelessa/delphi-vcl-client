# delphi-vcl-client

Cliente desktop em **Delphi (VCL)** com **DevExpress** que consome a **[delphi-horse-api](https://github.com/kauelessa/delphi-horse-api)**: login com JWT, cadastro de clientes e produtos e emissão de pedidos com baixa de estoque.

> 🚧 Projeto em desenvolvimento — faz parte do meu portfólio, junto com a API (back-end Horse + Firebird) e o [emissor de NF-e](https://github.com/kauelessa/delphi-emissor-nfe).

## 🎯 Objetivo

- Consumir todos os endpoints da API REST com tratamento claro dos erros que ela devolve
- Arquitetura em camadas com um cliente HTTP próprio e testável (`IHttpClient`)
- Interface moderna com DevExpress, sem travar a tela durante as chamadas
- Rastreabilidade local: log da aplicação e log HTTP com os JSONs (senha e token mascarados)

## 🧱 Tecnologias

| Item | Versão / Ferramenta |
|---|---|
| Linguagem | Delphi (Object Pascal) — VCL |
| Componentes de interface | DevExpress VCL Controls v26.1.5 |
| HTTP | `System.Net.HttpClient` (`TNetHTTPClient`) |
| JSON | `System.JSON` |
| Credenciais | DPAPI do Windows |
| Testes | DUnitX |

## 📁 Estrutura

```
delphi-vcl-client/
├── DelphiVclClient.dpr  # Projeto principal
├── config.example.ini   # Modelo do config.ini
├── src/
│   ├── Views/           # Forms e frames (DevExpress)
│   ├── Controllers/     # Ligação entre telas e services
│   ├── Services/        # Regras do cliente (sessão, pedido em digitação)
│   ├── Api/             # Rotas e JSON da API
│   ├── Models/          # Entidades e DTOs
│   └── Infra/           # HTTP, config, logs, DPAPI, preferências
├── tests/               # Testes unitários (DUnitX)
└── docs/
    ├── screenshots/     # Prints das telas
    └── superpowers/     # Design e plano de implementação
```

## ▶️ Como executar

1. Suba a [delphi-horse-api](https://github.com/kauelessa/delphi-horse-api) (por padrão em `http://localhost:9000`).
2. Copie `config.example.ini` para `config.ini`, ao lado do executável, e ajuste os endereços dos perfis de API.
3. Abra `DelphiVclClient.dpr` no RAD Studio (com o DevExpress 26.1.5 instalado), compile e execute.
4. Entre com um usuário da API (em desenvolvimento, `admin` / `admin123`, criado pelo seed da API).

## 🗺️ Roadmap

- [ ] Login, sessão e credenciais lembradas (DPAPI)
- [ ] Clientes e produtos (lista com busca, cadastro, edição e inativação)
- [ ] Pedidos (lista, detalhe, novo pedido com rascunho e cancelamento)
- [ ] Execução das chamadas fora da thread da tela
- [ ] Janela principal com o visual em cartões e indicador de API online
- [ ] Telas de clientes, produtos e pedidos
- [ ] Prints e documentação final

## 👤 Autor

**Kauê Lessa** — Desenvolvedor Delphi Sênior
[GitHub](https://github.com/kauelessa)
