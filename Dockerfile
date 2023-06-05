FROM registry.access.redhat.com/ubi8/ubi:8.7-1090
RUN dnf install -y iputils.x86_64 jq python39 wget
RUN wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.12/openshift-client-linux.tar.gz
RUN tar -xvf openshift-client-linux.tar.gz
COPY run.sh .
COPY network-check.sh .

CMD ./run.sh
