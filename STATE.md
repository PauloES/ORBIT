# ORBIT STATE

## Versão atual
v0.2 - Sprint 1 concluído

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

### Tabelas

| Tabela | Descrição |
|--------|-----------|
| pTB_SIMULATION | Container da simulação. Define a janela de tempo e status de execução |
| pTB_ENTITY | Entidades da simulação: empresa, departamentos, pessoas (ESTRUTURA ou OPERACIONAL) |
| pTB_RELATION | Hierarquia entre entidades via parent/child, isolada por simulation_id |
| pTB_EVENT | Registro de cada evento gerado (ex: EMAIL_RECEIVED) |
| pTB_EVENT_QUEUE | Fila de eventos pendentes de processamento |
| pTB_ROLE | Papéis que uma entidade pode assumir: EXECUTOR, SOLICITANTE, APROVADOR |
| pTB_PROCESS_DEFINITION | Catálogo de processos com duração média (avg_duration_minutes) |
| pTB_PROCESS_TRIGGER | Mapeamento evento → processo com prioridade |
| pTB_PROCESS_EXECUTION | Registro de cada execução de processo |
| pTB_PROCESS_EXECUTION_ALLOCATION | Quem executou o quê, com qual papel e em qual período |

### Procedures

| Procedure | Descrição |
|-----------|-----------|
| pSP_SIMULATION_CREATE | Cria nova simulação com janela de tempo |
| pSP_SIMULATION_CLONE | Clona simulação existente com IDs remapeados |
| pSP_SIMULATION_DELETE | Remove simulação e todos os dados relacionados em cascata |
| pSP_RUN_SIMUL | Motor principal — loop de tempo simulado do início ao fim |
| pSP_GENERATE_EVENTS | Gera eventos probabilísticos a cada tick (30% de chance de EMAIL_RECEIVED em horário comercial) |
| pSP_START_PROCESSES | Processa fila de eventos alocando todos os recursos livres disponíveis |
| pSP_EXECUTE_PROCESSES | Reservado para v2 (etapas internas, aprovações) |
| pSP_FINISH_PROCESSES | Finaliza execuções que atingiram a duração esperada (variação de 50%–150% da média) |

### Conceitos arquiteturais
- `simulation_id` isola todos os dados de cada simulação (ADR-002)
- Processos são unidades atômicas de trabalho — sem decomposição em tarefas na V1 (ADR-004)
- Loop de tempo é lógico, não real — simula dias em milissegundos
- Recursos livres são alocados em lote a cada tick — o gargalo emerge naturalmente da quantidade de entidades OPERACIONAL disponíveis

---

## Decisões arquiteturais (ADRs)

### ADR-001
Simulação é a unidade central do sistema

### ADR-002
Tudo pertence a uma simulação via simulation_id

### ADR-003
Sistema orientado a eventos com PROCESS_TRIGGER

### ADR-004
Processos são unidades atômicas — sem decomposição em tarefas na V1

---

## Como rodar o primeiro cenário

```sql
-- 1. Rodar o seed (cria simulação + entidades + processo de triagem)
-- arquivo: database/scripts/sprint1_modulo4_seed_triagem_email.sql

-- 2. Rodar a simulação (substitua 1 pelo ID retornado no seed)
EXEC pSP_RUN_SIMUL @simulation_id = 1;
```

---

## Estrutura de pastas

```
database/
  001_core/              pTB_ENTITY, pTB_RELATION
  002_simulation/        pTB_SIMULATION
  003_event_engine/      pTB_EVENT, pTB_EVENT_QUEUE
  004_process/           pTB_PROCESS_DEFINITION, pTB_PROCESS_TRIGGER,
                         pTB_ROLE, pTB_PROCESS_EXECUTION,
                         pTB_PROCESS_EXECUTION_ALLOCATION
  005_simulation_engine/ pSP_RUN_SIMUL e sub-procedures
  scripts/               equalizar_banco.sql — sincroniza o banco com o git
                         sprint1_modulo4_seed_triagem_email.sql — seed do primeiro cenário
```

---

## O que ainda NÃO existe (próximos sprints)

- Probabilidade de eventos ajustada por carga do sistema
- Controle de backlog (eventos que ficam em espera sem recurso disponível)
- Duração variável por entidade (analista sênior vs júnior)
- Múltiplos tipos de evento além de EMAIL_RECEIVED
- Métricas de gargalo e utilização
- Cenários comparativos (com IA vs sem IA)

---

## Hipótese a validar

> O ORBIT consegue transformar um fluxo simples (triagem de e-mails)
em métricas de gestão (tempo, carga, gargalo).

Se isso funcionar, o sistema é válido e escalável.

---

## Regra do projeto

> Não adicionar complexidade sem necessidade empírica.
