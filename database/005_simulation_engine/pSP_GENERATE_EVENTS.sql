CREATE OR ALTER PROCEDURE pSP_GENERATE_EVENTS
    @simulation_id INT,
    @dt_curr       DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- EMAIL_RECEIVED: 30% de chance por tick em horário comercial
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
