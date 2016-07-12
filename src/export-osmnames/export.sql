SELECT * FROM mv_polygons
UNION
SELECT * FROM mv_points
UNION
SELECT * FROM mv_linestrings
UNION
SELECT * FROM mv_merged_linestrings;