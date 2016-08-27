Export Data Format
==================

The requirement to the export data format is being simple to use. The decision led to using an UTF-8 encoded TSV like with Geonames, where the first line contains the column names. Compared to a CSV name are now allowed to have usual delimiters such as commas or semicolons. Best practices from `GISGraphy <http://download.gisgraphy.com/format.txt>`_  have been adapted. The definition looks as follows:

=================	====================================================================================================================================
Column name 		Description
=================	====================================================================================================================================
name 				The name of the feature (default language is en, others available are de, es, fr, ru, zh)
alternative_names	All other available and distinct names separated by commas
osm_type 			The OSM type of the feature (node, way, relation)
osm_id 				The unique osm_id for debug purposes
class 				The class of the feature e.g. boundary
type 				The type of the feature e.g. administrative
lon 				The decimal degrees (WGS84) longitude of the centroid of the feature
lat 				The decimal degrees (WGS84) latitude of the centroid of the feature
place_rank 			Rank from 1-30 ascending, 1 being the highest. Calculated with the type and class of the feature.
importance 			Importance of the feature, ranging [0.0-1.0], 1.0 being the most important. Calculated with wikipedia information or the place_rank.
street 				The name of the street if the feature is some kind of street
city 				The name of the city of the feature, if it has one
county 				The name of the county of the feature, if it has one
state 				The name of the state of the feature, it it has one
country 			The name of the country of the feature
country_code 		The ISO-3166 2-letter country code of the feature
display_name 		The display name of the feature representing the hierarchy, if available in English
west 				The western decimal degrees (WGS84) longitude of the bounding box of the feature
south 				The southern decimal degrees (WGS84) latitude of the bounding box of the feature
east 				The eastern decimal degrees (WGS84) longitude of the bounding box of the feature
north 				The northern decimal degrees (WGS84) latitude of the bounding box of the feature
wikidata 			The wikidata associated with the feature
wikipedia 			The wikipedia URL associated with the feature
=================	====================================================================================================================================