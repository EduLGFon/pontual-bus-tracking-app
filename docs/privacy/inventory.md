# Inventário de dados do Pontual

Fonte: PLAN.md 13.2. Manter atualizado a cada mudança no tratamento.
Última revisão: 2026-10-03.

| Dado | Finalidade | Onde | Retenção | Dado pessoal? |
| ---- | ---------- | ---- | -------- | ------------- |
| Código do aparelho + hash do token, criação/último uso/expiração | limites, titularidade, prova de consentimento | PostgreSQL `devices` | até apagar ou 30 dias inativo | Sim (pseudônimo) |
| Versão do consentimento + data | prova de consentimento (art. 8, par. 2) | PostgreSQL `consents` | com o registro do aparelho | Sim (ligado ao pseudônimo) |
| Bloqueio (código, motivo) | controle de abuso | PostgreSQL `blocked_devices` | com o registro do aparelho | Sim (pseudônimo) |
| Última posição: lat, lng, velocidade, direção, precisão | posicionar o ônibus | memória do servidor | até o fim da viagem | Sim (localização) |
| Bateria (faixas de 5%) + carregando | eleger líder | memória do servidor | até o fim da viagem | Sim (estado do aparelho) |
| Posição do veículo (junção) | mostrar o ônibus | memória do servidor | some após 120 s sem sinal | Pode revelar passageiro sozinho (KL2) |
| Limites por IP/aparelho | controle de abuso | memória do servidor | minutos; sem registro | Sim (IP), efêmero |
| Registros de infra (IP, agente) | segurança/operação | Cloudflare, OSM, provedor VPS; próprios desligados ou sem IP | por provedor (curto) | Sim (IP), no provedor |
| Backups cifrados das tabelas | recuperação | fora do servidor | 30 dias | Sim (pseudônimo), cifrado |
| Preferências locais (tema, consentimento, token) | uso do app | aparelho | até desinstalar ou apagar dados | Token é credencial, sem PII |

Nunca coletado: nome, e-mail, telefone, contatos, IMEI,
identificadores de publicidade, apps instalados, fotos,
microfone, histórico de viagens. Quem só olha não cria registro.
