#!/bin/bash

cat << EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

chmod 644 /etc/yum.repos.d/grafana.repo

cat << EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

chmod 644 /etc/yum.repos.d/influxdb.repo

## Install speedtest.net repo
curl -s https://install.speedtest.net/app/cli/install.rpm.sh | bash

## Install grafana, influxdb, git and speedtest
yum clean all
yum -y install grafana
yum -y install influxdb
yum -y install speedtest
yum -y install git

## Enable and start Grafana and InfluxDB
systemctl enable grafana-server && systemctl start grafana-server
systemctl enable influxdb && systemctl start influxdb &&

## Clone speedtest repo from GitHub to '/opt'
git clone https://github.com/drewsky87/speedtest /opt/speedtest

## Provision dashboard
mkdir /var/lib/grafana/dashboards &&
chown grafana:grafana /var/lib/grafana/dashboards &&
touch /etc/grafana/provisioning/dashboards/netmon.yaml &&
chown grafana:grafana /etc/grafana/provisioning/dashboards/netmon.yaml &&
cp /opt/speedtest/netmon-dashboard.json /var/lib/grafana/dashboards/netmon-dashboard.json &&
chown grafana:grafana /var/lib/grafana/dashboards/netmon-dashboard.json

echo "" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "apiVersion: 1" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "providers:" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo " - name: 'default'" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "   orgId: 1" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "   folder: ''" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "   folderUid: ''" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "   type: file" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "   options:" >> /etc/grafana/provisioning/dashboards/netmon.yaml
echo "     path: /var/lib/grafana/dashboards" >> /etc/grafana/provisioning/dashboards/netmon.yaml

## Restart Grafana so changes take effect
systemctl restart grafana-server

## Create speedtest database in InfluxDB
echo; echo "*** Creating speedtest database"
influx -execute 'CREATE DATABASE speedtest'

## Create crontab entry to run speedtest
(crontab -l ; echo "## Run speedtest every 30 minutes"; echo "*/30 * * * *    /opt/speedtest/run_speedtest") | crontab

## Run an initial speedtest
chmod 750 /opt/speedtest/run_speedtest
/opt/speedtest/run_speedtest


ip=`ifconfig | grep inet | grep -v inet6 | grep -v 127.0.0.1 | awk '{print $2}'`
clear
echo "****************************************************"
echo "****************************************************"
echo
echo "Grafana and InfluxDB Setup Complete"
echo
echo "****************************************************"
echo "****************************************************"
echo
echo
echo "Grafana URL:  https://$ip:3000"
echo "   Default Username: admin"
echo "   Default Password: admin"
echo
echo
echo "To complete datasource configuration:"
echo "  1. Goto Grafana web UI."
echo "  2. Click settings gear on left > Data sources"
echo "  3. Click Add data source > InfluxDB"
echo "  4. Change datasource name to InfluxDB-Speedtest"
echo "  5. Change URL to http://localhost:8086"
echo "  6. Change database name to speedtest"
echo "  7. Click Save & test"
echo
echo "****************************************************"
echo "****************************************************"

