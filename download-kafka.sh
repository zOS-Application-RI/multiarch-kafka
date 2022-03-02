#!/bin/bash -e

# shellcheck disable=SC1091
# /bin/bash -c "source /usr/bin/versions.sh"

KFILENAME="kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
# ZFILENAME="zookeeper-${ZOOKEEPER_VERSION}-bin.tgz"

url=$(curl --stderr /dev/null "https://www.apache.org/dyn/closer.cgi?path=/kafka/${KAFKA_VERSION}/${FILENAME}&as_json=1" | jq -r '"\(.preferred)\(.path_info)"')
# url2=$(curl --stderr /dev/null "https://www.apache.org/dyn/closer.cgi?path=/zookeeper/${FILENAME}&as_json=1" | jq -r '"\(.preferred)\(.path_info)"')
# Test to see if the suggested mirror has this version, currently pre 2.1.1 versions
# do not appear to be actively mirrored. This may also be useful if closer.cgi is down.
if [[ ! $(curl -s -f -I "${url}") ]]; then
    echo "Mirror does not have desired version, downloading direct from Apache"
    url="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/${KFILENAME}"
fi

echo "Downloading Kafka from $url"
wget "${url}" -O "/tmp/${KFILENAME}"

# Test to see if the suggested mirror has this version, currently pre 2.1.1 versions
# do not appear to be actively mirrored. This may also be useful if closer.cgi is down.
# if [[ ! $(curl -s -f -I "${url2}") ]]; then
#     echo "Mirror does not have desired version, downloading direct from Apache"
#     url="https://archive.apache.org/dist/zookeeper/${ZFILENAME}"
# fi

# echo "Downloading ZooKeeper from $url2"
# wget "${url2}" -O "/tmp/${ZFILENAME}"
