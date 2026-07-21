resource "aws_secretsmanager_secret" "db_password" {

  name = "alb-db-password"

  description = "Database password for the web application"

}


resource "aws_secretsmanager_secret_version" "db_password" {

  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({

    username = "admin"

    password = "ChangeMe123!"

  })

}
