Rivendell & Docker
==================

**How to use:**

* Install docker
* Clone this repo
* docker compose -f "docker-rivendell/docker-compose.yml" up -d --build

**Access:**

Login using Microsoft Remote Desktop Protocol (RDP). accepts connections from a variety of RDP clients:
  * FreeRDP
  * rdesktop
  * KRDC
  * NeutrinoRDP
  * Microsoft Remote Desktop (found on Microsoft Store, which is distinct from MSTSC)

Many of these work on some or all of Windows, Mac OS, iOS, and/or Android.

Default user/pass: rduser/rduser

Description
=======================

* Base OS is Rocky Linux 9.1
* Rivendell v4
* Jack Audio
* Audio Output redirection using the xrdp_pulseaudio module: https://github.com/neutrinolabs/pulseaudio-module-xrdp
* Folder redirecton client to server
