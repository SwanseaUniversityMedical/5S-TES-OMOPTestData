cd Synthea-Docker

docker build -t syntheadata:1.0 .

docker run -v ./output:/synthea/output -it syntheadata:1.0 -p 10000

cd ..
cd Synthea-Loader-Docker

docker compose down -v

docker compose up -d

