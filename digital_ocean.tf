# First, add a variable called do_token,
# which is populated by my environment
# see .config/fish/config.fish for the value
variable "do_token" {}

variable "templates" {
    default     = "templates"
    type        = "string"
    description = "directory of all files needed to be templated by TF"
}

variable "file_artifacts" {
    default     = "file_artifacts"
    type        = "string"
    description = "file actifacts is the output directory from templating everything"
}

variable "consul_data" {
    default     = "/consul-data"
    type        = "string"
    description = "name of the directory where consul writes it persister storage"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Link my local ssh key
resource "digitalocean_ssh_key" "default" {
  name       = "hashi-macbook"
  public_key = "${file("/Users/hashi/.ssh/id_rsa.pub")}"
}

# Create the master node
resource "digitalocean_droplet" "master" {
    image              = "docker-16-04"
    size               = "512mb"
    region             = "nyc3"
    name               = "master"
    ssh_keys           = ["${digitalocean_ssh_key.default.fingerprint}"]
    ipv6               = true
    private_networking = true
}

# Create the master node
resource "digitalocean_droplet" "minion" {
    image              = "docker-16-04"
    size               = "512mb"
    region             = "nyc3"
    name               = "minion"
    ssh_keys           = ["${digitalocean_ssh_key.default.fingerprint}"]
    ipv6               = true
    private_networking = true
}

resource "template_dir" "custom_templates" {
    source_dir      = "${var.templates}"
    destination_dir = "${var.file_artifacts}"

    vars {
        master_ip  = "${digitalocean_droplet.master.ipv4_address}"
        minion_ip  = "${digitalocean_droplet.minion.ipv4_address}"
        data_dir   = "${var.consul_data}"
    }
}

# Provision the nodes once
# their floating IP addresses have been assigned
resource "null_resource" "autojoin-consul-master" {
    depends_on = ["digitalocean_droplet.master", "digitalocean_droplet.minion", "template_dir.custom_templates"]

    triggers {
        do_node = "${digitalocean_droplet.master.ipv4_address}"
    }

    connection {
        agent = true
        host =  "${digitalocean_droplet.master.ipv4_address}"
    }

    provisioner "file" {
        source      = "${var.file_artifacts}/consul_master.service"
        destination = "/etc/systemd/system/consul.service"
    }

    provisioner "file" {
        source      = "${var.file_artifacts}/provision_consul_node.bash"
        destination = "/tmp/provision_consul_node.bash"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/provision_consul_node.bash",
            "/tmp/provision_consul_node.bash"
        ]
    }
}

# Provision the nodes once
# their floating IP addresses have been assigned
resource "null_resource" "autojoin-consul-minion" {

    depends_on = ["null_resource.autojoin-consul-master", "template_dir.custom_templates"]

    triggers {
        do_node = "${digitalocean_droplet.minion.ipv4_address}"
    }

    connection {
        agent = true
        host =  "${digitalocean_droplet.minion.ipv4_address}"
    }

    provisioner "file" {
        source      = "${var.file_artifacts}/consul_minion.service"
        destination = "/etc/systemd/system/consul.service"
    }

    provisioner "file" {
        source      = "${var.file_artifacts}/provision_consul_node.bash"
        destination = "/tmp/provision_consul_node.bash"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/provision_consul_node.bash",
            "/tmp/provision_consul_node.bash",
        ]
    }
}

output "master_ip" {
  value = "${digitalocean_droplet.master.ipv4_address}"
}

output "minion_ip" {
  value = "${digitalocean_droplet.minion.ipv4_address}"
}
