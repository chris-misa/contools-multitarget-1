#!/bin/bash

#
# Experiment to ping a list of locations each from
# the native ping instalation and from a container
# instalation.
#

# List of targets
declare -a TARGETS=(
   "127.0.0.1"       # [loopback]
   "128.110.153.106" # [source's outbound iface]
   "140.197.253.0"   # [Utah Education network]
   "198.71.45.230"   # [internet2 AS 11537]
   "162.252.70.155"  # [internet2 AS 11537]
   "128.223.142.244"   # [probably uoregon firewall AS 3582]
)

# Arguments for each ping invocations
PING_ARGS="-c 100 -i 2 -s 56"

# Native ping commant
NATIVE_PING_CMD="$(pwd)/iputils/ping"

# Info for running docker
CONTAINER_PING_CMD="/iputils/ping"
PING_IMAGE_NAME="ping-ubuntu"
PING_CONTAINER_NAME="ping-container"
DOCKER_BRIDGE_IPV4="172.17.0.1"

# Info for strace
STRACE_ARGS="-ttT -e trace=sendto,recvmsg"

# Experiment book keeping
DATE_TAG=`date +%Y%m%d%H%M%S`
META_DATA="Metadata"

SLEEP_CMD="sleep 5"
B="-----------------------"

#
# Experiment Start
#

echo $B Gathering metadata $B

mkdir $DATE_TAG
cd $DATE_TAG

# Get some basic meta-data
echo "uname -a -> $(uname -a)" >> $META_DATA
echo "docker -v -> $(docker -v)" >> $META_DATA
echo "lsb_release -a -> $(lsb_release -a)" >> $META_DATA
echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Set up containers
echo $B Spinning up containers . . . $B

# Spin up ping container in native docker
docker run -itd \
  --name="$PING_CONTAINER_NAME" \
  --entrypoint="/bin/bash" \
  --cap-add=SYS_PTRACE \
  -v $(pwd):/experiment \
  $PING_IMAGE_NAME

# Wait for them to be ready
until [ "`docker inspect -f {{.State.Running}} $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Go through target list
for t in ${TARGETS[@]}
do
  echo $B Target: $t $B
  echo "  native control. . ."
  $SLEEP_CMD
  $NATIVE_PING_CMD $PING_ARGS $t > control_native_${t}.ping
  echo "  native straced. . ."
  $SLEEP_CMD
  strace $STRACE_ARGS -o native_${t}.strace \
    $NATIVE_PING_CMD $PING_ARGS $t > strace_native_${t}.ping

  echo "  container control. . ."
  $SLEEP_CMD
  docker exec $PING_CONTAINER_NAME \
    $CONTAINER_PING_CMD $PING_ARGS $t > control_container_${t}.ping
  echo "  container straced. . ."
  $SLEEP_CMD
  docker exec $PING_CONTAINER_NAME \
    strace $STRACE_ARGS -o /experiment/container_${t}.strace \
      $CONTAINER_PING_CMD $PING_ARGS $t > strace_container_${t}.ping
done

# Grab some container-specific measurment
echo $B Container-internal targets $B
echo "  bridge network control. . ."
$SLEEP_CMD
docker exec $PING_CONTAINER_NAME \
  $CONTAINER_PING_CMD $PING_ARGS $DOCKER_BRIDGE_IPV4 > control_container_bridge.ping
echo "  bridge network straced. . ."
$SLEEP_CMD
docker exec $PING_CONTAINER_NAME \
  strace $STRACE_ARGS -o /experiment/container_bridge.strace \
   $CONTAINER_PING_CMD $PING_ARGS $DOCKER_BRIDGE_IPV4 > strace_container_bridge.ping


# Clean up
echo $B Cleaning up $B
docker stop $PING_CONTAINER_NAME
docker rm $PING_CONTAINER_NAME

echo Done.
