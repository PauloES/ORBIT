CREATE TABLE pTB_PROCESS_EXECUTION (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id   INT,
    entity_id       INT,
    process_name    NVARCHAR(255),
    start_time      DATETIME,
    end_time        DATETIME,
    status          NVARCHAR(50)
);