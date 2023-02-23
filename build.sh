podman build . --tag quay.io/<repo>/cluster-health:latest
podman push --authfile <your-auth> quay.io/<repo>/cluster-health:latest