#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
mkdir -p backups
backup_dir=$(mktemp -d backups/check-XXXXXXXX)
project="hw3-$(basename "$backup_dir" | tr '[:upper:]' '[:lower:]')"
backup="$backup_dir/redis.tar"
export HOST_PORT=0
stage='запуск'

compose() {
    docker compose -f compose.yaml -p "$project" "$@"
}

cleanup() {
    result=$?
    trap - EXIT
    if [ "$result" -ne 0 ]; then
        printf 'Ошибка на этапе «%s» (код %s)\n' "$stage" "$result" >&2
        compose ps -a >&2 || :
        compose logs --tail 20 >&2 || :
        rm -f "$backup.partial"
    fi
    if ! compose down -v; then
        printf 'Не удалось очистить проект %s\n' "$project" >&2
        exit 1
    fi
    exit "$result"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

start() {
    compose up -d --wait --wait-timeout 60 "$@"
    address=$(compose port app 8000)
    base_url="http://$address"
}

expect_count() {
    expected=$1
    method=$2
    path=$3
    body=$(curl --noproxy '*' --max-time 5 -fsS -X "$method" "$base_url$path")
    compose exec -T app python -c '
import json
import sys

body = json.loads(sys.argv[1])
expected = int(sys.argv[2])
if body["count"] != expected or body["storage"] != "redis":
    sys.exit(f"Ожидалось count={expected} и storage=redis, получено {body}")
' "$body" "$expected"
    printf '%s %s → %s\n' "$method" "$path" "$body"
}

expect_status() {
    expected=$1
    method=$2
    path=$3
    actual=$(curl --noproxy '*' --max-time 5 -sS -o /dev/null -w '%{http_code}' -X "$method" "$base_url$path")
    printf '%s %s → HTTP %s (ожидалось %s)\n' "$method" "$path" "$actual" "$expected"
    [ "$actual" = "$expected" ]
}

stage='проверка счётчика'
printf '\nПроект %s\n' "$project"
start --build
expect_count 0 GET /
for count in 1 2 3; do
    expect_count "$count" POST /increment
done
expect_count 3 GET /

stage='пересоздание app'
redis_id=$(compose ps -q redis)
app_id=$(compose ps -q app)
start --no-deps --force-recreate app
[ "$(compose ps -q redis)" = "$redis_id" ]
[ "$(compose ps -q app)" != "$app_id" ]
expect_count 3 GET /

stage='перезапуск проекта'
compose down
start
expect_count 3 GET /

stage='остановка и запуск Redis'
app_id=$(compose ps -q app)
compose stop redis
expect_status 200 GET /healthz
expect_status 503 GET /readyz
expect_status 503 POST /increment
compose start redis
attempt=0
until curl --noproxy '*' --max-time 2 -fsS "$base_url/readyz" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    [ "$attempt" -lt 15 ]
    sleep 1
done
[ "$(compose ps -q app)" = "$app_id" ]
expect_count 3 GET /
expect_count 4 POST /increment

stage='копирование данных Redis'
# Сначала останавливаем app, чтобы во время копирования не было запросов.
compose stop app
compose stop redis
compose run --rm --no-deps -T --user 0 --entrypoint tar redis -C /data -cpf - . > "$backup.partial"
mv "$backup.partial" "$backup"
printf 'Архив: %s\n' "$backup"
compose down -v

stage='восстановление из архива'
compose run --rm --no-deps -T --user 0 --entrypoint tar redis -C /data -xpf - < "$backup"
start
expect_count 4 GET /
expect_count 5 POST /increment

stage='удаление тестового проекта'
compose down -v
trap - EXIT
printf 'Все проверки пройдены. Архив: %s\n' "$backup"
