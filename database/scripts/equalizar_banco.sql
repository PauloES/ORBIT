-- ============================================================
-- ORBIT - Script de equalização do banco com o git
-- Executar uma única vez para sincronizar o banco
-- ============================================================

-- ------------------------------------------------------------
-- 1. Remover procedure depreciada
-- ------------------------------------------------------------
IF OBJECT_ID('pSP_ENGINE_RUN', 'P') IS NOT NULL
    DROP PROCEDURE pSP_ENGINE_RUN;
GO

-- ------------------------------------------------------------
-- 2. Novas tabelas
-- ------------------------------------------------------------

-- pTB_RELATION
IF OBJECT_ID('pTB_RELATION', 'U') IS NULL
BEGIN
    CREATE TABLE pTB_RELATION (
        id                INT IDENTITY(1,1) PRIMARY KEY,
        simulation_id     INT               NOT NULL,
        entity_child_id   INT               NOT NULL,
        entity_parent_id  INT               NOT NULL
    );
    PRINT 'pTB_RELATION criada.';
END
GO

-- pTB_ROLE
IF OBJECT_ID('pTB_ROLE', 'U') IS NULL
BEGIN
    CREATE TABLE pTB_ROLE (
        id     INT IDENTITY(1,1) PRIMARY KEY,
        name   NVARCHAR(100),
        detail NVARCHAR(500),
        status NVARCHAR(50)
    );
    PRINT 'pTB_ROLE criada.';
END
GO

-- pTB_PROCESS_DEFINITION
IF OBJECT_ID('pTB_PROCESS_DEFINITION', 'U') IS NULL
BEGIN
    CREATE TABLE pTB_PROCESS_DEFINITION (
        id                   INT IDENTITY(1,1) PRIMARY KEY,
        simulation_id        INT              NOT NULL,
        name                 NVARCHAR(255),
        detail               NVARCHAR(1000),
        avg_duration_minutes INT,
        status               NVARCHAR(50)
    );
    PRINT 'pTB_PROCESS_DEFINITION criada.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'pTB_PROCESS_DEFINITION' AND COLUMN_NAME = 'avg_duration_minutes'
)
BEGIN
    ALTER TABLE pTB_PROCESS_DEFINITION ADD avg_duration_minutes INT;
    PRINT 'pTB_PROCESS_DEFINITION: avg_duration_minutes adicionado.';
END
GO

-- pTB_PROCESS_TRIGGER
IF OBJECT_ID('pTB_PROCESS_TRIGGER', 'U') IS NULL
BEGIN
    CREATE TABLE pTB_PROCESS_TRIGGER (
        id             INT IDENTITY(1,1) PRIMARY KEY,
        simulation_id  INT               NOT NULL,
        process_id     INT               NOT NULL,
        event_type     NVARCHAR(100)     NOT NULL,
        priority       INT               DEFAULT 1,
        status         NVARCHAR(50)
    );
    PRINT 'pTB_PROCESS_TRIGGER criada.';
END
GO

-- pTB_PROCESS_EXECUTION_ALLOCATION
IF OBJECT_ID('pTB_PROCESS_EXECUTION_ALLOCATION', 'U') IS NULL
BEGIN
    CREATE TABLE pTB_PROCESS_EXECUTION_ALLOCATION (
        id            INT IDENTITY(1,1) PRIMARY KEY,
        simulation_id INT              NOT NULL,
        execution_id  INT              NOT NULL,
        entity_id     INT              NOT NULL,
        role_id       INT              NOT NULL,
        join_time     DATETIME,
        leave_time    DATETIME
    );
    PRINT 'pTB_PROCESS_EXECUTION_ALLOCATION criada.';
END
GO

-- ------------------------------------------------------------
-- 3. Ajustar pTB_PROCESS_EXECUTION
-- Substituir process_name (texto livre) e entity_id
-- por process_id (FK) e source_trigger_id
-- ------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'pTB_PROCESS_EXECUTION' AND COLUMN_NAME = 'process_name'
)
BEGIN
    ALTER TABLE pTB_PROCESS_EXECUTION DROP COLUMN process_name;
    PRINT 'pTB_PROCESS_EXECUTION: process_name removido.';
END
GO

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'pTB_PROCESS_EXECUTION' AND COLUMN_NAME = 'entity_id'
)
BEGIN
    ALTER TABLE pTB_PROCESS_EXECUTION DROP COLUMN entity_id;
    PRINT 'pTB_PROCESS_EXECUTION: entity_id removido.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'pTB_PROCESS_EXECUTION' AND COLUMN_NAME = 'process_id'
)
BEGIN
    ALTER TABLE pTB_PROCESS_EXECUTION ADD process_id INT;
    PRINT 'pTB_PROCESS_EXECUTION: process_id adicionado.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'pTB_PROCESS_EXECUTION' AND COLUMN_NAME = 'source_trigger_id'
)
BEGIN
    ALTER TABLE pTB_PROCESS_EXECUTION ADD source_trigger_id INT;
    PRINT 'pTB_PROCESS_EXECUTION: source_trigger_id adicionado.';
END
GO

-- ------------------------------------------------------------
-- 4. Procedures de gerenciamento de simulação
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE pSP_SIMULATION_CREATE
    @name        NVARCHAR(255),
    @start_time  DATETIME,
    @end_time    DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pTB_SIMULATION (name, start_time, end_time, status, created_at)
    VALUES (@name, @start_time, @end_time, 'PENDENTE', GETDATE());

    DECLARE @simulation_id INT = SCOPE_IDENTITY();

    PRINT 'Simulação criada: ID = ' + CAST(@simulation_id AS VARCHAR(10));

    SELECT @simulation_id AS simulation_id;
END
GO

CREATE OR ALTER PROCEDURE pSP_SIMULATION_DELETE
    @simulation_id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM pTB_PROCESS_EXECUTION_ALLOCATION WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_PROCESS_EXECUTION             WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_PROCESS_TRIGGER               WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_PROCESS_DEFINITION            WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_EVENT_QUEUE                   WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_EVENT                         WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_RELATION                      WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_ENTITY                        WHERE simulation_id = @simulation_id;
    DELETE FROM pTB_SIMULATION                    WHERE id            = @simulation_id;

    PRINT 'Simulação ' + CAST(@simulation_id AS VARCHAR(10)) + ' removida.';
END
GO

CREATE OR ALTER PROCEDURE pSP_SIMULATION_CLONE
    @source_id   INT,
    @new_name    NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO pTB_SIMULATION (name, start_time, end_time, status, created_at)
    SELECT @new_name, start_time, end_time, 'PENDENTE', GETDATE()
    FROM pTB_SIMULATION
    WHERE id = @source_id;

    DECLARE @new_id INT = SCOPE_IDENTITY();

    INSERT INTO pTB_ENTITY (simulation_id, name, detail, type, status)
    SELECT @new_id, name, detail, type, status
    FROM pTB_ENTITY
    WHERE simulation_id = @source_id;

    WITH origem AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_ENTITY WHERE simulation_id = @source_id
    ),
    destino AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_ENTITY WHERE simulation_id = @new_id
    )
    INSERT INTO pTB_RELATION (simulation_id, entity_child_id, entity_parent_id)
    SELECT @new_id, d_child.id, d_parent.id
    FROM pTB_RELATION r
    JOIN origem  o_child  ON o_child.id  = r.entity_child_id
    JOIN origem  o_parent ON o_parent.id = r.entity_parent_id
    JOIN destino d_child  ON d_child.rn  = o_child.rn
    JOIN destino d_parent ON d_parent.rn = o_parent.rn
    WHERE r.simulation_id = @source_id;

    INSERT INTO pTB_PROCESS_DEFINITION (simulation_id, name, detail, avg_duration_minutes, status)
    SELECT @new_id, name, detail, avg_duration_minutes, status
    FROM pTB_PROCESS_DEFINITION
    WHERE simulation_id = @source_id;

    WITH proc_orig AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_PROCESS_DEFINITION WHERE simulation_id = @source_id
    ),
    proc_dest AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_PROCESS_DEFINITION WHERE simulation_id = @new_id
    )
    INSERT INTO pTB_PROCESS_TRIGGER (simulation_id, process_id, event_type, priority, status)
    SELECT @new_id, pd.id, pt.event_type, pt.priority, pt.status
    FROM pTB_PROCESS_TRIGGER pt
    JOIN proc_orig po ON po.id = pt.process_id
    JOIN proc_dest pd ON pd.rn = po.rn
    WHERE pt.simulation_id = @source_id;

    PRINT 'Simulação clonada: ' + CAST(@source_id AS VARCHAR(10)) + ' → ' + CAST(@new_id AS VARCHAR(10));

    SELECT @new_id AS simulation_id;
END
GO

-- ------------------------------------------------------------
-- 5. Motor de simulação
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE pSP_GENERATE_EVENTS
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    IF (DATEPART(HOUR, @dt_curr) BETWEEN 8 AND 17)
       AND (RAND() < 0.30)
    BEGIN
        DECLARE @event_id INT;

        INSERT INTO pTB_EVENT (simulation_id, event_type, event_time, status)
        VALUES (@simulation_id, 'EMAIL_RECEIVED', @dt_curr, 'PENDENTE');

        SET @event_id = SCOPE_IDENTITY();

        INSERT INTO pTB_EVENT_QUEUE (simulation_id, event_id, status, created_at)
        VALUES (@simulation_id, @event_id, 'PENDENTE', @dt_curr);
    END
END
GO

CREATE OR ALTER PROCEDURE pSP_START_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event_id     INT;
    DECLARE @event_type   NVARCHAR(100);
    DECLARE @queue_id     INT;
    DECLARE @process_id   INT;
    DECLARE @execution_id INT;
    DECLARE @entity_id    INT;
    DECLARE @role_id      INT;

    SELECT TOP 1 @role_id = id FROM pTB_ROLE WHERE name = 'EXECUTOR' AND status = 'ATIVO';

    WHILE 1 = 1
    BEGIN

        SELECT TOP 1 @entity_id = e.id
        FROM pTB_ENTITY e
        WHERE e.simulation_id = @simulation_id
          AND e.type          = 'OPERACIONAL'
          AND e.status        = 'ATIVA'
          AND NOT EXISTS (
              SELECT 1 FROM pTB_PROCESS_EXECUTION_ALLOCATION a
              INNER JOIN pTB_PROCESS_EXECUTION pe ON pe.id = a.execution_id
              WHERE a.entity_id      = e.id
                AND pe.simulation_id = @simulation_id
                AND pe.status        = 'RUNNING'
                AND a.leave_time     IS NULL
          )
        ORDER BY e.id;

        IF @entity_id IS NULL
            BREAK;

        SELECT TOP 1
            @queue_id   = eq.id,
            @event_id   = eq.event_id,
            @event_type = e.event_type
        FROM pTB_EVENT_QUEUE eq
        INNER JOIN pTB_EVENT e ON e.id = eq.event_id
        WHERE eq.simulation_id = @simulation_id
          AND eq.status        = 'PENDENTE'
        ORDER BY eq.id;

        IF @event_id IS NULL
            BREAK;

        UPDATE pTB_EVENT_QUEUE
        SET status = 'PROCESSADO'
        WHERE id = @queue_id;

        SELECT TOP 1 @process_id = process_id
        FROM pTB_PROCESS_TRIGGER
        WHERE simulation_id = @simulation_id
          AND event_type    = @event_type
          AND status        = 'ATIVO'
        ORDER BY priority;

        IF @process_id IS NULL
        BEGIN
            SET @event_id = NULL;
            CONTINUE;
        END

        INSERT INTO pTB_PROCESS_EXECUTION (simulation_id, process_id, source_trigger_id, start_time, status)
        VALUES (@simulation_id, @process_id, @event_id, @dt_curr, 'RUNNING');

        SET @execution_id = SCOPE_IDENTITY();

        INSERT INTO pTB_PROCESS_EXECUTION_ALLOCATION
            (simulation_id, execution_id, entity_id, role_id, join_time)
        VALUES
            (@simulation_id, @execution_id, @entity_id, @role_id, @dt_curr);

        SET @event_id   = NULL;
        SET @entity_id  = NULL;
        SET @process_id = NULL;

    END
END
GO

CREATE OR ALTER PROCEDURE pSP_EXECUTE_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    -- Reservado para v2: etapas internas, bloqueios, aprovações
END
GO

CREATE OR ALTER PROCEDURE pSP_FINISH_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE pe
    SET pe.status   = 'FINALIZADO',
        pe.end_time = @dt_curr
    FROM pTB_PROCESS_EXECUTION pe
    INNER JOIN pTB_PROCESS_DEFINITION pd ON pd.id = pe.process_id
    WHERE pe.simulation_id = @simulation_id
      AND pe.status        = 'RUNNING'
      AND DATEDIFF(MINUTE, pe.start_time, @dt_curr) >=
          CAST(pd.avg_duration_minutes * (0.5 + RAND() * 1.0) AS INT);

    UPDATE pTB_PROCESS_EXECUTION_ALLOCATION
    SET leave_time = @dt_curr
    WHERE simulation_id = @simulation_id
      AND leave_time    IS NULL
      AND execution_id IN (
          SELECT id FROM pTB_PROCESS_EXECUTION
          WHERE simulation_id = @simulation_id
            AND status        = 'FINALIZADO'
            AND end_time      = @dt_curr
      );
END
GO

CREATE OR ALTER PROCEDURE pSP_RUN_SIMUL
    @simulation_id   INT,
    @cycle_size_sec  INT = 300
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dt_start DATETIME;
    DECLARE @dt_end   DATETIME;

    SELECT @dt_start = start_time, @dt_end = end_time
    FROM pTB_SIMULATION
    WHERE id = @simulation_id;

    IF @dt_start IS NULL
    BEGIN
        PRINT 'Simulação não encontrada: ' + CAST(@simulation_id AS VARCHAR(10));
        RETURN;
    END

    UPDATE pTB_SIMULATION SET status = 'RUNNING' WHERE id = @simulation_id;

    DECLARE @dt_curr DATETIME = @dt_start;
    DECLARE @tick    INT      = 0;

    PRINT '==========================================================';
    PRINT 'ORBIT - Iniciando simulação ID: ' + CAST(@simulation_id AS VARCHAR(10));
    PRINT 'Período: ' + CONVERT(VARCHAR(19), @dt_start, 120)
        + ' → ' + CONVERT(VARCHAR(19), @dt_end, 120);
    PRINT '==========================================================';

    WHILE @dt_curr < @dt_end
    BEGIN
        SET @tick = @tick + 1;

        EXEC pSP_GENERATE_EVENTS   @simulation_id, @dt_curr;
        EXEC pSP_START_PROCESSES   @simulation_id, @dt_curr;
        EXEC pSP_EXECUTE_PROCESSES @simulation_id, @dt_curr;
        EXEC pSP_FINISH_PROCESSES  @simulation_id, @dt_curr;

        SET @dt_curr = DATEADD(SECOND, @cycle_size_sec, @dt_curr);
    END

    UPDATE pTB_SIMULATION SET status = 'FINALIZADO' WHERE id = @simulation_id;

    PRINT '==========================================================';
    PRINT 'SIMULAÇÃO FINALIZADA';
    PRINT 'Ticks executados: ' + CAST(@tick AS VARCHAR(10));
    PRINT '==========================================================';

    SELECT
        pd.name                                           AS processo,
        COUNT(pe.id)                                      AS total_execucoes,
        AVG(DATEDIFF(MINUTE, pe.start_time, pe.end_time)) AS duracao_media_min,
        SUM(DATEDIFF(MINUTE, pe.start_time, pe.end_time)) AS tempo_total_min
    FROM pTB_PROCESS_EXECUTION pe
    INNER JOIN pTB_PROCESS_DEFINITION pd ON pd.id = pe.process_id
    WHERE pe.simulation_id = @simulation_id
      AND pe.status        = 'FINALIZADO'
    GROUP BY pd.name;
END
GO

-- ------------------------------------------------------------
-- Verificação final
-- ------------------------------------------------------------
SELECT
    type_desc,
    name,
    create_date
FROM sys.objects
WHERE name LIKE 'pTB_%' OR name LIKE 'pSP_%'
ORDER BY type_desc, name;
GO
