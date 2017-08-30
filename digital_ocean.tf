# First, add a variable called do_token,
# which is populated by my environment
# see .config/fish/config.fish for the value
variable "do_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Link my local ssh key
resource "digitalocean_ssh_key" "default" {
  name       = "hashi-macbook"
  public_key = "${file("/Users/hashi/.ssh/id_rsa.pub")}"
}

resource "digitalocean_floating_ip" "master" {
  droplet_id = "${digitalocean_droplet.master.id}"
  region     = "${digitalocean_droplet.master.region}"
}

resource "digitalocean_floating_ip" "minion" {
  droplet_id = "${digitalocean_droplet.minion.id}"
  region     = "${digitalocean_droplet.minion.region}"
}

# Provision the nodes once
# their floating IP addresses have been assigned
resource "null_resource" "autojoin-consul-master" {
    depends_on = ["digitalocean_floating_ip.master", "digitalocean_floating_ip.minion"]

    triggers {
        do_node = "${digitalocean_floating_ip.master.ip_address}"
    }

    connection {
        agent = true
        host =  "${digitalocean_floating_ip.master.ip_address}"
    }

    provisioner "file" {
        source      = "start_master.bash"
        destination = "/tmp/start_master.bash"
    }

    provisioner "remote-exec" {
    
        inline = [
            "chmod +x /tmp/start_master.bash",
            "MASTER_IP=${digitalocean_droplet.master.ipv4_address} /tmp/start_master.bash"

            # "apt-get update",
            # "apt-get install -yq zip",
            # "curl https://releases.hashicorp.com/nomad/0.6.0/nomad_0.6.0_linux_386.zip >> nomad.zip",
            # "curl https://releases.hashicorp.com/consul/0.9.2/consul_0.9.2_linux_386.zip >> consul.zip",
            # "unzip nomad.zip",
            # "unzip consul.zip",
            # "rm nomad.zip",
            # "rm consul.zip",
            # "consul join ${digitalocean_floating_ip.minion.ip_address}"
            # "docker run -d consul agent -dev -join=${digitalocean_floating_ip.minion.ip_address}"
        ]
    }
}

# Provision the nodes once
# their floating IP addresses have been assigned
resource "null_resource" "autojoin-consul-minion" {

    depends_on = ["null_resource.autojoin-consul-master"]

    triggers {
        do_node = "${digitalocean_floating_ip.minion.ip_address}"
    }

    connection {
        agent = true
        host =  "${digitalocean_floating_ip.minion.ip_address}"
    }

    provisioner "file" {
        source      = "start_minion.bash"
        destination = "/tmp/start_minion.bash"
    }
    provisioner "remote-exec" {

        inline = [
            "chmod +x /tmp/start_minion.bash",
            "MASTER_IP=${digitalocean_droplet.master.ipv4_address} /tmp/start_minion.bash",
            "echo ${digitalocean_droplet.minion.ipv4_address}"

            # "apt-get update",
            # "apt-get install -yq zip",
            # "curl https://releases.hashicorp.com/nomad/0.6.0/nomad_0.6.0_linux_386.zip >> nomad.zip",
            # "curl https://releases.hashicorp.com/consul/0.9.2/consul_0.9.2_linux_386.zip >> consul.zip",
            # "unzip nomad.zip",
            # "unzip consul.zip",
            # "rm nomad.zip",
            # "rm consul.zip",
            # "consul join ${digitalocean_floating_ip.master.ip_address}"
            # "docker run -d consul agent -dev -join=${digitalocean_floating_ip.master.ip_address}"
        ]
    }
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
