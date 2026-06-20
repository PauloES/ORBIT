CREATE TABLE pTB_PROCESS_TRIGGER (
    id             INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id  INT               NOT NULL,
    process_id     INT               NOT NULL,  -- FK pTB_PROCESS_DEFINITION
    event_type     NVARCHAR(100)     NOT NULL,  -- ex: EMAIL_RECEIVED
    priority       INT               DEFAULT 1,
    status         NVARCHAR(50)                 -- ATIVO | INATIVO
);
