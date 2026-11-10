NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml

all: up

up:
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down -v

fclean:
	$(COMPOSE) down -v --rmi all

re:
	$(COMPOSE) down -v --rmi all
	$(COMPOSE) up -d --build

logs:
	$(COMPOSE) logs

ps:
	$(COMPOSE) ps

.PHONY: all up build down clean fclean re logs ps
