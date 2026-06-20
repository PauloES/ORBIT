CREATE TABLE pTB_RELATION (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    simulation_id     INT               NOT NULL,
    entity_child_id   INT               NOT NULL,
    entity_parent_id  INT               NOT NULL
);
