Rivendell & Docker
==================

**How to use:**

* Install docker
* Clone this repo; cd into it
* Create an image in Docker: `docker build -t rivendell .` (this step takes about 20 minutes)
* Start a new container using the image: `docker run -d -p 5900 -p 8000 -p 22 rivendell`

**Access:**

After using the exact commands above, `docker ps` will show you what ports on the docker host have been mapped to the container. Of course, you can use `-p hostport:containerport` like `-p 666:22` to specify what ports to use.

**SSH** *- exposed on port 22:* Username & password is **rduser**.

**VNC** *- exposed on port 5900:* Password is **rduser**

**Icecast** *- exposed on port 8000:* Admin panel is username **admin** password **rduser**. (No authorization needed to simply view streams.)

Known Issues
============

* Clicking 'Add' on the rdairplay window created by default causes the window to close. After bringing up another window (through xterm), the button functions normally.
* Apache occasionally needs a manual restart after the container is started. This *should* be fixed

Included packages
=================

* Rivendell - http://www.rivendellaudio.org/
* Jackd - http://jackaudio.org/
* Edcast for jackd - (and older version of) https://code.google.com/p/edcast-reborn/
* Icecast - http://icecast.org/
* Jamin - http://jamin.sourceforge.net/
* MySQL