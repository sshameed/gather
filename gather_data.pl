#!/usr/bin/perl -w
# gather_data.pl, v 0.95, 11-9-2021, subin.hameed@mdxsolutions-me.com
# Gather FlexFrame information, run individually on all control nodes, hypervisor nodes and application nodes.

use Sys::Hostname;
use File::Copy;

$host = hostname;
$outputfile= "$host" . "_gather_data_pl" . ".log";
$outputfileold= "$outputfile" . ".old";

sub check_file_exists() {
  if (-f "$_[0]") {
    return 1;
  } else {
    return 0;
  }
}

sub run_command_and_save_output() {
  # this subroutine does following:
  # a. if argument doesn't contain leading "/", execute it
  # b. if argument contains leading "/", check if file exists
  # if file exists, execute it, else exit from subroutine

  # copy subroutine arguments (which is a command with options) in to a scalar
  @arglist=@_;
  $shellcmd=$arglist[0];
  $shellcmdwithargs=join(" ",@arglist);
  # check if shellcmd is an absolute path
  $_=$shellcmd;
  if ( m{^/} ) {
  # absolute path, check if file exists
    if (-f "$shellcmd") {
    # file exists
    } else {
      # file does not exist, return from subroutine
      print "Error: File $shellcmd does not exist.\n";
      return;
    }
  }
  print "Info: executing $shellcmdwithargs\n";
  @cmdoutput=`$shellcmdwithargs`;
  open(FH, ">>", $outputfile) or die "couldn't open outputfile $outputfile";
  print FH "cmd: $shellcmdwithargs\n";
  print FH @cmdoutput;
  close FH;
}

# main
# 
# collect hypervisor data unless it is a control node
$collect_hypervisor_data=1;
# 
# check if OS is Linux
if ($^O ne "linux") {
  die "Error: $0 should be run only on $^O";
}
# check if program is run as root user
if ($< != 0) {
  die "Error: $0 should be run as root";
}

print "Gathering FlexFrame data on host $host ...\n";
# if output file exists, move it to filename with prefix ".old"

if (-f "$outputfile") {
  move("$outputfile","$outputfileold");
}

##
if (&check_file_exists("/etc/os-release")) {
  &run_command_and_save_output("cat /etc/os-release");
  $osdist="suse";
}
##
if (&check_file_exists("/etc/SuSE-release")) {
  &run_command_and_save_output("cat /etc/SuSE-release");
  $osdist="suse";
}
#
##
if (&check_file_exists("/etc/redhat-release")) {
  &run_command_and_save_output("cat /etc/redhat-release");
  $osdist="redhat";
}
#
# FlexFrame Control node commands
if (&check_file_exists("/etc/FlexFrame-release")) {
  print "$host is a control node.\n";
  $collect_hypervisor_data=0;
  &run_command_and_save_output("cat /etc/FlexFrame-release");
}

# FlexFrame and LDAP client commands
&run_command_and_save_output("/opt/FlexFrame/bin/ff_identifier.sh","-l");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_swgroup_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_list_services.sh","-o nodes");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_list_services.sh");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_an_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_an_adm.pl","--op list-images");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_ha_cmd.sh","status");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_swport_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_pool_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_nas_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_sid_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_hn_adm.pl","--op list-all");
&run_command_and_save_output("/opt/FlexFrame/bin/ff_vm.pl","--op list-all");
&run_command_and_save_output("getent passwd");
&run_command_and_save_output("getent group");
&run_command_and_save_output("getent hosts");
&run_command_and_save_output("getent services");
&run_command_and_save_output("getent networks");

# Hypervisor commands
if ($collect_hypervisor_data) {
  &run_command_and_save_output("/usr/bin/virsh","-r list");
  &run_command_and_save_output("/usr/bin/virsh","-r list --all");
  &run_command_and_save_output("/usr/bin/virsh","-r pool-list");
}
# distribution specific commands
if ($osdist eq "redhat") {
  &run_command_and_save_output("yum repolist");
  &run_command_and_save_output("ls /etc/yum.repos.d");
  &run_command_and_save_output("cat /etc/yum.repos.d/*");
  &run_command_and_save_output("ls /etc/sysconfig/network-scripts/ifcfg*");
  &run_command_and_save_output("cat /etc/sysconfig/network-scripts/ifcfg*");
  &run_command_and_save_output("ls /var/spool/cron");
  &run_command_and_save_output("cat /var/spool/cron/*");
}

if ($osdist eq "suse") {
  &run_command_and_save_output("zypper lr");
  &run_command_and_save_output("ls /etc/zypp/repos.d");
  &run_command_and_save_output("cat /etc/zypp/repos.d/*");
  &run_command_and_save_output("ls /etc/sysconfig/network/ifcfg*");
  &run_command_and_save_output("cat /etc/sysconfig/network/ifcfg*");
  &run_command_and_save_output("ls /var/spool/cron/tabs");
  &run_command_and_save_output("cat /var/spool/cron/tabs/*");
}
# General UNIX commands to run on all nodes
&run_command_and_save_output("uname -a");
&run_command_and_save_output("date");
&run_command_and_save_output("ip a s");
&run_command_and_save_output("netstat -rn");
&run_command_and_save_output("netstat -anp");
&run_command_and_save_output("ps -ef");
&run_command_and_save_output("rpm -qa");
#&run_command_and_save_output("rpm -V -a");
&run_command_and_save_output("cat /etc/passwd");
&run_command_and_save_output("cat /etc/group");
&run_command_and_save_output("cat /etc/hosts");
&run_command_and_save_output("cat /etc/fstab");
&run_command_and_save_output("cat /etc/auto.master");
&run_command_and_save_output("cat /etc/sysctl.conf");
&run_command_and_save_output("ls /usr/lib/sysctl.d");
&run_command_and_save_output("cat /usr/lib/sysctl.d/*");
&run_command_and_save_output("ls /usr/lib/sysctl.d");
&run_command_and_save_output("cat /usr/lib/sysctl.d/*");
&run_command_and_save_output("ls /etc/sysctl.d");
&run_command_and_save_output("cat /etc/sysctl.d/*");
&run_command_and_save_output("sysctl -a");
&run_command_and_save_output("cat /proc/net/vlan/config");
&run_command_and_save_output("swapon -s");
&run_command_and_save_output("ls /");
&run_command_and_save_output("dmidecode -t system");
&run_command_and_save_output("lspci");
&run_command_and_save_output("lsmod");
&run_command_and_save_output("blkid");
&run_command_and_save_output("mount");
&run_command_and_save_output("df -h");
&run_command_and_save_output("parted -l -s");
&run_command_and_save_output("ls /boot");
&run_command_and_save_output("ls /boot/grub");
&run_command_and_save_output("ls /boot/grub2");
&run_command_and_save_output("lsblk -fp");
if (&check_file_exists("/boot/grub/menu.lst")) {
  &run_command_and_save_output("cat /boot/grub/menu.lst");
}
#
if (&check_file_exists("/boot/grub2/grub.cfg")) {
  &run_command_and_save_output("cat /boot/grub2/grub.cfg");
}
#
&run_command_and_save_output("/sbin/chkconfig","--list","2>&1");
&run_command_and_save_output("/usr/bin/systemctl","list-unit-files");
&run_command_and_save_output("/usr/bin/systemctl","--no-pager");

if (&check_file_exists("/proc/net/bonding/bond0")) {
  &run_command_and_save_output("cat /proc/net/bonding/bond0");
}

if (&check_file_exists("/proc/net/bonding/bond1")) {
  &run_command_and_save_output("cat /proc/net/bonding/bond1");
}

print "Finished gathering FlexFrame data on host $host.\n";
print "Please download output file $outputfile to a safe place.\n";
