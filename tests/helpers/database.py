import lazy_property

from sqlalchemy.ext.automap import automap_base


class Tables:
    def __init__(self, engine):
        self.base = automap_base()
        self.base.prepare(engine, reflect=True)

    @lazy_property.LazyProperty
    def osm_housenumber(self):
        return getattr(self.base.classes, 'osm_housenumber')

    @lazy_property.LazyProperty
    def osm_linestring(self):
        return getattr(self.base.classes, 'osm_linestring')

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
