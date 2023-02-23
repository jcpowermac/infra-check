FROM registry.access.redhat.com/ubi8/ubi:8.7-1090
RUN curl -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.12.5/openshift-client-linux-4.12.5.tar.gz
RUN dnf install -y iputils.x86_64 jq python39
RUN tar xf openshift-client-linux-4.12.5.tar.gz
COPY run.sh .

CMD ./run.sh