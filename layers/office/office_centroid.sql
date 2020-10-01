DROP TRIGGER IF EXISTS trigger_flag ON osm_office_point;
DROP TRIGGER IF EXISTS trigger_refresh ON office.updates;

-- etldoc: osm_office_point -> osm_office_point
CREATE OR REPLACE FUNCTION convert_office_point() RETURNS void AS
$$
BEGIN
    UPDATE osm_office_point
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE ST_GeometryType(geometry) <> 'ST_Point';
END;
$$ LANGUAGE plpgsql;

SELECT convert_office_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS office;

CREATE TABLE IF NOT EXISTS office.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION office.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO office.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION office.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh office';
    PERFORM convert_office_point();
    -- noinspection SqlWithoutWhere
    DELETE FROM office.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_office_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE office.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON office.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE office.refresh();
