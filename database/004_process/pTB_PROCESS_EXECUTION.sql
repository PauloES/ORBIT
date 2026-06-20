CREATE TABLE pTB_PROCESS_EXECUTION (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id     INT          NOT NULL,
    process_id        INT          NOT NULL,  -- FK pTB_PROCESS_DEFINITION
    source_trigger_id INT,                    -- FK pTB_EVENT (evento que originou)
    start_time        DATETIME,
    end_time          DATETIME,
    status            NVARCHAR(50)            -- RUNNING | FINALIZADO | ERRO
);
