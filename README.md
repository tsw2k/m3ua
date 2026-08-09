# [SigScale](http://www.sigscale.org) M3UA Protocol Stack

See the
[developers guide](https://storage.googleapis.com/m3ua.sigscale.org/debian-bookworm/lib/m3ua/doc/index.html)
for detailed information.

This application implements a distributed protocol stack
for the MTP3 user adaptation (M3UA) of the IETF Signaling
Transport (SIGTRAN) protocol suite.

## M3UA
The MTP3 user adaptation (M3UA) defines a protocol for supporting the
transport of any SS7 MTP3-User signalling (e.g. ISUP or SCCP) over IP
using the services of SCTP. This protocol is used to interconnect an SS7
Signaling Gateway (SG) with Application Servers (AS).

![interfaces](https://raw.githubusercontent.com/sigscale/m3ua/master/doc/boundaries.png)

## Logging

The convention is the whole stack's, because a node whose layers report
differently is a node nobody can bring up. See `AGENTS.md`.

```erlang
logger:set_application_level(m3ua, debug).
```

Every record carries `layer => m3ua` in its metadata. `debug` is a decision and
its reason; `notice` is a state change worth seeing unasked **and every message
that goes no further** because of the configuration or the peer; `warning` and
above are faults.

**Nothing in this fork follows it yet.** What is here is upstream's logging,
which predates the convention by years. Bringing it into line is outstanding
work.
