resource "aws_iam_role" "ec2" {

  name = "alb-web-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

}

resource "aws_iam_instance_profile" "ec2" {

  name = "alb-web-instance-profile"

  role = aws_iam_role.ec2.name

}

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.ec2.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

resource "aws_iam_role_policy_attachment" "secret_read" {

  role = aws_iam_role.ec2.name

  policy_arn = aws_iam_policy.secret_read.arn

}

resource "aws_iam_policy" "secret_read" {

  name = "alb-secret-read"

  description = "Allow EC2 to read the application database secret"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Action = [

          "secretsmanager:GetSecretValue"

        ]

        Resource = aws_secretsmanager_secret.db_password.arn

      }

    ]

  })

}
