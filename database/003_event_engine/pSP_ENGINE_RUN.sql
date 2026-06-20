CREATE PROCEDURE pSP_ENGINE_RUN
    @simulation_id INT
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @event_id INT;
    DECLARE @event_type NVARCHAR(100);

    -- pega próximo evento
    SELECT TOP 1
        @event_id = eq.event_id,
        @event_type = e.event_type
    FROM pTB_EVENT_QUEUE eq
    INNER JOIN pTB_EVENT e ON e.id = eq.event_id
    WHERE eq.status = 'PENDING'
      AND eq.simulation_id = @simulation_id
    ORDER BY eq.id;

    IF @event_id IS NULL
        RETURN;

    -- marca como processado
    UPDATE pTB_EVENT_QUEUE
    SET status = 'PROCESSED'
    WHERE event_id = @event_id;

    -- LOG simples (primeiro comportamento do ORBIT)
    INSERT INTO pTB_PROCESS_EXECUTION (
        simulation_id,
        entity_id,
        process_name,
        start_time,
        status
    )
    VALUES (
        @simulation_id,
        1,
        @event_type,
        GETDATE(),
        'RUNNING'
    );

    PRINT 'EVENTO PROCESSADO: ' + @event_type;

END