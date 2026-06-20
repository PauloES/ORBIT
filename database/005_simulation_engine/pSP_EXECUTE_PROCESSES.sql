CREATE OR ALTER PROCEDURE pSP_EXECUTE_PROCESSES
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    -- Reservado para lógica futura de progresso interno dos processos
    -- (ex: etapas, bloqueios, espera por aprovação)
    -- Na v1, o processo vai direto de RUNNING para finalização pelo pSP_FINISH_PROCESSES
END
GO
