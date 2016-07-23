----------------
-- LISTING 1
----------------
ALTER TABLE vector_data.road DROP COLUMN numberofla;
ALTER TABLE vector_data.road DROP COLUMN pavementty;
ALTER TABLE vector_data.road DROP COLUMN island;
ALTER TABLE vector_data.road DROP COLUMN cost_fp;
ALTER TABLE vector_data.road DROP COLUMN reverse_01;

----------------
-- LISTING 2
----------------
ALTER TABLE vector_data.road RENAME COLUMN reverse_co TO reverse_cost;

----------------
-- LISTING 3
----------------
ALTER TABLE vector_data.road ALTER direction TYPE int4;
ALTER TABLE vector_data.road ALTER category TYPE int4;
ALTER TABLE vector_data.road ALTER speedlimit TYPE int4;
ALTER TABLE vector_data.road ALTER condition TYPE int4;
ALTER TABLE vector_data.road ALTER source TYPE int4;
ALTER TABLE vector_data.road ALTER target TYPE int4;

----------------
-- LISTING 4
----------------
DELETE FROM vector_data.road;

----------------
-- LISTING 5
----------------
CREATE EXTENSION pgrouting;

----------------
-- LISTING 6
----------------
UPDATE vector_data.road SET source = NULL, target = NULL;

----------------
-- LISTING 7
----------------
SELECT pgr_createTopology('vector_data.road', 0.1, 'geometry', 'gid');

----------------
-- LISTING 8
----------------
UPDATE vector_data.road SET cost = ((ST_Length(geometry)/1000)/speedlimit)*60;
UPDATE vector_data.road SET reverse_cost = cost;
UPDATE vector_data.road SET reverse_cost = -1 WHERE direction = 1;

----------------
-- LISTING 9
----------------
GRANT SELECT ON vector_data.road_vertices_pgr TO gis_update, gis_view;

----------------
-- LISTING 10
----------------
SELECT * FROM pgr_bddijkstra('SELECT gid::int4 AS id, source::int4, target::int4, cost::float8, reverse_cost::float8 FROM vector_data.road', 281, 500, true, true);

----------------
-- LISTING 11
----------------
CREATE OR REPLACE VIEW shortest_path AS
SELECT * FROM vector_data.road WHERE gid IN
(SELECT id2 FROM pgr_bddijkstra('SELECT gid::int4 AS id, source::int4, target::int4, cost::float8, reverse_cost::float8 FROM vector_data.road', 281, 500, true, true));

----------------
-- LISTING 12
----------------
CREATE TABLE combined_driving_times AS
SELECT
    id,
    the_geom,
    (select sum(cost) FROM
    (
    SELECT * FROM pgr_bddijkstra('SELECT gid::int4 as id, source::int4, target::int4, cost::float8, reverse_cost::float8 FROM vector_data.road', 11127, id::int4, TRUE, TRUE)) as foo) AS cost
    FROM vector_data.road_vertices_pgr
UNION
SELECT
    id,
    the_geom,
    (select sum(cost) FROM
    (
    SELECT * FROM pgr_bddijkstra('SELECT gid::int4 as id, source::int4, target::int4, cost::float8, reverse_cost::float8 FROM vector_data.road', 11292, id::int4, TRUE, TRUE)) as foo) AS cost
    FROM vector_data.road_vertices_pgr;

----------------
-- LISTING 13
----------------
CREATE table min_driving_times AS
SELECT id, the_geom, min(cost) AS cost
FROM combined_driving_times
GROUP BY id, the_geom;
