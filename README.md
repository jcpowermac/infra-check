# infra-check

Verifies the connectivity of networks from the perspecitive of a kubernetes cluster.

## Building

~~~
./build.sh
~~~

## Deploying

~~~
oc create namespace infra-check
oc create -f pvc.yaml -n infra-check
oc create -f deployment.yaml -n infra-check
~~~