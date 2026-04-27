variable "image" {
  description = "Fallback base image used for containers"
  type        = string
  default     = "ubuntu:22.04"
}

variable "image_web" {
  description = "Web node image"
  type        = string
  default     = ""
}

variable "image_app" {
  description = "App node image"
  type        = string
  default     = ""
}

variable "image_db" {
  description = "DB node image"
  type        = string
  default     = ""
}

variable "network_name" {
  description = "Docker network name"
  type        = string
  default     = "app_network"
}

variable "network_driver" {
  description = "Docker network driver"
  type        = string
  default     = "bridge"
}

variable "network_internal" {
  description = "Whether the docker network is internal. Set false if apt/pip must reach internet during provisioning."
  type        = bool
  default     = false
}

variable "restart_policy" {
  description = "Restart policy for containers."
  type        = string
  default     = "unless-stopped"
}

variable "web_host_port" {
  description = "Host port mapped to the web container (nginx)"
  type        = number
  default     = 8080
}

variable "web_container_port" {
  description = "Container port nginx will listen on"
  type        = number
  default     = 80
}

variable "app_container_port" {
  description = "Application container port (Flask)"
  type        = number
  default     = 5000
}

variable "db_container_port" {
  description = "Database container internal port"
  type        = number
  default     = 5432
}

variable "healthcheck_start_period" {
  description = "Healthcheck start_period to allow Ansible provisioning to complete before checks begin"
  type        = string
  default     = "180s"
}