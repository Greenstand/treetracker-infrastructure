output "service_password" {
  value = random_password.s_password.result
}

output "migration_password" {
  value = random_password.m_password.result
}
