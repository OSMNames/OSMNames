Import Wikipedia
================

To have an importance value for each feature, a wikipedia helper table is
downloaded from a Nominatim server. This is the same information Nominatim uses
to determine the importance. It was decided to take this pre-calculated data
instead of calculating it due to longer processing times (up to several days!).
Also, the same calculations are applied, to achieve the same results.
The initialization of the database is skipped, if it is already present.

The download and import of the wikipedia dump are skipped, if it is already
present. Since the dump was created with the username `brian`, a temporary user
is created to restore the dump, which is dropped after transferring the
ownership to the `osm` user.
