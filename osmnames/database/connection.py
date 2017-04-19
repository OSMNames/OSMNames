from osmnames import settings

from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import Session

engine = create_engine(
        "postgresql+psycopg2://{user}:{password}@{host}/{db_name}".format(
            user=settings.get("DB_USER"),
            password=settings.get("DB_PASSWORD"),
            host=settings.get("DB_HOST"),
            db_name=settings.get("DB_NAME"),
            )
        )


def session():
    return Session(engine)
