CREATE OR ALTER PROCEDURE pSP_SIMULATION_CLONE
    @source_id   INT,
    @new_name    NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    -- Cria nova simulação baseada na original
    INSERT INTO pTB_SIMULATION (name, start_time, end_time, status, created_at)
    SELECT @new_name, start_time, end_time, 'PENDENTE', GETDATE()
    FROM pTB_SIMULATION
    WHERE id = @source_id;

    DECLARE @new_id INT = SCOPE_IDENTITY();

    -- Clona entidades
    INSERT INTO pTB_ENTITY (simulation_id, name, detail, type, status)
    SELECT @new_id, name, detail, type, status
    FROM pTB_ENTITY
    WHERE simulation_id = @source_id;

    -- Clona relações (remapeia para os novos IDs de entidade)
    -- Mapeamento via ROW_NUMBER baseado na ordem de inserção original
    WITH origem AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_ENTITY WHERE simulation_id = @source_id
    ),
    destino AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn
        FROM pTB_ENTITY WHERE simulation_id = @new_id
    )
    INSERT INTO pTB_RELATION (simulation_id, entity_child_id, entity_parent_id)
    SELECT
        @new_id,
        d_child.id,
        d_parent.id
    FROM pTB_RELATION r
    JOIN origem  o_child  ON o_child.id  = r.entity_child_id
    JOIN origem  o_parent ON o_parent.id = r.entity_parent_id
    JOIN destino d_child  ON d_child.rn  = o_child.rn
    JOIN destino d_parent ON d_parent.rn = o_parent.rn
    WHERE r.simulation_id = @source_id;

    -- Clona definições de processo
    INSERT INTO pTB_PROCESS_DEFINITION (simulation_id, name, detail, status)
    SELECT @new_id, name, detail, status
    FROM pTB_PROCESS_DEFINITION
    WHERE simulation_id = @source_id;

    -- Clona triggers (remapeia process_id para os novos)
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
