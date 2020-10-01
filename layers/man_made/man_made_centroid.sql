DROP TRIGGER IF EXISTS trigger_flag ON osm_man_made_point;
DROP TRIGGER IF EXISTS trigger_refresh ON man_made.updates;

-- etldoc: osm_man_made_point -> osm_man_made_point
CREATE OR REPLACE FUNCTION convert_man_made_point() RETURNS void AS
$$
BEGIN
    UPDATE osm_man_made_point
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE ST_GeometryType(geometry) <> 'ST_Point';
END;
$$ LANGUAGE plpgsql;

SELECT convert_man_made_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS man_made;

CREATE TABLE IF NOT EXISTS man_made.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION man_made.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO man_made.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION man_made.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh man_made';
    PERFORM convert_man_made_point();
    -- noinspection SqlWithoutWhere
    DELETE FROM man_made.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_man_made_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE man_made.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON man_made.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE man_made.refresh();
