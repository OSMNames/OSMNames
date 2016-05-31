DO
$body$
BEGIN
   IF NOT EXISTS (
      SELECT *
      FROM   pg_catalog.pg_user
      WHERE  usename = 'brian') THEN

      CREATE ROLE brian LOGIN PASSWORD 'brian';
      GRANT ALL PRIVILEGES ON DATABASE osm to brian;
   END IF;
   DROP TABLE IF EXISTS wikipedia_article;
END
$body$;