Processing
==========

After importing the OSM data with imposm3 the real processing begins. Each of the steps taken is described at this point




Delete unusable entries
-----------------------

Since the goal is to have names in the data set, each entry with an empty name in all imported languages is useless and therefore deleted. Instead of NULL values, imposm3 writes empty strings which has to be accounted for.

.. code-block:: sql

  DELETE FROM osm_polygon_tmp WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;

Additionally, since the export should be in TSV format, any entries containing tabs are deleted as well.

.. code-block:: sql

  UPDATE osm_polygon_tmp SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_fr =  regexp_replace(name_fr,'\t', ' ') WHERE name_fr LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_en =  regexp_replace(name_en,'\t', ' ') WHERE name_en LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_de =  regexp_replace(name_de,'\t', ' ') WHERE name_de LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_es =  regexp_replace(name_es,'\t', ' ') WHERE name_es LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_ru =  regexp_replace(name_ru,'\t', ' ') WHERE name_ru LIKE '%'||chr(9)||'%';
  UPDATE osm_polygon_tmp SET name_zh =  regexp_replace(name_zh,'\t', ' ') WHERE name_zh LIKE '%'||chr(9)||'%';

  Note that this extract shows the empty name and tab removal only for one table.





Ranking & Partitioning
----------------------

For every geometry type a new table is created since this is far more effective than altering the old tables and updating every single row. Additionally, the according rank and partition are calculated.

.. code-block:: sql

 CREATE TABLE osm_polygon AS
 (SELECT     
      id,
      osm_id,
      type,
      country_code,
      name,
      name_fr,
      name_en,
      name_de,
      name_es,
      name_ru,
      name_zh,
      wikipedia,
      wikidata,
      admin_level,
      geometry,
      rpc.place_rank AS place_rank,
      rpc.partition AS partition,
      rpc.calculated_country_code AS calculated_country_code,
      NULL::bigint AS parent_id,
      NULL::bigint AS linked_osm_id
  FROM
      osm_polygon_tmp p,
      determineRankPartitionCode(type, geometry, osm_id, country_code) AS rpc
  );

Pivotal to this process is the ranking for places and addresses as follows:

.. code-block:: sql

  CREATE OR REPLACE FUNCTION rank_place(type TEXT, osmID bigint)
  RETURNS int AS $$
  BEGIN
	RETURN CASE
		WHEN type IN ('administrative') THEN 2*(SELECT COALESCE(admin_level,15) FROM osm_polygon_tmp o WHERE osm_id = osmID)  
		WHEN type IN ('continent', 'sea') THEN 2
		WHEN type IN ('country') THEN 4
		WHEN type IN ('state') THEN 8
		WHEN type IN ('county') THEN 12
		WHEN type IN ('city') THEN 16
		WHEN type IN ('island') THEN 17
		WHEN type IN ('region') THEN 18 -- dropped from previous value of 10
		WHEN type IN ('town') THEN 18
		WHEN type IN ('village','hamlet','municipality','district','unincorporated_area','borough') THEN 19
		WHEN type IN ('suburb','croft','subdivision','isolated_dwelling','farm','locality','islet','mountain_pass') THEN 20
		WHEN type IN ('neighbourhood', 'residential') THEN 22
		WHEN type IN ('houses') THEN 28
		WHEN type IN ('house','building') THEN 30
		WHEN type IN ('quarter') THEN 30
	END;
  END;
  $$ LANGUAGE plpgsql IMMUTABLE;


  CREATE OR REPLACE FUNCTION rank_address(type TEXT)
  RETURNS int AS $$
  BEGIN
	RETURN CASE
		WHEN type IN ('service','cycleway','path','footway','steps','bridleway','motorway_link','primary_link','trunk_link','secondary_link','tertiary_link') THEN 27
		ELSE 26
	END;
  END;
  $$ LANGUAGE plpgsql IMMUTABLE;

Note that these value mappings are the same as in Nominatim. If not available, the country code is calculated along with its partition code (unique integer value for each country) with the help of the pre-initialized table *country_osm_grid*.

.. code-block:: sql

	CREATE OR REPLACE FUNCTION get_country_code(place geometry) RETURNS TEXT
	  AS $$
	DECLARE
	  place_centre GEOMETRY;
	  nearcountry RECORD;
	BEGIN
	  place_centre := ST_PointOnSurface(place);

	  FOR nearcountry IN select country_code from country_osm_grid where st_covers(geometry, place_centre) order by area asc limit 1
	  LOOP
	    RETURN nearcountry.country_code;
	  END LOOP;

	  FOR nearcountry IN select country_code from country_osm_grid where st_dwithin(geometry, place_centre, 0.5) order by st_distance(geometry, place_centre) asc, area asc limit 1
	  LOOP
	    RETURN nearcountry.country_code;
	  END LOOP;

	  RETURN NULL;
	END;
	$$
	LANGUAGE plpgsql IMMUTABLE;

The pre-initialized table country_osm_grid is used to determine the partition of a feature. However, as there are quite some features that could not be classified, a different method has been developed. The key is to work with the now imported countries (having a rank of 4). 

.. code-block:: sql

	CREATE OR REPLACE FUNCTION determinePartitionFromImportedData(geom geometry)
	RETURNS INTEGER AS $$
	DECLARE
	  result INTEGER;
	BEGIN
	  SELECT partition, calculated_country_code from osm_polygon where ST_Within(ST_PointOnSurface(geom), geometry) AND place_rank = 4 AND NOT partition = 0 INTO result;
	    RETURN result;
	END;
	$$ LANGUAGE plpgsql;


Determine linked places
-----------------------

In order to determine linked places (points linked with polygons) additional tags about the relations are imported. Specifically, the role values admin_centre and label are of interest.

.. code-block:: sql

	UPDATE osm_polygon p
	SET linked_osm_id = r.member         
	FROM osm_relation r                                     
	WHERE 
	r.type = 0 AND (r.role = 'admin_centre' OR r.role = 'admin_center')
	AND p.name = r.name
	AND p.osm_id = r.osm_id
	AND p.linked_osm_id IS NULL;

This information is later on used in the export mainly to rule out point features linked to their polygon features as well as determining city types instead of administrative types.




Create Hierarchy
----------------

In order to create the *display_name*, the parent feature of every feature is determined with the following function:

.. code-block:: sql

	CREATE OR REPLACE FUNCTION determineParentPlace(id_value BIGINT, partition_value INT, place_rank_value INT, geometry_value GEOMETRY) RETURNS BIGINT AS $$
	DECLARE
	  retVal BIGINT;
	BEGIN
	  FOR current_rank  IN REVERSE place_rank_value..1 LOOP
	     SELECT id FROM osm_polygon WHERE partition=partition_value AND place_rank = current_rank AND NOT id=id_value AND ST_Contains(geometry, geometry_value) AND NOT ST_Equals(geometry, geometry_value) INTO retVal;
	     IF retVal IS NOT NULL THEN
	      return retVal;
	    END IF;
	  END LOOP;
	RETURN retVal;
	END;
	$$ LANGUAGE plpgsql;

With the reverse loop it is ensured to match only features with the same or a lower rank. Also, by checking geometry equality it is ensured that no infinite loop emerge (parent of feature A is feature B whose parent is feature A). This phenomenon was identified with European OSM data where geometry duplicates with different ids exist. Finally, only features with the same partition are considered.

Finding Parent of Street segments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For every partition (country), all street segments that are contained in features having a rank of 22 or lower are determined and updated accordingly. 22 (neighborhood, residential) is the highest rank of features that can contain street segments. This way it is ensured, that the parent has the highest rank possible when a feature is contained in two parent features with different ranks.

.. code-block:: sql

	CREATE OR REPLACE FUNCTION findRoadsWithinGeometry(id_value BIGINT,partition_value INT, geometry_value GEOMETRY) RETURNS VOID AS $$
	BEGIN
		UPDATE osm_linestring SET parent_id = id_value WHERE parent_id IS NULL AND ST_Contains(geometry_value,geometry);
	END;
	$$ LANGUAGE plpgsql;

	CREATE OR REPLACE FUNCTION determineRoadHierarchyForEachCountry() RETURNS void AS $$
	DECLARE
	  retVal BIGINT;
	BEGIN
	  FOR current_partition  IN 1..255 LOOP
	    FOR current_rank  IN REVERSE 22..4 LOOP
	       PERFORM findRoadsWithinGeometry(id, current_partition, geometry) FROM osm_polygon WHERE partition = current_partition AND place_rank = current_rank;
	    END LOOP;
	  END LOOP;
	END;
	$$ LANGUAGE plpgsql;



Merge corresponding street segments
-----------------------------------

In order to merge streets segments that belong together, a new table osm_merged_multi_linestring is created. The ids are being aggregated into an array, the type into a comma separated string. Linestrings are merged to a multi-linestring when they have at least one point in common.

.. code-block:: sql

	CREATE TABLE osm_merged_multi_linestring AS 
	 	SELECT array_agg(DISTINCT a.id) AS member_ids,
	 	string_agg(DISTINCT a.type,',') AS type,
	 	a.name, max(a.name_fr) AS name_fr,
	 	max(a.name_en) AS name_en,
	 	max(a.name_de) AS name_de,
	 	max(a.name_es) AS name_es,
	 	max(a.name_ru) AS name_ru,
	 	max(a.name_zh) AS name_zh,
	 	max(a.wikipedia) AS wikipedia,
	 	max(a.wikidata) AS wikidata,
	 	ST_UNION(array_agg(ST_MakeValid(a.geometry))) AS geometry,
	 	bit_and(a.partition) AS partition,
	 	max(a.calculated_country_code) AS calculated_country_code,
	 	min(a.place_rank) AS place_rank,
	 	a.parent_id 
		FROM
			osm_linestring AS a,
			osm_linestring AS b
		WHERE 
			ST_Touches(ST_MakeValid(a.geometry), ST_MakeValid(b.geometry)) AND 
			a.parent_id = b.parent_id AND 
			a.parent_id IS  NOT NULL AND 
			a.name = b.name AND 
			a.id!=b.id
		GROUP BY 
			a.parent_id,
			a.name;

Note that before merging, invalid geometries are attempted to be made valid without loosing vertices.