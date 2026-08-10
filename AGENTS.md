# AGENTS.md — m3ua (fork)

SigScale's `m3ua`, forked to `github.com/tsw2k/m3ua` and carried as a dependency
of NG-STP. Apache-2.0, so borrowing from it and changing it are both free; what
follows is how *our* changes are made, not a rewrite of how it was written.

`CLAUDE.md` is a symlink to this file — keep them in sync by editing here only.

## What this fork is for

M3UA is the second leg of the MVP: the node talks to the HLR over it, where
everything below MTP3 faces the interconnect over M2PA. `configs/itp-parity-analysis.md`
in NG-STP found it mandatory and missing from the original plan.

Our commits so far are small and named in the log — `Let a signalling gateway
send SSNM` is the shape of them. Keep them that way: an upstream that still
merges is worth more than a fork that diverged for tidiness.

## Conventions for our changes

- **English everywhere** — code, comments, edoc, commit messages.
- **Match the surrounding code**, which is SigScale's: tabs, `gen_statem`, the
  same module and function naming. A fork that reads as two authors is harder
  to merge upstream and harder to review.
- **Say why upstream could not do it.** Every change here should carry, in the
  commit body, what NG-STP needed that the original did not give — that is what
  makes the diff reviewable years later and what an upstream pull request would
  have to say anyway.
- **Say what happened, at a level somebody can turn on.** The same convention as
  the libraries written in-house, because a node whose layers report differently
  is a node nobody can bring up. Count always, and log the particulars at
  `debug`.
  - Use the **macros** from `kernel/include/logger.hrl` — `?LOG_DEBUG`,
    `?LOG_NOTICE` and the rest — never the `logger:debug/2` functions. The macro
    tests the level before it evaluates anything; the function builds its
    arguments whether or not anyone is listening.
  - Every call carries **`layer =>`** in its metadata, naming the protocol, and
    whatever identifies the thing it happened to. Metadata is filterable; a
    prefix inside the text is not. Then one protocol at a time can be made to
    speak: `logger:set_application_level(m3ua, debug)`.
  - **A message that stops must say so, and not at `debug`.** Traffic that goes
    no further is an operational fact, not a decision anybody has to ask about.
    **`notice`** where the configuration or the peer stopped it — no route, no
    routing key, refused, an application server that is down — and **`warning`**
    where something arrived that will not decode. The reason goes in the
    metadata every time, because "discarded" without one says no more than the
    counter already did. A message that dies silently is indistinguishable from
    one that was never sent.
  - **An association that cannot carry traffic says so once, when that becomes
    true and again when it clears** — separately from, and in addition to, the
    messages that then stop. Here the condition is an ASP that is not active:
    set by ASPAC, cleared by ASPIA, ASPDN or the timeout that gives up on one
    of them, and holding until something changes it. Said once per discarded
    message it is the wrong shape twice over — far too loud under traffic, and
    **completely silent without any**, which is the half that caught us: in one
    run of `stack_corpus.erl` over an hour of the mirror this library said
    nothing at all, because nothing drove it, and "no association" and "working
    perfectly" were the same silence. It follows that an association that comes
    up and does not carry says so then, rather than waiting for the first
    message to arrive and be lost.
  - `debug` is a decision and its reason; `notice` a state change worth seeing
    unasked — an association up, an ASP active, a route unavailable; `warning`
    and above are faults.
- Commit messages are plain: a subject line in the imperative, a body when the
  reasoning is not obvious from the diff. No attribution trailers, no tool
  attribution of any kind.
