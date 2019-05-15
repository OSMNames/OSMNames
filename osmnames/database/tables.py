import lazy_property

from sqlalchemy.ext.automap import automap_base
from sqlalchemy import MetaData, Table, Column, Integer

from osmnames.database.connection import engine


def tables():
    return Tables(engine)


class Tables:
    def __init__(self, engine):
        metadata = MetaData(engine)

        self._define_tables_without_primary_keys(metadata)

        self.base = automap_base(metadata=metadata)
        self.base.prepare(engine, reflect=True)

    @lazy_property.LazyProperty
    def osm_point(self):
        return getattr(self.base.classes, 'osm_point')

    @lazy_property.LazyProperty
    def osm_housenumber(self):
        return getattr(self.base.classes, 'osm_housenumber')

    @lazy_property.LazyProperty
    def osm_linestring(self):
        return getattr(self.base.classes, 'osm_linestring')

    @lazy_property.LazyProperty
    def osm_merged_linestring(self):
        return getattr(self.base.classes, 'osm_merged_linestring')

    @lazy_property.LazyProperty
    def osm_relation(self):
        return getattr(self.base.classes, 'osm_relation')

    @lazy_property.LazyProperty
    def osm_relation_member(self):
        return getattr(self.base.classes, 'osm_relation_member')

    @lazy_property.LazyProperty
    def osm_polygon_tmp(self):
        return getattr(self.base.classes, 'osm_polygon_tmp')

    @lazy_property.LazyProperty
    def osm_polygon(self):
        return getattr(self.base.classes, 'osm_polygon')

    @lazy_property.LazyProperty
    def osm_linestring_tmp(self):
        return getattr(self.base.classes, 'osm_linestring_tmp')

    @lazy_property.LazyProperty
    def osm_point_tmp(self):
        return getattr(self.base.classes, 'osm_point_tmp')

    @lazy_property.LazyProperty
    def wikipedia_article(self):
        return getattr(self.base.classes, 'wikipedia_article')

    @lazy_property.LazyProperty
    def wikipedia_redirect(self):
        return getattr(self.base.classes, 'wikipedia_redirect')

    @lazy_property.LazyProperty
    def country_name(self):
        return getattr(self.base.classes, 'country_name')

    @lazy_property.LazyProperty
    def country_osm_grid(self):
        return getattr(self.base.classes, 'country_osm_grid')

    @lazy_property.LazyProperty
    def admin_level_type_mapping(self):
        return getattr(self.base.classes, 'admin_level_type_mapping')

    @lazy_property.LazyProperty
    def parent_polygons(self):
        return getattr(self.base.classes, 'parent_polygons')

    def _define_tables_without_primary_keys(self, metadata):
        # sqlalchemys automap only works with primary keys, even though country_code is not unique in production
        Table('country_osm_grid', metadata, Column('country_code', Integer, primary_key=True))
        Table('parent_polygons', metadata, Column('id', Integer, primary_key=True))
