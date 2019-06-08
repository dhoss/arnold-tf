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

resource "heroku_app" "arnold" {
  name = "${var.app_name}"
  region = "us"
  buildpacks = [
      "heroku/java"
  ]
}

resource "heroku_addon" "database" {
  app  = "${heroku_app.arnold.name}"
  plan = "heroku-postgresql:hobby-basic"
}

output "arnold_app_url" {
  value = "https://${heroku_app.arnold.name}.herokuapp.com"
}
