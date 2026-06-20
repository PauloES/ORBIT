CREATE TABLE pTB_EVENT (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id   INT,
    event_type      NVARCHAR(100),
    event_time      DATETIME,
    status          NVARCHAR(50)
);