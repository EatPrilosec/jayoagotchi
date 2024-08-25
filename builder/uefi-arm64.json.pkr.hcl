packer {
  required_plugins {
    arm-image = {
      source  = "github.com/solo-io/arm-image"
      version = ">= 0.0.1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.1"
    }
  }
}

variable "pwn_hostname" {
  type = string
}

variable "pwn_version" {
  type = string
}

source "arm-image" "uefi-arm64-pwnagotchi" {
  image_type      = "armbian"
  iso_urls        = [
    "https://mirrors.jevincanders.net/armbian/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://armbian.chi.auroradev.org/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://armbian.lv.auroradev.org/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://mirror-us-sea1.armbian.airframes.io/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://mirror-us-stl1.armbian.airframes.io/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://uk.mirrors.naho.moe/armbian-dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz",
    "http://mirror.vinehost.net/armbian/dl/uefi-arm64/archive/Armbian_24.5.5_Uefi-arm64_bookworm_current_6.6.42_minimal.img.xz"
  ]
  iso_checksum    = "sha256:D77CCA47E1CA822FD0E74EAD096FC2C8CBFD395884323F96F4D9F94BF29F19A8"
  output_filename = "../../../uefi-arm64.img"
  qemu_binary     = "qemu-aarch64-static"
  image_mounts    = ["/boot/efi","/"]
  target_image_size = 19969908736
}

build {
  name = "Generic UEFI aarch64 Pwnagotchi"
  sources = ["source.arm-image.uefi-arm64-pwnagotchi"]
  provisioner "file" {
    destination = "/usr/bin/"
    sources     = [
      "data/64bit/usr/bin/bettercap-launcher",
      "data/64bit/usr/bin/hdmioff",
      "data/64bit/usr/bin/hdmion",
      "data/64bit/usr/bin/monstart",
      "data/64bit/usr/bin/monstop",
      "data/64bit/usr/bin/pwnagotchi-launcher",
      "data/64bit/usr/bin/pwnlib",
    ]
  }
  provisioner "shell" {
    inline = ["chmod +x /usr/bin/*"]
  }
  provisioner "shell" {
    inline = ["mkdir -p /usr/local/src/pwnagotchi"]
  }
  provisioner "file" {
    destination = "/usr/local/src/pwnagotchi/"
    source = "../"
  }
  provisioner "file" {
    destination = "/etc/systemd/system/"
    sources     = [
      "data/64bit/etc/systemd/system/bettercap.service",
      "data/64bit/etc/systemd/system/pwnagotchi.service",
      "data/64bit/etc/systemd/system/pwngrid-peer.service",
    ]
  }
  provisioner "file" {
    destination = "/etc/update-motd.d/01-motd"
    source      = "data/64bit/etc/update-motd.d/01-motd"
  }
  provisioner "shell" {
    inline = ["chmod +x /etc/update-motd.d/*"]
  }
  provisioner "shell" {
    inline = ["apt-get -y --allow-releaseinfo-change update", "apt-get -y dist-upgrade", "apt-get install -y --no-install-recommends ansible"]
  }
  provisioner "ansible-local" {
    command         = "ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 PWN_VERSION=${var.pwn_version} PWN_HOSTNAME=${var.pwn_hostname} ansible-playbook"
    extra_arguments = ["--extra-vars \"ansible_python_interpreter=/usr/bin/python3\""]
    playbook_file   = "uefi-arm64.yml"
  }
}
