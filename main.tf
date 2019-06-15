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

variable "app_name" {
  description = "Name of the Heroku app"
}

resource "heroku_app" "arnold-stage" {
  name = "${var.app_name}-stage"
  region = "us"
  buildpacks = [
      "heroku/java"
  ]
}

resource "heroku_app" "arnold-prod" {
  name = "${var.app_name}-prod"
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
