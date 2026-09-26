%%% m3ua_sgp_fsm.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2015-2025 SigScale Global Inc.
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
%%% @doc This {@link //stdlib/gen_statem. gen_statem} behaviour callback module
%%% 	implements a communicating finite state machine within the
%%% 	{@link //m3ua. m3ua} application handling an SCTP association
%%%   for a Signaling Gateway Process (SGP).
%%%
%%% 	This behaviour module provides an MTP service primitives interface
%%% 	for an MTP user. A callback module name is provided when starting
%%% 	an `Endpoint'. MTP service primitive indications are delivered to
%%% 	the MTP user through calls to the corresponding callback functions
%%% 	as defined below.
%%%
%%%  <h2><a name="functions">Callbacks</a></h2>
%%%
%%%  <h3 class="function"><a name="init-5">init/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>init(Module, SGP, EP, EpName, Assoc, Options) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Module = atom()</tt></li>
%%%    <li><tt>SGP = pid()</tt></li>
%%%    <li><tt>EP = pid()</tt></li>
%%%    <li><tt>EpName = term()</tt></li>
%%%    <li><tt>Assoc = gen_sctp:assoc_id()</tt></li>
%%%    <li><tt>Options = term()</tt></li>
%%%    <li><tt>Result = {ok, Active, State} | {ok, Active, State, RKs} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>RKs = [{RC, RK, AsName}]</tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>RK = {NA, Keys, TMT}</tt></li>
%%%    <li><tt>NA = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>Keys = [m3ua:key()]</tt></li>
%%%    <li><tt>Mode = m3ua:tmt()</tt></li>
%%%    <li><tt>AsName = term()</tt></li>
%%%    <li><tt>Reason = term()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Initialize SGP callback handler.</p>
%%%  <p>Called when SGP is started.</p>
%%%
%%%  <h3 class="function"><a name="recv-9">recv/9</a></h3>
%%%  <div class="spec">
%%%  <p><tt>recv(Stream, RC, OPC, DPC, NI, SI, SLS,
%%%         Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined </tt></li>
%%%    <li><tt>OPC = 0..16777215</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>NI = byte() </tt></li>
%%%    <li><tt>SI = byte() </tt></li>
%%%    <li><tt>SLS = byte() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-TRANSFER indication.</p>
%%%  <p>Called when data has arrived for the MTP user.</p>
%%%
%%%  <h3 class="function"><a name="send-11">send/11</a></h3>
%%%  <div class="spec">
%%%  <p><tt>send(From, Ref, Stream, RC, OPC, DPC, NI, SI, SLS,
%%%        Data, State) -&gt; Result</tt>
%%%  <ul class="definitions">
%%%    <li><tt>From = pid()</tt></li>
%%%    <li><tt>Ref = reference()</tt></li>
%%%    <li><tt>Stream = pos_integer()</tt></li>
%%%    <li><tt>RC = 0..4294967295 | undefined</tt></li>
%%%    <li><tt>OPC = 0..16777215</tt></li>
%%%    <li><tt>DPC = 0..16777215</tt></li>
%%%    <li><tt>NI = byte() </tt></li>
%%%    <li><tt>SI = byte() </tt></li>
%%%    <li><tt>SLS = byte() </tt></li>
%%%    <li><tt>Data = binary() </tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-TRANSFER confirm.</p>
%%%  <p>Called when data has been sent by the MTP user.</p>
%%%
%%%  <h3 class="function"><a name="status-4">status/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>status(Stream, RCs, APCs, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RCs = [RC]</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>APCs = [APC]</tt></li>
%%%    <li><tt>APC = 0..16777215</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>MTP-STATUS indication.</p>
%%%  <p>Called when congestion occurs at an ASP.</p>
%%%
%%%  <h3 class="function"><a name="register-5">register/5</a></h3>
%%%  <div class="spec">
%%%  <p><tt>register(RC, NA, Keys, TMT, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>NA = 0..4294967295</tt></li>
%%%    <li><tt>Keys = [m3ua:key()]</tt></li>
%%%    <li><tt>TMT = m3ua:tmt()</tt></li>
%%%    <li><tt>State = term() </tt></li>
%%%    <li><tt>Result = {ok, NewState} | {error, Reason} </tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-RK_REG indication.</p>
%%%  <p>Called after successfully processing an
%%%   incoming Registration request or static registration completes.</p>
%%%
%%%  <h3 class="function"><a name="asp_up-1">asp_up/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_up(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_UP indication.</p>
%%%  <p>Called when ASP UP ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_down-1">asp_down/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_down(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_DOWN indication.</p>
%%%  <p>Called when ASP DOWN ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_active-1">asp_active/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_active(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_ACTIVE indication.</p>
%%%  <p>Called when ASP ACTIVE ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="asp_inactive-1">asp_inactive/1</a></h3>
%%%  <div class="spec">
%%%  <p><tt>asp_inactive(State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State} </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-ASP_INACTIVE indication.</p>
%%%  <p>Called when ASP INACTIVE ACK is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="notify-4">notify/4</a></h3>
%%%  <div class="spec">
%%%  <p><tt>notify(RCs, Status, AspID, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>RCs = [RC] | undefined</tt></li>
%%%    <li><tt>RC = 0..4294967295</tt></li>
%%%    <li><tt>Status = as_inactive | as_active | as_pending
%%%         | insufficient_asp_active | alternate_asp_active
%%%         | asp_failure</tt></li>
%%%    <li><tt>AspID = 0..4294967295</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, State}</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>M-NOTIFY indication.</p>
%%%  <p>Called when NOTIFY is sent to ASP.</p>
%%%
%%%  <h3 class="function"><a name="info-2">info/2</a></h3>
%%%  <div class="spec">
%%%  <p><tt>info(Info, State) -&gt; Result </tt>
%%%  <ul class="definitions">
%%%    <li><tt>Info = term()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%    <li><tt>Result = {ok, Active, NewState} | {error, Reason}</tt></li>
%%%    <li><tt>Active = true | false | once | pos_integer()</tt></li>
%%%    <li><tt>NewState = term() </tt></li>
%%%    <li><tt>Reason = term() </tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Handle info callback.</p>
%%%  <p>Called when other information is received by SGP.</p>
%%%
%%%  <h3 class="function"><a name="terminate-2">terminate/2</a></h3>
%%%  <div class="spec">
%%%  <p><tt>terminate(Reason, State)</tt>
%%%  <ul class="definitions">
%%%    <li><tt>Reason = term()</tt></li>
%%%    <li><tt>State = term()</tt></li>
%%%  </ul></p>
%%%  </div>
%%%  <p>Terminate ASP.</p>
%%%  <p>Called when an ASP shall be shutdown.</p>
%%%
%%% @end
-module(m3ua_sgp_fsm).
-copyright('Copyright (c) 2015-2025 SigScale Global Inc.').

-behaviour(gen_statem).

%% export the callbacks needed for gen_statem behaviour
-export([init/1, callback_mode/0, terminate/3, code_change/4]).

%% export the gen_statem state callbacks
-export([down/3, inactive/3, active/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").
-include_lib("kernel/include/logger.hrl").

-record(statedata,
		{socket :: m3ua_sctp:sock() | undefined,
		receiver :: undefined | pid(),
		ppid = 0 :: non_neg_integer(),
		active :: true | false | once | pos_integer(),
		peer_addr :: inet:ip_address(),
		peer_port :: inet:port_number(),
		in_streams :: non_neg_integer(),
		out_streams :: non_neg_integer(),
		assoc :: gen_sctp:assoc_id(),
		rks = [] :: [{RC :: 0..4294967295,
				RK :: m3ua:routing_key(),
				AsState :: down | inactive | active | pending}],
		registered = [] :: [RC :: 0..4294967295],
		ual :: undefined | integer(),
		stream :: undefined | pos_integer(),
		ep :: pid(),
		ep_name :: term(),
		static :: boolean(),
		use_rc :: boolean(),
		callback :: atom() | #m3ua_fsm_cb{},
		cb_opts :: term(),
		cb_state :: term(),
		count = #{} :: #{atom() => non_neg_integer()},
		lm :: undefined | pid()}).

%%----------------------------------------------------------------------
%%  Interface functions
%%----------------------------------------------------------------------

-callback init(Module, SGP, EP, EpName, Assoc, Options) -> Result
	when
		Module :: atom(),
		SGP :: pid(),
		EP :: pid(),
		EpName :: term(),
		Assoc :: gen_sctp:assoc_id(),
		Options :: term(),
		Result :: {ok, Active, State} | {ok, Active, State, ASs} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		State :: term(),
		ASs :: [{RC, RK, AsName}],
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: 0..4294967295 | undefined,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt(),
		AsName :: term(),
		Reason :: term().
-callback recv(Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback send(From, Ref, Stream, RC, OPC, DPC, NI, SI, SLS, Data, State) -> Result
	when
		From :: pid(),
		Ref :: reference(),
		Stream :: pos_integer(),
		RC :: 0..4294967295 | undefined,
		OPC :: 0..16777215,
		DPC :: 0..16777215,
		NI :: byte(),
		SI :: byte(),
		SLS :: byte(),
		Data :: binary(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback status(Stream, RCs, DPCs, State) -> Result
	when
		Stream :: pos_integer(),
		RCs :: [RC],
		RC :: 0..4294967295,
		DPCs :: [DPC],
		DPC :: 0..16777215,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
%% Called when a destination audit (DAUD) is received.  An ASP is
%% asking whether the affected point codes are available.  Only the
%% signalling gateway knows, so the answer is not sent from here: the
%% callback is expected to reply with m3ua:duna/3, m3ua:dava/3 or
%% m3ua:drst/3 as the case may be (RFC 4666 4.4.1.5).
-callback audit(Stream, RCs, APCs, State) -> Result
	when
		Stream :: pos_integer(),
		RCs :: [RC],
		RC :: 0..4294967295,
		APCs :: [APC],
		APC :: 0..16777215,
		State :: term(),
		Result :: {ok, State}.

-callback register(RC, NA, Keys, TMT, State) -> Result
	when
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt(),
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-callback asp_up(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_down(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_active(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback asp_inactive(State) -> Result
	when
		State :: term(),
		Result :: {ok, State}.
-callback notify(RCs, Status, AspID, State) -> Result
	when
		RCs :: [RC] | undefined,
		RC :: 0..4294967295,
		Status :: as_inactive | as_active | as_pending
				| insufficient_asp_active | alternate_asp_active | asp_failure,
		AspID :: 0..4294967295,
		State :: term(),
		Result :: {ok, State}.
-callback info(Info, State) -> Result
	when
		Info :: term(),
		State :: term(),
		Result :: {ok, Active, NewState} | {error, Reason},
		Active :: true | false | once | pos_integer(),
		NewState :: term(),
		Reason :: term().
-callback deregister(RC, NA, Keys, TMT, State) -> Result
	when
		RC :: 0..4294967295,
		NA :: 0..4294967295 | undefined,
		Keys :: [m3ua:key()],
		TMT :: m3ua:tmt() | undefined,
		State :: term(),
		Result :: {ok, NewState} | {error, Reason},
		NewState :: term(),
		Reason :: term().
-optional_callbacks([audit/4, deregister/5]).

-callback terminate(Reason, State) -> Result
	when
		Reason :: term(),
		State :: term(),
		Result :: any().

%%----------------------------------------------------------------------
%%  The m3ua_sgp_fsm gen_statem callbacks
%%----------------------------------------------------------------------

-spec callback_mode() -> Result
	when
		Result :: gen_statem:callback_mode_result().
%% @doc Set the callback mode of the callback module.
%% @see //stdlib/gen_statem:callback_mode/0
%% @private
%%
callback_mode() ->
	[state_functions].

-spec init(Args :: [term()]) ->
	{ok, StateName :: atom(), StateData :: #statedata{}}
			| {ok, StateName :: atom(), StateData :: #statedata{},
					Actions :: [gen_statem:action()] | gen_statem:action()}
			| {stop, Reason :: term()} | ignore.
%% @doc Initialize the {@module} finite state machine.
%% @see //stdlib/gen_statem:init/1
%% @private
%%
init([Socket, Address, Port,
		#sctp_assoc_change{assoc_id = Assoc,
		inbound_streams = InStreams, outbound_streams = OutStreams},
		EP, EpName, Cb, Static, UseRC, CbOpts]) ->
	process_flag(trap_exit, true),
	CbArgs = [?MODULE, self(), EP, EpName, Assoc, CbOpts],
	case m3ua_callback:cb(init, Cb, CbArgs) of
		{ok, Active, CbState} ->
			Statedata = #statedata{socket = Socket, active = Active,
					ppid = m3ua_sctp:ppid(Socket),
					assoc = Assoc, peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					ep = EP, ep_name = EpName,
					callback = Cb, cb_opts = CbOpts, cb_state = CbState,
					static = Static, use_rc = UseRC},
			report_discarding(Cb, EP, Assoc),
			report_carrying(undefined, down, EP, Assoc),
			{ok, down, Statedata, {timeout, 0, timeout}};
		{ok, Active, CbState, RKs} when is_list(RKs) ->
			StateData = #statedata{socket = Socket, active = Active,
					assoc = Assoc, peer_addr = Address, peer_port = Port,
					in_streams = InStreams, out_streams = OutStreams,
					callback = Cb, cb_opts = CbOpts, cb_state = CbState,
					ep = EP, ep_name = EpName,
					static = Static, use_rc = UseRC},
			init1(RKs, StateData, []);
		{error, Reason} ->
			m3ua_sctp:close(Socket),
			{stop, Reason}
	end.
%% @hidden
init1([{RC, RK, Name} | T], StateData, Acc) ->
	case reg_tables(RC, RK, Name, down) of
		{ok, AsState} ->
			init1(T, StateData, [{RC, RK, AsState} | Acc]);
		{error, Reason} ->
			{stop, Reason}
	end;
init1([], #statedata{socket = Socket,
		callback = Cb, ep = EP, assoc = Assoc} = StateData, Acc) ->
	NewStateData = StateData#statedata{rks = lists:reverse(Acc),
			ppid = m3ua_sctp:ppid(Socket)},
	report_discarding(Cb, EP, Assoc),
	report_carrying(undefined, down, EP, Assoc),
	{ok, down, NewStateData, {timeout, 0, timeout}}.

-spec down(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>down</b> state.
%% @private
%%
down(timeout, _EventContent, #statedata{ep = EP, assoc = Assoc, receiver = undefined,
		socket = Socket, active = Active,
		callback = CbMod, cb_state = CbState} = StateData) ->
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', indication, self(), EP, Assoc}),
	%% Reading starts here and not in init/1. This state is reached by
	%% the zero timeout that init/1 asks for, and gen_statem cancels a
	%% timeout the moment any message arrives -- so a receiver started
	%% in init/1 races the registration above and can win it. It did:
	%% the association came up, carried traffic, and was unknown to
	%% m3ua_lm_server, so every call naming it answered not_found.
	%% Nothing is lost by starting late; it waits in the socket's
	%% receive buffer, which is where the bound wants it anyway.
	Receiver = m3ua_receiver:start(Socket, self(), Active),
	{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, [CbState]),
	{next_state, down, StateData#statedata{cb_state = NewCbState,
			receiver = Receiver, lm = whereis(m3ua)}};
down(cast, {'M-RK_DEREG', request, _, _, _} = Event, StateData) ->
	handle_dereg(Event, down, StateData);
down({call, From}, {'MTP-TRANSFER', request, _Params},
		#statedata{ep = EP, assoc = Assoc, count = Count} = StateData) ->
	?LOG_NOTICE("MTP-TRANSFER refused",
			#{layer => m3ua, ep => EP, assoc => Assoc, reason => asp_down}),
	Discarded = maps:get(transfer_discarded, Count, 0),
	NewCount = maps:put(transfer_discarded, Discarded + 1, Count),
	{next_state, down, StateData#statedata{count = NewCount},
			{reply, From, {error, unexpected_message}}};
down(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, down, StateData).

-spec inactive(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>inactive</b> state.
%% @private
%%
inactive(cast, {'M-RK_REG', request, _, _, _, _, _, _, _} = Event, StateData) ->
	handle_reg(Event, inactive, StateData);
inactive(cast, {'M-RK_DEREG', request, _, _, _} = Event, StateData) ->
	handle_dereg(Event, inactive, StateData);
inactive(cast, {'MTP-TRANSFER', request, _Ref, _From, _Params},
		#statedata{ep = EP, assoc = Assoc, count = Count} = StateData) ->
	?LOG_NOTICE("MTP-TRANSFER discarded",
			#{layer => m3ua, ep => EP, assoc => Assoc, reason => asp_inactive}),
	Discarded = maps:get(transfer_discarded, Count, 0),
	NewCount = maps:put(transfer_discarded, Discarded + 1, Count),
	{next_state, inactive, StateData#statedata{count = NewCount}};
inactive({call, From}, {'MTP-TRANSFER', request, _Params},
		#statedata{ep = EP, assoc = Assoc, count = Count} = StateData) ->
	?LOG_NOTICE("MTP-TRANSFER refused",
			#{layer => m3ua, ep => EP, assoc => Assoc, reason => asp_inactive}),
	Discarded = maps:get(transfer_discarded, Count, 0),
	NewCount = maps:put(transfer_discarded, Discarded + 1, Count),
	{next_state, down, StateData#statedata{count = NewCount},
			{reply, From, {error, unexpected_message}}};
inactive(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, inactive, StateData).

-spec active(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>active</b> state.
%% @private
%%
active(cast, {'M-RK_REG', request, _, _, _, _, _, _, _} = Event, StateData) ->
	handle_reg(Event, active, StateData);
active(cast, {'M-RK_DEREG', request, _, _, _} = Event, StateData) ->
	handle_dereg(Event, active, StateData);
active(cast, {'MTP-TRANSFER', request, Ref, From,
		{Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
		#statedata{peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, socket = Socket, assoc = Assoc,
		ep = EP, out_streams = NumStreams,
		rks = RKs, use_rc = UseRC, callback = CbMod,
		cb_state = CbState, count = Count} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC,
			ni = NI, si = SI, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	P1 = case UseRC of
		true when is_integer(RC) ->
			m3ua_codec:add_parameter(?RoutingContext, [RC], P0);
		true ->
			routing_context(get_rc(DPC, OPC, SI, RKs, EP, Assoc), P0);
		false ->
			P0
	end,
	TransferMsg = #m3ua{class = ?TransferMessage,
			type = ?TransferMessageData, params = P1},
	Packet = m3ua_codec:m3ua(TransferMsg),
	Stream1 = case Stream of
		Stream when is_integer(Stream) ->
			Stream;
		undefined ->
			SLS rem NumStreams
	end,
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, Stream1, Ppid, Packet) of
		ok ->
			CbArgs = [From, Ref, Stream1,
					RC, OPC, DPC, NI, SI, SLS, Data, CbState],
			Fallback = {ok, StateData#statedata.active, CbState},
			case contain(send, CbMod, CbArgs, Fallback, Count, EP, Assoc) of
				{{ok, Active, NewCbState}, Count1} ->
					NewStateData = StateData#statedata{cb_state = NewCbState},
					ok = m3ua_receiver:replenish(Receiver, Active),
					TransferOut = maps:get(transfer_out, Count1, 0),
					NewCount = maps:put(transfer_out, TransferOut + 1, Count1),
					NextStateData = NewStateData#statedata{count = NewCount},
					{next_state, active, NextStateData};
				{{error, Reason}, _} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active({call, {From, Ref} = Caller},
		{'MTP-TRANSFER', request, {Stream, RC, OPC, DPC, NI, SI, SLS, Data}},
		#statedata{peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, socket = Socket, assoc = Assoc,
		ep = EP, out_streams = NumStreams,
		rks = RKs, use_rc = UseRC, callback = CbMod,
		cb_state = CbState, count = Count} = StateData) ->
	ProtocolData = #protocol_data{opc = OPC, dpc = DPC,
			ni = NI, si = SI, sls = SLS, data = Data},
	P0 = m3ua_codec:add_parameter(?ProtocolData, ProtocolData, []),
	P1 = case UseRC of
		true when is_integer(RC) ->
			m3ua_codec:add_parameter(?RoutingContext, [RC], P0);
		true ->
			routing_context(get_rc(DPC, OPC, SI, RKs, EP, Assoc), P0);
		false ->
			P0
	end,
	TransferMsg = #m3ua{class = ?TransferMessage,
			type = ?TransferMessageData, params = P1},
	Packet = m3ua_codec:m3ua(TransferMsg),
	Stream1 = case Stream of
		Stream when is_integer(Stream) ->
			Stream;
		undefined ->
			SLS rem NumStreams
	end,
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, Stream1, Ppid, Packet) of
		ok ->
			CbArgs = [From, Ref, Stream1,
					RC, OPC, DPC, NI, SI, SLS, Data, CbState],
			Fallback = {ok, StateData#statedata.active, CbState},
			case contain(send, CbMod, CbArgs, Fallback, Count, EP, Assoc) of
				{{ok, Active, NewCbState}, Count1} ->
					NewStateData = StateData#statedata{cb_state = NewCbState},
					ok = m3ua_receiver:replenish(Receiver, Active),
					TransferOut = maps:get(transfer_out, Count1, 0),
					NewCount = maps:put(transfer_out, TransferOut + 1, Count1),
					NextStateData = NewStateData#statedata{count = NewCount},
					{next_state, active, NextStateData, {reply, Caller, ok}};
				{{error, Reason}, _} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
active(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, active, StateData).

-spec handle_event(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events common to all states.
%% @hidden
handle_event(cast, 'M-LM_ADOPT', StateName,
		#statedata{receiver = undefined} = StateData) ->
	%% Not announced yet: down(timeout, ...) will do it, and this event
	%% has just cancelled the zero timeout that gets there.
	{next_state, StateName, StateData, {timeout, 0, timeout}};
handle_event(cast, 'M-LM_ADOPT', StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	%% A new layer manager, finding this association running; see
	%% m3ua_lm_server:adopt/1.
	gen_server:cast(m3ua, {'M-SCTP_ESTABLISH', indication, self(), EP, Assoc}),
	{next_state, StateName, StateData#statedata{lm = whereis(m3ua)}};
handle_event(cast, {'M-SCTP_RELEASE', request, Ref, From}, _StateName,
		#statedata{ep = EP, assoc = Assoc, socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, m3ua_sctp:close(Socket)}),
	NewStateData = StateData#statedata{socket = undefined},
	{stop, {shutdown, {{EP, Assoc}, shutdown}}, NewStateData};
handle_event(cast, {'M-SCTP_STATUS', request, Ref, From}, StateName,
		#statedata{socket = undefined, assoc = _Assoc} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_STATUS', confirm, Ref, {error, enotsock}}),
	{next_state, StateName, StateData};
handle_event(cast, {'M-SCTP_STATUS', request, Ref, From}, StateName,
		#statedata{socket = Socket, assoc = Assoc} = StateData) ->
	case m3ua_sctp:status(Socket, Assoc) of
		{ok, Status} ->
			gen_server:cast(From,
					{'M-SCTP_STATUS', confirm, Ref, {ok, Status}}),
			{next_state, StateName, StateData};
		{error, Reason} ->
			gen_server:cast(From,
					{'M-SCTP_STATUS', confirm, Ref, {error, Reason}}),
			{next_state, StateName, StateData}
	end;
handle_event(cast, {'M-NOTIFY', AsState, RC}, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active, ep = EP,
		assoc = Assoc, count = Count, rks = RKs} = StateData) ->
	NewRKs = update_rks(RC, undefined, AsState, RKs),
	NewStateData = StateData#statedata{rks = NewRKs},
	Params = m3ua_codec:store_parameter(?Status, AsState, []),
	Notify = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
	Packet = m3ua_codec:m3ua(Notify),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			NotifyIn = maps:get(notify_out, Count, 0),
			NewCount = maps:put(notify_out, NotifyIn + 1, Count),
			NextStateData = NewStateData#statedata{count = NewCount},
			{next_state, StateName, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, NewStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, NewStateData}
	end;
handle_event(cast, {'M-SSNM', Type, Params}, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active, ep = EP,
		assoc = Assoc, count = Count} = StateData) ->
	Message = #m3ua{class = ?SSNMMessage, type = Type, params = Params},
	Packet = m3ua_codec:m3ua(Message),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			Key = ssnm_count(Type),
			Out = maps:get(Key, Count, 0),
			NewCount = maps:put(Key, Out + 1, Count),
			NewStateData = StateData#statedata{count = NewCount},
			{next_state, StateName, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_event(cast, {'M-ASP_STATUS', request, Ref, From}, StateName, StateData) ->
	gen_server:cast(From, {'M-ASP_STATUS', confirm, Ref, StateName}),
	{next_state, StateName, StateData};
handle_event({call, From}, getassoc, StateName,
		#statedata{assoc = Assoc} = StateData) ->
	{next_state, StateName, StateData, {reply, From, Assoc}};
handle_event({call, From}, {getstat, undefined}, StateName,
		#statedata{socket = Socket} = StateData) ->
	{next_state, StateName, StateData, {reply, From, m3ua_sctp:getstat(Socket)}};
handle_event({call, From}, {getstat, Options}, StateName,
		#statedata{socket = Socket} = StateData) ->
	{next_state, StateName, StateData, {reply, From, m3ua_sctp:getstat(Socket, Options)}};
handle_event({call, From}, getcount, StateName,
		#statedata{count = Counters} = StateData) ->
	{next_state, StateName, StateData, {reply, From, Counters}};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[#sctp_sndrcvinfo{assoc_id = Assoc, stream = Stream}], Data}},
		StateName, #statedata{socket = Socket,
		assoc = Assoc} = StateData) when is_binary(Data) ->
	handle_sgp(Data, StateName, Stream, StateData);
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = comm_lost, assoc_id = Assoc}}}, _,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, comm_lost}}, StateData};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_assoc_change{state = restart, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, receiver = Receiver, active = Active,
		assoc = Assoc} = StateData) ->
	ok = m3ua_receiver:replenish(Receiver, Active),
	{next_state, StateName, StateData};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_adaptation_event{adaptation_ind = UAL, assoc_id = Assoc}}},
		StateName, #statedata{socket = Socket, receiver = Receiver, active = Active,
		assoc = Assoc} = StateData) ->
	ok = m3ua_receiver:replenish(Receiver, Active),
	{next_state, StateName, StateData#statedata{ual = UAL}};
% @todo Track peer address states.
handle_event(info, {sctp, Socket, _, _,
		{[], #sctp_paddr_change{addr = {PeerAddr, PeerPort},
		state = addr_confirmed, assoc_id = Assoc}}}, StateName,
		#statedata{socket = Socket, receiver = Receiver, active = Active,
		assoc = Assoc} = StateData) ->
	ok = m3ua_receiver:replenish(Receiver, Active),
	NewStateData = StateData#statedata{peer_addr = PeerAddr,
			peer_port = PeerPort},
	{next_state, StateName, NewStateData};
handle_event(info, {sctp, Socket, _, _,
		{[], #sctp_paddr_change{state = addr_unreachable}}}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, addr_unreachable}}, StateData};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[], #sctp_shutdown_event{assoc_id = Assoc}}}, _StateName,
		#statedata{socket = Socket, ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, shutdown}}, StateData};
handle_event(info, {sctp_error, Socket, PeerAddr, PeerPort,
		{[], #sctp_send_failed{flags = Flags, error = Error,
		info = Info, assoc_id = Assoc, data = Data}}},
		_StateName, #statedata{assoc = Assoc, ep = EP} = StateData) ->
	?LOG_ERROR("SCTP send failed",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			peer => {PeerAddr, PeerPort}, flags => Flags,
			reason => m3ua_sctp:error_string(Error)}),
	?LOG_DEBUG("SCTP send failed",
			#{layer => m3ua, ep => EP, assoc => Assoc, socket => Socket,
			info => Info, data => Data}),
	{stop, {shutdown, {{EP, Assoc}, Error}}, StateData};
handle_event(info, {'EXIT', EP, {shutdown, {EP, Reason}}}, _StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData};
handle_event(info, {'EXIT', Receiver, Reason}, _StateName,
		#statedata{receiver = Receiver, ep = EP, assoc = Assoc} = StateData) ->
	%% Where a closed port used to arrive. The receiver is this state
	%% machine's only ear, so its exit ends the association rather than
	%% leaving one that is up and hears nothing.
	{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData};
handle_event(info, {'EXIT', LM, _Reason}, StateName,
		#statedata{lm = LM} = StateData) when is_pid(LM) ->
	%% The layer manager links every association, and m3ua_sup restarts
	%% it on its own. Its successor asks for this one (M-LM_ADOPT); its
	%% death is no reason for the association to end.
	{next_state, StateName, StateData};
handle_event(info, Info, StateName, #statedata{receiver = Receiver, socket = _Socket,
		ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = CbState, active = Active0, count = Count} = StateData) ->
	Fallback = {ok, Active0, CbState},
	case contain(info, CbMod, [Info, CbState], Fallback, Count, EP, Assoc) of
		{{ok, Active, NewCbState}, Count1} ->
			NewStateData = StateData#statedata{cb_state = NewCbState,
					count = Count1},
			ok = m3ua_receiver:replenish(Receiver, Active),
			{next_state, StateName, NewStateData};
		{{error, Reason}, _} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_statem:terminate/3
%% @private
%%
terminate(Reason, StateName, #statedata{socket = undefined} = StateData) ->
	report_terminated(Reason, StateName, StateData),
	terminate1(Reason, StateName, StateData);
terminate(Reason, StateName, #statedata{socket = Socket} = StateData) ->
	report_terminated(Reason, StateName, StateData),
	case m3ua_sctp:close(Socket) of
		ok ->
			ok;
		{error, Reason1} ->
			?LOG_WARNING("Socket not closed",
					#{layer => m3ua, ep => StateData#statedata.ep,
					assoc => StateData#statedata.assoc, socket => Socket,
					reason => Reason1})
	end,
	terminate1(Reason, StateName, StateData).
%% @hidden
terminate1(Reason, _StateName, #statedata{rks = RKs, registered = Registered,
		ep = EP, assoc = Assoc} = StateData) ->
	Fsm = self(),
	Fdel = fun F([{RC, _RK, _Active} | T]) ->
				[#m3ua_as{asp = L1} = AS] = mnesia:read(m3ua_as, RC, write),
				L2 = lists:keydelete(Fsm, #m3ua_as_asp.fsm, L1),
				case removable(L2, lists:member(RC, Registered), AS) of
					true ->
						mnesia:delete(m3ua_as, RC, write);
					false ->
						mnesia:write(AS#m3ua_as{asp = L2})
				end,
				mnesia:delete(m3ua_asp, Fsm, write),
				F(T);
			F([]) ->
				ok
	end,
	mnesia:transaction(Fdel, [RKs]),
	report_removed(Registered, EP, Assoc),
	terminate2(Reason, StateData).
%% @hidden
terminate2(_, #statedata{callback = undefined}) ->
	ok;
terminate2(Reason, #statedata{callback = CbMod, cb_state = CbState}) ->
	m3ua_callback:cb(terminate, CbMod, [Reason, CbState]).

-spec code_change(OldVsn :: term() | {down, term()}, StateName :: atom(),
		StateData :: term(), Extra :: term()) ->
	{ok, NextStateName :: atom(), NewStateData :: #statedata{}}.
%% @doc Update internal state data during a release upgrade&#047;downgrade.
%% @see //stdlib/gen_statem:code_change/4
%% @private
%%
code_change(_OldVsn, StateName, StateData, _Extra) ->
	{ok, StateName, StateData}.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-spec audit(CbMod, CbArgs, CbState, EP, Assoc) -> {ok, CbState}
	when
		CbMod :: atom() | #m3ua_fsm_cb{},
		CbArgs :: [term()],
		CbState :: term(),
		EP :: pid(),
		Assoc :: gen_sctp:assoc_id().
%% @doc Ask the callback about a destination audit, where it wants to
%% 	be asked.
%%
%% 	Optional, and checked rather than assumed: a callback module
%% 	written before there was an audit callback must go on working. An
%% 	audit it does not answer goes no further, so it says so rather than
%% 	leaving the ASP to wonder which of the two happened.
%% @hidden
audit(CbMod, CbArgs, CbState, EP, Assoc) when is_atom(CbMod) ->
	case erlang:function_exported(CbMod, audit, 4) of
		true ->
			m3ua_callback:cb(audit, CbMod, CbArgs);
		false ->
			case code:ensure_loaded(CbMod) of
				{module, CbMod} ->
					case erlang:function_exported(CbMod, audit, 4) of
						true ->
							m3ua_callback:cb(audit, CbMod, CbArgs);
						false ->
							?LOG_NOTICE("DAUD unanswered",
									#{layer => m3ua, ep => EP, assoc => Assoc,
									callback => CbMod, reason => no_audit_callback}),
							{ok, CbState}
					end;
				{error, Reason} ->
					?LOG_NOTICE("DAUD unanswered",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							callback => CbMod, reason => Reason}),
					{ok, CbState}
			end
	end;
audit(#m3ua_fsm_cb{} = CbMod, CbArgs, _CbState, _EP, _Assoc) ->
	m3ua_callback:cb(audit, CbMod, CbArgs).

-spec ssnm_count(Type) -> Key
	when
		Type :: byte(),
		Key :: atom().
%% @doc Statistics key for an SSNM message sent.
%% @hidden
ssnm_count(?SSNMDUNA) -> duna_out;
ssnm_count(?SSNMDAVA) -> dava_out;
ssnm_count(?SSNMDAUD) -> daud_out;
ssnm_count(?SSNMSCON) -> scon_out;
ssnm_count(?SSNMDUPU) -> dupu_out;
ssnm_count(?SSNMDRST) -> drst_out.


-spec report_terminated(Reason, StateName, StateData) -> ok
	when
		Reason :: term(),
		StateName :: atom(),
		StateData :: #statedata{}.
%% @doc Retract the carrying condition when the association goes away.
%%
%% 	Every other way of ceasing to carry is a transition, and
%% 	report_carrying/4 catches it there. Terminating is not: comm_lost,
%% 	an unreachable peer, a shutdown or a release all leave the active
%% 	state without passing through another one. Said here so that a
%% 	"Carrying traffic" line always has a mate, and an association that
%% 	died carrying does not read as one that still is.
%% @hidden
report_terminated(Reason, active,
		#statedata{ep = EP, assoc = Assoc} = _StateData) ->
	?LOG_NOTICE("Cannot carry traffic",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => terminate_reason(Reason)}),
	ok;
report_terminated(_Reason, _StateName, _StateData) ->
	ok.

%% @hidden
terminate_reason({shutdown, {{_EP, _Assoc}, Reason}}) ->
	Reason;
terminate_reason({shutdown, Reason}) ->
	Reason;
terminate_reason(Reason) ->
	Reason.

-spec report_carrying(StateName, NextStateName, EP, Assoc) -> ok
	when
		StateName :: undefined | atom(),
		NextStateName :: atom(),
		EP :: pid(),
		Assoc :: gen_sctp:assoc_id().
%% @doc Say once when this association starts or stops carrying traffic.
%%
%% 	Only the active state carries. Whether it does is a condition and
%% 	not a property of any one message, so it is said when it becomes
%% 	true and again when it clears; the messages that stop meanwhile say
%% 	so on their own account. Said at startup as well, since an
%% 	association that comes up and never carries would otherwise be
%% 	indistinguishable from one with nothing to do.
%% @hidden
report_carrying(undefined, NextStateName, EP, Assoc)
		when NextStateName /= active ->
	?LOG_NOTICE("Cannot carry traffic",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => carrying_reason(NextStateName)}),
	ok;
report_carrying(StateName, StateName, _EP, _Assoc) ->
	ok;
report_carrying(active, NextStateName, EP, Assoc) ->
	?LOG_NOTICE("Cannot carry traffic",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => carrying_reason(NextStateName)}),
	ok;
report_carrying(_StateName, active, EP, Assoc) ->
	?LOG_NOTICE("Carrying traffic",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => asp_active}),
	ok;
report_carrying(_StateName, _NextStateName, _EP, _Assoc) ->
	ok.

%% @hidden
carrying_reason(down) ->
	asp_down;
carrying_reason(inactive) ->
	asp_inactive;
carrying_reason(Other) ->
	Other.

-spec report_discarding(Cb, EP, Assoc) -> ok
	when
		Cb :: atom() | #m3ua_fsm_cb{},
		EP :: pid(),
		Assoc :: gen_sctp:assoc_id().
%% @doc Say once which indications this association will discard.
%%
%% 	An indication with no handler behind it is dropped by the defaults
%% 	in {@link //m3ua/m3ua_callback. m3ua_callback}. Saying so for each
%% 	message would put a line on the data path for every packet, so it
%% 	is said here, where the configuration that decides it is known.
%% @hidden
report_discarding(Cb, EP, Assoc) ->
	case m3ua_callback:discarding(Cb, [recv, status, audit]) of
		[] ->
			ok;
		Discarded ->
			?LOG_NOTICE("Indications will be discarded",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					indications => Discarded, reason => no_callback}),
			ok
	end.

%% @hidden
handle_reg({'M-RK_REG', request, Ref, From, RC, NA, Keys, Mode, AS},
		StateName, #statedata{static = true, rks = RKs,
		assoc = Assoc, ep = EP, callback = CbMod,
		cb_state = CbState} = StateData) when is_integer(RC) ->
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	case reg_tables(RC, RK, AS, StateName) of
		{ok, AsState} ->
			NewRKs = lists:keystore(RC, 1, RKs, {RC, RK, AsState}),
			CbArgs = [RC, NA, SortedKeys, Mode, CbState],
			{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
			NewStateData = StateData#statedata{rks = NewRKs,
					cb_state = NewCbState},
			gen_server:cast(From, {'M-RK_REG', confirm, Ref, {ok, RC}}),
			{next_state, StateName, NewStateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_reg(_, _, #statedata{ep = EP, assoc = Assoc} = StateData) ->
	{stop, {shutdown, {{EP, Assoc}, bad_routing_context}}, StateData}.

%% @hidden
%% 	M-RK_DEREG from layer management at the sgp: take the asp out of
%% 	an application server, however it came to be a member. There is
%% 	no peer to ask; it is the sgp's own configuration.
handle_dereg({'M-RK_DEREG', request, Ref, From, RC}, StateName,
		#statedata{rks = RKs, registered = Registered,
		ep = EP, assoc = Assoc} = StateData) ->
	case lists:keymember(RC, 1, RKs) of
		true ->
			Fsm = self(),
			Reg = lists:member(RC, Registered),
			case mnesia:transaction(fun() -> deregister1(Fsm, RC, Reg) end) of
				{atomic, ok} ->
					?LOG_NOTICE("Routing keys deregistered",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							rcs => [RC], reason => 'M-RK_DEREG'}),
					report_removed([RC], EP, Assoc),
					gen_server:cast(From, {'M-RK_DEREG', confirm, Ref, ok}),
					NewStateData = deregistered([RC], RKs, StateData#statedata{
							rks = lists:keydelete(RC, 1, RKs),
							registered = lists:delete(RC, Registered)}),
					{next_state, StateName, NewStateData};
				{aborted, Reason} ->
					gen_server:cast(From,
							{'M-RK_DEREG', confirm, Ref, {error, Reason}}),
					{next_state, StateName, StateData}
			end;
		false ->
			gen_server:cast(From,
					{'M-RK_DEREG', confirm, Ref, {error, not_registered}}),
			{next_state, StateName, StateData}
	end.

%% @hidden
handle_sgp(M3UA, StateName, Stream, StateData) when is_binary(M3UA) ->
	case m3ua_codec:check(M3UA) of
		{ok, Message} ->
			handle_sgp(Message, StateName, Stream, StateData);
		{error, Reason} ->
			undecodable(M3UA, Reason, StateName, Stream, StateData)
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP, params = Params},
		down, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspUp = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspUp, undefined),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_up, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_up, CbMod, CbArgs),
			ok = m3ua_receiver:replenish(Receiver, Active),
			UpIn = maps:get(up_in, Count, 0),
			UpAckOut = maps:get(up_ack_out, Count, 0),
			NewCount = maps:put(up_in, UpIn + 1, Count),
			NextCount = maps:put(up_ack_out, UpAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			{next_state, inactive, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
%% RFC4666, Section-4.3.4.1: an ASP UP at an asp already inactive is
%% acknowledged "and no further action is taken". It is most often the
%% same ASP UP sent again when T(ack) ran out before the first ACK came.
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP},
		inactive, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	?LOG_DEBUG("ASPUP acknowledged again",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => already_inactive}),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			UpIn = maps:get(up_in, Count, 0),
			UpAckOut = maps:get(up_ack_out, Count, 0),
			NewCount = maps:put(up_in, UpIn + 1, Count),
			NextCount = maps:put(up_ack_out, UpAckOut + 1, NewCount),
			NewStateData = StateData#statedata{count = NextCount},
			{next_state, inactive, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
%% RFC4666, Section-4.3.4.1: an ASP UP at an active asp is acknowledged,
%% reported as unexpected, takes the asp out of service in every
%% application server it is in, and deregisters its routing keys.
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP},
		active, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	?LOG_NOTICE("ASPUP received in the active state",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => unexpected_message}),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = deregister(asp_up,
					state_traffic_maint(undefined, asp_inactive, StateData)),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_inactive, CbMod, CbArgs),
			UpIn = maps:get(up_in, Count, 0),
			UpAckOut = maps:get(up_ack_out, Count, 0),
			NewCount = maps:put(up_in, UpIn + 1, Count),
			NextCount = maps:put(up_ack_out, UpAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			report_carrying(active, inactive, EP, Assoc),
			send_error(unexpected_message, inactive, NextStateData);
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
		StateName, _Stream, StateData)
		when StateName == inactive; StateName == active ->
	Parameters = m3ua_codec:parameters(Params),
	RKs = m3ua_codec:get_all_parameter(?RoutingKey, Parameters),
	reg_request(RKs, StateName, StateData);
handle_sgp(#m3ua{class = ?RKMMessage, type = ?RKMDEREGREQ, params = Params},
		StateName, _Stream, StateData)
		when StateName == inactive; StateName == active ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:fetch_parameter(?RoutingContext, Parameters),
	dereg_request(RCs, StateName, StateData);
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspActive, undefined),
	AspActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
	Packet = m3ua_codec:m3ua(AspActiveAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_active, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_active, CbMod, CbArgs),
			ok = m3ua_receiver:replenish(Receiver, Active),
			ActiveIn = maps:get(active_in, Count, 0),
			ActiveAckOut = maps:get(active_ack_out, Count, 0),
			NewCount = maps:put(active_in, ActiveIn + 1, Count),
			NextCount = maps:put(active_ack_out, ActiveAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			report_carrying(inactive, active, EP, Assoc),
			{next_state, active, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN, params = Params},
		StateName, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData)
		when StateName == inactive; StateName == active ->
	AspDown = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspDown, undefined),
	AspDownAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
	Packet = m3ua_codec:m3ua(AspDownAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = deregister(asp_down,
					state_traffic_maint(RCs, asp_down, StateData)),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_down, CbMod, CbArgs),
			ok = m3ua_receiver:replenish(Receiver, Active),
			DownIn = maps:get(down_in, Count, 0),
			DownAckOut = maps:get(down_ack_out, Count, 0),
			NewCount = maps:put(down_in, DownIn + 1, Count),
			NextCount = maps:put(down_ack_out, DownAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			report_carrying(StateName, down, EP, Assoc),
			{next_state, down, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = Params},
		active, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, callback = CbMod, cb_state = CbState,
		count = Count} = StateData) ->
	AspInActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspInActive, undefined),
	AspInActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(AspInActiveAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_inactive, StateData),
			CbArgs = [CbState],
			{ok, NewCbState} = m3ua_callback:cb(asp_inactive, CbMod, CbArgs),
			ok = m3ua_receiver:replenish(Receiver, Active),
			InactiveIn = maps:get(inactive_in, Count, 0),
			InactiveAckOut = maps:get(inactive_ack_out, Count, 0),
			NewCount = maps:put(inactive_in, InactiveIn + 1, Count),
			NextCount = maps:put(inactive_ack_out, InactiveAckOut + 1, NewCount),
			NextStateData = NewStateData#statedata{cb_state = NewCbState,
					count = NextCount},
			report_carrying(active, inactive, EP, Assoc),
			{next_state, inactive, NextStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?TransferMessage,
		type = ?TransferMessageData, params = Params},
		_ActiveState, Stream, #statedata{receiver = Receiver, socket = _Socket,
		ep = EP, assoc = Assoc, callback = CbMod,
		cb_state = CbState, count = Count} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RC = case m3ua_codec:find_parameter(?RoutingContext, Parameters) of
		{ok, [RC1]} ->
			RC1;
		{error, not_found} ->
			undefined
	end,
	#protocol_data{opc = OPC, dpc = DPC, ni = NI, si = SI, sls = SLS,
			data = Data} = m3ua_codec:fetch_parameter(?ProtocolData, Parameters),
	CbArgs = [Stream, RC, OPC, DPC, NI, SI, SLS, Data, CbState],
	Fallback = {ok, StateData#statedata.active, CbState},
	case contain(recv, CbMod, CbArgs, Fallback, Count, EP, Assoc) of
		{{ok, Active, NewCbState}, Count1} ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			TransferIn = maps:get(transfer_in, Count1, 0),
			NewCount = maps:put(transfer_in, TransferIn + 1, Count1),
			NewStateData = StateData#statedata{active = Active,
					cb_state = NewCbState, count = NewCount},
			{next_state, active, NewStateData};
		{{error, Reason}, _} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMSCON, params = Params},
		StateName, Stream, #statedata{socket = _Socket, receiver = Receiver, active = Active,
		callback = CbMod, cb_state = CbState} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = lists:append(m3ua_codec:get_all_parameter(?AffectedPointCode,
			Parameters)),
	CbArgs = [Stream, RCs, APCs, CbState],
	{{ok, NewCbState}, Count1} = contain(status, CbMod, CbArgs,
			{ok, CbState}, StateData#statedata.count,
			StateData#statedata.ep, StateData#statedata.assoc),
	NewStateData = StateData#statedata{cb_state = NewCbState,
			count = Count1},
	ok = m3ua_receiver:replenish(Receiver, Active),
	{next_state, StateName, NewStateData};
handle_sgp(#m3ua{class = ?SSNMMessage, type = ?SSNMDAUD, params = Params},
		StateName, Stream, #statedata{socket = _Socket, receiver = Receiver, active = Active,
		callback = CbMod, cb_state = CbState, count = Count,
		ep = EP, assoc = Assoc} = StateData)
		when CbMod /= undefined ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, []),
	APCs = lists:append(m3ua_codec:get_all_parameter(?AffectedPointCode,
			Parameters)),
	CbArgs = [Stream, RCs, APCs, CbState],
	F = fun() -> audit(CbMod, CbArgs, CbState, EP, Assoc) end,
	{{ok, NewCbState}, Count1} = contain1(audit, F, {ok, CbState},
			Count, EP, Assoc),
	ok = m3ua_receiver:replenish(Receiver, Active),
	DaudIn = maps:get(daud_in, Count1, 0),
	NewCount = maps:put(daud_in, DaudIn + 1, Count1),
	NewStateData = StateData#statedata{cb_state = NewCbState,
			count = NewCount},
	{next_state, StateName, NewStateData};
handle_sgp(#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params},
		StateName, _Stream, #statedata{assoc = Assoc, ep = EP,
		socket = _Socket, receiver = Receiver, active = Active,
		count = Count} = StateData) ->
	%% The peer found fault with something this end sent, and says no
	%% more than the code; the diagnostic, if any, goes to debug.
	Parameters = m3ua_codec:parameters(Params),
	ErrorCode = proplists:get_value(?ErrorCode, Parameters),
	?LOG_WARNING("ERR received",
			#{layer => m3ua, ep => EP, assoc => Assoc, state => StateName,
			reason => ErrorCode}),
	?LOG_DEBUG("ERR received",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			parameters => Parameters}),
	ok = m3ua_receiver:replenish(Receiver, Active),
	ErrorIn = maps:get(error_in, Count, 0),
	NewCount = maps:put(error_in, ErrorIn + 1, Count),
	{next_state, StateName, StateData#statedata{count = NewCount}};
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMBEAT, params = Params},
		StateName, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, count = Count} = StateData) ->
	BeatAck = #m3ua{class = ?ASPSMMessage,
			type = ?ASPSMBEATACK, params = Params},
	Packet = m3ua_codec:m3ua(BeatAck),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			UpIn = maps:get(beat_in, Count, 0),
			UpAckOut = maps:get(beat_ack_out, Count, 0),
			NewCount = maps:put(beat_in, UpIn + 1, Count),
			NextCount = maps:put(beat_ack_out, UpAckOut + 1, NewCount),
			NewStateData = StateData#statedata{count = NextCount},
			{next_state, StateName, NewStateData};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_sgp(#m3ua{} = M3UA, StateName, Stream, StateData) ->
	unexpected(M3UA, StateName, Stream, StateData).

%% @hidden
%% 	Discard a message that will not decode, and answer it with an
%% 	ERR -- unless it was itself an ERR, which is never answered.
undecodable(Packet, Reason, StateName, Stream,
		#statedata{receiver = Receiver, active = Active,
		ep = EP, assoc = Assoc, count = Count} = StateData) ->
	?LOG_WARNING("Message would not decode",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			stream => Stream, reason => Reason}),
	?LOG_DEBUG("Message would not decode",
			#{layer => m3ua, ep => EP, assoc => Assoc, packet => Packet}),
	Undecodable = maps:get(undecodable_in, Count, 0),
	NewCount = maps:put(undecodable_in, Undecodable + 1, Count),
	NewStateData = StateData#statedata{count = NewCount},
	case Packet of
		<<_, _, ?MGMTMessage, ?MGMTError, _/binary>> ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			{next_state, StateName, NewStateData};
		_ ->
			send_error(Reason, StateName, NewStateData)
	end.

%% @hidden
%% 	Discard a message that decodes but that no clause takes in this
%% 	state, and answer it with an ERR.
unexpected(#m3ua{class = Class, type = Type}, StateName, Stream,
		#statedata{ep = EP, assoc = Assoc, count = Count} = StateData) ->
	?LOG_NOTICE("Message discarded",
			#{layer => m3ua, ep => EP, assoc => Assoc, stream => Stream,
			state => StateName, class => Class, type => Type,
			reason => unexpected_message}),
	Unexpected = maps:get(unexpected_in, Count, 0),
	NewCount = maps:put(unexpected_in, Unexpected + 1, Count),
	send_error(unexpected_message, StateName,
			StateData#statedata{count = NewCount}).

%% @hidden
send_error(ErrorCode, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort,
		ppid = Ppid, receiver = Receiver, active = Active,
		ep = EP, assoc = Assoc, count = Count} = StateData) ->
	P0 = m3ua_codec:add_parameter(?ErrorCode, ErrorCode, []),
	ErrorParams = m3ua_codec:parameters(P0),
	ErrorMsg = #m3ua{class = ?MGMTMessage,
			type = ?MGMTError, params = ErrorParams},
	Packet = m3ua_codec:m3ua(ErrorMsg),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			ErrorOut = maps:get(error_out, Count, 0),
			NewCount = maps:put(error_out, ErrorOut + 1, Count),
			{next_state, StateName, StateData#statedata{count = NewCount}};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

%% @private
reg_request(RoutingKeys, StateName, StateData) ->
	reg_request(RoutingKeys, StateName, StateData, [], []).
%% @hidden
reg_request([H | T], StateName, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid,
		receiver = Receiver, active = Active, ep = EP, assoc = Assoc, rks = RKs,
		registered = Registered, callback = CbMod, cb_state = CbState,
		count = Count} = StateData, RegResults, Notifies) ->
	try m3ua_codec:routing_key(H)
	of
		#m3ua_routing_key{rc = RC, na = NA,
				key = Keys, tmt = Mode, lrk_id = LrkId} ->
			SortedKeys = m3ua:sort(Keys),
			RK = {NA, SortedKeys, Mode},
			F = fun() -> reg_request1(RC, RK, LrkId) end,
			case mnesia:transaction(F) of
				{atomic, {reg, AsState, #registration_result{rc = NewRC} = RR}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					CbArgs = [NewRC, NA, SortedKeys, Mode, CbState],
					{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
					NewStateData = StateData#statedata{rks = NewRKs,
							registered = [NewRC | lists:delete(NewRC, Registered)],
							cb_state = NewCbState},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], Notifies);
				{atomic, {reg, AsState, #registration_result{rc = NewRC} = RR, Notify}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					CbArgs = [NewRC, NA, SortedKeys, Mode, CbState],
					{ok, NewCbState} = m3ua_callback:cb(register, CbMod, CbArgs),
					NewStateData = StateData#statedata{rks = NewRKs,
							registered = [NewRC | lists:delete(NewRC, Registered)],
							cb_state = NewCbState},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], [Notify | Notifies]);
				{atomic, {not_reg, AsState,
						#registration_result{rc = NewRC, status = Status} = RR}} ->
					?LOG_NOTICE("Routing key registration refused",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							rc => NewRC, reason => Status}),
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					NewStateData = StateData#statedata{rks = NewRKs},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], Notifies);
				{atomic, {not_reg,
						#registration_result{rc = NewRC, status = Status} = RR}} ->
					?LOG_NOTICE("Routing key registration refused",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							rc => NewRC, reason => Status}),
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, StateData, [RegResult | RegResults], Notifies);
				{aborted, Reason} ->
					?LOG_WARNING("Routing key registration failed",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							rc => RC, reason => Reason}),
					RegResult = {?RegistrationResult, #registration_result{lrk_id = LrkId,
							status = rk_change_refused, rc = RC}},
					reg_request(T, StateName, StateData, [RegResult | RegResults], Notifies)
			end
	catch
		_:Reason1 ->
			?LOG_WARNING("Routing key would not decode",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					reason => Reason1}),
			P0 = m3ua_codec:add_parameter(?ErrorCode, unexpected_parameter, []),
			ErrorParams = m3ua_codec:parameters(P0),
			ErrorMsg = #m3ua{class = ?MGMTMessage, type = ?MGMTError, params = ErrorParams},
			Packet = m3ua_codec:m3ua(ErrorMsg),
			case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
				ok ->
					ErrorOut = maps:get(error_out, Count, 0),
					NewCount = maps:put(error_out, ErrorOut + 1, Count),
					NewStateData = StateData#statedata{count = NewCount},
					ok = m3ua_receiver:replenish(Receiver, Active),
					{next_state, StateName, NewStateData};
				{error, eagain} ->
					% @todo flow control
					{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
				{error, Reason} ->
					{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
			end
	end;
reg_request([], StateName, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid,
		ep = EP, assoc = Assoc} = StateData, RegResults, Notifies) ->
	RegResMsg = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = lists:reverse(RegResults)},
	RegResPacket = m3ua_codec:m3ua(RegResMsg),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, RegResPacket) of
		ok ->
			send_notify(Notifies, StateName, StateData);
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.
%% @hidden
reg_request1(RC, RK, LrkId) when is_integer(RC) ->
	SGP = self(),
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			RegRes = #registration_result{lrk_id = LrkId,
					status = rk_change_refused, rc = RC},
			{not_reg, RegRes};
		[#m3ua_as{rk = RK, state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					RegRes = #registration_result{lrk_id = LrkId,
							status = rk_already_registered, rc = RC},
					{not_reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					mnesia:write(AS#m3ua_as{asp = NewSGPs}),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes}
			end;
		[#m3ua_as{state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					mnesia:write(AS#m3ua_as{rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					mnesia:write(AS#m3ua_as{rk = RK, asp = NewSGPs}),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, AsState, RegRes}
			end
	end;
reg_request1(undefined, RK, LrkId) ->
	SGP = self(),
	case mnesia:index_read(m3ua_as, RK, #m3ua_as.rk) of
		[] ->
			RC = rand:uniform(16#FFFFFFFF), % @todo better RC assignment
			ASASP = #m3ua_as_asp{fsm = SGP, state = inactive},
			AS = #m3ua_as{rc = RC, rk = RK, state = inactive, asp = [ASASP]},
			mnesia:write(AS),
			ASP = #m3ua_asp{fsm = SGP, rc = RC, rk = RK},
			mnesia:write(ASP),
			RegRes = #registration_result{lrk_id = LrkId,
					status = registered, rc = RC},
			{reg, inactive, RegRes, {as_inactive, RC}};
		[#m3ua_as{rc = RC, state = AsState, asp = SGPs} = AS] ->
			case lists:keymember(SGP, #m3ua_as_asp.fsm, SGPs) of
				true ->
					RegRes = #registration_result{lrk_id = LrkId,
							status = rk_already_registered, rc = RC},
					{not_reg, AsState, RegRes};
				false ->
					NewSGPs = [#m3ua_as_asp{fsm = SGP, state = inactive} | SGPs],
					NewAS = case AsState of
						active ->
							AS#m3ua_as{asp = NewSGPs};
						_ ->
							AS#m3ua_as{asp = NewSGPs, state = inactive}
					end,
					mnesia:write(NewAS),
					mnesia:write(#m3ua_asp{fsm = SGP, rc = RC, rk = RK}),
					RegRes = #registration_result{lrk_id = LrkId,
							status = registered, rc = RC},
					{reg, NewAS#m3ua_as.state, RegRes}
			end
	end.

%% @hidden
send_notify([{Status, RC} | T] = _Notifies, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, ep = EP, assoc = Assoc,
		callback = CbMod, cb_state = CbState, count = Count} = StateData) ->
	P0 = m3ua_codec:add_parameter(?Status, Status, []),
	P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
	Message = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = P1},
	Packet = m3ua_codec:m3ua(Message),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			CbArgs = [RC, Status, undefined, CbState],
			{{ok, NewCbState}, Count1} = contain(notify, CbMod, CbArgs,
					{ok, CbState}, Count, EP, Assoc),
			NotifyOut = maps:get(notify_out, Count1, 0),
			NewCount = maps:put(notify_out, NotifyOut + 1, Count1),
			NewStateData = StateData#statedata{cb_state = NewCbState, count = NewCount},
			send_notify(T, StateName, NewStateData);
	{error, eagain} ->
		% @todo flow control
		{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
	{error, Reason} ->
		{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
send_notify([], StateName,
		#statedata{socket = _Socket, receiver = Receiver, active = Active} = StateData) ->
	ok = m3ua_receiver:replenish(Receiver, Active),
	{next_state, StateName, StateData}.

-spec get_rc(DPC, OPC, SI, RKs, EP, Assoc) -> RC | undefined
	when
		DPC :: 0..16777215,
		OPC :: 0..16777215,
		SI :: byte(),
		RKs :: [{RC, RK, AsState}],
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: 0..4294967295,
		Keys :: [{DPC, [SI], [OPC]}],
		TMT :: m3ua:tmt(),
		AsState :: down | inactive | active | pending,
		EP :: pid(),
		Assoc :: gen_sctp:assoc_id().
%% @doc Find routing context matching destination.
%%
%% 	Exhausting the routing keys takes the association down, as it
%% 	always has. It names the destination it could not place on the way
%% 	out, so the crash report says which message stopped and why rather
%% 	than only that a clause did not match.
%% @hidden
get_rc(DPC, OPC, SI, [{RC, RK, _} | T] = _RKs, EP, Assoc)
		when is_integer(DPC), is_integer(OPC), is_integer(SI) ->
	case m3ua:keymember(DPC, OPC, SI, [RK]) of
		true ->
			RC;
		false ->
			get_rc(DPC, OPC, SI, T, EP, Assoc)
	end;
get_rc(DPC, OPC, SI, [], EP, Assoc) ->
	%% None to name, so name none. RFC 4666 3.4 makes the parameter
	%% optional and expects it omitted where the process belongs to one
	%% application server, which is the ordinary case here: with a
	%% static routing key the peer goes straight to ASPAC, never sends
	%% a REGISTER, and there is no context to quote back at it.
	%%
	%% This used to raise, which took the association down over one
	%% message and then over the next, because the peer reconnects and
	%% sends it again. Four crashes in twenty seconds on nothing but
	%% MTP3 management, before any traffic was directed into the links
	%% at all.
	?LOG_NOTICE("MTP-TRANSFER sent with no routing context",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			dpc => DPC, opc => OPC, si => SI, reason => no_routing_key}),
	undefined.

%% @hidden
%% 	The absence of a context is carried by leaving the parameter out,
%% 	not by a parameter holding `undefined'.
routing_context(undefined, Params) ->
	Params;
routing_context(RC, Params) ->
	m3ua_codec:add_parameter(?RoutingContext, [RC], Params).

-spec reg_tables(RC, RK, Name, AspState) -> Result
	when
		RC :: 0..4294967295,
		RK :: {NA, Keys, TMT},
		NA :: 0..4294967295,
		Keys :: [{DPC, [SI], [OPC]}],
		DPC :: 0..16777215,
		OPC :: 0..16777215,
		SI :: byte(),
		TMT :: m3ua:tmt(),
		Name :: term(),
		AspState :: down | inactive | active,
		Result :: {ok, AsState} | {error, Reason},
		AsState :: down | inactive | active | pending,
		Reason :: term().
%% @hidden
reg_tables(RC, RK, Name, AspState) ->
	Fsm = self(),
	F = fun() ->
			case mnesia:read(m3ua_as, RC, write) of
				[] ->
					ASPs = [#m3ua_as_asp{fsm = Fsm, state = AspState}],
					AS = #m3ua_as{rc = RC, rk = RK, name = Name, asp = ASPs},
					mnesia:write(AS),
					ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
					mnesia:write(ASP),
					AS#m3ua_as.state;
				[#m3ua_as{asp = ASPs} = AS] ->
					NewASPs = case lists:keymember(Fsm, #m3ua_as_asp.fsm, ASPs) of
						true ->
							ASPs;
						false ->
							[#m3ua_as_asp{fsm = Fsm, state = AspState} | ASPs]
					end,
					NewAS = AS#m3ua_as{rk = RK, name = Name, asp = NewASPs},
					mnesia:write(NewAS),
					ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
					mnesia:write(ASP),
					NewAS#m3ua_as.state
			end
	end,
	case mnesia:transaction(F) of
		{atomic, AsState} ->
			{ok, AsState};
		{aborted, Reason} ->
			{error, Reason}
	end.

%% @hidden
%% 	RFC4666, Sections 4.3.4.1 and 4.3.4.2: an ASP DOWN, or an ASP UP at
%% 	an active asp, deregisters every routing key the asp registered.
%% 	The application servers it was put in by configuration it stays
%% 	in; only those it joined with a REG REQ does it leave. Called once
%% 	the asp's state in each of them has been brought up to date.
deregister(_Reason, #statedata{registered = []} = StateData) ->
	StateData;
deregister(Reason, #statedata{registered = RCs, rks = RKs,
		ep = EP, assoc = Assoc} = StateData) ->
	Fsm = self(),
	F = fun() ->
			lists:foreach(fun(RC) -> deregister1(Fsm, RC, true) end, RCs)
	end,
	case mnesia:transaction(F) of
		{atomic, ok} ->
			?LOG_NOTICE("Routing keys deregistered",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rcs => RCs, reason => Reason}),
			report_removed(RCs, EP, Assoc),
			NewRKs = [RK || {RC, _, _} = RK <- RKs,
					not lists:member(RC, RCs)],
			deregistered(RCs, RKs,
					StateData#statedata{rks = NewRKs, registered = []});
		{aborted, Reason1} ->
			?LOG_ERROR("Routing keys not deregistered",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rcs => RCs, reason => Reason1}),
			StateData
	end.
%% @hidden
%% 	RFC4666, Section-4.4.2: deregister each routing context the asp
%% 	registered and is not active in, and answer for every one of them
%% 	in a single DEREG RSP.
dereg_request(RCs, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort,
		ppid = Ppid, receiver = Receiver, active = Active,
		ep = EP, assoc = Assoc, rks = RKs,
		registered = Registered} = StateData) ->
	Fsm = self(),
	F = fun() ->
			[{RC, dereg_request1(Fsm, RC, Registered)} || RC <- RCs]
	end,
	Results = case mnesia:transaction(F) of
		{atomic, Results1} ->
			Results1;
		{aborted, Reason} ->
			?LOG_WARNING("Routing key deregistration failed",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rcs => RCs, reason => Reason}),
			[{RC, unknown} || RC <- RCs]
	end,
	Deregistered = [RC || {RC, deregistered} <- Results],
	case Deregistered of
		[] ->
			ok;
		_ ->
			?LOG_NOTICE("Routing keys deregistered",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rcs => Deregistered, reason => dereg_req}),
			report_removed(Deregistered, EP, Assoc)
	end,
	Frefused = fun({_RC, deregistered}) ->
				ok;
			({RC, Status}) ->
				?LOG_NOTICE("Routing key deregistration refused",
						#{layer => m3ua, ep => EP, assoc => Assoc,
						rc => RC, reason => Status})
	end,
	ok = lists:foreach(Frefused, Results),
	NewRKs = [RK || {RC, _, _} = RK <- RKs,
			not lists:member(RC, Deregistered)],
	NewStateData = deregistered(Deregistered, RKs,
			StateData#statedata{rks = NewRKs,
			registered = Registered -- Deregistered}),
	DeregResults = [{?DeregistrationResult,
			#deregistration_result{rc = RC, status = Status}}
			|| {RC, Status} <- Results],
	DeregRsp = #m3ua{class = ?RKMMessage, type = ?RKMDEREGRSP,
			params = DeregResults},
	Packet = m3ua_codec:m3ua(DeregRsp),
	case m3ua_sctp:send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			Count1 = NewStateData#statedata.count,
			DeregIn = maps:get(dereg_in, Count1, 0),
			DeregRspOut = maps:get(dereg_rsp_out, Count1, 0),
			NewCount = maps:put(dereg_in, DeregIn + 1, Count1),
			NextCount = maps:put(dereg_rsp_out, DeregRspOut + 1, NewCount),
			{next_state, StateName, NewStateData#statedata{count = NextCount}};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, NewStateData};
		{error, Reason1} ->
			{stop, {shutdown, {{EP, Assoc}, Reason1}}, NewStateData}
	end.
%% @hidden
dereg_request1(Fsm, RC, Registered) ->
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			invalid_rc;
		[#m3ua_as{asp = ASPs}] ->
			case lists:keyfind(Fsm, #m3ua_as_asp.fsm, ASPs) of
				false ->
					not_registered;
				#m3ua_as_asp{state = active} ->
					asp_currently_active;
				#m3ua_as_asp{} ->
					%% Membership given by configuration is not the
					%% asp's to give up.
					case lists:member(RC, Registered) of
						true ->
							ok = deregister1(Fsm, RC, true),
							deregistered;
						false ->
							permission_denied
					end
			end
	end.

%% @hidden
deregister1(Fsm, RC, Registered) ->
	case mnesia:read(m3ua_as, RC, write) of
		[#m3ua_as{asp = ASPs} = AS] ->
			NewASPs = lists:keydelete(Fsm, #m3ua_as_asp.fsm, ASPs),
			case removable(NewASPs, Registered, AS) of
				true ->
					ok = mnesia:delete(m3ua_as, RC, write);
				false ->
					%% An application server with no asp left up is down.
					NewAS = case [A || #m3ua_as_asp{state = S} = A <- NewASPs,
							S /= down] of
						[] ->
							AS#m3ua_as{asp = NewASPs, state = down};
						_ ->
							AS#m3ua_as{asp = NewASPs}
					end,
					ok = mnesia:write(NewAS)
			end;
		[] ->
			ok
	end,
	case mnesia:read(m3ua_asp, Fsm, write) of
		[#m3ua_asp{rc = RC}] ->
			mnesia:delete(m3ua_asp, Fsm, write);
		_ ->
			ok
	end.

%% @hidden
%% 	A callback on the path the traffic takes. An exception raised in it
%% 	is a fault of the user's, and is said at error with where it came
%% 	from; but it is the fault of one message or one event. Ending the
%% 	association over it would drop every message behind it, and a
%% 	message that raises every time would end each new association in
%% 	turn until the endpoint's supervisor gave up. So it is contained:
%% 	counted under callback_raised, and `Fallback' answered in its place,
%% 	which is what the callback would have answered had it done nothing
%% 	and kept its state.
contain(Handler, CbMod, CbArgs, Fallback, Count, EP, Assoc) ->
	F = fun() -> m3ua_callback:cb(Handler, CbMod, CbArgs) end,
	contain1(Handler, F, Fallback, Count, EP, Assoc).
%% @hidden
contain1(Handler, F, Fallback, Count, EP, Assoc) ->
	try F() of
		Result ->
			{Result, Count}
	catch
		Class:Reason:Stacktrace ->
			?LOG_ERROR("Callback raised",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					callback => Handler, class => Class, reason => Reason,
					stacktrace => Stacktrace}),
			Raised = maps:get(callback_raised, Count, 0),
			{Fallback, maps:put(callback_raised, Raised + 1, Count)}
	end.

%% @hidden
%% 	Tell the callback of the routing contexts just deregistered, with
%% 	the routing key each had, as register/5 was told of them. `RKs' is
%% 	the list from before they were taken out of it. deregister/5 is
%% 	optional -- a callback module written before it existed does not
%% 	export it -- and the deregistration has happened whatever the
%% 	callback answers, so neither its absence nor an error from it
%% 	undoes anything; both are said at notice.
deregistered(RCs, RKs, #statedata{callback = CbMod, cb_state = CbState,
		count = Count, ep = EP, assoc = Assoc} = StateData) ->
	F = fun(RC, {CbState0, Count0}) ->
			{NA, Keys, Mode} = case lists:keyfind(RC, 1, RKs) of
				{RC, RK, _AsState} ->
					RK;
				false ->
					{undefined, [], undefined}
			end,
			CbArgs = [RC, NA, Keys, Mode, CbState0],
			Fcb = fun() -> deregister_cb(CbMod, CbArgs, CbState0, EP, Assoc) end,
			case contain1(deregister, Fcb, {ok, CbState0}, Count0, EP, Assoc) of
				{{ok, CbState1}, Count1} ->
					{CbState1, Count1};
				{{error, Reason}, Count1} ->
					?LOG_NOTICE("Deregistration refused by callback",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							rc => RC, reason => Reason}),
					{CbState0, Count1}
			end
	end,
	{NewCbState, NewCount} = lists:foldl(F, {CbState, Count}, RCs),
	StateData#statedata{cb_state = NewCbState, count = NewCount}.
%% @hidden
deregister_cb(CbMod, CbArgs, CbState, EP, Assoc) when is_atom(CbMod) ->
	case code:ensure_loaded(CbMod) of
		{module, CbMod} ->
			case erlang:function_exported(CbMod, deregister, 5) of
				true ->
					m3ua_callback:cb(deregister, CbMod, CbArgs);
				false ->
					?LOG_NOTICE("Deregistration not delivered",
							#{layer => m3ua, ep => EP, assoc => Assoc,
							callback => CbMod, reason => no_callback}),
					{ok, CbState}
			end;
		{error, Reason} ->
			?LOG_NOTICE("Deregistration not delivered",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					callback => CbMod, reason => Reason}),
			{ok, CbState}
	end;
deregister_cb(#m3ua_fsm_cb{} = CbMod, CbArgs, _CbState, _EP, _Assoc) ->
	m3ua_callback:cb(deregister, CbMod, CbArgs).

%% @hidden
%% 	RFC4666, Section-4.4.2: "If a Deregistration results in no more ASPs
%% 	in an Application Server, an SG MAY delete the Routing Key data."
%% 	This one does for an application server a REG REQ brought into
%% 	being, left by the last asp that registered into it -- and for no
%% 	other. One layer management configured has a name (m3ua:as_add/7);
%% 	one reg_request1/3 made for a routing key it had not seen has none,
%% 	and no other record is kept of how it came to be, short of a field
%% 	the table schema does not have.
removable([], true, #m3ua_as{name = undefined}) ->
	true;
removable(_ASPs, _Registered, #m3ua_as{}) ->
	false.

%% @hidden
report_removed(RCs, EP, Assoc) ->
	case [RC || RC <- RCs, mnesia:dirty_read(m3ua_as, RC) == []] of
		[] ->
			ok;
		Removed ->
			?LOG_NOTICE("Application servers removed",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rcs => Removed, reason => no_asp_left})
	end.

%% @hidden
update_rks(RC, RK, AsState, RKs) ->
	case lists:keytake(RC, 1, RKs) of
		{value, {RC, RK1, AsState}, RKs1} when RK == undefined ->
			[{RC, RK1, AsState} | RKs1];
		{value, _, RKs1} ->
			[{RC, RK, AsState} | RKs1];
		false when RK == undefined ->
			RKs;
		false ->
			[{RC, RK, AsState} | RKs]
	end.

%% @hidden
state_traffic_maint(undefined, Event, #statedata{rks = RKs} = StateData) ->
	RCs = [RC || {RC, _, _} <- RKs],
	state_traffic_maint1(RCs, Event, StateData);
state_traffic_maint(RCs, Event, StateData) ->
	state_traffic_maint1(RCs, Event, StateData).
%% @hidden
state_traffic_maint1([RC | T], Event,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	F = fun() -> state_traffic_maint2(RC, Event) end,
	case mnesia:transaction(F) of
		{atomic, NotifyFsms} ->
			F3 = fun({Fsm, pending}) ->
						ok = gen_statem:cast(Fsm, {'M-NOTIFY', as_pending, RC});
					({Fsm, inactive}) ->
						ok = gen_statem:cast(Fsm, {'M-NOTIFY', as_inactive, RC});
					({Fsm, active}) ->
						ok = gen_statem:cast(Fsm, {'M-NOTIFY', as_active, RC});
					({Fsm, down}) ->
						ok = gen_statem:cast(Fsm, {'M-NOTIFY', as_inactive, RC})
			end,
			ok = lists:foreach(F3, NotifyFsms),
			state_traffic_maint1(T, Event, StateData);
		{aborted, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
state_traffic_maint1([], _Event, StateData) ->
	StateData.
%% @hidden
state_traffic_maint2(RC, Event) ->
	Fcount = fun(#m3ua_as_asp{state = active}, {NA, NIA}) ->
				{NA + 1, NIA};
			(#m3ua_as_asp{state = inactive}, {NA, NIA}) ->
				{NA, NIA + 1};
			(_, Acc) ->
				Acc
	end,
	Fdown = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, down} | Acc]
	end,
	Finactive = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, inactive} | Acc]
	end,
	Factive = fun(#m3ua_as_asp{fsm = Fsm}, Acc) ->
				[{Fsm, active} | Acc]
	end,
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			[];
		[#m3ua_as{asp = Asps, state = AsState, min_asp = Min} = AS] ->
			case lists:keytake(self(), #m3ua_as_asp.fsm, Asps) of
				{value, Asp, RemAsp} ->
					AspState = case Event of
						asp_down ->
							down;
						asp_up ->
							inactive;
						asp_inactive ->
							inactive;
						asp_active ->
							active
					end,
					NewAsp = Asp#m3ua_as_asp{state = AspState},
					NewAsps = [NewAsp | RemAsp],
					case lists:foldl(Fcount, {0, 0}, NewAsps) of
						{0, 0} when AsState == down ->
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{0, 0} ->
							% @todo pending state with recovery timer T(r)
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Fdown, [], NewAsps);
						{0, NumInactive} when NumInactive > 0, AsState == inactive ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{0, NumInactive} when NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Finactive, [], NewAsps);
						{NumActive, NumInactive} when AsState == inactive,
								NumActive < Min, NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							[];
						{NumActive, _NumInactive}
								when AsState == inactive, NumActive >= Min ->
							NewAS = AS#m3ua_as{state = active, asp = NewAsps},
							mnesia:write(NewAS),
							lists:foldl(Factive, [], NewAsps);
						{_NumActive, _NumInactive} ->
							NewAS = AS#m3ua_as{asp = NewAsps},
							mnesia:write(NewAS),
							[]
					end;
				false ->
					[]
			end
	end.

