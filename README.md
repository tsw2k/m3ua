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

**The traffic path follows it; the rest does not yet.** `m3ua_asp_fsm`,
`m3ua_sgp_fsm` and `m3ua_lm_server` say where a message stops and why, and
the two state machines say once when an association stops and starts
carrying traffic. What remains is upstream's `error_logger` reporting, which
predates the convention by years: all of `m3ua_app`, `m3ua_listen_fsm`,
`m3ua_connect_fsm` and `m3ua_rest_prometheus`, the shutdown report in
`m3ua_lm_server`, and in the two state machines the reports of an SCTP error,
a socket that will not close and an ERR from the peer. A message that
will not decode is not reported at all: the codec fails and takes the state
machine with it.
