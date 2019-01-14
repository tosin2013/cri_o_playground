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


## Example podman Usage

## Additional links
[OpenShift Container Platform 3.11 CRI-O Runtime Guide](https://access.redhat.com/documentation/en-us/openshift_container_platform/3.11/html/cri-o_runtime/)  
[CRI-O Command Line Interface: crictl](https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md)  
[runc](https://github.com/opencontainers/runc)  
[skopeo](https://github.com/containers/skopeo)  


## Known Issues
[minishift and cri-o runtime does not work](https://github.com/minishift/minishift/issues/3120)
