# Docker Workspace

The goal of this project is to provide a clean and easy development environment that supports all kinds of docker-composerised projects.

## How does it work?
The docker-compose file included in this repository fires up an nginx-proxy server together with the let's encrypt companion. This handles all traffic on port 80, and passes it on to other containers, making it possible to access multiple containers via the same port (80/443).

The Let's encrypt companion adds https support. Let's encrypt is not actually used, we just use the logic from this container, generate certificates via mkcert and sync them to the container.

This is all done in the start.sh script.

- https://github.com/nginx-proxy/nginx-proxy
- https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion
- https://github.com/FiloSottile/mkcert


## Use
When your docker-compose file is located in the `sites/example` folder, run this:
Run `sh start.sh example` 

The start.sh script will also search for a `sites/example/config.init.sh` script and execute it when it's found.

## Setup
1. Install [mkcert](https://github.com/FiloSottile/mkcert).</br>
	*1.1* Run ```brew install mkcert``` (for Firefox: ```brew install nss```)</br>
2. Install and configure dnsmasq</br>
	*2.1* Run ```brew install dnsmasq```</br>
	*2.2* Run```nano $(brew --prefix)/etc/dnsmasq.conf```</br>
	*2.3* Add the contents below to the top of the file
	```
	# --- Added by mklasen
	# Route all *.test addresses to localhost
	address=/test/127.0.0.1
	# Don't read /etc/resolv.conf or any other configuration files.
	no-resolv
	# Never forward plain names (without a dot or domain part)
	domain-needed
	# Never forward addresses in the non-routed address spaces.
	bogus-priv
	# ----
	```
	*2.4* Run ```sudo mkdir /etc/resolver```</br>
	*2.5* Run ```sudo nano /etc/resolver/test```</br>
	*2.6* Add the contents below to the file</br>
	```nameserver 127.0.0.1```</br>
	*2.7* Run```sudo brew services start dnsmasq```<br/>
3. Create a docker network: `docker network create nginx-proxy`
4. Run `docker-compose up`
5. Setup your own project in `sites/`
6. Run `npm run start example`

## Dependencies
- dnsmasq
- mkcert
- npm