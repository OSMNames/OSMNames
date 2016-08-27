Imposm Mapping
==============

Currently the features matching following key/values are imported by imposm3:


* place
	* city
	* borough
	* suburb
	* quarter
	* neighbourhood
	* town
	* village
	* hamlet 
* landuse
	* residential
* boundary
	* administrative
* highway
	* motorway
	* motorway_link
	* trunk
	* trunk_link
	* primary
	* primary_link
	* secondary
	* secondary_link
	* tertiary
	* tertiary_link
	* unclassified
	* residential
	* road
	* living_street
	* raceway
	* construction
	* track
	* service
	* path
	* cycleway
	* steps
	* bridleway
	* footway
	* corridor
	* crossing

The following fiels are then incorporated into OSMNames:


=================	========  ============================================================================
Column name 		Type	  Description
=================	========  ============================================================================
id 			Integer   the osm id (negative for relations)
geometry 		geometry  polygon, point or linestring
type 			String 	  the mapping value from the table above
name 			String 	  the name used locally
name_en 		String    English (if available)
name_de 		String 	  German (if available)
name_fr 		String 	  French (if available)
name_es 		String 	  Spanish (if available)
name_ru 		String 	  Russian (if available)
name_zh 		String 	  Chinese (if available)
wikipedia 		String 	  wikipedia link
wikidata 		String 	  wikidata Hash
admin_level 		Integer   originally used for differentiate border rendering, now used for ranking
ISO3166-1:alpha2 	String 	  the ISO 3166 2-letter country code
member_id 		Integer   the id of the member
member_role 		String 	  the role of the member
member_type 		String 	  the type of the member
=================	========  ============================================================================
