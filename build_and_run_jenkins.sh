#!/bin/bash

appId=jenkins
appVersion=2.277.1
latesttag=latest

# REGISTRY parameters
# HOME parameters

REGISTRY_DOMAIN="docker.io"
REGISTRY_URL="${REGISTRY_DOMAIN}/${REGISTRY_USER_NAME}"
PROXY_HOST=""
PROXY_USER=""
PROXY_PASS=""

docker login --username ${REGISTRY_USER_NAME} --password ${REGISTRY_USER_PSW} ${REGISTRY_DOMAIN} 	
cd /build_jenkins
docker build -t ${appId} .

echo '################################################################################'
echo 'if the build failed for any reasons, you have 30 seconds to stop it here - STRG+C'
sleep 30


#image taggen
docker tag ${appId} ${REGISTRY_URL}/${appId}:${latesttag}
docker tag ${appId} ${REGISTRY_URL}/${appId}:${appVersion}


# push to REGISTRY
docker push ${REGISTRY_URL}/${appId}:${latesttag}
docker push ${REGISTRY_URL}/${appId}:${appVersion}


# cleanup
docker rmi ${REGISTRY_URL}/${appId}:${latesttag}
docker rmi ${REGISTRY_URL}/${appId}:${appVersion}

cd ..
# create k8s image pul secret
kubectl create secret docker-registry pull-secret --dry-run=client --docker-server=${REGISTRY_DOMAIN} --docker-username=${REGISTRY_USER_NAME} --docker-password=${REGISTRY_USER_PSW} -o yaml > docker-secret.yaml
kubectl apply -f docker-secret.yaml && rm docker-secret.yaml
kubectl delete -f ./deployment/pod-jenkins.yaml

echo "Warten bis Jenkins runtergefahren"
sleep 20

echo "Jenkins starten"
#jenkins-persistence-volume-claim.yaml
kubectl apply -f ./deployment/pod-jenkins.yaml

sleep 20

#kubectl cp /data/dex/jenkins/build_jenkins/plugins $(kubectl get pods --all-namespaces|grep jenkins|awk '{print $2}'):/var/jenkins_home
