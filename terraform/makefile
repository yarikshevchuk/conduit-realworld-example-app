.DEFAULT_GOAL := terraform

.PHONY: terraform init validate plan apply fmt destroy

GREEN = $(shell tput -Txterm setab 2 && tput -Txterm setaf 7)
RESET = $(shell tput -Txterm sgr0)

terraform: init validate plan fmt apply
	@printf "$(GREEN) All stages completed succesfully. $(RESET)\n"

init:
	@printf "$(GREEN) Terraform init: $(RESET)\n"
	@terraform init -migrate-state -force-copy

validate:
	@printf "$(GREEN) Terraform validate: $(RESET)\n"
	@terraform validate

plan: 
	@printf "$(GREEN) Terraform plan: $(RESET)\n"
	@terraform plan

fmt:
	@printf "$(GREEN) Terraform fmt: $(RESET)\n"
	@terraform fmt

apply:
	@printf "$(GREEN) Terraform apply: $(RESET)\n"
	@terraform apply -auto-approve

destroy:
	@printf "$(GREEN) Terraform destroy: $(RESET)\n"
	@terraform destroy -auto-approve