Vagrant.configure("2") do |config|
  config.vm.box = "minimal/centos6"
  config.ssh.insert_key = false

  config.vm.define "mgmt1", autostart: true do |vm|
      vm.vm.hostname = "mgmt1.bdr.nl"
      vm.vm.network "private_network", ip: "10.0.0.2"
      vm.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--memory", "2048", "--nicpromisc1", "allow-all"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
  end

  config.vm.define "en1", autostart: true do |vm|
      vm.vm.hostname = "en1.bdr.nl"
      vm.vm.network "private_network", ip: "10.0.0.3"
      vm.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--memory", "2048", "--nicpromisc1", "allow-all"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
  end

  config.vm.define "mn1", autostart: true do |vm|
      vm.vm.hostname = "mn1.bdr.nl"
      vm.vm.network "private_network", ip: "10.0.0.4"
      vm.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--memory", "2048", "--nicpromisc1", "allow-all"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
  end

  config.vm.define "wn1", autostart: true do |vm|
      vm.vm.hostname = "wn1.bdr.nl"
      vm.vm.network "private_network", ip: "10.0.0.5"
      vm.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--memory", "2048", "--nicpromisc1", "allow-all"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
  end

    config.vm.define "ipa", autostart: true do |vm|
      vm.vm.hostname = "ipa.bdr.nl"
      vm.vm.network "private_network", ip: "10.0.0.6"
      vm.vm.provider "virtualbox" do |vb|
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--memory", "2048", "--nicpromisc1", "allow-all"]
        vb.customize ["modifyvm", :id, "--usb", "off"]
        vb.customize ["modifyvm", :id, "--usbehci", "off"]
      end
  end
end
