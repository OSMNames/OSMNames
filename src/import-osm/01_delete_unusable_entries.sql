--cleanup unusable entries
DELETE FROM osm_polygon WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_point WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_linestring WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;