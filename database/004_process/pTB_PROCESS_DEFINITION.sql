CREATE TABLE pTB_PROCESS_DEFINITION (
    id                   INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id        INT              NOT NULL,
    name                 NVARCHAR(255),
    detail               NVARCHAR(1000),
    avg_duration_minutes INT,             -- duração média; execução varia entre 50% e 150%
    status               NVARCHAR(50)     -- ATIVO | INATIVO
);
