PATH=$PATH:.

DATA_DIR=/data

mkdir -p $DATA_DIR/query
mkdir -p $DATA_DIR/http
while [ true ]; do 
    SA_CA_PATH="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
    SA_TOKEN_PATH="/var/run/secrets/kubernetes.io/serviceaccount/token"

    ${UTIL_OC_BIN} login "${INT_URI}" \
            --token="$(cat "${SA_TOKEN_PATH}")" \
            --certificate-authority="${SA_CA_PATH}"

    check_range () {
        for (( SEG=$SEG_START; SEG<=$SEG_END; SEG++ )); do
            ping -c 1 192.168.$SEG.1
            if [ $? -eq 0 ]; then
                echo "Segment $SEG responding" >> $DATA_DIR/query/network_status.txt
            else
                echo "!!! Segment $SEG not responding" >> $DATA_DIR/query/network_status.txt
            fi
        done
    }

    SEG_START=88
    SEG_END=108
    echo "IBM 7 VPN status" > $DATA_DIR/query/network_status.txt
    check_range
    echo "" >> $DATA_DIR/query/network_status.txt

    SEG_START=151
    SEG_END=157
    echo "Multi-Zone VPN status" >> $DATA_DIR/query/network_status.txt
    check_range
    echo "" >> $DATA_DIR/query/network_status.txt

    SEG_START=200
    SEG_END=203
    echo "IBM 8 VPN status" >> $DATA_DIR/query/network_status.txt
    check_range


    NAMESPACES=$(oc get namespace -o=jsonpath='{.items[*].metadata.name}')
    for NAMESPACE in $NAMESPACES; do    
        if [[ $NAMESPACE != *"ci-op"* ]]; then
        continue
        fi    
        echo $NAMESPACE
        oc get pods -n $NAMESPACE -o=json > $DATA_DIR/pod.yaml

        PODS=$(cat $DATA_DIR/pod.yaml | jq -r .items[].metadata.name | grep e2e)
        SEGMENT_SLICES=$(cat $DATA_DIR/pod.yaml | jq -r '.items[].spec.containers[].env[] | select(.name == "LEASED_RESOURCE") | .value')
        SEGMENT=""
        for _SEGMENT in $SEGMENT_SLICES; do
            if [[ $_SEGMENT == *"ci-segment-"* ]]; then
                SEGMENT=$_SEGMENT
                mkdir -p $DATA_DIR/$SEGMENT
            fi
        done

        echo $SEGMENT
        if [ -z $SEGMENT ]; then 
            continue
        fi

        OK=1
        
        for POD in $PODS; do
            if [[ $POD == *"openshift-e2e-test"* ]]; then
                continue
            fi
            STATUSES=$(cat $DATA_DIR/pod.yaml | jq -r '.items[].status.conditions[] | select(.type == "Ready") | .reason')
            for STATUS in $STATUSES; do
                if [[ $STATUS == 'PodFailed' ]]; then
                    OK=0
                    break
                fi
            done
        done
        if [ ${OK} -eq 1 ]; then
            echo "$SEGMENT/$NAMESPACE OK"
            echo "." > $DATA_DIR/$SEGMENT/$NAMESPACE
        else 
            echo "$SEGMENT/$NAMESPACE Failed"
            echo "X" > $DATA_DIR/$SEGMENT/$NAMESPACE
        fi
    done

    rm ${DATA_DIR}/query/segment_pass_trends.txt
    for dir in "${DATA_DIR}"/*/ ; do  
    if [[ $dir != *"ci-segment-"* ]]; then
    continue
    fi
    
    SEGMENT=$(echo $dir | cut -d'/' -f 3)
    echo -n "$SEGMENT - ">> ${DATA_DIR}/query/segment_pass_trends.txt
    for f in "$dir"* ; do
        if [[ $f == *"ci-op-"* ]]; then
            echo -n $(cat $f) >> ${DATA_DIR}/query/segment_pass_trends.txt
        fi
    done
    echo "" >> ${DATA_DIR}/query/segment_pass_trends.txt
    done
    mv ${DATA_DIR}/query/network_status.txt ${DATA_DIR}/http/network_status.txt
    mv ${DATA_DIR}/query/segment_pass_trends.txt ${DATA_DIR}/http/segment_pass_trends.txt
    sleep 300
done