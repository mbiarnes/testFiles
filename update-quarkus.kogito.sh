#!/usr/bin/env bash

set -euo pipefail

PROJECT=$1
VERSION=$2
COMMAND=$3

if [ "${COMMAND}" = "stage" ]; then

    # add custom repositories
    cat ${MAVEN_SETTINGS_FILE} | grep ${KOGITO_STAGING_REPOSITORY}
    if [ "$?" != "0" ]; then
        echo "$DIFF_FILE" | patch ${MAVEN_SETTINGS_FILE}
    fi
    set -e

    # process versions
    ./mvnw \
    -s ${MAVEN_SETTINGS_FILE} \
    versions:set-property \
    -Dproperty=${PROJECT}-quarkus.version \
    -DnewVersion=${VERSION} \
    -DgenerateBackupPoms=false

    # update pom metadata
    ./mvnw -s ${MAVEN_SETTINGS_FILE} -Dsync
fi

if [ "${COMMAND}" = "finalize" ]; then

    set -x

    # undo patch to add repos
    set +e
    cat ${MAVEN_SETTINGS_FILE} | grep ${KOGITO_STAGING_REPOSITORY}
    if [ "$?" = "0" ]; then
        echo "$DIFF_FILE" | patch -R ${MAVEN_SETTINGS_FILE}
    fi
    set -e

    ./mvnw -Dsync
fi

if [ "${COMMAND}" = "finalizeOnly" ]; then

    set -x
    # process versions
    ./mvnw \
    versions:set-property \
    -Dproperty=${PROJECT}-quarkus.version \
    -DnewVersion=${VERSION} \
    -DgenerateBackupPoms=false

    # update pom metadata
    ./mvnw -Dsync
fi

KOGITO_STAGING_REPOSITORY='https://repository.jboss.org/nexus/content/groups/kogito-public/'
MAVEN_SETTINGS_FILE='../quarkus-platform/.github/mvn-settings.xml'
DIFF_FILE="diff --git a/${MAVEN_SETTINGS_FILE} b/${MAVEN_SETTINGS_FILE}
index d5e4664b..b03cc023 100644
--- a/${MAVEN_SETTINGS_FILE}
+++ b/${MAVEN_SETTINGS_FILE}
@@ -14,6 +14,14 @@
             <enabled>false</enabled>
           </snapshots>
         </repository>
+        <repository>
+          <snapshots>
+              <enabled>false</enabled>
+          </snapshots>
+          <id>kogito</id>
+          <name>kogito</name>
+          <url>${KOGITO_STAGING_REPOSITORY}</url>
+        </repository>
       </repositories>
       <pluginRepositories>
         <pluginRepository>
"