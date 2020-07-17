CREATE TABLE trains (
    departure_date      date NOT NULL,
    train_number        int NOT NULL,
    operator_code       text,
    train_type          text NOT NULL,
    commuter_line_id    text,
    running_currently   boolean NOT NULL DEFAULT FALSE,
    cancelled           boolean NOT NULL DEFAULT FALSE,
    version             bigint NOT NULL,
    adhoc_timetable     boolean NOT NULL DEFAULT FALSE,
    acceptance_date     timestamptz NOT NULL,
    begin_station       text NOT NULL,
    begin_time          timestamptz NOT NULL,
    end_station         text NOT NULL,
    end_time            timestamptz NOT NULL,
    last_modified       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted             boolean NOT NULL DEFAULT FALSE,
    PRIMARY KEY (departure_date, train_number)
);

CREATE INDEX ON trains (operator_code);
CREATE INDEX ON trains (train_type);

CREATE TYPE train_ready_type AS ENUM ('KUPLA', 'LIIKE', 'PHONE', 'UNKNOWN');

CREATE TABLE timetablerows (
    departure_date      date NOT NULL,
    train_number        int NOT NULL,
    row_index           smallint NOT NULL,
    train_stopping      boolean NOT NULL DEFAULT FALSE,
    station             text NOT NULL,
    commercial_stop     boolean NOT NULL DEFAULT FALSE,
    commercial_track    text,
    arr_cancelled       boolean,
    arr_scheduled       timestamptz,
    arr_estimate        timestamptz,
    arr_unknown_delay   boolean,
    arr_actual          timestamptz,
    arr_minutes         smallint,
    arr_cause_code      text,
    dep_cancelled       boolean,
    dep_scheduled       timestamptz,
    dep_estimate        timestamptz,
    dep_unknown_delay   boolean,
    dep_actual          timestamptz,
    dep_minutes         smallint,
    dep_cause_code      text,
    train_ready         timestamptz,
    train_ready_src     train_ready_type,
    train_passed        boolean,
    actual_platform     text,
    PRIMARY KEY (departure_date, train_number, row_index)
);

CREATE INDEX ON timetablerows (station);

-- create timescaledb tables
SELECT create_hypertable('rata.trains', 'departure_date');
SELECT create_hypertable('rata.timetablerows', 'departure_date');
SELECT set_chunk_time_interval('rata.trains', interval '1 year');
SELECT set_chunk_time_interval('rata.timetablerows', interval '3 months');