#!/bin/bash

# this script will setup the VPN controller box for the first time, and create necessary files.
target="192.168.0.6"

function update_e {

expect -c '
puts ""
puts "Checking VPN endpoint versions..."

log_user 1
spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vyos@'$target'
set timeout 1

proc update_fun {} {
	puts ""
	puts "please wait,this make take a few minutes."
	puts "updating to latest version..."
	puts ""
send "\r"
expect "~$ "
set timeout 180
send "add system image http://packages.vyos.net/iso/release/1.1.7/vyos-1.1.7-amd64.iso\r"

expect "\[no\] "
send "yes\r"

expect ": "
send "\r"

expect ": "
send "\r"

expect ": "
send "\r"

	puts "Done!!"

expect "~$ "
send "exit\r"
	
	}

expect {
	timeout {puts "connection timed out"; exit}
	"connection refused" exit
	"unknown host" exit
	"no route" exit
	"~$ "
	}
expect "~$ "
send "show system image\r"

expect -re {.*VyOS-(\d+\.\d+\.\d+?)} {

set output $expect_out(1,string)
}

if {![info exists output]} {
	puts ""
	puts "Vyos is out of date..."
	set running [update_fun]

} elseif {$output == "1.1.7"} {
	puts ""
	puts "Vyos is up to date with version $output"
	
} else {
	puts ""
	puts "Vyos is out of date..."
	set running [update_fun]
}
'
}


if [ -f "healthcheck.key" ]
then 
	echo "SSH keys have already been created..."
	ssh -A -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $target
	ssh-add healthcheck.key
	echo "Setting up VPN endpoints with SSH keys..."
	update_e
else
	echo "creating SSH keypair for VPN healthchecks..."
	ssh-keygen -t rsa -b 1024 -N "" -f healthcheck.key
	ssh -A -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $target
	ssh-add healthcheck.key 
	cat healthcheck.key.pub | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vyos@$target 'sudo cat - >> .ssh/authorized_keys'
	update_e
fi
