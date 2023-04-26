terraform {
  required_version = ">= 1.2.1"
}

variable "pool" {
  description = "Slurm pool of compute nodes"
  default = []
}

module "openstack" {
  source         = "./openstack"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "12.3.0"

  cluster_name = "sprbas2023"
  domain       = "ace-net.training"
  image        = "Rocky-8.7-x64-2023-02"

  instances = {
    mgmt   = { type = "p4-6gb", tags = ["puppet", "mgmt", "nfs"], count = 1 }
    login  = { type = "p2-3gb", tags = ["login", "public", "proxy"], count = 1 }
    node   = { type = "p2-3gb", tags = ["node"], count = 1 }
  }

  # var.pool is managed by Slurm through Terraform REST API.
  # To let Slurm manage a type of nodes, add "pool" to its tag list.
  # When using Terraform CLI, this parameter is ignored.
  # Refer to Magic Castle Documentation - Enable Magic Castle Autoscaling
  pool = var.pool

  volumes = {
    nfs = {
      home     = { size = 100 }
      project  = { size = 50 }
      scratch  = { size = 50 }
    }
  }

  public_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC3Ym8RnkOSzwS66QPxT1Ub00knXM5i0aMfFW7yZvoTm16aO9f6Z0wqbEp3+IwZTJ0lwDrtTZV8MZTuWNqximaXz8t4UTQ3aGBEQ0tW1JGSIgmQ9SilBwBdMQBVUQL3i3H32+L3uUnYtlOtZM+g0G0FwiHVX7ULV4d2z4RkjCDaHkO37rxOikRPbKhtQFLHAjURR3DzM9iV/cN1nFhL7iKjhdbMPjQ1AmC5VcA/y0YDFdB1yxCD8EID3+vzqymwe5DUy/lgn/bg0jECEtBPQS9neQVUhAieOQ5FAiSxB3T0bHwq9rtAmcwxwXJpABpIv91Lwz6bC/OtRiFBFKC21yxRyP0xWZlemi8quayYqzIcsdYBUPs2CGUO6aph7KTCYfNWBuEdIO2NmraqqF9RsiMfkXwczGnVfJTDQyOyLh+iYkl37zpb3PXGzwcYzo4bFwKxTrWaAlOv/VFNolm2ovier+xRJic3vnS/SGvfytwFmiqpV9Lnlbnebbi4GAQr4VXyiUPW7EYmWm/Zlvdj5Z+0xldRaJvcVLNB7p81N2QAMD3mSnj2YdM4QrI+C3u8+diftaCNKhFWuP70nx6cYCj7kP809lG+u1dbwXhx/DJh0FcA2LjNej2UmteOypU25QBtz31MgQR+Sru/rLXk5/rtdhivyn/EPEORkMHcTB5VdQ== castlemanager@castle-manager"]

  generate_ssh_key = true
  
  nb_users = 100
  # Shared password, randomly chosen if blank
  guest_passwd = ""
}

output "accounts" {
  value = module.openstack.accounts
}

output "public_ip" {
  value = module.openstack.public_ip
}

# Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "./dns/cloudflare"
  email            = "chris.geroux@ace-net.ca"
  name             = module.openstack.cluster_name
  domain           = module.openstack.domain
  public_instances = module.openstack.public_instances
  ssh_private_key  = module.openstack.ssh_private_key
  sudoer_username  = module.openstack.accounts.sudoer.username
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "./dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.openstack.cluster_name
#   domain           = module.openstack.domain
#   public_instances = module.openstack.public_instances
#   ssh_private_key  = module.openstack.ssh_private_key
#   sudoer_username  = module.openstack.accounts.sudoer.username
# }

output "hostnames" {
  value = module.dns.hostnames
}
