# infra-check

Verifies the connectivity of networks from the perspecitive of a kubernetes cluster.

## Building

~~~
./build.sh
~~~

## Deploying

~~~bash
oc create namespace infra-check
oc create -f pvc.yaml -n infra-check
oc create -f deployment.yaml -n infra-check
~~~

## Deploying as a liveness probe

Add the following container to an existing pod:

~~~yaml

  containers:
    - resources: {}
      terminationMessagePath: /dev/termination-log
      name: check
      command:
        - sleep
        - infinity
      livenessProbe:
        exec:
          command:
            - /bin/sh
            - '-c'
            - ./network-check.sh
        initialDelaySeconds: 5
        timeoutSeconds: 30
        periodSeconds: 30
        successThreshold: 1
        failureThreshold: 3
      env:
        - name: SEG_START
          value: '200'
        - name: SEG_END
          value: '203'
      imagePullPolicy: Always
      image: 'quay.io/<repo>/cluster-health:latest'

~~~