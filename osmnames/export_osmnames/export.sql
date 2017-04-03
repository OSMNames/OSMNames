SELECT * FROM mv_polygons
UNION ALL
SELECT * FROM mv_points
UNION ALL
SELECT * FROM mv_linestrings
UNION ALL
SELECT * FROM mv_merged_linestrings;