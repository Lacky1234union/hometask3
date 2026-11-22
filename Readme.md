запуск:

```bash
docker compose up -d --build --wait
```

 по умолчанию порт `8080`, приветствие `Hello, Docker!`. SQLite : `compose.sqlite.yaml`.

контейнер:

```bash
docker build -t ipr-hw3 .
docker run -d --name ipr-hw3-report \
  -p 127.0.0.1::8000 -e 'GREETING=Привет из Docker!' ipr-hw3
url="http://$(docker port ipr-hw3-report 8000/tcp)"
curl --retry 10 --retry-all-errors --retry-delay 1 --max-time 2 -fsS -w '\n' "$url/"
curl -fsS -w '\n' -X POST "$url/increment"
docker logs ipr-hw3-report
docker rm -f ipr-hw3-report
```

```text
{"greeting": "Привет из Docker!", "count": 0, "hostname": "58971e263534", "storage": "sqlite"}
{"greeting": "Привет из Docker!", "count": 1, "hostname": "58971e263534", "storage": "sqlite"}
2026-11-23 14:35:04,565 listening port=8000 storage=sqlite
2026-11-23 14:35:05,073 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-23 14:35:05,092 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -
```

SQLite:

```bash
HOST_PORT=8081 GREETING='Привет из Compose!' docker compose -p hw3-sqlite -f compose.sqlite.yaml up -d --build
curl --retry 10 --retry-all-errors --retry-delay 1 --max-time 2 -fsS -w '\n' http://127.0.0.1:8081/
curl -fsS -w '\n' -X POST http://127.0.0.1:8081/increment
docker compose -p hw3-sqlite -f compose.sqlite.yaml down
HOST_PORT=8081 GREETING='Привет из Compose!' docker compose -p hw3-sqlite -f compose.sqlite.yaml up -d
curl --retry 10 --retry-all-errors --retry-delay 1 --max-time 2 -fsS -w '\n' http://127.0.0.1:8081/
docker compose -p hw3-sqlite -f compose.sqlite.yaml down
```

```text
[+] Building 0.2s (12/12) FINISHED
 => [internal] load local bake definitions                                               0.0s
 => => reading from stdin 532B                                                           0.0s
 => [internal] load build definition from Dockerfile                                     0.0s
 => => transferring dockerfile: 337B                                                     0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                      0.0s
 => [internal] load .dockerignore                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => [1/5] FROM docker.io/library/python:3.13-slim                                        0.0s
 => [internal] load build context                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => CACHED [2/5] WORKDIR /app                                                            0.0s
 => CACHED [3/5] COPY app/requirements.txt .                                             0.0s
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt     && mkdir /data   0.0s
 => CACHED [5/5] COPY app/app.py .                                                       0.0s
 => exporting to image                                                                   0.0s
 => => exporting layers                                                                  0.0s
 => => writing image sha256:caec349263a13846482b5dab4f39841a7fba50bd8849b1a3ae70929bf8b  0.0s
 => => naming to docker.io/library/hw3-sqlite-app                                        0.0s
 => resolving provenance for metadata file                                               0.0s
[+] up 4/4
 ✔ Image hw3-sqlite-app          Built                                                    0.3s
 ✔ Volume hw3-sqlite_sqlite-data Created                                                  0.0s
 ✔ Network hw3-sqlite_default    Created                                                  0.1s
 ✔ Container hw3-sqlite-app-1    Started                                                  0.4s
curl: (56) Recv failure: Connection reset by peer
{"greeting": "Привет из Compose!", "count": 0, "hostname": "6debdece71cc", "storage": "sqlite"}
{"greeting": "Привет из Compose!", "count": 1, "hostname": "6debdece71cc", "storage": "sqlite"}
[+] down 2/2
 ✔ Container hw3-sqlite-app-1 Removed                                                    10.3s
 ✔ Network hw3-sqlite_default Removed                                                     0.1s
[+] up 2/2
 ✔ Network hw3-sqlite_default Created                                                     0.1s
 ✔ Container hw3-sqlite-app-1 Started                                                     0.4s
curl: (56) Recv failure: Connection reset by peer
{"greeting": "Привет из Compose!", "count": 1, "hostname": "e85271cd7170", "storage": "sqlite"}
[+] down 2/2
 ✔ Container hw3-sqlite-app-1 Removed                                                    10.3s
 ✔ Network hw3-sqlite_default Removed
```

запуск с Redis:

```bash
docker compose up -d --build
docker compose ps
```

```text
[+] Building 0.2s (12/12) FINISHED
 => [internal] load local bake definitions                                               0.0s
 => => reading from stdin 530B                                                           0.0s
 => [internal] load build definition from Dockerfile                                     0.0s
 => => transferring dockerfile: 337B                                                     0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                      0.0s
 => [internal] load .dockerignore                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => [1/5] FROM docker.io/library/python:3.13-slim                                        0.0s
 => [internal] load build context                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => CACHED [2/5] WORKDIR /app                                                            0.0s
 => CACHED [3/5] COPY app/requirements.txt .                                             0.0s
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt     && mkdir /data   0.0s
 => CACHED [5/5] COPY app/app.py .                                                       0.0s
 => exporting to image                                                                   0.0s
 => => exporting layers                                                                  0.0s
 => => writing image sha256:1bd415a96bf4f566c6efbbb8ff88f204c9031db84e68470641ea8374f91  0.0s
 => => naming to docker.io/library/hometask3-app                                         0.0s
 => resolving provenance for metadata file                                               0.0s
[+] up 5/5
 ✔ Image hometask3-app         Built                                                      0.3s
 ✔ Network hometask3_default   Created                                                    0.1s
 ✔ Volume hometask3_redis-data Created                                                    0.0s
 ✔ Container hometask3-redis-1 Healthy                                                    2.9s
 ✔ Container hometask3-app-1   Started

NAME                IMAGE              COMMAND                  SERVICE   CREATED          STATUS                    PORTS
hometask3-app-1     hometask3-app      "python app.py"          app       24 seconds ago   Up 21 seconds (healthy)   127.0.0.1:8080->8000/tcp
hometask3-redis-1   redis:7.4-alpine   "docker-entrypoint.s…"   redis     24 seconds ago   Up 24 seconds (healthy)   6379/tcp
```

Проверка Redis:

```bash
curl -sS http://127.0.0.1:8080/
printf '\n'
curl -sS -X POST http://127.0.0.1:8080/increment
printf '\n'
curl -sS http://127.0.0.1:8080/
printf '\n'
```

```text
{"greeting": "Hello, Docker!", "count": 0, "hostname": "f989aeaae2fd", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 1, "hostname": "f989aeaae2fd", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 1, "hostname": "f989aeaae2fd", "storage": "redis"}
```

Redis после пересоздания и остановки:

```bash
docker compose up -d --build --wait
url=http://127.0.0.1:8080

for i in 1 2 3; do
  curl -fsS -w '\n' -X POST "$url/increment"
done
curl -fsS -w '\n' "$url/"

docker compose down
docker compose up -d --wait
curl -fsS -w '\n' "$url/"

docker compose stop redis
curl -sS -w '\nHTTP %{http_code}\n' "$url/healthz"
curl -sS -w '\nHTTP %{http_code}\n' "$url/readyz"
curl -sS -w '\nHTTP %{http_code}\n' -X POST "$url/increment"

docker compose start redis
curl --retry 10 --retry-delay 1 --retry-max-time 30 --max-time 3 \
  -fsS -w '\nHTTP %{http_code}\n' "$url/readyz"
curl -fsS -w '\n' "$url/"
curl -fsS -w '\n' -X POST "$url/increment"
```

```text
[+] Building 0.2s (12/12) FINISHED
 => [internal] load local bake definitions                                               0.0s
 => => reading from stdin 530B                                                           0.0s
 => [internal] load build definition from Dockerfile                                     0.0s
 => => transferring dockerfile: 337B                                                     0.0s
 => [internal] load metadata for docker.io/library/python:3.13-slim                      0.0s
 => [internal] load .dockerignore                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => [1/5] FROM docker.io/library/python:3.13-slim                                        0.0s
 => [internal] load build context                                                        0.0s
 => => transferring context: 94B                                                         0.0s
 => CACHED [2/5] WORKDIR /app                                                            0.0s
 => CACHED [3/5] COPY app/requirements.txt .                                             0.0s
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt     && mkdir /data   0.0s
 => CACHED [5/5] COPY app/app.py .                                                       0.0s
 => exporting to image                                                                   0.0s
 => => exporting layers                                                                  0.0s
 => => writing image sha256:1bd415a96bf4f566c6efbbb8ff88f204c9031db84e68470641ea8374f91  0.0s
 => => naming to docker.io/library/hometask3-app                                         0.0s
 => resolving provenance for metadata file                                               0.0s
[+] up 3/3
 ✔ Image hometask3-app         Built                                                      0.3s
 ✔ Container hometask3-app-1   Healthy                                                    0.5s
 ✔ Container hometask3-redis-1 Healthy                                                    0.5s
{"greeting": "Hello, Docker!", "count": 2, "hostname": "f989aeaae2fd", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 3, "hostname": "f989aeaae2fd", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 4, "hostname": "f989aeaae2fd", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 4, "hostname": "f989aeaae2fd", "storage": "redis"}
[+] down 3/3
 ✔ Container hometask3-app-1   Removed                                                   10.3s
 ✔ Container hometask3-redis-1 Removed                                                    0.3s
 ✔ Network hometask3_default   Removed                                                    0.1s
[+] up 3/3
 ✔ Network hometask3_default   Created                                                    0.1s
 ✔ Container hometask3-redis-1 Healthy                                                    3.6s
 ✔ Container hometask3-app-1   Healthy                                                    6.0s
{"greeting": "Hello, Docker!", "count": 4, "hostname": "1368cc51aaaa", "storage": "redis"}
[+] stop 1/1
 ✔ Container hometask3-redis-1 Stopped                                                    0.2s
{"status": "alive"}
HTTP 200
{"error": "storage_unavailable"}
HTTP 503
{"error": "storage_unavailable"}
HTTP 503
[+] start 1/1
 ✔ Container hometask3-redis-1 Started                                                    0.2s
{"status": "ready", "storage": "redis"}
HTTP 200
{"greeting": "Hello, Docker!", "count": 4, "hostname": "1368cc51aaaa", "storage": "redis"}
{"greeting": "Hello, Docker!", "count": 5, "hostname": "1368cc51aaaa", "storage": "redis"}
```

Ограничения:

```bash
docker compose exec -T app id
docker inspect --format 'read_only={{.HostConfig.ReadonlyRootfs}} memory_bytes={{.HostConfig.Memory}} nano_cpus={{.HostConfig.NanoCpus}}' "$(docker compose ps -q app)"
```

```text
uid=10001 gid=10001 groups=10001
read_only=true memory_bytes=268435456 nano_cpus=1000000000
```

Проверка скриптом:

```bash
mkdir -p logs
./scripts/check.sh > logs/check-1.log 2>&1 &&
  ./scripts/check.sh > logs/check-2.log 2>&1
```
