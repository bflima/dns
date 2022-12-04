#!/usr/bin/env bash

clear

# Variáveis
IP=$(ip a | grep inet | grep -v inet6 | grep -v "127.0.0.*" | awk '{print $2}' | cut -d "/" -f 1)
ARQ=$(find /etc/ -iname unbound.conf)
MASK=$(ip a | grep inet | grep -v inet6 | grep -v "127.0.0.*" | awk '{print $2}' | cut -d "/" -f 2)
TOTAL_INTERFACES=$(nmcli device show | grep -ic device)

# Verificar se unbound está instalado
which unbound || yum install unbound -y

# Testar se existe mais de uma interface de rede cadastrada sai do script
[ "$TOTAL_INTERFACES" -eq 2 ] || { clear ; echo "Mais de uma interface de rede cadastrada, favor alterar manualmente o script" ; exit 1 ; }

# Realizar copia do arquivo
cp  "$ARQ"{,.bkp}

cat > "$ARQ" << EOF
server:
       	directory: "/etc/unbound"
        chroot: ""
        logfile: "/var/log/unbound.log"
        verbosity: 1
        log-queries: yes
        username: unbound

        interface: 127.0.0.1
        interface: $IP

        access-control: $IP/$MASK allow
        access-control: 127.0.0.0/8 allow
        access-control: 0.0.0.0/0 refuse
        access-control: ::/0 deny

        port: 53
        do-udp: yes
        do-tcp: yes
        do-ip4: yes
        do-ip6: no

#DNSSEC
auto-trust-anchor-file: "/etc/unbound/root.key"

#[ privacidade ]
        hide-identity: yes
        hide-version: yes
        harden-glue: yes
        harden-dnssec-stripped: yes
        use-caps-for-id: yes
        val-clean-additional: yes
        unwanted-reply-threshold: 10000
        private-address: 10.0.0.0/8
        private-address: 100.64.0.0/10
        private-address: 127.0.0.0/8
        private-address: 172.16.0.0/12
        private-address: 192.168.0.0/16
        private-address: 169.254.0.0/16
        private-address: fd00::/8
        private-address: fe80::/10
        private-address: ::ffff:0:0/96

#[ performance ]
        num-threads: $(nproc)
        msg-cache-slabs: $(nproc)
        key-cache-slabs: $(nproc)
        rrset-cache-slabs: $(nproc)
        infra-cache-slabs: $(nproc)
        rrset-roundrobin: yes
        cache-max-ttl: 86400
        outgoing-num-tcp: 1024
        outgoing-range: 8192
        num-queries-per-thread: 4096
        so-reuseport: yes
        prefetch: yes
        prefetch-key: yes

#HYPERLOCAL
auth-zone:
	name: "."
        master: 192.228.79.201          # b.root-servers.net
        master: 192.33.4.12             # c.root-servers.net
        master: 192.5.5.241             # f.root-servers.net
        master: 192.112.36.4            # g.root-servers.net
        master: 193.0.14.129            # k.root-servers.net
        master: 192.0.47.132            # xfr.cjr.dns.icann.org
        master: 192.0.32.132            # xfr.lax.dns.icann.org
        master: 2001:500:84::b          # b.root-servers.net
        master: 2001:500:2f::f          # f.root-servers.net
        master: 2001:7fd::1             # k.root-servers.net
        master: 2620:0:2830:202::132    # xfr.cjr.dns.icann.org
        master: 2620:0:2d0:202::132     # xfr.lax.dns.icann.org
        fallback-enabled: yes
        for-downstream: no
        for-upstream: yes
        zonefile: "root.zone"
        url: http://www.internic.net/domain/root.zone
EOF
