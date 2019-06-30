# TODO: configuration variables per environment
# e.g.: dev instance should connect as arnold-dev to get-pumped-bot-test server, 
# prod should connect as arnold to get-pumped server
# database credentials as well

terraform {
  backend "pg" {
  }
}

provider "heroku" {
  version = "~> 2.0"
}

variable "secrethub_passphrase" {}

provider "secrethub" {
  credential            = "${file("~/.secrethub/credential")}"
  credential_passphrase = "${var.secrethub_passphrase}"
}

data "secrethub_secret" "discord-api-token-dev" {
  path  = "djaustin/arnold-fitness-bot/tokens/discord/dev:1"
}

resource "heroku_config" "discord-api-tokens" {
    sensitive_vars = {
        token = "${data.secrethub_secret.discord-api-token-dev.value}"
    }
}

resource "heroku_app" "arnold-stage" {
  name = "arnold-fitness-bot-stage"
  region = "us"
  buildpacks = [
      "heroku/java"
  ]
}

resource "heroku_app" "arnold-prod" {
  name = "arnold-fitness-bot-prod"
  region = "us"
  buildpacks = [
      "heroku/java"
  ]
}

resource "heroku_pipeline" "arnold-app" {
  name = "arnold-app"
}

resource "heroku_pipeline_coupling" "staging" {
  app      = "${heroku_app.arnold-stage.name}"
  pipeline = "${heroku_pipeline.arnold-app.id}"
  stage    = "staging"
}

resource "heroku_pipeline_coupling" "production" {
  app      = "${heroku_app.arnold-prod.name}"
  pipeline = "${heroku_pipeline.arnold-app.id}"
  stage    = "production"
}

resource "heroku_addon" "database-stage" {
  app  = "${heroku_app.arnold-stage.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_addon" "database-prod" {
  app  = "${heroku_app.arnold-prod.name}"
  plan = "heroku-postgresql:hobby-dev"
}
