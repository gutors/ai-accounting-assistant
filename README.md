# Fechamento mensal para coordenadores de ONG

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

## Ritual

1. O coordenador importa o extrato de cada **conta bancária** (PDF + CSV/XLSX nesta versão).
2. Coordenador e submitters inserem **documentos de suporte** (foto e/ou XML autorizado).
3. O sistema sugere casamentos; o coordenador confirma — ou marca uma **exceção documental**.
4. Pagamento sem casamento nem exceção é **documento faltante** e impede fechar para envio.
5. **Fechar para envio** congela o mês no produto e grava o pacote na **pasta do mês** `{YYYY-MM}` no arquivo Drive da organização.
6. O coordenador entrega o mesmo pacote ao contador.

Vocabulário canônico: [`CONTEXT.md`](CONTEXT.md).

## Estado

> [!NOTE]
> Ainda não há aplicativo nem `Gemfile`. Não há o que instalar ou rodar neste repositório.

As decisões de produto estão no [mapa do fechamento mensal](https://github.com/gutors/ai-accounting-assistant/issues/1). Código de produto começa na primeira feature com plano e checks aprovados (`tlc-spec-lean`), não a partir do mapa.

## Plataforma (v1)

Travada. Detalhe e alternativas rejeitadas: [ADR-0001](docs/adr/0001-rails-8-hotwire.md).

| Peça | Escolha |
| --- | --- |
| App | Rails 8, um processo (Puma), HTML no servidor com Hotwire (Turbo + Stimulus) |
| UI | Tailwind, locale `pt-BR` |
| Dados | PostgreSQL, Active Record; dinheiro em cents inteiros (`bigint`) |
| Auth | Google OIDC (`openid email`); sessão da app. A conta que escreve no Drive **não** é o login do operador |
| Arquivos de trabalho | Object store opaco (disco do container é efêmero) |
| Arquivo do pacote | Drive, só no fechar para envio / restaurar a pasta do mês |
| Deploy | Container que dorme quando ocioso; timeout de minutos (cabe o fechar para envio). Marca de host **não** está travada |
| Testes | RSpec |

> [!WARNING]
> Não coloque certificado A1, senhas, tokens de Drive ou dados financeiros reais no repositório.

## Fora desta versão

- Consentimento Open Finance (o caminho JSON fica desenhado; só upload nesta versão)
- Contador como operador; emissão de NF-e; CNPJ da organização como campo de setup
- O sistema virar receptor no Open Finance (BCB)

## Documentação

| Doc | Para quê |
| --- | --- |
| [`CONTEXT.md`](CONTEXT.md) | Glossário do domínio |
| [Issue #1](https://github.com/gutors/ai-accounting-assistant/issues/1) | Mapa de produto |
| [`docs/adr/`](docs/adr/) | Decisões de plataforma |
| [`AGENTS.md`](AGENTS.md) | Como agentes trabalham neste repo |

O código neste repositório é só para visualização. Todos os direitos reservados — ver [`LICENSE`](LICENSE).
