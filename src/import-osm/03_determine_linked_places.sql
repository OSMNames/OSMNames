--determine linked places
-- places with admin_centre tag
UPDATE osm_polygon p
	SET linked_osm_id = r.member         
	FROM osm_relation r                                     
	WHERE 
	r.type = 0 AND r.role = 'admin_centre' 
	AND p.osm_id = r.osm_id;    

-- places with label tag inside geometry
UPDATE osm_polygon p
	SET linked_osm_id = n.osm_id 
	FROM osm_point  n, osm_polygon r WHERE n.name = r.name AND ST_WITHIN(n.geometry,r.geometry)
	AND p.osm_id = r.osm_id      
	AND r.osm_id NOT IN (
	SELECT osm_id 
	FROM osm_relation
	WHERE role = 'label');  

--tag linked places
UPDATE osm_point p SET linked = TRUE
	FROM osm_point po WHERE po.osm_id IN (SELECT linked_osm_id FROM osm_polygon WHERE linked_osm_id IS NOT NULL)
	AND po.osm_id = p.osm_id;