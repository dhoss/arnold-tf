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

#### SECRETS
variable "secrethub_passphrase" {}

provider "secrethub" {
  credential            = "${file("~/.secrethub/credential")}"
  credential_passphrase = "${var.secrethub_passphrase}"
}

data "secrethub_secret" "discord-api-token-dev" {
  path  = "djaustin/arnold-fitness-bot/tokens/discord/dev:4"
}

data "secrethub_secret" "discord-api-token-prod" {
  path  = "djaustin/arnold-fitness-bot/tokens/discord/prod:1"
}


data "secrethub_secret" "sentry-dsn" {
  path  = "djaustin/arnold-fitness-bot/tokens/common/sentry:1"
}
####

#### CONFIG
resource "heroku_config" "discord-api-token-dev" {
    sensitive_vars = {
        DISCORD_API_TOKEN = "${data.secrethub_secret.discord-api-token-dev.value}"
    }
}

resource "heroku_config" "discord-api-token-prod" {
    sensitive_vars = {
        DISCORD_API_TOKEN = "${data.secrethub_secret.discord-api-token-prod.value}"
    }
}

resource "heroku_config" "sentry-dsn-dev" {
    sensitive_vars = {
        SENTRY_DSN = "${data.secrethub_secret.sentry-dsn.value}"
    }
}

resource "heroku_config" "sentry-dsn-stage" {
    sensitive_vars = {
        SENTRY_DSN = "${data.secrethub_secret.sentry-dsn.value}"
    }
}

resource "heroku_config" "public-stage" {
    vars = {
        JVM_OPTS = "-Xmx300m -Xss512k -XX:CICompilerCount=2 -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC"
        APP_USER = "arnold-stage"
    }
}

resource "heroku_config" "public-prod" {
    vars = {
        JVM_OPTS = "-Xmx300m -Xss512k -XX:CICompilerCount=2 -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC"
        APP_USER = "arnold-prod"
    }
}

resource "heroku_app_config_association" "arnold-stage" {
  app_id = "${heroku_app.arnold-stage.id}"

  vars = "${heroku_config.public-stage.vars}"
  sensitive_vars = "${heroku_config.discord-api-token-dev.sensitive_vars}"
}

resource "heroku_app_config_association" "arnold-prod" {
  app_id = "${heroku_app.arnold-prod.id}"

  vars = "${heroku_config.public-prod.vars}"
  sensitive_vars = "${heroku_config.discord-api-token-prod.sensitive_vars}"
}
####

#### PIPELINE STAGES
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
####

#### ADDONS
resource "heroku_addon" "database-stage" {
  app  = "${heroku_app.arnold-stage.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_addon" "database-prod" {
  app  = "${heroku_app.arnold-prod.name}"
  plan = "heroku-postgresql:hobby-dev"
}

resource "heroku_addon" "sentry-stage" {
  app  = "${heroku_app.arnold-stage.name}"
  plan = "sentry:f1"
}

resource "heroku_addon" "sentry-prod" {
  app  = "${heroku_app.arnold-prod.name}"
  plan = "sentry:f1"
}
####
