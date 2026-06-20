CREATE OR ALTER PROCEDURE pSP_RUN_SIMUL
    @simulation_id   INT,
    @cycle_size_sec  INT = 300   -- 5 minutos de tempo simulado por tick
AS
BEGIN
    SET NOCOUNT ON;

    -- Carrega janela de tempo da simulação
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

    -- Marca simulação como em execução
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

        -- 1. Gerar eventos probabilísticos
        EXEC pSP_GENERATE_EVENTS @simulation_id, @dt_curr;

        -- 2. Disparar processos a partir dos eventos pendentes
        EXEC pSP_START_PROCESSES @simulation_id, @dt_curr;

        -- 3. Atualizar estado interno dos processos em andamento (v1: passthrough)
        EXEC pSP_EXECUTE_PROCESSES @simulation_id, @dt_curr;

        -- 4. Finalizar processos que atingiram duração esperada (vem de pTB_PROCESS_DEFINITION)
        EXEC pSP_FINISH_PROCESSES @simulation_id, @dt_curr;

        -- Avança o relógio
        SET @dt_curr = DATEADD(SECOND, @cycle_size_sec, @dt_curr);
    END

    -- Marca simulação como finalizada
    UPDATE pTB_SIMULATION SET status = 'FINALIZADO' WHERE id = @simulation_id;

    PRINT '==========================================================';
    PRINT 'SIMULAÇÃO FINALIZADA';
    PRINT 'Ticks executados: ' + CAST(@tick AS VARCHAR(10));
    PRINT '==========================================================';

    -- Relatório rápido
    SELECT
        pd.name                                          AS processo,
        COUNT(pe.id)                                     AS total_execucoes,
        AVG(DATEDIFF(MINUTE, pe.start_time, pe.end_time)) AS duracao_media_min,
        SUM(DATEDIFF(MINUTE, pe.start_time, pe.end_time)) AS tempo_total_min
    FROM pTB_PROCESS_EXECUTION pe
    INNER JOIN pTB_PROCESS_DEFINITION pd ON pd.id = pe.process_id
    WHERE pe.simulation_id = @simulation_id
      AND pe.status        = 'FINALIZADO'
    GROUP BY pd.name;
END
GO
