# The below examples will run on fedora
# install Buildah:
sudo dnf -y install buildah

# pull and start fedora container image
buildah from fedora

# list containers
buildah containers

# install nodejs
buildah run $(buildah containers | grep fedora | awk '{print $1}') -- dnf -y install nodejs

# Confirm nodejs is installed
buildah run $(buildah containers | grep fedora | awk '{print $1}') -- dnf -y install npm

#login to container
buildah run $(buildah containers | grep fedora | awk '{print $1}') bash
