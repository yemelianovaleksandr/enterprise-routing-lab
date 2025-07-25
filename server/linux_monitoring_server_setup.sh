
# Server: Monitoring & Control (Ubuntu/Debian-based recommended)

# === Update system ===
sudo apt update && sudo apt upgrade -y

# === Install core services ===
sudo apt install -y ntp snmpd apache2 net-tools   freeradius syslog-ng netflow nfdump tcpdump

# === Configure NTP ===
sudo sed -i 's/^pool /# pool /' /etc/ntp.conf
echo "server 0.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf
sudo systemctl enable ntp
sudo systemctl restart ntp

# === Configure Syslog (syslog-ng) ===
cat <<EOF | sudo tee /etc/syslog-ng/conf.d/cisco.conf
source s_net {
  udp(ip(0.0.0.0) port(514));
};
destination d_logs {
  file("/var/log/cisco/\${HOST}/\${YEAR}\${MONTH}\${DAY}.log");
};
log {
  source(s_net);
  destination(d_logs);
};
EOF
sudo mkdir -p /var/log/cisco
sudo systemctl enable syslog-ng
sudo systemctl restart syslog-ng

# === Configure SNMP ===
sudo sed -i 's/^agentAddress.*/agentAddress udp:161,udp6:[::1]:161/' /etc/snmp/snmpd.conf
sudo sed -i 's/^rocommunity.*/rocommunity public default    -V systemonly/' /etc/snmp/snmpd.conf
sudo systemctl enable snmpd
sudo systemctl restart snmpd

# === Setup NetFlow collector ===
sudo mkdir -p /var/netflow
sudo nfcapd -w -D -l /var/netflow -p 2055

# === (Optional) AAA via FreeRADIUS ===
sudo systemctl enable freeradius
sudo systemctl start freeradius

# === Done ===
echo "Monitoring server configured."
