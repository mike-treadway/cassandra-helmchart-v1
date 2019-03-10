#!/bin/bash
set -e

# first arg is `-f` or `--some-option`
# or there are no args
if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
  set -- cassandra -f "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'cassandra' -a "$(id -u)" = '0' ]; then
  # Copy JMX files over. Create the directory in case it doesn't exist so
  if [ -d "/etc/cassandra-jmx" ]; then
    cp /etc/cassandra-jmx/*.* /etc/cassandra
  fi

  chown -R cassandra /var/lib/cassandra /var/log/cassandra "$CASSANDRA_CONFIG"
  echo "Switching to user 'cassandra'..."
  exec gosu cassandra "$BASH_SOURCE" "$@"
fi

_ip_address() {
  # scrape the first non-localhost IP address of the container
  # in Swarm Mode, we often get two IPs -- the container IP, and the (shared) VIP, and the container IP should always be first
  ip address | awk '
    $1 == "inet" && $NF != "lo" {
      gsub(/\/.+$/, "", $2)
      print $2
      exit
    }
  '
}

if [ "$1" = 'cassandra' ]; then

  # If a full config was passed in, replace the existing one before proceeding
  if [ "$CASSANDRA_YAML_PATH" ]; then
    echo "Using configuration found in '$CASSANDRA_YAML_PATH'"
    cat "$CASSANDRA_YAML_PATH" > "$CASSANDRA_CONFIG/cassandra.yaml"
  fi

  # If multiple broadcast addresses were past in, then assume we're running as a stateful set
  # and use the hostname to determine the index.
  if [ "$CASSANDRA_BROADCAST_ADDRESS_LIST" ]; then
    index=$((${HOST: -1}+1))
    myAddress=`echo "$CASSANDRA_BROADCAST_ADDRESS_LIST" | sed "$index q;d"`
    if [ "$myAddress" ]; then
      CASSANDRA_BROADCAST_ADDRESS="$myAddress"
      echo "Detected \$CASSANDRA_BROADCAST_ADDRESS_LIST, broadcast address is now set to $CASSANDRA_BROADCAST_ADDRESS"
    else
      >&2 echo "Detected \$CASSANDRA_BROADCAST_ADDRESS_LIST, but no address was found in CASSANDRA_BROADCAST_ADDRESS_LIST at line $index"
      >&2 echo "CASSANDRA_BROADCAST_ADDRESS_LIST:"
      >&2 echo "---------------------------------"
      >&2 printf "$CASSANDRA_BROADCAST_ADDRESS_LIST\n\n"
      exit -1
    fi
  fi

  : ${CASSANDRA_RPC_ADDRESS='0.0.0.0'}

  : ${CASSANDRA_LISTEN_ADDRESS='auto'}
  if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
    CASSANDRA_LISTEN_ADDRESS="$(_ip_address)"
  fi

  : ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

  if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
    CASSANDRA_BROADCAST_ADDRESS="$(_ip_address)"
  fi
  : ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

  if [ -n "${CASSANDRA_NAME:+1}" ]; then
    : ${CASSANDRA_SEEDS:="cassandra"}
  fi
  : ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}

  sed -ri 's/(- seeds:).*/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_CONFIG/cassandra.yaml"

  for yaml in \
    broadcast_address \
    broadcast_rpc_address \
    cluster_name \
    endpoint_snitch \
    listen_address \
    num_tokens \
    rpc_address \
    start_rpc \
  ; do
    var="CASSANDRA_${yaml^^}"
    val="${!var}"
    if [ "$val" ]; then
      sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
    fi
  done

  for rackdc in dc rack prefer_local; do
    var="CASSANDRA_${rackdc^^}"
    val="${!var}"
    if [ "$val" ]; then
      sed -ri 's/^[# ]*('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
    fi
  done
fi

echo "Executing '$@'"
exec "$@"