# Fechamento mensal para coordenadores de ONG

<img src="public/icon.svg" alt="" width="48" height="48">

<a href="https://paladini.github.io/harness-score/">
  <img alt="Harness Score" src="https://raw.githubusercontent.com/gutors/ai-accounting-assistant/badges/harness-badge.svg" height="20" width="112">
</a>

Sistema para fechar o mês de uma ou mais **organizações** (ONG ou similar): importar extratos, guardar documentos de suporte, casar cada pagamento com documento ou exceção, apontar documentos faltantes, gerar a planilha-resumo e montar o **pacote mensal** para o contador.

O coordenador entrega o pacote. O sistema não substitui o contador.

> [!IMPORTANT]
> O produto prepara o pacote e grava uma cópia no **arquivo do pacote** (Drive). **Fechar para envio** não é entregar ao contador.

## Quem usa

| Papel | Faz | Não faz |
| --- | --- | --- |
| **Coordenador** | Fecha o mês, valida casamentos, marca exceções | — |
| **Submitter** | Insere documentos de suporte | Ver extrato ou pagamentos do banco |
| **Contador** | Recebe o pacote | Usar o sistema |

O ritual e o formato da planilha-resumo são os mesmos em todas as organizações. Contas bancárias, contador, destino do pacote, arquivo do pacote e extras (tipos de exceção, certificado SEFAZ, submitters) variam por organização.

Quem cadastra uma organização nova é uma conta Google allowlistada (`ADMINISTRATOR_EMAIL`). Essa pessoa abre **Administração**, confirma o nome e o e-mail do coordenador, e o sistema manda o correio de boas-vindas. Ela não fecha o mês no lugar do coordenador.

## Ritual

1. O coordenador importa o extrato de cada **conta bancária** (PDF + CSV/XLSX nesta versão).
2. Coordenador e submitters inserem **documentos de suporte** (foto e/ou XML autorizado). A foto de uma nota pode ser lida no servidor para achar a chave de acesso.
3. O sistema sugere casamentos; o coordenador confirma — ou marca uma **exceção documental**.
4. Pagamento sem casamento nem exceção é **documento faltante** e impede fechar para envio.
5. **Fechar para envio** congela o mês no produto e grava o pacote na **pasta do mês** `{YYYY-MM}` no arquivo Drive da organização.
6. O coordenador entrega o mesmo pacote ao contador.

Vocabulário canônico: [`GLOSSARY.md`](GLOSSARY.md).

## Rodar localmente

Ruby `3.4.10` (`.ruby-version`) e PostgreSQL aceitando conexões. O banco de development é `ai_accounting_assistant_development`.

### Primeira vez

Na pasta do repositório:

```sh
bundle install
bin/lefthook install
bin/rails db:setup
```

`db:setup` cria o banco, carrega o schema e roda o seed. Se o banco já existir, use `bin/rails db:migrate`. O seed em development é idempotente: não grava uma segunda `ONG Exemplo` quando a conta de exemplo já está lá.

Crie um `.env` na raiz (o Git ignora esse arquivo) e preencha o cliente OAuth e o correio. Sem aspas e sem espaço em volta do `=`:

```sh
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
ADMINISTRATOR_EMAIL=
MAIL_FROM=
MAILER_HOST=localhost:3000
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USER_NAME=
SMTP_PASSWORD=
```

No cliente OAuth do Google, tipo **Web application**, a redirect URI autorizada é `http://localhost:3000/auth/google_oauth2/callback`. O esquema, o host e a porta têm de ser os mesmos da barra do navegador.

### Cada vez

```sh
bin/dev
```

Abra `http://localhost:3000`. Pare com `Ctrl-C` nesse terminal.

`bin/dev` sobe o Puma e o Tailwind, e o Foreman carrega o `.env`. `bin/rails server` sozinho não carrega o `.env` nem observa o CSS.

Se a porta 3000 estiver ocupada:

```sh
PORT=3001 bin/dev
```

A URL e a redirect URI passam a usar a porta `3001`.

### Entrar

Entre com Google usando `gutors@gmail.com` para cair na `ONG Exemplo` como coordenador. Em development, `/login` também lista **Ambiente local**: um botão por conta já persistida (`POST /dev/session`) para o agente (ou você) entrar sem o Google. Essa porta não existe em production. Outro nome ou outro e-mail:

```sh
ORGANIZATION_NAME="ONG Norte" COORDINATOR_EMAIL="coord@exemplo.org" bin/rails coordinator:bootstrap
```

A conta Google do login tem de ser a mesma do coordenador, com o e-mail verificado. Enquanto o app OAuth estiver em modo de teste, essa conta precisa estar na lista de test users.

### Variáveis

Obrigatórias para o login local: `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET`.

| Variável | Quando |
| --- | --- |
| `ADMINISTRATOR_EMAIL` | E-mail Google que abre `/administration` |
| `MAIL_FROM` | Remetente do correio de boas-vindas |
| `MAILER_HOST` | Host dos links nesse correio |
| `SMTP_ADDRESS` | Servidor SMTP; sem ele o envio não é configurado |
| `SMTP_PORT` | Porta SMTP; `587` quando vazia |
| `SMTP_USER_NAME` | Usuário SMTP |
| `SMTP_PASSWORD` | Senha SMTP |
| `GOOGLE_DRIVE_REFRESH_TOKEN` | Conta escritora do Drive no fechar para envio. Não é o login do operador |
| `SEFAZ_WRAP_KEY` | Embrulha o certificado A1. Sem ela, instalar o certificado e a consulta identificada ficam de fora; o resto do fechamento segue |
| `ORGANIZATION_NAME`, `COORDINATOR_EMAIL` | Só no `coordinator:bootstrap` |

A foto da nota usa o binário `tesseract` no `PATH`, com os idiomas `por` e `eng`. Sem ele, a leitura volta vazia e a chave continua digitada.

A foto PDF usa o binário `pdftoppm` (Poppler) no `PATH`. Sem ele, a leitura do PDF volta vazia e os campos continuam digitados.

> [!WARNING]
> Não coloque certificado A1, senhas, tokens de Drive, o `.env` ou dados financeiros reais no repositório.

## Estado

> [!NOTE]
> `bin/rails db:seed` em development persiste a organização `ONG Exemplo` e a conta coordenadora `gutors@gmail.com`.

As decisões de produto estão no [mapa do fechamento mensal](https://github.com/gutors/ai-accounting-assistant/issues/1). Uma feature nova parte de uma tarefa (`tlc-plan`) e do checklist (`tlc-implement`). O mapa não é a especificação a implementar.

## Plataforma (v1)

Travada. Detalhe e alternativas rejeitadas: [ADR-0001](docs/adr/0001-rails-8-hotwire.md).

| Peça | Escolha |
| --- | --- |
| App | Rails 8, um processo (Puma), HTML no servidor com Hotwire (Turbo + Stimulus) |
| UI | Tailwind, locale `pt-BR` |
| Dados | PostgreSQL, Active Record; dinheiro em cents inteiros (`bigint`) |
| Auth | Google OIDC (`openid email`); sessão da app. A conta que escreve no Drive não é o login do operador |
| Arquivos de trabalho | Object store opaco (disco do container é efêmero) |
| Arquivo do pacote | Drive, só no fechar para envio / restaurar a pasta do mês |
| Deploy | Container que dorme quando ocioso; timeout de minutos (cabe o fechar para envio). Marca de host não está travada |
| Testes | RSpec (`bin/rspec`) |

## Fora desta versão

- Consentimento Open Finance (o caminho JSON fica desenhado; só upload nesta versão)
- Contador como operador; emissão de NF-e; CNPJ da organização como campo de setup
- O sistema virar receptor no Open Finance (BCB)

## Documentação

| Doc | Para quê |
| --- | --- |
| [`GLOSSARY.md`](GLOSSARY.md) | Glossário do domínio |
| [Issue #1](https://github.com/gutors/ai-accounting-assistant/issues/1) | Mapa de produto |
| [`docs/adr/`](docs/adr/) | Decisões de plataforma |
| [`AGENTS.md`](AGENTS.md) | Como agentes trabalham neste repo |

O código neste repositório é só para visualização. Todos os direitos reservados — ver [`LICENSE`](LICENSE).
