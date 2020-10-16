# Docker Workspace

The goal of this project is to provide a clean and easy development environment that supports all kinds of projects.

## How does it work?
The docker-compose file included in this repository fires up an nginx-proxy server together with the let's encrypt companion. This handles all traffic on port 80, and passes it on to other containers, making it possible to access multiple containers via the same port (80/443).

The Let's encrypt companion adds https support. We don't actually use Let's encrypt since it's local development, but why reinvent the wheel, right?

In this case mkcert is used to generate ssl certificates for local environments. These are then copied to the certificates folder in nginx-proxy.

This is all done in the start.sh script.

- https://github.com/nginx-proxy/nginx-proxy
- https://github.com/nginx-proxy/docker-letsencrypt-nginx-proxy-companion
- https://github.com/FiloSottile/mkcert


## Use
When your docker-compose file is located in the sites/wp-test folder, run this:
Run `sh start.sh wp-test` 

## Setup
1. Install mkcert (see https://github.com/FiloSottile/mkcert)
2. Setup dnsmasq (follow the first part of this guide: https://mklasen.com/general/wildcard-subdomains-in-mamp-pro-on-macos/)
3. Create a docker network: `docker network create nginx-proxy`
4. Run `docker-compose up`
5. Create a sites folder
6. Create a project folder in sites, and add your docker-compose file
7. Run `sh start.sh project-folder`

## Dependencies
- dnsmasq
- mkcert