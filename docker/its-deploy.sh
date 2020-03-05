#!/usr/bin/env bash

CURRENT_VERSION=$(xmllint --xpath "//*[local-name() = 'project']/*[local-name() = 'version']/text()" ../pom.xml )

#echo "version: "${CURRENT_VERSION}"

DOCKER_IMAGE="its-project/its.de:"${CURRENT_VERSION}
MOUNT_DEPLOYMENT_FOLDER="true"
WILDFLY_HOME="/opt/jboss/wildfly"
MOUNT_ATTRIBUTE_AVAILABLE='\-\-mount'
DOCKER_CONTAINER_NAME="itsportal"

docker build --no-cache -t "${DOCKER_IMAGE}" .

echo "Using docker container name [${DOCKER_CONTAINER_NAME}] with image [${DOCKER_IMAGE}] ..."

CONTAINER_RUNS_OR_EXISTS=$(docker ps -a -f "$DOCKER_FILTER" --format "table {{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Image}}")
if [[ $? -ne 0 ]]; then
  echo "No running container found"
else
  echo -e "\nContainer found:\n${CONTAINER_RUNS_OR_EXISTS}\n"
  echo "Stop and remove container ..."
  CONTAINER_IDS=$(docker ps -qa -f "$DOCKER_FILTER")
  docker stop $CONTAINER_IDS && docker rm $CONTAINER_IDS
fi

echo "Restarting ..."
if [[ ! -d ~/public_html ]]; then
  echo "Creating public_html folder under HOME ..."
  mkdir -p ~/public_html/document-center && mkdir ~/public_html/brand
  chmod -R o+w ~/public_html/
fi

if [[ "${MOUNT_ATTRIBUTE_AVAILABLE}" != "" ]] && [[ "${MOUNT_DEPLOYMENT_FOLDER}" != "false" ]]; then
  DEPLOYMENT_FOLDER=$(echo "$(pwd)/deployments")
  mkdir -p "$DEPLOYMENT_FOLDER" 2>/dev/null
  chmod a+rwx "$DEPLOYMENT_FOLDER"
  echo "Using development deployment folder [${DEPLOYMENT_FOLDER}] ..."

  docker run \
    --rm \
    -v ~/public_html:/home/prj2756/public_html \
    --mount type=bind,source="$(pwd)/deployments",target="${WILDFLY_HOME}/standalone/deployments" \
    -p 8081:8080 -p 8444:8443 -p 9991:9990 -p 4142:4142 \
    --name ${DOCKER_CONTAINER_NAME} \
    -d ${DOCKER_IMAGE}
fi
sleep 2
docker exec -it ${DOCKER_CONTAINER_NAME} bash -c "tail -F ${WILDFLY_HOME}/standalone/log/server.log"