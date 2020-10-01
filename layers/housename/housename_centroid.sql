DROP TRIGGER IF EXISTS trigger_flag ON osm_housename_point;
DROP TRIGGER IF EXISTS trigger_refresh ON housename.updates;

-- etldoc: osm_housename_point -> osm_housename_point
CREATE OR REPLACE FUNCTION convert_housename_point() RETURNS void AS
$$
BEGIN
    UPDATE osm_housename_point
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE ST_GeometryType(geometry) <> 'ST_Point';
END;
$$ LANGUAGE plpgsql;

SELECT convert_housename_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS housename;

CREATE TABLE IF NOT EXISTS housename.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION housename.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO housename.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION housename.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh housename';
    PERFORM convert_housename_point();
    -- noinspection SqlWithoutWhere
    DELETE FROM housename.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_housename_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE housename.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON housename.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE housename.refresh();
