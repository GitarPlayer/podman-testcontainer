# Use Red Hat UBI 9 as the base
FROM quay.io/podman/stable

LABEL description="imagebuilder image with buildah and tools to build images" 

USER root

ENV TZ="Europe/Zurich"
ENV HELM_VERSION="v3.14.4"
WORKDIR /home/build/



# Install essential packages, skipping cert addition
# RUN dnf install -y \
#       nss-tools \
#       jq \
#       buildah \
#       skopeo \
#       git \
#       file \
#       procps-ng \
#       zip \
#       unzip 

RUN dnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y java-21-openjdk-headless maven podman-remote jq && \
    chmod -R 770 /home/build/ && \
    chgrp -R 0 /home/build/ && \    
    chown -R 1000 /home/build/ && \  
    sed -i 's/driver = "overlay"/driver = "vfs"/' /etc/containers/storage.conf && \  
     mkdir -p /home/build/.config/containers && \  
    (echo '[storage]';echo 'driver = "overlay"') > /home/build/.config/containers/storage.conf && \  
    sed -i 's/# log_level = "7"/log_level = "4"/' /etc/containers/storage.conf 

ENV JAVA_HOME="/usr/lib/jvm/jre" \
    JAVA_VERSION="21" \
    JAVA_VENDOR="openjdk" \
    PATH="${JAVA_HOME}/bin:${PATH}"

# do the buildah stuff here

# RUN mkdir -pv /var/tmp/containers/storage && \
#     chmod -R 777 /var/tmp/containers/storage && \
#     groupadd -g 53967 build && \
#     useradd -u 53967 -g 53967 -m build && \
#     mkdir -pv /home/build/.local/share/containers 
#     #&& chown -R build:build /home/build/.local
    
# RUN chown -R 53967:build /home/build /var/tmp/containers/storage && \
#     echo build:60000:65536 > /etc/subuid && \
#     echo build:60000:65536 > /etc/subgid && \
#     mkdir -p /home/build/.config/containers && \
#     (echo '[storage]';echo 'driver = "overlay"') > /home/build/.config/containers/storage.conf && \
#     sed -i 's/# log_level = "7"/log_level = "4"/' /etc/containers/storage.conf 

# RUN sed -i 's|# rootless_storage_path = "$HOME/.local/share/containers/storage"|rootless_storage_path = "/var/tmp/containers/storage"|' /etc/containers/storage.conf && \
#     echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc && \
#     echo "[[registry]]" >/etc/containers/registries.conf.d/rchregistry.conf && \
#     echo 'location = "image-repo:5000"' >>/etc/containers/registries.conf.d/rchregistry.conf && \
#     echo "insecure = true" >>/etc/containers/registries.conf.d/rchregistry.conf && \
#     chown -R build:build /home/build/.local && \
#     # cosign binary
#     curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64" && \
#     mv cosign-linux-amd64 /usr/local/bin/cosign && \
#     chmod +x /usr/local/bin/cosign && \
#     yum -y update && \
#     # yq binary
#     BINARY=yq_linux_amd64 && \
#     LATEST=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep browser_download_url | grep yq_linux_amd64 | grep -v "tar.gz" | cut -d '"' -f 4 ) && \
#     curl -fsSL "$LATEST" -o /usr/local/bin/yq && \
#     chmod +x /usr/local/bin/yq && \
#     # podman prereqs
#     mkdir /.config /.kube /.cache && \
#     chmod 777 /.config /.kube /.cache && \
#     chown 53967 /.config /.kube /.cache && \
#     # skopeo
#     mkdir /run/containers && \
#     chmod -R 777 /run/containers && \
#     # buildah
#     pwd && \
#     id && \
#     ls -al /home/build/.local/share/ && \
#     chown -R 53967 /home/build/ && \
#     ls -aln /home/ && \
#     cat /etc/passwd && \

#     # cleanup the system
#     yum clean all && \
#     rm -rf /etc/pki/entitlement/* 
RUN groupadd -g 53967 build && \
    useradd -u 53967 -g 53967 -m build
RUN echo "podman:1:999" > /etc/subuid && \
    echo "podman1001:5999" >>/etc/subuid && \
    echo "build:60000:65536" >> /etc/subuid && \
    echo "podman:1:999" > /etc/subgid && \
    echo "podman1001:5999" >>/etc/subgid && \
    echo "build:60000:65536" >> /etc/subgid 

USER 1001