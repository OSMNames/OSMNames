Export
======

The data for the TSV is extracted with the help of the pgclimb tool which takes an SQL file as an argument [7]. The results of the SELECT statements for each geometry table are then combined with UNION ALL. The resulting TSV is then being gzipped. The hierarchy for each feature is extracted with the following custom type and function:

.. code-block:: sql

	CREATE TYPE parentInfo AS (
	    state           TEXT,
	    county          TEXT,
	    city 			TEXT,
	    displayName		TEXT
	);

	CREATE OR REPLACE FUNCTION getParentInfo(name_value TEXT, id_value BIGINT, from_rank INTEGER, delimiter character varying(2)) RETURNS parentInfo AS $$
	DECLARE
	  retVal parentInfo;
	  current_rank INTEGER;
	  current_id BIGINT;
	  currentName TEXT;
	BEGIN
	  current_rank := from_rank;
	  retVal.displayName := name_value;
	  current_id := id_value;

	  IF current_rank = 16 THEN
	    retVal.city := retVal.displayName;
	  ELSE
	    retVal.city := '';
	  END IF;
	  IF current_rank = 12 THEN
	    retVal.county := retVal.displayName;
	  ELSE
	    retVal.county := '';
	  END IF;
	  IF current_rank = 8 THEN
	    retVal.state := retVal.displayName;
	  ELSE
	    retVal.state := '';
	  END IF;

	  --RAISE NOTICE 'finding parent for % with rank %', name_value, from_rank;

	  WHILE current_rank >= 8 LOOP
	    SELECT getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh), rank_search, parent_id FROM osm_polygon  WHERE id = current_id INTO currentName, current_rank, current_id;
	    IF currentName IS NOT NULL THEN
	      retVal.displayName := retVal.displayName || delimiter || ' ' || currentName;
	    END IF;

	    IF current_rank = 16 THEN
	      retVal.city := currentName;
	    END IF;
	    IF current_rank = 12 THEN
	      retVal.county := currentName;
	    END IF;
	    IF current_rank = 8 THEN
	      retVal.state := currentName;
	    END IF;
	  END LOOP;
	RETURN retVal;
	END;
	$$ LANGUAGE plpgsql;


First, it checks if the feature itself has a rank of 16,12 or 8 (city, county, state). Then it determines the name of the parent, appends it to the display_name and checks if the parent itself is a city, county or state and so on. The parent_ids of the countries are always NULL and therefore the loop always terminates.



Language Precedence
-------------------
Because the names are imported in seven different languages, there needs to be a unique way of weighing which language is more relevant in the exported data. This happens in the following function with the precedence [English -> native name -> French -> German -> Spanish -> Russian -> Chinese]:

.. code-block:: sql

	CREATE OR REPLACE FUNCTION getLanguageName(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT)
	RETURNS TEXT AS $$
	BEGIN
	  RETURN CASE
	    WHEN en NOT IN ('') THEN en
	    WHEN default_lang NOT IN ('') THEN default_lang
	    WHEN fr NOT IN ('') THEN fr
	    WHEN de NOT IN ('') THEN de
	    WHEN es NOT IN ('') THEN es
	    WHEN ru NOT IN ('') THEN ru
	    WHEN zh NOT IN ('') THEN zh
	    ELSE ''
	  END;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE;

Of course, this behavior can be interchanged.



Alternative Names
-----------------
It is a requirement to have also the names in the export that weren’t used in the name field in the export. This way a geocoder can index these fields as well and find for instance native names as well.

.. code-block:: sql

	CREATE OR REPLACE FUNCTION getAlternativesNames(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT, name TEXT, delimiter character varying)
	RETURNS TEXT AS $$
	DECLARE
	  alternativeNames TEXT[];
	BEGIN
	  alternativeNames := array_distinct(ARRAY[default_lang, en, fr, de, es, ru, zh]);
	  alternativeNames := array_remove(alternativeNames, '');
	  alternativeNames := array_remove(alternativeNames, name);
	RETURN array_to_string(alternativeNames,delimiter);
	END;
	$$ LANGUAGE plpgsql IMMUTABLE;

The name parameter is the value used in the name field, so it is excluded as well as empty name fields. Also, it is ensured that the names in the result are distinct.



Country Names
-------------
Country names are exported from the pre-initialized helper table country_name. This happens with the same language precedence as defined in *getLanguageName*.

.. code-block:: sql

	CREATE OR REPLACE FUNCTION countryName(partition_id int) returns TEXT as $$
	  SELECT COALESCE(name -> 'name:en',name -> 'name',name -> 'name:fr',name -> 'name:de',name -> 'name:es',name -> 'name:ru',name -> 'name:zh') FROM country_name WHERE partition = partition_id;
	$$ language 'sql';



Wikipedia Import & Importance
-----------------------------
In order to have an importance value for each feature, a wikipedia helper table is being downloaded from a Nominatim server. This is the same information Nominatim uses to determine the importance. It was decided to take this pre-calculated data instead of calculating it itself due to longer processing times (up to several days!). Also, the same calculations are applied, in order to achieve the same results.

If a feature has a wikipedia URL a matching entry in the wikipedia helper table is taken for calculating the importance with the following formula:

.. code-block:: bash

	importance = log (totalcount) / log( max(totalcount))

where totalcount is the number of references to the article from other wikipedia articles. In case there is no wikipedia information or no match was found, the following formula is applied:

.. code-block:: bash

	importance = 0.75 - (rank/40)

Since every feature has a rank, it is ensured that every feature also has an importance.

The function *get_importance* for calculating the importance is called during the export.

Type of relations
-----------------------------

In order to tackle the problem of relations often being administrative although being linked to 'city' nodes the following function has been developed:

.. code-block:: sql

	CREATE OR REPLACE FUNCTION getTypeForRelations(linked_osm_id BIGINT, type_value TEXT, rank_search INTEGER) returns TEXT as $$
	DECLARE
	  retVal TEXT;
	BEGIN
	IF linked_osm_id IS NOT NULL AND type_value = 'administrative' AND (rank_search = 16 OR rank_search = 12) THEN
	  SELECT type FROM osm_point WHERE osm_id = linked_osm_id INTO retVal;
	  IF retVal = 'city' THEN
	  RETURN retVal;
	  ELSE
	  RETURN type_value;
	  END IF;
	ELSE
	  return type_value;
	 END IF;
	END;
	$$ LANGUAGE plpgsql IMMUTABLE;
