# Ansible code for TakTor nodes

## Introduction

TakTor is a set of relay/exit nodes on the Tor network. Freedom of speech on the
internet is one of the biggest achievements of our generation. At Tak.io we
believe it should be protected, and currently the best way a small organization
can help in this cause is by donating Tor nodes to the network.

## Architecture

![TakTor](https://user-images.githubusercontent.com/1315327/126013095-7ad63c67-c34f-4bfb-80bf-c0c7d3de6549.png)

The software setup have been done as recommended by the Tor Project. The overall system
architecture has been designed to be very scalable. Another design criterium is
to have minimal impact if one of the nodes is compromised. Nodes are considered
to be expendable. If a node fails somehow, it's one Ansible run away from being
completely reconfigured and back up and running.

Components in this setup are:

- haveged: Virtual machines have a tendency to not have enough entropy in their
  randomness pool. haveged is a pseudo randomness generator, alleviating that 
  problem and preventing Tor from stalling due to not having enough randomness.
- Unbound DNS server: A possible attack vector on exit nodes is that someone could
  be monitoring the DNS requests made on behalf of the users. To avoid this, an 
  unbound DNS resolver is installed on every node, which directly starts queries 
  at the root DNS level, thus avoiding third-party resolvers.
- Exporters: Prometheus exporters are used to monitor overall system health and
  Tor metrics. No specific user information is stored, only overall statistics
  like throughput and connection count.
- Nyx is a terminal based control application for the Tor daemon. It's mostly there
  for just-in-case scenarios. Day to day monitoring is generally done with Prometheus. 

## Contributing

This code is mainly available for reference and transparency. External pull
requests will be considered, but won't have a high priority for the development
team.

