CREATE TABLE pTB_EVENT_QUEUE (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id   INT,
    event_id        INT,
    status          NVARCHAR(50), -- PENDENTE | PROCESSADO | ERRO
    created_at      DATETIME DEFAULT GETDATE()
);