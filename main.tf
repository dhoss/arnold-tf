terraform {
  backend "pg" {
  }
}

provider "heroku" {
  version = "~> 2.0"
}
