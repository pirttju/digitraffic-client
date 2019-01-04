CREATE SCHEMA rata;

CREATE TYPE rata.train_type AS ENUM ('AE','H','HDM','HL','HLV','HSM','HV','IC','IC2','LIV','MUS','MUV','MV','P','PAI','PVS','PVV','PYO','S','SAA','T','TYO','V','VET','VEV','VLI','W');
CREATE TYPE rata.timetable_type AS ENUM ('REGULAR', 'ADHOC');

CREATE TABLE rata.trains (
    train_number        int NOT NULL,
    departure_date      date NOT NULL,
    operator_code       text,
    train_type          rata.train_type NOT NULL,
    commuter_line_id    text,
    running_currently   boolean NOT NULL DEFAULT FALSE,
    cancelled           boolean NOT NULL DEFAULT FALSE,
    version             bigint NOT NULL,
    timetable_type      rata.timetable_type NOT NULL DEFAULT 'REGULAR'::rata.timetable_type,
    acceptance_date     timestamptz NOT NULL,
    begin_station       text NOT NULL,
    begin_time          timestamptz NOT NULL,
    end_station         text NOT NULL,
    end_time            timestamptz NOT NULL,
    last_modified       timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (train_number, departure_date)
);

CREATE INDEX ON rata.trains (operator_code);
CREATE INDEX ON rata.trains (train_type);

CREATE TYPE rata.train_ready_type AS ENUM ('KUPLA', 'LIIKE', 'PHONE', 'UNKNOWN');

CREATE TABLE rata.timetablerows (
    train_number        int NOT NULL,
    departure_date      date NOT NULL,
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
    train_ready_src     rata.train_ready_type,
    train_passed        boolean,
    actual_platform     text,
    PRIMARY KEY (train_number, departure_date, row_index)
);

CREATE INDEX ON rata.timetablerows (station);

CREATE TABLE rata.compositions (
    train_number        int NOT NULL,
    departure_date      date NOT NULL,
    version             bigint NOT NULL,
    journey_index       smallint NOT NULL,
    begin_station       text NOT NULL,
    begin_time          timestamptz NOT NULL,
    end_station         text NOT NULL,
    end_time            timestamptz NOT NULL,
    locomotives         jsonb,
    wagons              jsonb,
    total_length        smallint,
    maximum_speed       smallint,
    last_modified       timestamptz,
    PRIMARY KEY (train_number, departure_date, journey_index)
);

CREATE TABLE rata.trainlocations (
    train_number        int NOT NULL,
    departure_date      date NOT NULL,
    description         text NOT NULL,
    timestamp           timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    geom                geometry(Point,4326) NOT NULL,
    speed               smallint,
    bearing             smallint,
    track_section       text,
    data_source         text,
    PRIMARY KEY (train_number, departure_date)
);

-- bearing is not supplied from the train-location feed so we have to calculate it
CREATE OR REPLACE FUNCTION set_bearing() RETURNS TRIGGER AS
$$
BEGIN
    IF (ST_Equals(OLD.geom, NEW.geom)) THEN
        NEW."bearing" := OLD."bearing";
    ELSE
        NEW."bearing" := round(ST_Azimuth(OLD."geom", NEW."geom")/(2*pi())*360);
    END IF;
    RETURN NEW;
END
$$
LANGUAGE plpgsql;

CREATE TRIGGER set_bearing
BEFORE UPDATE ON rata.trainlocations
FOR EACH ROW EXECUTE PROCEDURE set_bearing();

-- create timescaledb tables
SELECT create_hypertable('rata.trains', 'departure_date');
SELECT create_hypertable('rata.timetablerows', 'departure_date');
SELECT create_hypertable('rata.compositions', 'departure_date');
