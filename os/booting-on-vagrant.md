# Running Flatcar Container Linux on Vagrant

_While we always welcome community contributions and fixes, please note that Vagrant is not an officially supported platform at this time. (See the [platform overview](/#getting-started).)_


Running Flatcar Container Linux with Vagrant is one way to bring up a single machine or virtualize an entire cluster on your laptop. Since the true power of Flatcar Container Linux can be seen with a cluster, we're going to concentrate on that. Instructions for a single machine can be found [towards the end](#single-machine) of the guide.

You can direct questions to the [IRC channel][irc] or [mailing list][flatcar-dev].

## Install Vagrant and VirtualBox

Vagrant is a simple-to-use command line virtual machine manager. There are install packages available for Windows, Linux and OS X. Find the latest installer on the [Vagrant downloads page][vagrant]. Be sure to get version 2.0.4 or greater, to be able to detect Flatcar images correctly.

[vagrant]: http://www.vagrantup.com/downloads.html

Vagrant can use either the free VirtualBox provider or the commercial VMware provider. Instructions for both are below. For the VirtualBox provider, version 4.3.10 or greater is required.

## Install Flatcar Container Linux

You can import the flatcar box and boot it with Vagrant.
You'll find it in `https://${CHANNEL}.release.flatcar-linux.net/amd64-usr/${VERSION}/flatcar_production_vagrant.box`.
Make sure you download the signature (it's available in `https://${CHANNEL}.release.flatcar-linux.net/amd64-usr/${VERSION}/flatcar_production_vagrant.box.sig`) and check it before proceeding.

For example, to get the latest alpha:

```
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vagrant.box
$ wget https://alpha.release.flatcar-linux.net/amd64-usr/current/flatcar_production_vagrant.box.sig
$ gpg --verify flatcar_production_vagrant.box.sig
gpg: assuming signed data in 'flatcar_production_vagrant.box'
gpg: Signature made Thu 15 Mar 2018 10:29:23 AM CET
gpg:                using RSA key A621F1DA96C93C639506832D603443A1D0FC498C
gpg: Good signature from "Flatcar Buildbot (Official Builds) <buildbot@flatcar-linux.org>" [ultimate]
$ vagrant box add flatcar-alpha flatcar_production_vagrant.box
==> box: Box file was not detected as metadata. Adding it directly...
==> box: Adding box 'flatcar-alpha' (v0) for provider:
    box: Unpacking necessary files from: file:///tmp/flatcar_production_vagrant.box
==> box: Successfully added box 'flatcar-alpha' (v0) for 'virtualbox'!
$ vagrant init flatcar-alpha
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'flatcar-alpha'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: vagrant_default_1520510346048_14823
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 22 (guest) => 2222 (host) (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
    default: SSH address: 127.0.0.1:2222
    default: SSH username: core
    default: SSH auth method: private key
==> default: Machine booted and ready!
$ vagrant ssh
Last login: Thu Mar 15 17:02:25 UTC 2018 from 10.0.2.2 on ssh
Flatcar Container Linux by Kinvolk alpha (1702.1.0)
core@localhost ~ $
```

## Starting a cluster

You can configure your Vagrant machine by having a `Vagrantfile` example file:

```
ENV["TERM"] = "xterm-256color"
ENV["LC_ALL"] = "en_US.UTF-8"

Vagrant.require_version '>= 2.0.4'

Vagrant.configure('2') do |config|
  config.ssh.username = 'core'
  config.ssh.insert_key = true
  config.vm.box = 'flatcar-alpha'
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provider :virtualbox do |v|
    v.check_guest_additions = false
    v.functional_vboxsf = false
    v.cpus = 2
    v.memory = 2048
  end
  config.vm.define 'core-01' do |c|
  end
  config.vm.define 'core-02' do |c|
  end
  config.vm.define 'core-03' do |c|
  end
end
```

### Start machines using Vagrant's default VirtualBox provider

Start the machine(s):

```sh
vagrant up
```

List the status of the running machines:

```sh
$ vagrant status
Current machine states:

core-01                   running (virtualbox)
core-02                   running (virtualbox)
core-03                   running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```

Connect to one of the machines:

```sh
vagrant ssh core-01 -- -A
```

### Start machines using Vagrant's VMware provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```sh
vagrant up --provider vmware_fusion
vagrant ssh core-01 -- -A
```

## Single machine

To start a single machine, we need to provide some config parameters in cloud-config format via the `user-data` file.

Start the machine:

```sh
vagrant up
```

Connect to the machine:

```sh
vagrant ssh core-01 -- -A
```

### Start machine using Vagrant's VMware provider

If you have purchased the [VMware Vagrant provider](http://www.vagrantup.com/vmware), run the following commands:

```sh
vagrant up --provider vmware_fusion
vagrant ssh core-01 -- -A
```

## Shared folder setup

Optionally, you can share a folder from your laptop into the virtual machine. This is useful for easily getting code and Dockerfiles into Flatcar Container Linux.

```ini
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

After a 'vagrant reload' you will be prompted for your local machine password.

## New box versions

Flatcar Container Linux is a rolling release distribution and versions that are out of date will automatically update. If you want to start from the most up to date version you will need to make sure that you have the latest box file of Flatcar Container Linux. You can do this using `vagrant box update` - or, simply remove the old box file and Vagrant will download the latest one the next time you `vagrant up`.

```sh
vagrant box remove flatcar-alpha vmware_fusion
vagrant box remove flatcar-alpha virtualbox
```

If you'd like to download the box separately, you can download the URL contained in the Vagrantfile and add it manually:

```sh
vagrant box add flatcar-alpha <path-to-box-file>
```

## Using Flatcar Container Linux

Now that you have a machine booted it is time to play around. Check out the [Flatcar Container Linux Quickstart](quickstart.md) guide, learn about [CoreOS Container Linux clustering with Vagrant](https://coreos.com/blog/coreos-clustering-with-vagrant/), or dig into [more specific topics](https://docs.flatcar-linux.org).


[flatcar-dev]: https://groups.google.com/forum/#!forum/flatcar-linux-dev
[irc]: irc://irc.freenode.org:6667/#flatcar
