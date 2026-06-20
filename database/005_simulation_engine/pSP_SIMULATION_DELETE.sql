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
