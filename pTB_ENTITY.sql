CREATE TABLE pTB_ENTITY (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id   INT,
    name            NVARCHAR(255),
    detail          NVARCHAR(1000),
    type            NVARCHAR(50),
    status          NVARCHAR(50)
);