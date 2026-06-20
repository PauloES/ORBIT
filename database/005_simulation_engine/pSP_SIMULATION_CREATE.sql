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
