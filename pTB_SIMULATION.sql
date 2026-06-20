CREATE TABLE pTB_SIMULATION (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(255),
    start_time      DATETIME,
    end_time        DATETIME NULL,
    status          NVARCHAR(50),
    created_at      DATETIME DEFAULT GETDATE()
);