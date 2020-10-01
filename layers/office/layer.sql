-- etldoc: layer_office[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_office | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_office(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id      bigint,
                geometry    geometry,
                name text
            )
AS
$$
SELECT
    -- etldoc: osm_office_point -> layer_office:z14_
    osm_id,
    geometry,
    name
FROM osm_office_point
WHERE zoom_level >= 14
  AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
