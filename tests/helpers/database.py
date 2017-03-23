from sqlalchemy.ext.automap import automap_base


def table_class_for(table, engine):
    base = automap_base()
    base.prepare(engine, reflect=True)
    return getattr(base.classes, table)
