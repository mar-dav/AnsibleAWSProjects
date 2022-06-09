#! /bin/bash

#Install Java
 yum install java-1.8.0-openjdk.x86_64 -y

#Download & Install Jenkins
yum update -y
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install jenkins -y


#make jenkins start on boot
chkconfig jenkins on

#Start Jenkins
service jenkins start

#Enable Jenkins with systemctl
systemctl start jenkins

#Make Jenkins persistent
systemctl enable jenkins

#Install Git SCM
yum install git -y

# Make sur eJenkins comes up/on when reboot
chkconfig jenkins on