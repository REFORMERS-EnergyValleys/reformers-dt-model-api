FROM sonatype/nexus3:3.70.3

# Install jq for parsing JSON
ADD --chmod=111 https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64 /usr/local/bin/jq

# Copy installation script
COPY --chmod=755 init-nexus3-repo.sh /setup/init-nexus3-repo.sh

ENTRYPOINT [ "/bin/bash", "-c", "/setup/init-nexus3-repo.sh" ]
