default: help

env ?= local

cnf ?= $(PWD)/deployment/config/$(env)/.env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))


DEPLOYMENT_DIR 						:= deployment
DEPLOYMENT_CONFIG_DIR 				:= $(DEPLOYMENT_DIR)/config
DEPLOYMENT_DOCKER_COMPOSE 			:= $(DEPLOYMENT_DIR)/docker-compose.yml
DEPLOYMENT_DOCKER_COMPOSE_OVERRIDE 	:= $(DEPLOYMENT_DIR)/docker-compose.$(BUILD_ENV).yml


BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
WHITE        := $(shell tput -Txterm setaf 7)

RESET := $(shell tput -Txterm sgr0)


# set target color
TARGET_COLOR := $(BLUE)

colors: ## - Show all the colors
	@echo "${BLACK}BLACK${RESET}"
	@echo "${RED}RED${RESET}"
	@echo "${GREEN}GREEN${RESET}"
	@echo "${YELLOW}YELLOW${RESET}"
	@echo "${LIGHTPURPLE}LIGHTPURPLE${RESET}"
	@echo "${PURPLE}PURPLE${RESET}"
	@echo "${BLUE}BLUE${RESET}"
	@echo "${WHITE}WHITE${RESET}"


.PHONY: help
help: ## - Show help message
	@printf "${TARGET_COLOR} usage: make [target]\n${RESET}"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s${RESET} %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error ${RED} $1$(if $2, ($2)) is required ${RESET}))

$(info ${YELLOW}Deployment Information${RESET})
$(info ${GREEN}- DEPLOYMENT_DIR                     : $(DEPLOYMENT_DIR) ${RESET})
$(info ${GREEN}- DEPLOYMENT_CONFIG_DIR              : $(DEPLOYMENT_CONFIG_DIR) ${RESET})
$(info ${GREEN}- DEPLOYMENT_DOCKER_COMPOSE          : $(DEPLOYMENT_DOCKER_COMPOSE) ${RESET})
$(info ${GREEN}- DEPLOYMENT_DOCKER_COMPOSE_OVERRIDE : $(DEPLOYMENT_DOCKER_COMPOSE_OVERRIDE) ${RESET})

#======================= Commands =======================#

# Docs
doc: api-doc consumer-doc chat-doc marketplace-doc tpl-doc ## - Generate docs

# Docs
api-doc: ## - Generate docs
	@echo "${TARGET_COLOR} Generating api docs... !${RESET}"
	swag init -g ./cmd/backend/main.go -o ./services/backend/docs --exclude="services/chat,services/marketplace,services/tpl,services/consumer"

consumer-doc: ## - Generate chat docs
	@echo "${TARGET_COLOR} Generating consumer docs... !${RESET}"
	@swag init -g ./cmd/consumer/main.go  -o ./services/consumer/docs --exclude="services/backend,services/marketplace,services/tpl,services/chat"

chat-doc: ## - Generate chat docs
	@echo "${TARGET_COLOR} Generating chat docs... !${RESET}"
	@swag init -g ./cmd/chat/main.go  -o ./services/chat/docs --exclude="services/backend,services/marketplace,services/tpl,services/consumer"

marketplace-doc: ## - Generate marketplace docs
	@echo "${TARGET_COLOR} Generating marketplace api docs... !${RESET}"
	@swag init -g ./cmd/marketplace/main.go  -o ./services/marketplace/docs --exclude="services/chat,services/backend,services/tpl,services/consumer"

tpl-doc: ## - Generate tpl docs
	@echo "${TARGET_COLOR} Generating tpl api docs... !${RESET}"
	@swag init -g ./cmd/tpl/main.go  -o ./services/tpl/docs --exclude="services/chat,services/marketplace,services/backend,services/consumer"


lint: ## - Linter
	@echo "${TARGET_COLOR} Lint code !${RESET}" ;\
	go vet ./...

dc: ## - Run docker-compose with default config (Example: make dc env=local args="up")
	@echo "${TARGET_COLOR} Start dc !${RESET}" ;\
	chmod 600 ${DEPLOYMENT_CONFIG_DIR}/acme.json ;\
	docker network create ${DEFAULT_NETWORK} || true ;\
	docker-compose -p ${APP_NAME}_${BUILD_ENV} --env-file=${cnf} -f ${DEPLOYMENT_DOCKER_COMPOSE} -f ${DEPLOYMENT_DOCKER_COMPOSE_OVERRIDE} $(args);\
	sleep 10;\
	make clean ;\
	echo "${TARGET_COLOR} End dc !${RESET}"


clean: ## - Clean docker resources
	@echo "${TARGET_COLOR} Cleaning docker resources ...${RESET}";\
	docker container prune -f ;\
	docker image prune -f ;\
	docker volume prune -f ;\
	docker network prune -f ;\
	docker ps


update-service: ## - Update specific service in EC2 (Example: make update-service env=staging service="backend")
	@echo "${GREEN}Start update service ${RESET}" ;\
	read -p "${GREEN}Private .pem file: default = $(EC2_PEM_FILE) ${RESET}" pem_file;\
	pem_file=$${pem_file:-$(EC2_PEM_FILE)};\
	chmod 400 $$pem_file;\
	cmd='cd app && git stash && git pull origin master && make dc env=$(env) args="up -d --build --remove-orphans $(service)"';\
	echo "${GREEN}  - Service    : ${RED}$(service) ${RESET}" ;\
	echo "${GREEN}  - Env file   : ${RED}$(cnf) ${RESET}";\
	echo "${GREEN}  - Build Env  : ${RED}$(BUILD_ENV) ${RESET}";\
	echo "${GREEN}  - PEM file   : ${RED}$$pem_file ${RESET}";\
	echo "${GREEN}  - Public DNS : ${RED}$(EC2_PUBLIC_DNS) ${RESET}";\
	echo "${GREEN}  - CMD        : ${RED}$$cmd ${RESET}";\
	read -p "${GREEN}Are you sure you the configration is correct ?[y/n] default=n${RESET} " answer ;\
	answer=$${answer:-n};\
	if [ $$answer != "$${answer#[Yy]}" ] ;then\
		ssh -i $$pem_file $(EC2_PUBLIC_DNS) $$cmd;\
	fi;\
    echo "${GREEN} End update service ${RESET}"


remote: ## - SSH remote EC2 instance with specific cmd (Example: make env=staging cmd="docker logs -f backend")
	@echo "${GREEN}Start remote ${RESET}" ;\
	read -p "${GREEN}Private .pem file: default = $(EC2_PEM_FILE) ${RESET}" pem_file;\
	pem_file=$${pem_file:-$(EC2_PEM_FILE)};\
	chmod 400 $$pem_file;\
	echo "${GREEN}  - Env file   : ${RED}$(cnf) ${RESET}";\
	echo "${GREEN}  - PEM file   : ${RED}$$pem_file ${RESET}";\
	echo "${GREEN}  - Public DNS : ${RED}$(EC2_PUBLIC_DNS) ${RESET}";\
	echo "${GREEN}  - CMD        : ${RED}$(cmd) ${RESET}";\
	read -p "${GREEN}Are you sure you the configration is correct ?[y/n] default=n${RESET} " answer ;\
	answer=$${answer:-n};\
	if [ $$answer != "$${answer#[Yy]}" ] ;then\
		ssh -i $$pem_file $(EC2_PUBLIC_DNS) $(cmd);\
	fi;\
	echo "${GREEN} End remote ${RESET}"

config-aws:
	@echo "${GREEN}Configure S3 ${RESET}" ;\
	aws_profile=$${aws_profile:-$(APP_NAME)};\
	echo "[$$aws_profile]" >> ~/.aws/credentials;\
	echo "aws_access_key_id=$(AWS_ACCESS_KEY)" >> ~/.aws/credentials;\
	echo "aws_secret_access_key=$(AWS_SECRET_KEY)" >> ~/.aws/credentials



db-rds-backup: ## - Backup databse from AWS RDS
	@chmod +x ${DEPLOYMENT_DIR}/scripts/backup_db.sh && ${DEPLOYMENT_DIR}/scripts/backup_db.sh ${DB_HOST} ${DB_PORT} $(DB_USER) '${DB_PASSWORD}' $(DB_NAME)

db-rds-restore: ## - Restore databse to AWS RDS
	@chmod +x ${DEPLOYMENT_DIR}/scripts/restore_db.sh && ${DEPLOYMENT_DIR}/scripts/restore_db.sh ${DB_HOST} ${DB_PORT} $(DB_USER) '${DB_PASSWORD}' $(DB_NAME)

db-local-create: ## - Create database locally in docker container
	docker exec -i $(APP_NAME)-postgres psql -U postgres -c "CREATE DATABASE $(DB_NAME);"

db-local-terminate-session: ## - Terminall locally all active sessions except your own connectivity
	docker exec -it $(APP_NAME)-postgres -c SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = '$(DB_NAME)';

db-local-restore: ## - Restore locally databse to docker container
	docker exec -i $(APP_NAME)-postgres pg_restore -U postgres --no-privileges --no-owner --verbose --clean -d $(DB_NAME) -v -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d $(DB_NAME) < $(file)

git-clone:
	@echo "git clone https://$(GIT_ACCESS_USER):$(GIT_ACCESS_TOKEN)@gitlab.com/ezie-logistics/ezie-log-backend.git"


