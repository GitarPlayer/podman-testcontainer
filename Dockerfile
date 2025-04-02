# Use Red Hat UBI 9 as the base
FROM registry.access.redhat.com/ubi9:latest

LABEL description="imagebuilder image with buildah and tools to build images" \
      baseimage="ubi9" \
      imageversion="v1.39.3"

USER root

ENV TZ="Europe/Zurich"
ENV HELM_VERSION="v3.14.4"


# Install essential packages, skipping cert addition
RUN dnf install -y \
      nss-tools \
      jq \
      podman \
      buildah \
      skopeo \
      git \
      file \
      procps-ng \
      zip \
      unzip 
# do the buildah stuff here

RUN mkdir -pv /var/tmp/containers/storage && \
    chmod -R 777 /var/tmp/containers/storage && \
    groupadd -g 53967 build && \
    useradd -u 53967 -g 53967 -m build && \
    mkdir -pv /home/build/.local/share/containers 
    #&& chown -R build:build /home/build/.local
    
RUN chown -R 53967:build /home/build /var/tmp/containers/storage \
    && echo build:60000:65536 > /etc/subuid \
    && echo build:60000:65536 > /etc/subgid \
    # Use VFS since fuse does not work
    #&& sed -i 's/driver = "overlay"/driver = "vfs"/' /etc/containers/storage.conf \
    && mkdir -p /home/build/.config/containers \
    && (echo '[storage]';echo 'driver = "overlay"') > /home/build/.config/containers/storage.conf \
    && sed -i 's/# log_level = "7"/log_level = "4"/' /etc/containers/storage.conf 

RUN sed -i 's|# rootless_storage_path = "$HOME/.local/share/containers/storage"|rootless_storage_path = "/var/tmp/containers/storage"|' /etc/containers/storage.conf \
    # Use chroot since the default runc does not work when running rootless
    #&& echo "export BUILDAH_ISOLATION=chroot" >> /etc/bashrc \
    && echo "export BUILDAH_ISOLATION=chroot" >> /home/build/.bashrc \
    # allow insecure connection to local registry in namespace (for testing)
    && echo "[[registry]]" >/etc/containers/registries.conf.d/rchregistry.conf \
    && echo 'location = "image-repo:5000"' >>/etc/containers/registries.conf.d/rchregistry.conf \
    && echo "insecure = true" >>/etc/containers/registries.conf.d/rchregistry.conf \
   && chown -R build:build /home/build/.local \

    # cosign binary
    && curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64" \
    && mv cosign-linux-amd64 /usr/local/bin/cosign \
    && chmod +x /usr/local/bin/cosign \
    # Update packages
    && yum -y update \
    # Install cekit
    && yum -y install cekit \
    # yq binary
    && BINARY=yq_linux_amd64 \
    && LATEST=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | grep browser_download_url | grep yq_linux_amd64 | grep -v "tar.gz" | cut -d '"' -f 4 ) \
    && curl -fsSL "$LATEST" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq \
    # helm client
    && curl  -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
      | tar -zxf - -C /usr/local/bin/ \
    && mv /usr/local/bin/helm-linux-amd64 /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    # podman prereqs
    && mkdir /.config /.kube /.cache \
    && chmod 777 /.config /.kube /.cache \
    && chown 53967 /.config /.kube /.cache \
    # skopeo
    && mkdir /run/containers \
    && chmod -R 777 /run/containers \
    # buildah
    && pwd \
    && id \
    && ls -al /home/build/.local/share/ \
    && chown -R 53967 /home/build/ \
    && ls -aln /home/ \
    && cat /etc/passwd \

    # cleanup the system
    && yum clean all \
    && rm -rf /etc/pki/entitlement/*

USER 53967
WORKDIR /home/build/
