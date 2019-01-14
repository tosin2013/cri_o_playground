# The below examples will run on fedora
# install podman
sudo dnf -y install podman

# Run rhel container from using podman CLI
podman run -it rhel sh

# Show running Containers
podman ps

# Show stopped  Containers
podman ps -a

#run as an nginx continaer using podman cli
sudo podman run -t -p 8000:80 nginx

#in new terminal
curl http://localhost:8000
