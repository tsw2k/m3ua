# M3UA Protocol Stack

A fork of [SigScale's m3ua](https://github.com/sigscale/m3ua), Apache-2.0,
carried as a dependency of NG-STP. The API is upstream's, with the additions
below, and upstream's
[developers guide](https://storage.googleapis.com/m3ua.sigscale.org/debian-bookworm/lib/m3ua/doc/index.html)
describes it. How changes are made here is in `AGENTS.md`.

This application implements a distributed protocol stack
for the MTP3 user adaptation (M3UA) of the IETF Signaling
Transport (SIGTRAN) protocol suite.

## M3UA
The MTP3 user adaptation (M3UA) defines a protocol for supporting the
transport of any SS7 MTP3-User signalling (e.g. ISUP or SCCP) over IP
using the services of SCTP. This protocol is used to interconnect an SS7
Signaling Gateway (SG) with Application Servers (AS).

![interfaces](doc/boundaries.png)

## What the fork changes

Each commit says what NG-STP needed that upstream did not give; this is the
summary a user of the library needs.

**Transport.** SCTP is carried over the `socket` module rather than
`gen_sctp` (`m3ua_sctp`, `m3ua_receiver`). An endpoint takes `{device, Name}`
to bind into a VRF. Options given with `{connect, Address, Port, Options}` are
set on the socket, and one that `m3ua_sctp` cannot set is an error naming it:
the endpoint logs *Connect failed* and tries again, rather than coming up
without it. `sctp_nodelay` is on unless `{sctp_nodelay, false}` is given:
with Nagle on, a message can wait for the peer's delayed SACK, 200 ms.

**Messages from the peer.** One the stack cannot use no longer ends the
association:

- a message that will not decode -- header, version, class or type,
  parameter lengths and values, a missing mandatory parameter (RFC 4666 §3) --
  is answered with an ERR carrying the RFC 4666 §3.8.1 code;
- a message that decodes but that nothing takes in the current state is
  answered with ERR *Unexpected Message*;
- an ERR is never answered with one.

**RFC 4666 procedures** added or corrected:

- SSNM can be sent: DUNA, DAVA, DUPU, DRST and SCON by a signalling gateway,
  DAUD by an ASP;
- an ASP takes a DRST as MTP-RESUME, like a DAVA (§5.4), and a DUPU through the
  optional callback `unavailable_user/6` (§5.5.2.3.4);
- an ASP UP at an active ASP is acknowledged, answered with ERR and leaves the
  ASP inactive; at an inactive one it is acknowledged and nothing more; an ASP
  UP ACK the ASP did not ask for leaves it inactive, and from active or down it
  asks to go back (§4.3.4.1);
- ASP DOWN, and ASP UP at an active ASP, deregister the routing keys the ASP
  registered; membership given by configuration stays (§4.3.4);
- an application server a REG REQ created is removed once the last ASP that
  registered into it has left; one configured with `m3ua:as_add/7` stays
  (§4.4.2);
- DEREG REQ and DEREG RSP (§4.4.2), and a REG RSP is matched to its request by
  the local routing key identifier;
- DATA and SSNM are sent without a routing context where there is none to
  send (§3.4).

**API.**

- `m3ua:deregister(EndPoint, Assoc, RoutingContext) -> ok | {error, Reason}`:
  at an ASP it sends a DEREG REQ; statically registered, or at a gateway, it
  is done locally.
- The optional callback `deregister(RC, NA, Keys, TMT, State)` is told of every
  deregistration, however it came about, with what `register/5` was given.
- `m3ua:stop(EndPoint)` removes the endpoint and everything on it, and frees
  its port; it used to be restarted at once. An endpoint no supervisor holds
  answers `{error, not_found}`.
- Endpoints can be found by the `{name, Term}` they were started with:
  `m3ua:get_ep/1` answers it first, and it survives restarts.
- A request an ASP sends is timed by a timer of its own, so traffic arriving
  meanwhile no longer keeps it from ever timing out.

**Failure containment.** One fault stays where it happened:

- a connect endpoint whose association ends connects again as the same
  process, instead of dying and being restarted;
- an endpoint whose supervisor gives up (ten restarts a minute) is gone, and
  nothing else is. It is not started again: that is its owner's call;
- `m3ua_lm_server` restarts alone and takes on the endpoints and associations
  that are still running. It drops a call, cast or message it has no clause
  for instead of dying of it;
- an exception raised by a callback on the traffic path (`recv`, `send`,
  `info`, the SSNM and NTFY callbacks) costs that one message: it is logged,
  counted, and the association goes on. The callbacks of the association's
  own life (`init`, `asp_up` and the rest, `register`, `terminate`) are not
  contained.

**Counters.** `m3ua:getcount(EndPoint, Assoc)` has, besides upstream's:
`undecodable_in`, `unexpected_in`, `error_in`, `error_out`, `callback_raised`,
`drst_in`, `dupu_in`, and for
deregistration `dereg_out` and `dereg_rsp_in` at an ASP, `dereg_in` and
`dereg_rsp_out` at a gateway. `transfer_discarded` counts transfers refused
or dropped for the association's state.

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

Every module reports by it; none uses `error_logger` any more. Among what is
reported:

- where a message stops and why, at `notice`;
- once when an association stops and starts carrying traffic;
- a message from the peer that will not decode, at `warning` with its octets
  at `debug`; one nothing takes in its state, at `notice`;
- an ERR from the peer, at `warning`, counted under `error_in`;
- a routing key registration or deregistration refused, routing keys
  deregistered, and application servers removed, at `notice`;
- a callback that raised, at `error` with its stack trace;
- anything the layer manager has no clause for, at `warning`;
- a connect endpoint connecting again after its association ended, at
  `notice`, and one whose attempt failed, at `warning`;
- an SCTP send failure, at `error`; an SCTP remote error, a socket that would
  not close, and a metrics query that failed, at `warning`.

Payloads, socket options and process state are never in the `warning` or
`error` record itself: each has a `debug` record beside it carrying them.
