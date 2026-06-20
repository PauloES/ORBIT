-- ============================================================
-- ORBIT - Sprint 1 - Módulo 4
-- Seed: primeiro processo real — Triagem de E-mail
--
-- Este script configura uma simulação completa de 1 dia de trabalho
-- com 1 funcionário de suporte fazendo triagem de e-mails.
--
-- Ao final, execute:
--   EXEC pSP_RUN_SIMUL @simulation_id = 1;
-- ============================================================

-- ------------------------------------------------------------
-- 1. Papéis
-- ------------------------------------------------------------
INSERT INTO pTB_ROLE (name, detail, status) VALUES
    ('EXECUTOR',    'Executor direto do processo',            'ATIVO'),
    ('SOLICITANTE', 'Quem originou o trigger do processo',    'ATIVO'),
    ('APROVADOR',   'Quem valida a conclusão do processo',    'ATIVO');

-- ------------------------------------------------------------
-- 2. Simulação
-- ------------------------------------------------------------
INSERT INTO pTB_SIMULATION (name, start_time, end_time, status, created_at)
VALUES (
    'Triagem de E-mail - Dia 1',
    '2026-06-19 08:00:00',
    '2026-06-19 18:00:00',
    'PENDENTE',
    GETDATE()
);

DECLARE @sim_id INT = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- 3. Entidades
-- ------------------------------------------------------------
INSERT INTO pTB_ENTITY (simulation_id, name, detail, type, status) VALUES
    (@sim_id, 'DIGITALSS',        'Empresa Digitalss',                            'ESTRUTURA',   'ATIVA'),
    (@sim_id, 'SUPORTE',          'Departamento de Suporte',                      'ESTRUTURA',   'ATIVA'),
    (@sim_id, 'SUPORTE-ANALISTA', 'Analista de Suporte responsável pela triagem', 'OPERACIONAL', 'ATIVA');

DECLARE @id_digitalss  INT = (SELECT id FROM pTB_ENTITY WHERE simulation_id = @sim_id AND name = 'DIGITALSS');
DECLARE @id_suporte    INT = (SELECT id FROM pTB_ENTITY WHERE simulation_id = @sim_id AND name = 'SUPORTE');
DECLARE @id_analista   INT = (SELECT id FROM pTB_ENTITY WHERE simulation_id = @sim_id AND name = 'SUPORTE-ANALISTA');

-- ------------------------------------------------------------
-- 4. Relacionamentos
-- ------------------------------------------------------------
INSERT INTO pTB_RELATION (simulation_id, entity_child_id, entity_parent_id) VALUES
    (@sim_id, @id_suporte,  @id_digitalss),   -- SUPORTE pertence a DIGITALSS
    (@sim_id, @id_analista, @id_suporte);      -- ANALISTA pertence a SUPORTE

-- ------------------------------------------------------------
-- 5. Processo
-- ------------------------------------------------------------
INSERT INTO pTB_PROCESS_DEFINITION (simulation_id, name, detail, avg_duration_minutes, status)
VALUES (
    @sim_id,
    'TRIAGEM DE CHAMADOS DE SUPORTE',
    'Análise de e-mails recebidos para determinar direcionamento: abertura de chamado, resposta direta ou encaminhamento.',
    15,      -- média de 15 minutos; execução varia entre 7 e 22 minutos
    'ATIVO'
);

DECLARE @proc_id INT = SCOPE_IDENTITY();

-- ------------------------------------------------------------
-- 6. Trigger: EMAIL_RECEIVED dispara triagem
-- ------------------------------------------------------------
INSERT INTO pTB_PROCESS_TRIGGER (simulation_id, process_id, event_type, priority, status)
VALUES (@sim_id, @proc_id, 'EMAIL_RECEIVED', 1, 'ATIVO');

-- ------------------------------------------------------------
-- Confirmação
-- ------------------------------------------------------------
PRINT '============================================';
PRINT 'Seed concluído. simulation_id = ' + CAST(@sim_id AS VARCHAR(10));
PRINT 'Para rodar: EXEC pSP_RUN_SIMUL ' + CAST(@sim_id AS VARCHAR(10));
PRINT '============================================';

SELECT 'SIMULAÇÃO'  AS tipo, CAST(@sim_id AS VARCHAR(10)) AS id, 'Triagem de E-mail - Dia 1' AS nome
UNION ALL
SELECT 'PROCESSO',  CAST(@proc_id AS VARCHAR(10)),   'TRIAGEM DE CHAMADOS DE SUPORTE'
UNION ALL
SELECT 'ENTIDADE',  CAST(@id_digitalss AS VARCHAR(10)),  'DIGITALSS'
UNION ALL
SELECT 'ENTIDADE',  CAST(@id_suporte AS VARCHAR(10)),    'SUPORTE'
UNION ALL
SELECT 'ENTIDADE',  CAST(@id_analista AS VARCHAR(10)),   'SUPORTE-ANALISTA';
