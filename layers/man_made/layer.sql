-- etldoc: layer_man_made[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_man_made | <z12_> z12+" ] ;

CREATE OR REPLACE FUNCTION layer_man_made(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id      bigint,
                geometry    geometry,
                name text
            )
AS
$$
SELECT
    -- etldoc: osm_man_made_point -> layer_man_made:z12_
    osm_id,
    geometry,
    name
FROM osm_man_made_point
WHERE zoom_level >= 12
  AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
