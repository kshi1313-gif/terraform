variable "security_group_name" {
    description = "My SG Name"
    type = string
    default = "allow_8080"
}

variable "server_port" {
    default = 8080
}
