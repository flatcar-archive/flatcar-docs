variant (string): used to differentiate configs for different operating systems. Must be flatcar for this specification.
version (string): the semantic version of the spec for this document. This document is for version 1.0.0 and generates Ignition configs with version 3.3.0.
ignition (object): metadata about the configuration itself.
config (objects): options related to the configuration.
merge (list of objects): a list of the configs to be merged to the current config.
source (string): the URL of the config. Supported schemes are http, https, s3, gs, tftp, and data. Note: When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. Mutually exclusive with inline and local.
inline (string): the contents of the config. Mutually exclusive with source and local.
local (string): a local path to the contents of the config, relative to the directory specified by the --files-dir command-line argument. Mutually exclusive with source and inline.
compression (string): the type of compression used on the config (null or gzip). Compression cannot be used with S3.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the config.
hash (string): the hash of the config, in the form <type>-<value> where type is either sha512 or sha256.
replace (object): the config that will replace the current.
source (string): the URL of the config. Supported schemes are http, https, s3, gs, tftp, and data. Note: When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. Mutually exclusive with inline and local.
inline (string): the contents of the config. Mutually exclusive with source and local.
local (string): a local path to the contents of the config, relative to the directory specified by the --files-dir command-line argument. Mutually exclusive with source and inline.
compression (string): the type of compression used on the config (null or gzip). Compression cannot be used with S3.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the config.
hash (string): the hash of the config, in the form <type>-<value> where type is either sha512 or sha256.
timeouts (object): options relating to http timeouts when fetching files over http or https.
http_response_headers (integer) the time to wait (in seconds) for the server’s response headers (but not the body) after making a request. 0 indicates no timeout. Default is 10 seconds.
http_total (integer) the time limit (in seconds) for the operation (connection, request, and response), including retries. 0 indicates no timeout. Default is 0.
security (object): options relating to network security.
tls (object): options relating to TLS when fetching resources over https.
certificate_authorities (list of objects): the list of additional certificate authorities (in addition to the system authorities) to be used for TLS verification when fetching over https. All certificate authorities must have a unique source, inline, or local.
source (string): the URL of the certificate bundle (in PEM format). With Ignition ≥ 2.4.0, the bundle can contain multiple concatenated certificates. Supported schemes are http, https, s3, gs, tftp, and data. Note: When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. Mutually exclusive with inline and local.
inline (string): the contents of the certificate bundle (in PEM format). With Ignition ≥ 2.4.0, the bundle can contain multiple concatenated certificates. Mutually exclusive with source and local.
local (string): a local path to the contents of the certificate bundle (in PEM format), relative to the directory specified by the --files-dir command-line argument. With Ignition ≥ 2.4.0, the bundle can contain multiple concatenated certificates. Mutually exclusive with source and inline.
compression (string): the type of compression used on the certificate (null or gzip). Compression cannot be used with S3.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the certificate.
hash (string): the hash of the certificate, in the form <type>-<value> where type is either sha512 or sha256.
proxy (object): options relating to setting an HTTP(S) proxy when fetching resources.
http_proxy (string): will be used as the proxy URL for HTTP requests and HTTPS requests unless overridden by https_proxy or no_proxy.
https_proxy (string): will be used as the proxy URL for HTTPS requests unless overridden by no_proxy.
no_proxy (list of strings): specifies a list of strings to hosts that should be excluded from proxying. Each value is represented by an IP address prefix (1.2.3.4), an IP address prefix in CIDR notation (1.2.3.4/8), a domain name, or a special DNS label (*). An IP address prefix and domain name can also include a literal port number (1.2.3.4:80). A domain name matches that name and all subdomains. A domain name with a leading . matches subdomains only. For example foo.com matches foo.com and bar.foo.com; .y.com matches x.y.com but not y.com. A single asterisk (*) indicates that no proxying should be done.
storage (object): describes the desired state of the system’s storage devices.
disks (list of objects): the list of disks to be configured and their options. Every entry must have a unique device.
device (string): the absolute path to the device. Devices are typically referenced by the /dev/disk/by-* symlinks.
wipe_table (boolean): whether or not the partition tables shall be wiped. When true, the partition tables are erased before any further manipulation. Otherwise, the existing entries are left intact.
partitions (list of objects): the list of partitions and their configuration for this particular disk. Every partition must have a unique number, or if 0 is specified, a unique label.
label (string): the PARTLABEL for the partition.
number (integer): the partition number, which dictates its position in the partition table (one-indexed). If zero, use the next available partition slot.
size_mib (integer): the size of the partition (in mebibytes). If zero, the partition will be made as large as possible.
start_mib (integer): the start of the partition (in mebibytes). If zero, the partition will be positioned at the start of the largest block available.
type_guid (string): the GPT partition type GUID. If omitted, the default will be 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem data).
guid (string): the GPT unique partition GUID.
wipe_partition_entry (boolean) if true, Ignition will clobber an existing partition if it does not match the config. If false (default), Ignition will fail instead.
should_exist (boolean) whether or not the partition with the specified number should exist. If omitted, it defaults to true. If false Ignition will either delete the specified partition or fail, depending on wipePartitionEntry. If false number must be specified and non-zero and label, start, size, guid, and typeGuid must all be omitted.
resize (boolean) whether or not the existing partition should be resized. If omitted, it defaults to false. If true, Ignition will resize an existing partition if it matches the config in all respects except the partition size.
raid (list of objects): the list of RAID arrays to be configured. Every RAID array must have a unique name.
name (string): the name to use for the resulting md device.
level (string): the redundancy level of the array (e.g. linear, raid1, raid5, etc.).
devices (list of strings): the list of devices (referenced by their absolute path) in the array.
spares (integer): the number of spares (if applicable) in the array.
options (list of strings): any additional options to be passed to mdadm.
filesystems (list of objects): the list of filesystems to be configured. device and format need to be specified. Every filesystem must have a unique device.
device (string): the absolute path to the device. Devices are typically referenced by the /dev/disk/by-* symlinks.
format (string): the filesystem format (ext4, btrfs, xfs, vfat, swap, or none).
path (string): the mount-point of the filesystem while Ignition is running relative to where the root filesystem will be mounted. This is not necessarily the same as where it should be mounted in the real root, but it is encouraged to make it the same.
wipe_filesystem (boolean): whether or not to wipe the device before filesystem creation, see the documentation on filesystems for more information. Defaults to false.
label (string): the label of the filesystem.
uuid (string): the uuid of the filesystem.
options (list of strings): any additional options to be passed to the format-specific mkfs utility.
mount_options (list of strings): any special options to be passed to the mount command.
with_mount_unit (bool): whether to additionally generate a generic mount unit for this filesystem or a swap unit for this swap area. If a more specific unit is needed, a custom one can be specified in the systemd.units section. The unit will be named with the escaped version of the path or device, depending on the unit type. If your filesystem is located on a Tang-backed LUKS device, the unit will automatically require network access if you specify the device as /dev/mapper/<device-name> or /dev/disk/by-id/dm-name-<device-name>.
files (list of objects): the list of files to be written. Every file, directory and link must have a unique path.
path (string): the absolute path to the file.
overwrite (boolean): whether to delete preexisting nodes at the path. contents must be specified if overwrite is true. Defaults to false.
contents (object): options related to the contents of the file.
compression (string): the type of compression used on the contents (null or gzip). Compression cannot be used with S3.
source (string): the URL of the file contents. Supported schemes are http, https, tftp, s3, gs, and data. When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. If source is omitted and a regular file already exists at the path, Ignition will do nothing. If source is omitted and no file exists, an empty file will be created. Mutually exclusive with inline and local.
inline (string): the contents of the file. Mutually exclusive with source and local.
local (string): a local path to the contents of the file, relative to the directory specified by the --files-dir command-line argument. Mutually exclusive with source and inline.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the file contents.
hash (string): the hash of the config, in the form <type>-<value> where type is either sha512 or sha256.
append (list of objects): list of contents to be appended to the file. Follows the same stucture as contents
compression (string): the type of compression used on the contents (null or gzip). Compression cannot be used with S3.
source (string): the URL of the contents to append. Supported schemes are http, https, tftp, s3, gs, and data. When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. Mutually exclusive with inline and local.
inline (string): the contents to append. Mutually exclusive with source and local.
local (string): a local path to the contents to append, relative to the directory specified by the --files-dir command-line argument. Mutually exclusive with source and inline.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the appended contents.
hash (string): the hash of the config, in the form <type>-<value> where type is either sha512 or sha256.
mode (integer): the file’s permission mode. Setuid/setgid/sticky bits are not supported. If not specified, the permission mode for files defaults to 0644 or the existing file’s permissions if overwrite is false, contents is unspecified, and a file already exists at the path.
user (object): specifies the file’s owner.
id (integer): the user ID of the owner.
name (string): the user name of the owner.
group (object): specifies the file’s group.
id (integer): the group ID of the group.
name (string): the group name of the group.
directories (list of objects): the list of directories to be created. Every file, directory, and link must have a unique path.
path (string): the absolute path to the directory.
overwrite (boolean): whether to delete preexisting nodes at the path. If false and a directory already exists at the path, Ignition will only set its permissions. If false and a non-directory exists at that path, Ignition will fail. Defaults to false.
mode (integer): the directory’s permission mode. Setuid/setgid/sticky bits are not supported. If not specified, the permission mode for directories defaults to 0755 or the mode of an existing directory if overwrite is false and a directory already exists at the path.
user (object): specifies the directory’s owner.
id (integer): the user ID of the owner.
name (string): the user name of the owner.
group (object): specifies the directory’s group.
id (integer): the group ID of the group.
name (string): the group name of the group.
links (list of objects): the list of links to be created. Every file, directory, and link must have a unique path.
path (string): the absolute path to the link
overwrite (boolean): whether to delete preexisting nodes at the path. If overwrite is false and a matching link exists at the path, Ignition will only set the owner and group. Defaults to false.
user (object): specifies the owner for a symbolic link. Ignored for hard links.
id (integer): the user ID of the owner.
name (string): the user name of the owner.
group (object): specifies the group for a symbolic link. Ignored for hard links.
id (integer): the group ID of the group.
name (string): the group name of the group.
target (string): the target path of the link
hard (boolean): a symbolic link is created if this is false, a hard one if this is true.
luks (list of objects): the list of luks devices to be created. Every device must have a unique name.
name (string): the name of the luks device.
device (string): the absolute path to the device. Devices are typically referenced by the /dev/disk/by-* symlinks.
key_file (string): options related to the contents of the key file.
compression (string): the type of compression used on the contents (null or gzip). Compression cannot be used with S3.
source (string): the URL of the key file contents. Supported schemes are http, https, tftp, s3, gs, and data. When using http, it is advisable to use the verification option to ensure the contents haven’t been modified. Mutually exclusive with inline and local.
inline (string): the contents of the key file. Mutually exclusive with source and local.
local (string): a local path to the contents of the key file, relative to the directory specified by the --files-dir command-line argument. Mutually exclusive with source and inline.
http_headers (list of objects): a list of HTTP headers to be added to the request. Available for http and https source schemes only.
name (string): the header name.
value (string): the header contents.
verification (object): options related to the verification of the file contents.
hash (string): the hash of the config, in the form <type>-<value> where type is either sha512 or sha256.
label (string): the label of the luks device.
uuid (string): the uuid of the luks device.
options (list of strings): any additional options to be passed to the cryptsetup utility.
wipe_volume (boolean): whether or not to wipe the device before volume creation, see the Ignition documentation on filesystems for more information.
trees (list of objects): a list of local directory trees to be embedded in the config. Ownership is not preserved. File modes are set to 0755 if the local file is executable or 0644 otherwise. Attributes of files, directories, and symlinks can be overridden by creating a corresponding entry in the files, directories, or links section; such files entries must omit contents and such links entries must omit target.
local (string): the base of the local directory tree, relative to the directory specified by the --files-dir command-line argument.
path (string): the path of the tree within the target system. Defaults to /.
systemd (object): describes the desired state of the systemd units.
units (list of objects): the list of systemd units. Every unit must have a unique name.
name (string): the name of the unit. This must be suffixed with a valid unit type (e.g. “thing.service”).
enabled (boolean): whether or not the service shall be enabled. When true, the service is enabled. When false, the service is disabled. When omitted, the service is unmodified. In order for this to have any effect, the unit must have an install section.
mask (boolean): whether or not the service shall be masked. When true, the service is masked by symlinking it to /dev/null.
contents (string): the contents of the unit.
dropins (list of objects): the list of drop-ins for the unit. Every drop-in must have a unique name.
name (string): the name of the drop-in. This must be suffixed with “.conf”.
contents (string): the contents of the drop-in.
passwd (object): describes the desired additions to the passwd database.
users (list of objects): the list of accounts that shall exist. All users must have a unique name.
name (string): the username for the account.
password_hash (string): the hashed password for the account.
ssh_authorized_keys (list of strings): a list of SSH keys to be added as an SSH key fragment at .ssh/authorized_keys.d/ignition in the user’s home directory. All SSH keys must be unique.
uid (integer): the user ID of the account.
gecos (string): the GECOS field of the account.
home_dir (string): the home directory of the account.
no_create_home (boolean): whether or not to create the user’s home directory. This only has an effect if the account doesn’t exist yet.
primary_group (string): the name of the primary group of the account.
groups (list of strings): the list of supplementary groups of the account.
no_user_group (boolean): whether or not to create a group with the same name as the user. This only has an effect if the account doesn’t exist yet.
no_log_init (boolean): whether or not to add the user to the lastlog and faillog databases. This only has an effect if the account doesn’t exist yet.
shell (string): the login shell of the new account.
should_exist (boolean) whether or not the user with the specified name should exist. If omitted, it defaults to true. If false, then Ignition will delete the specified user.
system (bool): whether or not this account should be a system account. This only has an effect if the account doesn’t exist yet.
groups (list of objects): the list of groups to be added. All groups must have a unique name.
name (string): the name of the group.
gid (integer): the group ID of the new group.
password_hash (string): the hashed password of the new group.
should_exist (boolean) whether or not the group with the specified name should exist. If omitted, it defaults to true. If false, then Ignition will delete the specified group.
system (bool): whether or not the group should be a system group. This only has an effect if the group doesn’t exist yet.
kernel_arguments (object): describes the desired kernel arguments.
should_exist (list of strings): the list of kernel arguments that should exist.
should_not_exist (list of strings): the list of kernel arguments that should not exist.