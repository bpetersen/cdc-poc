CREATE TABLE IF NOT EXISTS member (
    id text NOT NULL PRIMARY KEY,
    name text,
    position text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS team (
    id text NOT NULL PRIMARY KEY,
    name text,
    year text,
    created_at text,
    updated_at text
);

CREATE TABLE IF NOT EXISTS team_member (
    team_id text NOT NULL REFERENCES team(id),
    member_id text NOT NULL REFERENCES member(id),
    created_at text,
    PRIMARY KEY(team_id, member_id)
);

CREATE TABLE IF NOT EXISTS domain_event (
    id text NOT NULL,
    aggregate_id text NOT NULL,
    aggregate_type text NOT NULL,
    payload text,
    timestamp text NOT NULL,
    type text NOT NULL,
    PRIMARY KEY(aggregate_id, aggregate_type) --This is what controls the kafka partition key.  If we used id (which is randomly generated) then we will have events for the same aggregate id going to different kafka partitions (bad).
);

CREATE TABLE IF NOT EXISTS cdc_heartbeat (
    id SERIAL NOT NULL PRIMARY KEY,
    last_heartbeat_at text
);

INSERT INTO member (id, name, position, created_at, updated_at) VALUES ('1c0a75de-670f-11eb-ae93-0242ac130002', 'Patrick Kane', 'F', '2021-02-01T17:39:58.796Z', '2021-02-01T17:39:58.796Z');
INSERT INTO member (id, name, position, created_at, updated_at) VALUES ('2c0a75de-670f-11eb-ae93-0242ac130002', 'Alex DeBrincat', 'F', '2021-02-02T17:39:58.796Z', '2021-02-02T17:39:58.796Z');
INSERT INTO member (id, name, position, created_at, updated_at) VALUES ('3c0a75de-670f-11eb-ae93-0242ac130002', 'Alec Martinez', 'D', '2021-02-03T17:39:58.796Z', '2021-02-03T17:39:58.796Z');
INSERT INTO member (id, name, position, created_at, updated_at) VALUES ('4c0a75de-670f-11eb-ae93-0242ac130002', 'Ryan Reaves', 'F', '2021-02-04T17:39:58.796Z', '2021-02-04T17:39:58.796Z');
INSERT INTO member (id, name, position, created_at, updated_at) VALUES ('5c0a75de-670f-11eb-ae93-0242ac130002', 'Jonathan Marchessault', 'F', '2021-02-04T17:39:58.796Z', '2021-02-04T17:39:58.796Z');

INSERT INTO team (id, name, year, created_at, updated_at) VALUES ('ac0a75de-670f-11eb-ae93-0242ac130002', 'Team USA', '2019', '2021-02-06T17:39:58.796Z', '2021-02-06T17:39:58.796Z');
INSERT INTO team (id, name, year, created_at, updated_at) VALUES ('bc0a75de-670f-11eb-ae93-0242ac130002', 'Chicago Blackhawks', '2021', '2021-02-06T17:39:58.796Z', '2021-02-06T17:39:58.796Z');
INSERT INTO team (id, name, year, created_at, updated_at) VALUES ('cc0a75de-670f-11eb-ae93-0242ac130002', 'Vegas Golden Knights', '2021', '2021-02-06T17:39:58.796Z', '2021-02-06T17:39:58.796Z');
INSERT INTO team (id, name, year, created_at, updated_at) VALUES ('dc0a75de-670f-11eb-ae93-0242ac130002', 'Team Canada', '2019', '2021-02-06T17:39:58.796Z', '2021-02-06T17:39:58.796Z');

INSERT INTO team_member (member_id, team_id, created_at) VALUES ('1c0a75de-670f-11eb-ae93-0242ac130002', 'ac0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('1c0a75de-670f-11eb-ae93-0242ac130002', 'bc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('2c0a75de-670f-11eb-ae93-0242ac130002', 'bc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('2c0a75de-670f-11eb-ae93-0242ac130002', 'ac0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('3c0a75de-670f-11eb-ae93-0242ac130002', 'ac0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('3c0a75de-670f-11eb-ae93-0242ac130002', 'cc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('4c0a75de-670f-11eb-ae93-0242ac130002', 'cc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('5c0a75de-670f-11eb-ae93-0242ac130002', 'dc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');
INSERT INTO team_member (member_id, team_id, created_at) VALUES ('5c0a75de-670f-11eb-ae93-0242ac130002', 'cc0a75de-670f-11eb-ae93-0242ac130002', '2021-02-06T17:39:58.796Z');

