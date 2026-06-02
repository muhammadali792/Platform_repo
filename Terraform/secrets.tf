# 1. Configuration (Control Panel)
locals {
  services = {
    auth    = { rds = true,  redis = false, needs_jwt = true }
    product = { rds = true,  redis = true,  needs_jwt = false }
    order   = { rds = true,  redis = true,  needs_jwt = true }
    notif   = { rds = false, redis = true,  needs_jwt = false }
  }
}

# 2. Random Secrets
resource "random_password" "db_pass" { length = 16 }
resource "random_password" "jwt_secret" { length = 32 }
resource "random_password" "redis_pass" { length = 16 }

# 3. Secrets Manager (Loop)
resource "aws_secretsmanager_secret" "service_secrets" {
  for_each = local.services
  name     = "${each.key}-service/secrets"
}

resource "aws_secretsmanager_secret_version" "secrets_val" {
  for_each  = local.services
  secret_id = aws_secretsmanager_secret.service_secrets[each.key].id
  
  # Dynamic construction of secret_string
  secret_string = jsonencode(merge(
    each.value.needs_jwt ? { JWT_SECRET = random_password.jwt_secret.result } : {},
    each.value.rds   ? { DATABASE_URL = "postgresql://admin:${random_password.db_pass.result}@${aws_db_instance.main_db.address}:5432/${each.key}_db" } : {},
    each.value.redis ? { REDIS_URL    = "redis://:${random_password.redis_pass.result}@${aws_elasticache_cluster.main_redis.cache_nodes[0].address}:6379" } : {}
  ))
}

# 4. Infrastructure
resource "aws_db_instance" "main_db" {
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  db_name             = "main_db"
  username            = "admin"
  password            = random_password.db_pass.result
  skip_final_snapshot = true
}

resource "aws_elasticache_cluster" "main_redis" {
  cluster_id           = "main-redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
}
