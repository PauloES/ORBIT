CREATE TABLE pTB_PROCESS_EXECUTION_ALLOCATION (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id INT              NOT NULL,
    execution_id INT               NOT NULL,  -- FK pTB_PROCESS_EXECUTION
    entity_id    INT               NOT NULL,  -- FK pTB_ENTITY
    role_id      INT               NOT NULL,  -- FK pTB_ROLE
    join_time    DATETIME,
    leave_time   DATETIME
);
