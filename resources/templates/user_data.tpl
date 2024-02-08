#!/bin/bash
main(){
  install_dependencies
  mount_volume
  create_files
  config_openvpn
}

mount_volume(){
  aws ec2 attach-volume --region ${aws_region} \
  --instance-id "$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)" \
  --device ${volume_device_name} \
  --volume-id ${volume_id}
  sleep 30
  mkdir ${volume_path}
  DEVICE=/dev/$(lsblk -J | jq -r '.blockdevices[] | select(.type | index("disk")) | select(has("children") | not) | select(.mountpoints | index(null)).name')
  mount $DEVICE ${volume_path} || echo "Creating $DEVICE fs..." > init.log 
  if [ -f init.log ]; then
    mkfs -t xfs $DEVICE
    mount $DEVICE ${volume_path}
    rm init.log
  fi
  cd ${volume_path}
}

install_dependencies(){
  apt-get update && apt-get install -y awscli jq
  # docker
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  usermod -aG docker ubuntu
}

create_files(){
  cat > /etc/docker/daemon.json <<'EOF'
{
  "bip": "${docker_cidr}"
}
EOF

  cat > docker-compose.yml <<'EOF'
${docker_compose}
EOF

  cat > create_client.sh <<'EOF'
${create_client}
EOF

  cat > revoke_client.sh <<'EOF'
${revoke_client}
EOF

  chmod +x create_client.sh revoke_client.sh

}

config_openvpn(){

  aws ec2 disassociate-address --public-ip ${eip_address} --region ${aws_region}
  aws ec2 associate-address --region ${aws_region} --instance-id "$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id)" --allocation-id ${eip_allocation_id}

  if [ ! -f ${volume_path}/conf/openvpn.conf ]; then
      docker compose run --rm openvpn ovpn_genconfig -N -d \
                    %{ for route in routes  ~}
                    -p "route ${route}" \
                    %{ endfor ~}
                    -e 'topology subnet' -u udp://${server_address}
      echo "openvpn" | docker compose run -T --rm openvpn ovpn_initpki nopass
  fi

  chown -R ubuntu:ubuntu .

  docker compose up -d openvpn

}

main "$@"