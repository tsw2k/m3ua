%%% m3ua_sctp.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2026 MTX Connect S.a r.l.
%%% @end
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc SCTP for the {@link //m3ua. m3ua} application, over the
%%% 	`socket' module rather than {@link //kernel/gen_sctp. gen_sctp}.
%%%
%%% 	== Why ==
%%%
%%% 	`gen_sctp' binds through the inet driver, which offers no
%%% 	`SO_BINDTODEVICE'. A node whose signalling lives in its own VRF
%%% 	therefore has to be started under `ip vrf exec', which puts the
%%% 	whole node in one VRF and rules out a node with legs in two. The
%%% 	`socket' module can bind a device per socket, which is how FRR
%%% 	holds sessions in dozens of VRFs from one process.
%%%
%%% 	`{device, "sig"}' in the option list is that binding. Give it and
%%% 	the beam need not run inside the VRF at all, which is worth more
%%% 	than tidiness: `ip vrf exec' takes loopback with it, and with
%%% 	loopback go epmd, distribution and every way of asking a running
%%% 	node a question.
%%%
%%% 	== What the caller still sees ==
%%%
%%% 	The four state machines keep the `gen_sctp' option lists and the
%%% 	`gen_sctp' messages; this module and {@link m3ua_receiver} take
%%% 	the difference. Options arrive as they always did and are turned
%%% 	into `socket' calls here, one at a time, so a rejected option can
%%% 	be named rather than collapsing the whole open into `einval'.
%%%
%%% 	== Four things measured rather than assumed ==
%%%
%%% 	<ul>
%%% 		<li>`struct sctp_sndrcvinfo' has <b>two octets of padding</b>
%%% 			between `flags' and `ppid'. Reading them adjacent puts
%%% 			`assoc_id' two octets adrift, and the symptom is data
%%% 			arriving on an association nobody has heard of.</li>
%%% 		<li>The protocol identifier is held in <b>big-endian</b>, which
%%% 			is what `gen_sctp' writes and therefore what the peers we
%%% 			already interoperate with expect. The `socket' module's own
%%% 			decoding of that field reads it in native order and so
%%% 			answers 50331648 where the wire says 3 -- everything else
%%% 			in its decoded map is right, that one field is not, and
%%% 			{@link ancillary/1} takes it from the octets instead.</li>
%%% 		<li>`SCTP_DEFAULT_SEND_PARAM' is copied into an association
%%% 			when the association is created, so it must be set
%%% 			<b>before</b> connecting or listening. Set afterwards it is
%%% 			accepted, changes nothing, and the identifier silently goes
%%% 			out as zero.</li>
%%% 		<li>A per-message ancillary replaces that default wholesale.
%%% 			Every send here names a stream, so every send carries an
%%% 			ancillary, so every send must spell the identifier out --
%%% 			which is why {@link ppid/1} reads it back off the socket
%%% 			once and the callers keep it.</li>
%%% 	</ul>
%%%
%%% @end
-module(m3ua_sctp).
-copyright('Copyright (c) 2026 MTX Connect S.a r.l.').

-export([open/1, listen/1, close/1, connect_init/4, peeloff/2,
		controlling_process/2, send/5, recvmsg/2, sockname/1,
		getstat/1, getstat/2, status/2, ppid/1, error_string/1]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

-type sock() :: socket:socket().
-export_type([sock/0]).

%% Level and options from <linux/sctp.h>. The socket module has names
%% for a handful of SCTP options and not for these, so they go through
%% setopt_native/getopt_native by number.
-define(SOL_SCTP, 132).
-define(SCTP_NODELAY, 3).
-define(SCTP_ADAPTATION_LAYER, 7).
-define(SCTP_DEFAULT_SEND_PARAM, 10).
-define(SCTP_EVENTS, 11).
-define(SCTP_STATUS, 14).
%% Repeatable, and per peer: socket:connect/2 answers eisconn the
%% second time, which a one-to-many endpoint cannot live with.
-define(SCTP_SOCKOPT_CONNECTX, 107).

%% Ancillary types: 1 is `struct sctp_sndrcvinfo', which is what
%% arrives on a receive; 2 is `struct sctp_sndinfo', which is what a
%% send has to use -- type 1 on a send is accepted and drops the
%% protocol identifier on the floor.
-define(SCTP_SNDRCV, 1).
-define(SCTP_SNDINFO, 2).

%% What gen_sctp subscribes to when it opens a socket, measured on
%% both: a fresh socket-module socket has every event off, a fresh
%% gen_sctp socket has the first seven on. gen_sctp then applies the
%% caller's record on top of that, so an option list that named one
%% event kept the rest -- and the same list handed to a bare socket
%% would have subscribed to that one event alone. The baseline goes on
%% first here so the option lists the state machines build keep the
%% meaning they have always had.
-define(BASELINE, #sctp_event_subscribe{data_io_event = true,
		association_event = true, address_event = true,
		send_failure_event = true, peer_error_event = true,
		shutdown_event = true, partial_delivery_event = true,
		adaptation_layer_event = false}).

%% struct sctp_status is 176 octets here, not the 184 that adding up
%% the header would suggest; the size is measured, and the fields it
%% is read for are cross-checked against inet:getopts/2 on the same
%% association.
-define(STATUS_SIZE, 176).

%%----------------------------------------------------------------------
%%  The m3ua_sctp API
%%----------------------------------------------------------------------

-spec open(Options) -> Result
	when
		Options :: [gen_sctp:option()],
		Result :: {ok, Socket :: sock()} | {error, Reason :: term()}.
%% @doc Open an SCTP endpoint.
%%
%% 	Takes the option list the state machines already build. Anything
%% 	this does not know how to set is an error naming the option: an
%% 	endpoint that came up having quietly ignored `recbuf' is worse
%% 	than one that refused to come up.
open(Options) when is_list(Options) ->
	Family = family(Options),
	case socket:open(Family, seqpacket, sctp) of
		{ok, Socket} ->
			case setopts(Socket, [{sctp_events, ?BASELINE} | Options]) of
				ok ->
					bind(Socket, Family, Options);
				{error, Reason} ->
					_ = socket:close(Socket),
					{error, Reason}
			end;
		{error, _Reason} = Error ->
			Error
	end.

-spec listen(Socket :: sock()) -> ok | {error, Reason :: term()}.
%% @doc Accept associations on `Socket'.
listen(Socket) ->
	socket:listen(Socket).

-spec close(Socket :: sock()) -> ok | {error, Reason :: term()}.
%% @doc Close `Socket'.
close(Socket) ->
	case socket:close(Socket) of
		{error, closed} ->
			ok;
		Other ->
			Other
	end.

-spec connect_init(Socket, Address, Port, Options) -> Result
	when
		Socket :: sock(),
		Address :: inet:ip_address(),
		Port :: inet:port_number(),
		Options :: [gen_sctp:option()],
		Result :: ok | {error, Reason :: term()}.
%% @doc Ask for an association, without waiting for one.
%%
%% 	The answer arrives as an `#sctp_assoc_change{}' like it always
%% 	did. `einprogress' is that answer and not a fault.
connect_init(Socket, Address, Port, _Options) ->
	case socket:setopt_native(Socket,
			{?SOL_SCTP, ?SCTP_SOCKOPT_CONNECTX}, sockaddr(Address, Port)) of
		ok ->
			ok;
		{error, einprogress} ->
			ok;
		{error, _Reason} = Error ->
			Error
	end.

-spec peeloff(Socket, Assoc) -> Result
	when
		Socket :: sock(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, NewSocket :: sock()} | {error, Reason :: term()}.
%% @doc Take one association off a one-to-many socket.
%%
%% 	The events subscription and the default send parameters come with
%% 	it, and a send on the result needs no address.
peeloff(Socket, Assoc) ->
	socket:peeloff(Socket, Assoc).

-spec controlling_process(Socket, Pid) -> Result
	when
		Socket :: sock(),
		Pid :: pid(),
		Result :: ok | {error, Reason :: term()}.
%% @doc Hand `Socket' to `Pid', which is thereafter what keeps it open.
controlling_process(Socket, Pid) ->
	socket:setopt(Socket, otp, controlling_process, Pid).

-spec send(Socket, Peer, Stream, Ppid, Data) -> Result
	when
		Socket :: sock(),
		Peer :: {inet:ip_address(), inet:port_number()},
		Stream :: non_neg_integer(),
		Ppid :: non_neg_integer(),
		Data :: binary() | iolist(),
		Result :: ok | {error, Reason :: term()}.
%% @doc Send on one stream of an association.
%%
%% 	The destination is always named. An sgp holds a socket peeled off
%% 	the listening one and an asp holds the one it connected on, and
%% 	those are not the same kind of socket: measured, an unaddressed
%% 	send answers `epipe' on the one the asp holds and works on the
%% 	one the sgp holds, while an addressed send works on both. One
%% 	rule rather than two, and nowhere the difference has to be
%% 	remembered.
send(Socket, {Address, Port}, Stream, Ppid, Data) when is_binary(Data) ->
	Msg = #{addr => #{family => family(Address), addr => Address,
					port => Port},
			iov => [Data],
			ctrl => [#{level => sctp, type => ?SCTP_SNDINFO,
					data => sndinfo(Stream, Ppid)}]},
	socket:sendmsg(Socket, Msg);
send(Socket, Peer, Stream, Ppid, Data) when is_list(Data) ->
	send(Socket, Peer, Stream, Ppid, iolist_to_binary(Data)).

-spec recvmsg(Socket, Timeout) -> Result
	when
		Socket :: sock(),
		Timeout :: timeout() | nowait,
		Result :: {ok, {Address, Port, AncData, Data}}
				| {select, socket:select_info()}
				| {error, Reason :: term()},
		Address :: inet:ip_address() | undefined,
		Port :: inet:port_number() | undefined,
		AncData :: [#sctp_sndrcvinfo{}],
		Data :: binary() | tuple().
%% @doc Read one message or one notification.
%%
%% 	`Data' is a binary for a message and the notification record for
%% 	a notification, which is the shape {@link m3ua_receiver} passes on
%% 	and therefore the shape the state machines match on.
recvmsg(Socket, Timeout) ->
	case socket:recvmsg(Socket, 0, 0, [], Timeout) of
		{ok, Msg} ->
			{ok, delivered(Msg)};
		{select, _} = Select ->
			Select;
		{error, _Reason} = Error ->
			Error
	end.

-spec sockname(Socket :: sock()) -> Result
	when
		Result :: {ok, {inet:ip_address(), inet:port_number()}}
				| {error, Reason :: term()}.
%% @doc The local address, in the shape `inet:sockname/1' answered in.
sockname(Socket) ->
	case socket:sockname(Socket) of
		{ok, #{addr := Address, port := Port}} ->
			{ok, {Address, Port}};
		{ok, _Other} ->
			{error, einval};
		{error, _Reason} = Error ->
			Error
	end.

-spec getstat(Socket :: sock()) -> Result
	when
		Result :: {ok, [{Option :: atom(), Value :: integer()}]}
				| {error, Reason :: term()}.
%% @doc Counters for `Socket'.
%%
%% 	Six of `inet:getstat/1''s ten have a counter behind them here.
%% 	The other four -- the two smoothed averages, the deviation and the
%% 	pending count -- are the inet driver's own bookkeeping and have no
%% 	equivalent, so they are left out rather than reported as zero: a
%% 	`send_pend' of 0 that is really "not counted" is the sort of
%% 	number somebody reads a conclusion out of.
getstat(Socket) ->
	getstat(Socket, [recv_oct, recv_cnt, recv_max,
			send_oct, send_cnt, send_max]).

-spec getstat(Socket, Options) -> Result
	when
		Socket :: sock(),
		Options :: [atom()],
		Result :: {ok, [{Option :: atom(), Value :: integer()}]}
				| {error, Reason :: term()}.
%% @doc The named counters for `Socket'.
getstat(Socket, Options) when is_list(Options) ->
	#{counters := Counters} = socket:info(Socket),
	{ok, [{Option, maps:get(counter(Option), Counters, 0)}
			|| Option <- Options, counter(Option) /= undefined]}.

-spec status(Socket, Assoc) -> Result
	when
		Socket :: sock(),
		Assoc :: gen_sctp:assoc_id(),
		Result :: {ok, #sctp_status{}} | {error, Reason :: term()}.
%% @doc The state of one association, as `m3ua:sctp_status/2' reports it.
status(Socket, Assoc) ->
	Ask = <<Assoc:32/native-signed, 0:((?STATUS_SIZE - 4) * 8)>>,
	case socket:getopt_native(Socket, {?SOL_SCTP, ?SCTP_STATUS}, Ask) of
		{ok, Status} ->
			decode_status(Status);
		{error, _Reason} = Error ->
			Error
	end.

-spec ppid(Socket :: sock()) -> non_neg_integer().
%% @doc The protocol identifier this socket was opened with.
%%
%% 	Read back rather than passed down, because it is set at open time
%% 	from an option the state machine that opens the socket handles and
%% 	the one that sends on it never sees. `{ppi, false}' leaves it
%% 	unset, and this then answers 0, which is what that option means.
ppid(Socket) ->
	case socket:getopt_native(Socket,
			{?SOL_SCTP, ?SCTP_DEFAULT_SEND_PARAM}, 32) of
		{ok, <<_:8/binary, Ppid:32/big, _/binary>>} ->
			Ppid;
		_Other ->
			0
	end.

-spec error_string(Error :: integer()) -> string().
%% @doc Name an SCTP error cause, as `gen_sctp:error_string/1' does.
error_string(0) -> "ok";
error_string(1) -> "Invalid Stream Identifier";
error_string(2) -> "Missing Mandatory Parameter";
error_string(3) -> "Stale Cookie Error";
error_string(4) -> "Out of Resource";
error_string(5) -> "Unresolvable Address";
error_string(6) -> "Unrecognized Chunk Type";
error_string(7) -> "Invalid Mandatory Parameter";
error_string(8) -> "Unrecognized Parameters";
error_string(9) -> "No User Data";
error_string(10) -> "Cookie Received While Shutting Down";
error_string(11) -> "Restart of an Association with New Addresses";
error_string(12) -> "User Initiated Abort";
error_string(13) -> "Protocol Violation";
error_string(Reason) when is_atom(Reason) -> atom_to_list(Reason);
error_string(_) -> "Unknown Error".

%%----------------------------------------------------------------------
%%  Internal functions
%%----------------------------------------------------------------------

%% @hidden
family(Address) when tuple_size(Address) == 4 ->
	inet;
family(Address) when tuple_size(Address) == 8 ->
	inet6;
family(Options) when is_list(Options) ->
	case lists:keyfind(ip, 1, Options) of
		{ip, Address} when tuple_size(Address) == 8 ->
			inet6;
		_Other ->
			case lists:member(inet6, Options) of
				true -> inet6;
				false -> inet
			end
	end.

%% @hidden
bind(Socket, Family, Options) ->
	Address = case lists:keyfind(ip, 1, Options) of
		{ip, A} -> A;
		false when Family == inet6 -> any;
		false -> any
	end,
	Port = case lists:keyfind(port, 1, Options) of
		{port, P} -> P;
		false -> 0
	end,
	case socket:bind(Socket, #{family => Family,
			addr => Address, port => Port}) of
		ok ->
			{ok, Socket};
		{error, Reason} ->
			_ = socket:close(Socket),
			{error, Reason}
	end.

%% @hidden
%% 	One option at a time, so a failure names the option that failed.
setopts(_Socket, []) ->
	ok;
setopts(Socket, [Option | T]) ->
	case setopt(Socket, Option) of
		ok ->
			setopts(Socket, T);
		{error, Reason} ->
			{error, {Option, Reason}}
	end.

%% @hidden
%% 	The receiver holds the active mode, and the address and port are
%% 	the bind; both are handled elsewhere and are not faults here.
setopt(_Socket, {active, _}) ->
	ok;
setopt(_Socket, {ip, _}) ->
	ok;
setopt(_Socket, {port, _}) ->
	ok;
setopt(_Socket, inet) ->
	ok;
setopt(_Socket, inet6) ->
	ok;
setopt(Socket, {device, Device}) when is_list(Device) ->
	%% What the whole transport change was for. Bound into a VRF the
	%% socket reaches the signalling network while the beam stays in
	%% the default VRF, where loopback works -- and with loopback come
	%% epmd, distribution and every way of asking a running node a
	%% question. Measured on the host, unprivileged, no CAP_NET_RAW.
	%% It goes on before the bind, which is why every option in this
	%% list is applied before open/1 binds.
	socket:setopt(Socket, {socket, bindtodevice}, Device);
setopt(_Socket, {device, undefined}) ->
	ok;
setopt(Socket, {reuseaddr, Boolean}) ->
	socket:setopt(Socket, socket, reuseaddr, Boolean);
setopt(Socket, {recbuf, Size}) ->
	socket:setopt(Socket, socket, rcvbuf, Size);
setopt(Socket, {sndbuf, Size}) ->
	socket:setopt(Socket, socket, sndbuf, Size);
setopt(Socket, {sctp_nodelay, Boolean}) ->
	socket:setopt_native(Socket, {?SOL_SCTP, ?SCTP_NODELAY},
			<<(boolean(Boolean)):32/native>>);
setopt(Socket, {sctp_events, #sctp_event_subscribe{} = Events}) ->
	%% Read, modify, write. The record's fields default to `undefined',
	%% not to `false', and a caller naming one event means "and this
	%% one too" rather than "only this one". Writing the record out
	%% whole turns the rest off: m3ua asks for the adaptation layer
	%% event and would silently lose data_io and association with it,
	%% at which point a listening socket is never told an association
	%% came up and simply waits.
	case socket:getopt_native(Socket, {?SOL_SCTP, ?SCTP_EVENTS}, 11) of
		{ok, Current} ->
			socket:setopt_native(Socket, {?SOL_SCTP, ?SCTP_EVENTS},
					events(Events, Current));
		{error, _Reason} = Error ->
			Error
	end;
setopt(Socket, {sctp_adaptation_layer,
		#sctp_setadaptation{adaptation_ind = Indication}}) ->
	socket:setopt_native(Socket, {?SOL_SCTP, ?SCTP_ADAPTATION_LAYER},
			<<Indication:32/native>>);
setopt(Socket, {sctp_default_send_param, #sctp_sndrcvinfo{} = Info}) ->
	%% Before any association exists, which is where the state machines
	%% call this from and the only place it takes effect.
	socket:setopt_native(Socket,
			{?SOL_SCTP, ?SCTP_DEFAULT_SEND_PARAM}, sndrcvinfo(Info));
setopt(_Socket, _Option) ->
	{error, enoprotoopt}.

%% @hidden
%% 	`struct sctp_event_subscribe' is eleven octets, one per event, in
%% 	the order the header declares them, and `Current' is what the
%% 	socket already has. Only the fields the caller named are changed.
events(#sctp_event_subscribe{data_io_event = DataIo,
		association_event = Assoc, address_event = Address,
		send_failure_event = SendFailure, peer_error_event = PeerError,
		shutdown_event = Shutdown, partial_delivery_event = Partial,
		adaptation_layer_event = Adaptation},
		<<DataIo0, Assoc0, Address0, SendFailure0, PeerError0,
		Shutdown0, Partial0, Adaptation0, Rest/binary>>) ->
	<<(flag(DataIo, DataIo0)), (flag(Assoc, Assoc0)),
			(flag(Address, Address0)), (flag(SendFailure, SendFailure0)),
			(flag(PeerError, PeerError0)), (flag(Shutdown, Shutdown0)),
			(flag(Partial, Partial0)), (flag(Adaptation, Adaptation0)),
			Rest/binary>>.

%% @hidden
flag(undefined, Current) -> Current;
flag(true, _Current) -> 1;
flag(false, _Current) -> 0;
flag(N, _Current) when is_integer(N) -> N.

%% @hidden
boolean(true) -> 1;
boolean(false) -> 0;
boolean(N) when is_integer(N) -> N;
boolean(undefined) -> 0.

%% @hidden
%% 	`struct sockaddr_in' or `sockaddr_in6', padded out to the size the
%% 	kernel copies. AF_INET is 2 and AF_INET6 is 10 on Linux.
sockaddr({A, B, C, D}, Port) ->
	<<2:16/native, Port:16/big, A, B, C, D, 0:64>>;
sockaddr({A, B, C, D, E, F, G, H}, Port) ->
	<<10:16/native, Port:16/big, 0:32, A:16/big, B:16/big, C:16/big,
			D:16/big, E:16/big, F:16/big, G:16/big, H:16/big, 0:32>>.

%% @hidden
%% 	`struct sctp_sndinfo': stream, flags, the identifier, a context
%% 	and the association. The identifier is big-endian; see the note at
%% 	the top of this module.
sndinfo(Stream, Ppid) ->
	<<Stream:16/native, 0:16/native, Ppid:32/big,
			0:32/native, 0:32/native-signed>>.

%% @hidden
%% 	`struct sctp_sndrcvinfo'. **Two octets of padding sit between
%% 	flags and ppid** -- the compiler puts them there to align a
%% 	four-octet field, and leaving them out shifts everything after.
sndrcvinfo(#sctp_sndrcvinfo{stream = Stream, ssn = Ssn, flags = Flags,
		ppid = Ppid, context = Context, timetolive = TimeToLive,
		assoc_id = Assoc}) ->
	<<(zero(Stream)):16/native, (zero(Ssn)):16/native,
			(flags(Flags)):16/native, 0:16,
			(zero(Ppid)):32/big, (zero(Context)):32/native,
			(zero(TimeToLive)):32/native, 0:32/native, 0:32/native,
			(zero(Assoc)):32/native-signed>>.

%% @hidden
zero(undefined) -> 0;
zero(N) when is_integer(N) -> N.

%% @hidden
flags(undefined) -> 0;
flags(N) when is_integer(N) -> N;
flags(L) when is_list(L) -> 0.

%% @hidden
%% 	One received message, in the shape gen_sctp delivered it.
delivered(#{notification := Notification} = Msg) ->
	Address = maps:get(addr, Msg, undefined),
	{address(Address), port(Address), [],
			notification(Notification, address(Address), port(Address))};
delivered(#{addr := Address, iov := Iov, ctrl := Ctrl}) ->
	{address(Address), port(Address), ancillary(Ctrl),
			iolist_to_binary(Iov)};
delivered(#{iov := Iov, ctrl := Ctrl}) ->
	{undefined, undefined, ancillary(Ctrl), iolist_to_binary(Iov)}.

%% @hidden
address(#{addr := Address}) -> Address;
address(_Other) -> undefined.

%% @hidden
port(#{port := Port}) -> Port;
port(_Other) -> undefined.

%% @hidden
%% 	The runtime decodes the ancillary for us, and everything in its
%% 	map is right except the protocol identifier, which it reads in
%% 	native order where the octets are big-endian. So take that one
%% 	field from the octets and the rest from the map.
ancillary([#{level := sctp, type := Type,
		value := #{} = Value, data := Data} | _])
		when Type == sndrcv; Type == ?SCTP_SNDRCV ->
	[sndrcvinfo(Value, Data)];
ancillary([#{level := sctp, type := Type, data := Data} | _])
		when Type == sndrcv; Type == ?SCTP_SNDRCV ->
	case decode_sndrcvinfo(Data) of
		#sctp_sndrcvinfo{} = Info ->
			[Info];
		undefined ->
			[]
	end;
ancillary([_Other | T]) ->
	ancillary(T);
ancillary([]) ->
	[].

%% @hidden
sndrcvinfo(#{} = Value, Data) ->
	#sctp_sndrcvinfo{stream = maps:get(stream, Value, 0),
			ssn = maps:get(ssn, Value, 0),
			flags = maps:get(flags, Value, []),
			ppid = big_ppid(Data, maps:get(ppid, Value, 0)),
			context = maps:get(context, Value, 0),
			timetolive = maps:get(time_to_live, Value, 0),
			tsn = maps:get(tsn, Value, 0),
			cumtsn = maps:get(cum_tsn, Value, 0),
			assoc_id = maps:get(assoc_id, Value, 0)}.

%% @hidden
big_ppid(<<_:8/binary, Ppid:32/big, _/binary>>, _Native) ->
	Ppid;
big_ppid(_Other, Native) ->
	Native.

%% @hidden
%% 	0 stream, 2 ssn, 4 flags, 6 padding, 8 ppid, 12 context,
%% 	16 timetolive, 20 tsn, 24 cumtsn, 28 assoc_id.
decode_sndrcvinfo(<<Stream:16/native, Ssn:16/native, Flags:16/native,
		_Padding:16, Ppid:32/big, Context:32/native, TimeToLive:32/native,
		Tsn:32/native, CumTsn:32/native, Assoc:32/native-signed,
		_/binary>>) ->
	#sctp_sndrcvinfo{stream = Stream, ssn = Ssn, flags = Flags,
			ppid = Ppid, context = Context, timetolive = TimeToLive,
			tsn = Tsn, cumtsn = CumTsn, assoc_id = Assoc};
decode_sndrcvinfo(_Other) ->
	undefined.

%% @hidden
%% 	The runtime hands notifications over decoded; turn each into the
%% 	record the state machines match on. A notification it does not
%% 	name is not one m3ua subscribed to.
notification(#{type := assoc_change} = N, _Address, _Port) ->
	#sctp_assoc_change{state = maps:get(state, N, undefined),
			error = maps:get(error, N, 0),
			outbound_streams = maps:get(outbound_streams, N, 0),
			inbound_streams = maps:get(inbound_streams, N, 0),
			assoc_id = maps:get(assoc_id, N, 0)};
notification(#{type := peer_addr_change} = N, Address, Port) ->
	#sctp_paddr_change{addr = {Address, Port},
			state = paddr_state(maps:get(state, N, undefined)),
			error = maps:get(error, N, 0),
			assoc_id = maps:get(assoc_id, N, 0)};
notification(#{type := shutdown_event} = N, _Address, _Port) ->
	#sctp_shutdown_event{assoc_id = maps:get(assoc_id, N, 0)};
notification(#{type := adaptation_event} = N, _Address, _Port) ->
	#sctp_adaptation_event{adaptation_ind = maps:get(adaptation_indication,
			N, 0),
			assoc_id = maps:get(assoc_id, N, 0)};
notification(#{type := Type} = N, _Address, _Port)
		when Type == send_failed; Type == send_failed_event ->
	#sctp_send_failed{flags = maps:get(flags, N, []),
			error = maps:get(error, N, 0),
			info = maps:get(info, N, undefined),
			assoc_id = maps:get(assoc_id, N, 0),
			data = maps:get(data, N, <<>>)};
notification(#{type := remote_error} = N, _Address, _Port) ->
	#sctp_remote_error{error = maps:get(error, N, 0),
			assoc_id = maps:get(assoc_id, N, 0),
			data = maps:get(data, N, <<>>)};
notification(#{} = N, _Address, _Port) ->
	N.

%% @hidden
%% 	inet's name on the left, the socket module's counter on the right.
%% 	The four with no counter answer undefined and are dropped.
counter(recv_oct) -> read_byte;
counter(recv_cnt) -> read_pkg;
counter(recv_max) -> read_pkg_max;
counter(send_oct) -> write_byte;
counter(send_cnt) -> write_pkg;
counter(send_max) -> write_pkg_max;
counter(_Other) -> undefined.

%% @hidden
%% 	Cross-checked against inet:getopts/2 on the same association: the
%% 	association, the state, the window, the counts, the streams and
%% 	the fragmentation point all agree. The primary address follows at
%% 	offset 24 and is decoded from there.
decode_status(<<Assoc:32/native-signed, State:32/native-signed,
		Rwnd:32/native, UnackData:16/native, PendData:16/native,
		InStreams:16/native, OutStreams:16/native, FragPoint:32/native,
		Primary/binary>>) ->
	{ok, #sctp_status{assoc_id = Assoc, state = state(State), rwnd = Rwnd,
			unackdata = UnackData, penddata = PendData,
			instrms = InStreams, outstrms = OutStreams,
			fragmentation_point = FragPoint, primary = paddrinfo(Primary)}};
decode_status(_Other) ->
	{error, einval}.

%% @hidden
%% 	`struct sctp_paddrinfo': the association, a sockaddr_storage of
%% 	128 octets, then the state and four counters. 152 octets, which
%% 	with the 24 before it is the 176 the kernel copies.
paddrinfo(<<Assoc:32/native-signed, Address:128/binary,
		State:32/native-signed, Cwnd:32/native, Srtt:32/native,
		Rto:32/native, Mtu:32/native, _/binary>>) ->
	#sctp_paddrinfo{assoc_id = Assoc, address = sockaddr_in(Address),
			state = path_state(State), cwnd = Cwnd, srtt = Srtt,
			rto = Rto, mtu = Mtu};
paddrinfo(_Other) ->
	undefined.

%% @hidden
sockaddr_in(<<2:16/native, Port:16/big, A, B, C, D, _/binary>>) ->
	{{A, B, C, D}, Port};
sockaddr_in(<<10:16/native, Port:16/big, _Flow:32, A:16/big, B:16/big,
		C:16/big, D:16/big, E:16/big, F:16/big, G:16/big, H:16/big,
		_/binary>>) ->
	{{A, B, C, D, E, F, G, H}, Port};
sockaddr_in(_Other) ->
	undefined.

%% @hidden
state(0) -> empty;
state(1) -> closed;
state(2) -> cookie_wait;
state(3) -> cookie_echoed;
state(4) -> established;
state(5) -> shutdown_pending;
state(6) -> shutdown_sent;
state(7) -> shutdown_received;
state(8) -> shutdown_ack_sent;
state(N) -> N.

%% @hidden
%% 	The state of one peer address. The runtime hands this over as an
%% 	integer where it hands the association's own state over as an
%% 	atom, so the numbers from <linux/sctp.h> are named here. Two of
%% 	them decide whether an association lives: m3ua notes the peer's
%% 	address on `addr_confirmed' and takes the association down on
%% 	`addr_unreachable'.
paddr_state(0) -> addr_available;
paddr_state(1) -> addr_unreachable;
paddr_state(2) -> addr_removed;
paddr_state(3) -> addr_added;
paddr_state(4) -> addr_made_prim;
paddr_state(5) -> addr_confirmed;
paddr_state(State) -> State.

%% @hidden
%% 	And the state of a path, as SCTP_GET_PEER_ADDR_INFO reports it,
%% 	which is a different enumeration entirely.
path_state(0) -> inactive;
path_state(1) -> active;
path_state(2) -> unconfirmed;
path_state(N) -> N.
