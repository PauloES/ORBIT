# ORBIT STATE

## Versão atual
v0.1 - Engine inicial funcional

---

## Objetivo do sistema
Simular o funcionamento de uma empresa através de eventos,
permitindo medir tempo, carga de trabalho e impacto de mudanças (ex: IA).

---

## Caso de uso atual (foco da V1)
Triagem de e-mails

Pergunta central:
> Quanto custa em tempo humano realizar triagem de e-mails?

---

## O que já existe

### Estrutura base
- pTB_SIMULATION (isolamento total do cenário)
- pTB_ENTITY (recursos / pessoas)
- pTB_EVENT (ocorrências do mundo)
- pTB_EVENT_QUEUE (fila de processamento)
- pTB_PROCESS_EXECUTION (execução de trabalho)

### Engine
- pSP_ENGINE_RUN (processa eventos da fila)

### Conceito arquitetural
- simulation_id isola tudo
- sistema orientado a eventos
- engine não cria lógica, apenas executa fluxo

---

## Decisões arquiteturais (ADRs)

### ADR-001
Simulação é a unidade central do sistema

### ADR-002
Tudo pertence a uma simulação via simulation_id

### ADR-003
Sistema orientado a eventos com PROCESS_TRIGGER simples (V1)

---

## O que ainda NÃO existe (crítico)

- Loop automático de simulação (tempo correndo sozinho)
- Gerador de eventos (emails reais simulados)
- Controle de ocupação de recursos
- Fila com comportamento real (espera + gargalo)
- Relatório automático de métricas

---

## Próximo passo imediato (Sprint 2)

1. Criar pSP_SIMULATION_RUN (loop de tempo)
2. Criar pSP_GENERATE_EMAIL_EVENTS
3. Integrar engine em execução contínua
4. Gerar primeiro dia completo simulado
5. Produzir métricas básicas

---

## Hipótese a validar

> O ORBIT consegue transformar um fluxo simples (emails)
em métricas de gestão (tempo, carga, gargalo).

Se isso funcionar, o sistema é válido.

---

## Regra do projeto

> Não adicionar complexidade sem necessidade empírica.

---

## Status conceitual

ORBIT ainda está em fase de:

- protótipo funcional
- validação de conceito
- motor inicial

Ainda NÃO é:

- plataforma completa
- sistema multi-departamental
- IA integrada