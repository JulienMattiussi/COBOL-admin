.PHONY: start stop test build

build:
	docker compose build

start:
	docker compose up -d

stop:
	docker compose down

test:
	docker compose build cobol

logs:
	docker compose logs -f
