# Openshift Container runtimes
This document will discuss the cri-o container runtime that OpenShift can use. It will also discuss the tools that work with CRI-O such as buildah and podman.

## CRI-O
CRI-O is a lightweight alternative to using Docker as the runtime for Kubernetes. It allows Kubernetes to use any OCI-compliant runtime as the container runtime for running pods.
[cri-o.io](https://cri-o.io/)

The CRI-O container engine provides a stable, more secure, and performant platform for running Open Container Initiative (OCI) compatible runtimes. You can use the CRI-O container engine to launch containers and pods by engaging OCI-compliant runtimes like runc, the default OCI runtime, or Kata Containers. CRI-O’s purpose is to be the container engine that implements the Kubernetes Container Runtime Interface (CRI) for OpenShift Container Platform and Kubernetes, replacing the Docker service.

[Using the CRI-O Container Engine](https://docs.openshift.com/container-platform/3.11/crio/crio_runtime.html)


**CRI-O  architectural components:**

* Kubernetes contacts the kubelet to launch a pod.
  * Pods are a kubernetes concept consisting of one or more containers sharing the same IPC, NET and PID namespaces and living in the same cgroup.
* The kublet forwards the request to the CRI-O daemon VIA kubernetes CRI (Container runtime interface) to launch the new POD.
* CRI-O uses the containers/image library to pull the image from a container registry.
* The downloaded image is unpacked into the container’s root filesystems, * stored in COW file systems, using containers/storage library.
* After the rootfs has been created for the container, CRI-O generates an OCI runtime specification json file describing how to run the container using the OCI Generate tools.
* CRI-O then launches an OCI Compatible Runtime using the specification to run the container proceses. The default OCI Runtime is runc.
* Each container is monitored by a separate conmon process. The conmon process holds the pty of the PID1 of the container process. It handles logging for the container and records the exit code for the container process.
* Networking for the pod is setup through use of CNI, so any CNI plugin can be used with CRI-O.

**A list of tools used to interact with CRI-O**
* crictl - For troubleshooting and working directly with CRI-O container engines
* runc - For running container images
* podman - For managing pods and container images (run, stop, start, ps, attach, exec, etc.) outside of the container engine
* buildah - For building, pushing and signing container images
* skopeo - For copying, inspecting, deleting, and signing images

## BUILDAH
Buildah is a newer tool to build container images with. One benefit of this tool is that you do not have to have the docker daemon running in the background to build an image.

**Buildah package provides the following functionality:**
* create a working container, either from scratch or using an image as a starting point  
* create an image, either from a working container or via the instructions in a Dockerfile  
* images can be built in either the OCI image format or the traditional upstream docker image format  
* mount a working container's root filesystem for manipulation  
* unmount a working container's root filesystem  
* use the updated contents of a container's root filesystem as a filesystem layer to create a new image  
* delete a working container or an image  
* rename a local container  
[buildah](https://github.com/containers/buildah)

## PODMAN
Podman is a damon-less CLI/API for running, managing and debugging OCI containers and pods. I would like to think of it as a replacement for the docker cli.

**Podman and libpod provides the following:**
* Support multiple image formats including the existing Docker/OCI image formats.  
* Support for multiple means to download images including trust & image verification.  
* Container image management (managing image layers, overlay filesystems, etc).  
* Full management of container lifecycle  
* Support for pods to manage groups of containers together  
* Resource isolation of containers and pods.  
* Integration with CRI-O to share containers and backend code.  
[podman](https://github.com/containers/libpod)

## Example CRI-O Usage
run []./cri-o-example-via-minikube.sh](https://github.com/tosin2013/cri_o_playground/blob/master/cri-o-example-via-minikube.sh) to see cri-o functionality. In order to run script please have minikube already installed.


## Outputs
```
$ minikube logs | grep cri-o
Jan 14 18:56:47 minikube kubelet[2897]: I0114 18:56:47.776932    2897 kuberuntime_manager.go:197] Container runtime cri-o initialized, version: 1.11.8, apiVersion: v1alpha1
```

```
$ kubectl describe pods/$(kubectl get pods | grep nginx | awk '{print $1}') | grep "Container ID:"
Container ID:   cri-o://14e2c777141ad90762651d9887a1b464f4c8e0ab3c181347e09bcd1871c65fdf
```

```
$ minikube ssh "docker ps"
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

```
$ NGINXIP=$(kubectl describe pods/$(kubectl get pods | grep nginx | awk '{print $1}') | grep IP | awk '{print $2}')
$ minikube ssh "curl -I ${NGINXIP}"
HTTP/1.1 200 OK
Server: nginx/1.15.8
Date: Mon, 14 Jan 2019 19:21:55 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Dec 2018 09:56:47 GMT
Connection: keep-alive
ETag: "5c21fedf-264"
Accept-Ranges: bytes
```
```
$ minikube ssh "sudo runc list "
ID                                                                 PID         STATUS      BUNDLE                                                                                                                 CREATED                          OWNER
09ed56c218cb758a2e2947eaf9050496906bdcdc2c3f3317a4084e6b425d3d36   3187        running     /run/containers/storage/overlay-containers/09ed56c218cb758a2e2947eaf9050496906bdcdc2c3f3317a4084e6b425d3d36/userdata   2019-01-14T18:57:02.915424082Z   root
...
```

## Example buildah Usage
see build-example.sh for explanation of examples below.
```
$ buildah from fedora
Getting image source signatures
Copying blob sha256:e1736333d4050f3323b7c71d7e7aa9af69650b6c7e1edc4e8874e6ce004a1a7f
 85.71 MiB / 85.71 MiB [===================================================] 11s
Copying config sha256:8bd04269a51be87e39303d97c8f645a39016fcc2bd235e41812e0cfb96b283e3
 2.20 KiB / 2.20 KiB [======================================================] 0s
Writing manifest to image destination
Storing signatures
fedora-working-container

```

```
$ buildah from fedora
Getting image source signatures
Copying blob sha256:e1736333d4050f3323b7c71d7e7aa9af69650b6c7e1edc4e8874e6ce004a1a7f
 85.71 MiB / 85.71 MiB [===================================================] 11s
Copying config sha256:8bd04269a51be87e39303d97c8f645a39016fcc2bd235e41812e0cfb96b283e3
 2.20 KiB / 2.20 KiB [======================================================] 0s
Writing manifest to image destination
Storing signatures
fedora-working-container
```

```
$ buildah run $(buildah containers | grep fedora | awk '{print $1}') -- dnf -y install nodejs
Fedora 29 - x86_64                              5.0 MB/s |  62 MB     00:12    
Last metadata expiration check: 0:00:14 ago on Mon Jan 14 22:26:39 2019.
Dependencies resolved.
================================================================================
Package          Arch        Version                        Repository    Size
================================================================================
Installing:
nodejs           x86_64      1:10.15.0-1.fc29               updates      6.3 M
Installing dependencies:
http-parser      x86_64      2.9.0-1.fc29                   updates       35 k
libicu           x86_64      62.1-3.fc29                    updates      8.8 M
libuv            x86_64      1:1.23.2-1.fc29                updates      122 k
Installing weak dependencies:
npm              x86_64      1:6.4.1-1.10.15.0.1.fc29       updates      3.6 M

Transaction Summary
================================================================================
Install  5 Packages

Total download size: 19 M
Installed size: 76 M
Downloading Packages:
(1/5): http-parser-2.9.0-1.fc29.x86_64.rpm       29 kB/s |  35 kB     00:01    
(2/5): libuv-1.23.2-1.fc29.x86_64.rpm            94 kB/s | 122 kB     00:01    
(3/5): npm-6.4.1-1.10.15.0.1.fc29.x86_64.rpm    2.3 MB/s | 3.6 MB     00:01    
(4/5): libicu-62.1-3.fc29.x86_64.rpm            2.7 MB/s | 8.8 MB     00:03    
(5/5): nodejs-10.15.0-1.fc29.x86_64.rpm         2.3 MB/s | 6.3 MB     00:02    
--------------------------------------------------------------------------------
Total                                           3.5 MB/s |  19 MB     00:05     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
Running scriptlet: npm-1:6.4.1-1.10.15.0.1.fc29.x86_64                    1/1
Preparing        :                                                        1/1
Installing       : libuv-1:1.23.2-1.fc29.x86_64                           1/5
Installing       : libicu-62.1-3.fc29.x86_64                              2/5
Running scriptlet: libicu-62.1-3.fc29.x86_64                              2/5
Installing       : http-parser-2.9.0-1.fc29.x86_64                        3/5
Installing       : npm-1:6.4.1-1.10.15.0.1.fc29.x86_64                    4/5
Installing       : nodejs-1:10.15.0-1.fc29.x86_64                         5/5
Running scriptlet: nodejs-1:10.15.0-1.fc29.x86_64                         5/5
Verifying        : http-parser-2.9.0-1.fc29.x86_64                        1/5
Verifying        : libicu-62.1-3.fc29.x86_64                              2/5
Verifying        : libuv-1:1.23.2-1.fc29.x86_64                           3/5
Verifying        : nodejs-1:10.15.0-1.fc29.x86_64                         4/5
Verifying        : npm-1:6.4.1-1.10.15.0.1.fc29.x86_64                    5/5

Installed:
nodejs-1:10.15.0-1.fc29.x86_64       npm-1:6.4.1-1.10.15.0.1.fc29.x86_64     
http-parser-2.9.0-1.fc29.x86_64      libicu-62.1-3.fc29.x86_64               
libuv-1:1.23.2-1.fc29.x86_64        

Complete!


```

```
$ buildah run $(buildah containers | grep fedora | awk '{print $1}') npm -version
6.4.1
```

## Example podman Usage
see build-example.sh for explanation of examples below.
```
$ podman run -it rhel sh
Trying to pull docker.io/rhel:latest...Failed
Trying to pull registry.fedoraproject.org/rhel:latest...Failed
Trying to pull quay.io/rhel:latest...Failed
Trying to pull registry.access.redhat.com/rhel:latest...Getting image source signatures
Copying blob sha256:23113ae36f8e9d98b1423e44673979132dec59db2805e473e931d83548b0be82
 72.21 MB / 72.21 MB [======================================================] 8s
Copying blob sha256:d134b18b98b0d113b7b1194a60efceaa2c06eff41386d6c14b0e44bfe557eee8
 1.19 KB / 1.19 KB [========================================================] 0s
Copying config sha256:5edf42cf4ed898acd4d920c02ab8c69fe4d5b744d9197aea9b4a0918d68a2a32
 6.18 KB / 6.18 KB [========================================================] 0s
Writing manifest to image destination
Storing signatures
sh-4.2#
```

```
$ podman ps -a
CONTAINER ID  IMAGE                                   COMMAND  CREATED        STATUS                      PORTS  NAMES
20924891870b  registry.access.redhat.com/rhel:latest  sh       2 minutes ago  Exited (127) 7 seconds ago         nervous_wright

```

```
$ sudo podman run -t -p 8000:80 nginx
[sudo] password for takinosho:
Sorry, try again.
[sudo] password for takinosho:
Trying to pull docker.io/nginx:latest...Getting image source signatures
Copying blob sha256:177e7ef0df6987e0c5738a1fb5aba98b6b6e7a5fef992e481977dbb5ba3f91be
 21.45 MB / 21.45 MB [======================================================] 3s
Copying blob sha256:ea57c53235dfe1ae1db219ca7cda6210c8f875367bcb892fdc6d86c047174f3d
 21.20 MB / 21.20 MB [======================================================] 3s
Copying blob sha256:bbdb1fbd4a86c36dbc219ff18eba7a332d7a41a4101731874da06a708d4db2f9
 204 B / 204 B [============================================================] 0s
Copying config sha256:7042885a156a01cc99e5a531f41ff47ea2facf655d4fc605aa80b216489586a4
 5.88 KB / 5.88 KB [========================================================] 0s
Writing manifest to image destination
Storing signatures
10.88.0.1 - - [14/Jan/2019:22:48:23 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.61.1" "-"\

```

```
ps aux | grep podman
root     24524  0.0  0.2 256752 11152 pts/0    S+   17:43   0:00 sudo podman run -t -p 8000:80 nginx
root     24539  1.3  0.9 1715764 38348 pts/0   Sl+  17:43   0:12 podman run -t -p 8000:80 nginx
root     24721  0.0  0.0  77844  2072 ?        Ssl  17:43   0:00 /usr/libexec/podman/conmon -s -c dee0dc0dd74ebaea1a28b17087d3833db2a516bf7723b53af81803c1663ccbfa -u dee0dc0dd74ebaea1a28b17087d3833db2a516bf7723b53af81803c1663ccbfa -r /usr/sbin/runc -b /var/lib/containers/storage/overlay-containers/dee0dc0dd74ebaea1a28b17087d3833db2a516bf7723b53af81803c1663ccbfa/userdata -p /var/run/containers/storage/overlay-containers/dee0dc0dd74ebaea1a28b17087d3833db2a516bf7723b53af81803c1663ccbfa/userdata/pidfile -l /var/lib/containers/storage/overlay-containers/dee0dc0dd74ebaea1a28b17087d3833db2a516bf7723b53af81803c1663ccbfa/userdata/ctr.log --exit-dir /var/run/libpod/exits --socket-dir-path /var/run/libpod/socket -t --log-level error
takinos+ 25702  0.0  0.0 215744   832 pts/1    S+   17:59   0:00 grep --color=auto podman
```


## Additional links
[OpenShift Container Platform 3.11 CRI-O Runtime Guide](https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/)  
[CRI-O Command Line Interface: crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)  
[runc](https://github.com/opencontainers/runc)  
[skopeo](https://github.com/containers/skopeo)  
[Getting started with Buildah](https://opensource.com/article/18/6/getting-started-buildah)  
[Intro to Podman (Red Hat Enterprise Linux 7.6 Beta)](https://developers.redhat.com/blog/2018/08/29/intro-to-podman/)

## Known Issues
[minishift and cri-o runtime does not work](https://github.com/minishift/minishift/issues/3120)
