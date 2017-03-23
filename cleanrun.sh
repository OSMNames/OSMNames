docker-compose kill
docker-compose rm --force
docker system prune --force

docker-compose build
docker-compose run osmnames python -m cProfile -o cprofile.log run.py
