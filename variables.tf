variable "location" {
  type        = string
  default     = "eastus" # time zone
  description = "Azure location"
}

variable "allowed_ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0" # change before deployement ->203.0.113.5 -> default = ["203.0.113.5/32"]
  description = "CIDR block allowed to SSH"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for deployuser"
  default     = "ssh-rsa AAAA...My_public_key_here"
}
