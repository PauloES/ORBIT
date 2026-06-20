CREATE OR ALTER PROCEDURE pSP_START_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event_id   INT;
    DECLARE @event_type NVARCHAR(100);
    DECLARE @queue_id   INT;
    DECLARE @process_id INT;
    DECLARE @execution_id INT;
    DECLARE @entity_id  INT;
    DECLARE @role_id    INT;

    SELECT TOP 1 @role_id = id FROM pTB_ROLE WHERE name = 'EXECUTOR' AND status = 'ATIVO';

    -- Processa eventos enquanto houver fila pendente E recurso operacional livre
    WHILE 1 = 1
    BEGIN

        -- Verifica se há entidade operacional livre
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
            BREAK;  -- nenhum recurso livre, encerra o loop

        -- Verifica se há evento pendente na fila
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
            BREAK;  -- fila vazia, encerra o loop

        -- Marca evento como processado
        UPDATE pTB_EVENT_QUEUE
        SET status = 'PROCESSADO'
        WHERE id = @queue_id;

        -- Encontra processo que responde a este evento
        SELECT TOP 1 @process_id = process_id
        FROM pTB_PROCESS_TRIGGER
        WHERE simulation_id = @simulation_id
          AND event_type    = @event_type
          AND status        = 'ATIVO'
        ORDER BY priority;

        IF @process_id IS NULL
        BEGIN
            SET @event_id = NULL;
            CONTINUE;  -- evento sem processo mapeado, tenta o próximo
        END

        -- Cria execução do processo
        INSERT INTO pTB_PROCESS_EXECUTION (simulation_id, process_id, source_trigger_id, start_time, status)
        VALUES (@simulation_id, @process_id, @event_id, @dt_curr, 'RUNNING');

        SET @execution_id = SCOPE_IDENTITY();

        -- Aloca a entidade livre encontrada no início do loop
        INSERT INTO pTB_PROCESS_EXECUTION_ALLOCATION
            (simulation_id, execution_id, entity_id, role_id, join_time)
        VALUES
            (@simulation_id, @execution_id, @entity_id, @role_id, @dt_curr);

        -- Reseta para a próxima iteração
        SET @event_id   = NULL;
        SET @entity_id  = NULL;
        SET @process_id = NULL;

    END
END
GO
