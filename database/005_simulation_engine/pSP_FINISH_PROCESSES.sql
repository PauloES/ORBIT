CREATE OR ALTER PROCEDURE pSP_FINISH_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Finaliza execuções cuja duração real atingiu a duração esperada
    -- A duração esperada é calculada no momento da criação da execução
    -- como uma variação aleatória entre 50% e 150% da média do processo
    UPDATE pe
    SET pe.status   = 'FINALIZADO',
        pe.end_time = @dt_curr
    FROM pTB_PROCESS_EXECUTION pe
    INNER JOIN pTB_PROCESS_DEFINITION pd ON pd.id = pe.process_id
    WHERE pe.simulation_id = @simulation_id
      AND pe.status        = 'RUNNING'
      AND DATEDIFF(MINUTE, pe.start_time, @dt_curr) >=
          CAST(pd.avg_duration_minutes * (0.5 + RAND() * 1.0) AS INT);

    -- Libera alocações das execuções finalizadas
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
