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
%%%    <li><tt>APC = 0..16777215 | {0..16777215, Mask}</tt>, Mask the number of wildcarded low-order bits (RFC 4666 3.4.1)</li>
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

%% How often the counters an association publishes (m3ua_status) are
%% brought up to date. Its state is written as it changes.
-define(PUBLISH_INTERVAL, 1000).

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
		APC :: m3ua_codec:apc(),
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
	%% state_enter: each state writes itself to m3ua_status on entry,
	%% in one place rather than at every transition into it.
	[state_functions, state_enter].

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
		EP, EpName, Cb, #{static := Static, use_rc := UseRC,
		cb_opts := CbOpts, copy := Copy}]) ->
	process_flag(trap_exit, true),
	ok = copying(Copy, EpName, Assoc),
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
		{ok, AsState, _Notify} ->
			%% Nobody is told here. A cast to this process would cancel
			%% the zero timeout that announces it, and the members that
			%% are up were told of the state they brought about.
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
down(enter, _OldStateName, StateData) ->
	ok = publish(down, StateData),
	keep_state_and_data;
down(timeout, _EventContent, #statedata{ep = EP, assoc = Assoc, receiver = undefined,
		socket = Socket, active = Active,
		cb_state = CbState} = StateData) ->
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
	%% Not before: this message would cancel the zero timeout above.
	_ = erlang:send_after(?PUBLISH_INTERVAL, self(), '$m3ua_publish'),
	{NewCbState, CbCount} = lifecycle(asp_down, [CbState], StateData),
	{next_state, down, StateData#statedata{cb_state = NewCbState,
			count = CbCount, receiver = Receiver, lm = whereis(m3ua)}};
down(cast, {'M-RK_DEREG', request, _, _, _} = Event, StateData) ->
	handle_dereg(Event, down, StateData);
%% A static registration asks nothing of the peer and may be made down,
%% as at the asp (m3ua_asp_fsm): the process joins its server down and
%% is carried from there by its ASPUP and ASPAC. It fell to the
%% catch-all here and was discarded, and layer management's call timed
%% out: on a node whose far end reconnected, a registration made the
%% moment the association was up reached this state machine 20 ms
%% before the peer's ASPUP and was lost for good. Anything else is
%% refused at once rather than left to time out.
down(cast, {'M-RK_REG', request, _, _, _, _, _, _, _} = Event,
		#statedata{static = true} = StateData) ->
	handle_reg(Event, down, StateData);
down(cast, {'M-RK_REG', request, Ref, From, RC, _, _, _, _},
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	?LOG_NOTICE("Routing key registration refused",
			#{layer => m3ua, ep => EP, assoc => Assoc, rc => RC,
			reason => asp_down}),
	gen_server:cast(From, {'M-RK_REG', confirm, Ref, {error, asp_down}}),
	{next_state, down, StateData};
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
inactive(enter, _OldStateName, StateData) ->
	ok = publish(inactive, StateData),
	keep_state_and_data;
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
	{next_state, inactive, StateData#statedata{count = NewCount},
			{reply, From, {error, unexpected_message}}};
inactive(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, inactive, StateData).

-spec active(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>active</b> state.
%% @private
%%
active(enter, _OldStateName, StateData) ->
	ok = publish(active, StateData),
	keep_state_and_data;
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
			data_stream(SLS, NumStreams)
	end,
	case send(Socket, {PeerAddr, PeerPort}, Stream1, Ppid, Packet) of
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
			data_stream(SLS, NumStreams)
	end,
	case send(Socket, {PeerAddr, PeerPort}, Stream1, Ppid, Packet) of
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
handle_event(cast, {'M-DISPLACE', RC}, active,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort,
		ppid = Ppid, rks = RKs, cb_state = CbState, count = Count,
		ep = EP, assoc = Assoc} = StateData) ->
	%% Another process of an override server went active in this one's
	%% place (state_traffic_maint2/2): tell the peer, and stop carrying
	%% unless it still carries for another server.
	P0 = m3ua_codec:add_parameter(?Status, alternate_asp_active, []),
	P1 = m3ua_codec:add_parameter(?RoutingContext, [RC], P0),
	Notify = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = P1},
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, m3ua_codec:m3ua(Notify)) of
		ok ->
			NotifyOut = maps:get(notify_out, Count, 0),
			StateData1 = StateData#statedata{
					count = maps:put(notify_out, NotifyOut + 1, Count)},
			?LOG_NOTICE("ASP displaced by an alternate ASP active",
					#{layer => m3ua, ep => EP, assoc => Assoc, rc => RC,
					reason => alternate_asp_active}),
			case carrying_elsewhere(RC, RKs) of
				true ->
					{next_state, active, StateData1};
				false ->
					{NewCbState, CbCount} = lifecycle(asp_inactive,
							[CbState], StateData1),
					report_carrying(active, inactive, EP, Assoc),
					{next_state, inactive, StateData1#statedata{
							cb_state = NewCbState, count = CbCount}}
			end;
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end;
handle_event(cast, {'M-DISPLACE', _RC}, StateName, StateData) ->
	%% Displaced after it had stopped carrying of its own accord.
	{next_state, StateName, StateData};
handle_event(cast, {'M-NOTIFY', AsState, RC}, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active, ep = EP,
		assoc = Assoc, count = Count, rks = RKs} = StateData) ->
	NewRKs = update_rks(RC, undefined, AsState, RKs),
	NewStateData = StateData#statedata{rks = NewRKs},
	%% With the routing context, as send_notify/3 has it: a process in
	%% more than one server cannot otherwise tell which is pending.
	Params = m3ua_codec:add_parameter(?RoutingContext, [RC],
			m3ua_codec:add_parameter(?Status, AsState, [])),
	Notify = #m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params},
	Packet = m3ua_codec:m3ua(Notify),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
	{next_state, StateName, StateData, {reply, From, counters(Counters)}};
handle_event(cast, Event, StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	%% Nothing sends one of these that this process knows of; ending
	%% the association over it, as a function_clause used to, would
	%% cost every message behind it.
	?LOG_NOTICE("Unexpected event discarded",
			#{layer => m3ua, ep => EP, assoc => Assoc, state => StateName,
			event => Event, reason => no_clause}),
	{next_state, StateName, StateData};
handle_event({call, From}, Request, StateName,
		#statedata{ep = EP, assoc = Assoc} = StateData) ->
	?LOG_NOTICE("Unexpected request refused",
			#{layer => m3ua, ep => EP, assoc => Assoc, state => StateName,
			request => Request, reason => no_clause}),
	{next_state, StateName, StateData,
			{reply, From, {error, unexpected_request}}};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{[#sctp_sndrcvinfo{assoc_id = Assoc, stream = Stream}], Data}},
		StateName, #statedata{socket = Socket,
		assoc = Assoc} = StateData) when is_binary(Data) ->
	ok = copy(received, Data),
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
handle_event(info, '$m3ua_publish', StateName, StateData) ->
	_ = erlang:send_after(?PUBLISH_INTERVAL, self(), '$m3ua_publish'),
	ok = publish(StateData),
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
	ok = m3ua_status:forget(),
	report_terminated(Reason, StateName, StateData),
	terminate1(Reason, StateName, StateData);
terminate(Reason, StateName, #statedata{socket = Socket} = StateData) ->
	ok = m3ua_status:forget(),
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
terminate1(Reason, StateName, StateData0) when StateName /= down ->
	%% Ending as an association is lost is ASPDN for the server: taken
	%% out of it, it has to be counted out first, or a server whose one
	%% active process this was stays active with none, never pending and
	%% nobody told -- the commonest failover there is.
	StateData = state_traffic_maint(undefined, asp_down, StateData0),
	terminate1(Reason, down, StateData);
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
terminate2(Reason, #statedata{callback = CbMod, cb_state = CbState,
		count = Count, ep = EP, assoc = Assoc}) ->
	%% Ending anyway; an exception here would only replace the reason
	%% it is ending for, and be logged as a crash of this process.
	F = fun() -> m3ua_callback:cb(terminate, CbMod, [Reason, CbState]) end,
	_ = contain1(terminate, F, ok, Count, EP, Assoc),
	ok.

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
		assoc = Assoc, ep = EP,
		cb_state = CbState} = StateData) when is_integer(RC) ->
	SortedKeys = m3ua:sort(Keys),
	RK = {NA, SortedKeys, Mode},
	case reg_tables(RC, RK, AS, StateName) of
		{ok, AsState, Notify} ->
			ok = notify(RC, Notify),
			NewRKs = lists:keystore(RC, 1, RKs, {RC, RK, AsState}),
			CbArgs = [RC, NA, SortedKeys, Mode, CbState],
			{NewCbState, CbCount} = lifecycle(register, CbArgs, StateData),
			NewStateData = StateData#statedata{rks = NewRKs,
					cb_state = NewCbState, count = CbCount},
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
		assoc = Assoc, ep = EP, cb_state = CbState} = StateData) ->
	AspUp = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspUp, undefined),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_up, StateData),
			CbArgs = [CbState],
			{NewCbState, CbCount} = lifecycle(asp_up, CbArgs, StateData),
			ok = m3ua_receiver:replenish(Receiver, Active),
			UpIn = maps:get(up_in, CbCount, 0),
			UpAckOut = maps:get(up_ack_out, CbCount, 0),
			NewCount = maps:put(up_in, UpIn + 1, CbCount),
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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
		assoc = Assoc, ep = EP} = StateData) ->
	?LOG_NOTICE("ASPUP received in the active state",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => unexpected_message}),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	Packet = m3ua_codec:m3ua(AspUpAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = deregister(asp_up,
					state_traffic_maint(undefined, asp_inactive, StateData)),
			%% From NewStateData: deregistering told the callback too.
			CbArgs = [NewStateData#statedata.cb_state],
			{NewCbState, CbCount} = lifecycle(asp_inactive, CbArgs, NewStateData),
			UpIn = maps:get(up_in, CbCount, 0),
			UpAckOut = maps:get(up_ack_out, CbCount, 0),
			NewCount = maps:put(up_in, UpIn + 1, CbCount),
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
%% RFC4666, Sections 4.3.4.3 and 4.3.4.4: an ASP Active or ASP Inactive
%% naming a routing context that is not defined, by configuration or
%% registration, is answered with an ERR -- "No configured AS for ASP"
%% for ASPAC, "Invalid Routing Context" for ASPIA -- naming the contexts
%% that are not, and changes nothing; one naming none is refused only
%% where there is no application server here at all. These used to be
%% acknowledged whatever they named. A message naming some contexts
%% that are defined and some that are not is refused whole.
handle_sgp(#m3ua{class = ?ASPTMMessage, type = Type, params = Params} = M3UA,
		StateName, Stream, #statedata{rks = RKs} = StateData)
		when (Type == ?ASPTMASPAC andalso StateName == inactive)
		orelse (Type == ?ASPTMASPIA andalso
		(StateName == active orelse StateName == inactive)) ->
	Parameters = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, Parameters, undefined),
	Undefined = case Type of
		?ASPTMASPAC ->
			no_configured_as_for_asp;
		?ASPTMASPIA ->
			invalid_routing_context
	end,
	case undefined_rcs(RCs, RKs) of
		[] ->
			handle_asptm(M3UA, StateName, Stream, StateData);
		none ->
			refuse_asptm(Type, no_configured_as_for_asp, [], StateName,
					StateData);
		Unknown ->
			refuse_asptm(Type, Undefined, Unknown, StateName, StateData)
	end;
handle_sgp(#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN, params = Params},
		StateName, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP} = StateData)
		when StateName == inactive; StateName == active ->
	AspDown = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspDown, undefined),
	AspDownAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDNACK},
	Packet = m3ua_codec:m3ua(AspDownAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = deregister(asp_down,
					state_traffic_maint(RCs, asp_down, StateData)),
			%% From NewStateData: deregistering told the callback too.
			CbArgs = [NewStateData#statedata.cb_state],
			{NewCbState, CbCount} = lifecycle(asp_down, CbArgs, NewStateData),
			ok = m3ua_receiver:replenish(Receiver, Active),
			DownIn = maps:get(down_in, CbCount, 0),
			DownAckOut = maps:get(down_ack_out, CbCount, 0),
			NewCount = maps:put(down_in, DownIn + 1, CbCount),
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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
%% 	ASPAC and ASPIA once their routing contexts are known to be defined.
handle_asptm(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC, params = Params},
		inactive, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, cb_state = CbState} = StateData) ->
	AspActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspActive, undefined),
	%% RFC4666, Section-4.3.4.3: the ACK reflects any Traffic Mode Type
	%% the ASPAC had, and MUST name its routing contexts where it named
	%% any. It used to carry neither.
	Tmt = case m3ua_codec:get_parameter(?TrafficModeType, AspActive,
			undefined) of
		undefined ->
			[];
		Mode ->
			[{?TrafficModeType, Mode}]
	end,
	Rc = case RCs of
		undefined ->
			[];
		_ ->
			[{?RoutingContext, RCs}]
	end,
	AspActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK,
			params = m3ua_codec:parameters(Tmt ++ Rc)},
	Packet = m3ua_codec:m3ua(AspActiveAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_active, StateData),
			CbArgs = [CbState],
			{NewCbState, CbCount} = lifecycle(asp_active, CbArgs, StateData),
			ok = m3ua_receiver:replenish(Receiver, Active),
			ActiveIn = maps:get(active_in, CbCount, 0),
			ActiveAckOut = maps:get(active_ack_out, CbCount, 0),
			NewCount = maps:put(active_in, ActiveIn + 1, CbCount),
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
handle_asptm(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA, params = Params},
		active, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort, ppid = Ppid, receiver = Receiver, active = Active,
		assoc = Assoc, ep = EP, cb_state = CbState} = StateData) ->
	AspInActive = m3ua_codec:parameters(Params),
	RCs = m3ua_codec:get_parameter(?RoutingContext, AspInActive, undefined),
	AspInActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(AspInActiveAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			NewStateData = state_traffic_maint(RCs, asp_inactive, StateData),
			CbArgs = [CbState],
			{NewCbState, CbCount} = lifecycle(asp_inactive, CbArgs, StateData),
			ok = m3ua_receiver:replenish(Receiver, Active),
			InactiveIn = maps:get(inactive_in, CbCount, 0),
			InactiveAckOut = maps:get(inactive_ack_out, CbCount, 0),
			NewCount = maps:put(inactive_in, InactiveIn + 1, CbCount),
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
%% RFC4666, Section-4.3.4.4: "An ASP Inactive message MUST always be
%% responded to by the peer", with an ASP Inactive Ack where the routing
%% key is defined -- the asp already inactive included. Most often it
%% is an asp this gateway displaced in an override application server
%% (4.3.4.3), whose ASPIA crossed the NTFY Alternate ASP Active; it used
%% to get an ERR, Unexpected Message, and take itself to be active
%% still. Nothing changes here: the asp is where it asked to be.
handle_asptm(#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA},
		inactive, _Stream, #statedata{socket = Socket, peer_addr = PeerAddr,
		peer_port = PeerPort, ppid = Ppid, receiver = Receiver,
		active = Active, assoc = Assoc, ep = EP, count = Count} = StateData) ->
	?LOG_DEBUG("ASPIA acknowledged again",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			reason => already_inactive}),
	AspInActiveAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIAACK},
	Packet = m3ua_codec:m3ua(AspInActiveAck),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
		ok ->
			ok = m3ua_receiver:replenish(Receiver, Active),
			InactiveIn = maps:get(inactive_in, Count, 0),
			InactiveAckOut = maps:get(inactive_ack_out, Count, 0),
			NewCount = maps:put(inactive_in, InactiveIn + 1, Count),
			NextCount = maps:put(inactive_ack_out, InactiveAckOut + 1, NewCount),
			{next_state, inactive, StateData#statedata{count = NextCount}};
		{error, eagain} ->
			% @todo flow control
			{stop, {shutdown, {{EP, Assoc}, eagain}}, StateData};
		{error, Reason} ->
			{stop, {shutdown, {{EP, Assoc}, Reason}}, StateData}
	end.

%% @hidden
%% 	The routing contexts named that are not defined here, by
%% 	configuration or registration: [] where all are, and `none' where
%% 	none is named and this process has no routing key, nor is any
%% 	application server configured here.
undefined_rcs(undefined, []) ->
	try mnesia:table_info(m3ua_as, size) of
		0 ->
			none;
		_ ->
			[]
	catch
		exit:_ ->
			none
	end;
undefined_rcs(undefined, _RKs) ->
	[];
undefined_rcs(RCs, _RKs) when is_list(RCs) ->
	[RC || RC <- RCs, mnesia:dirty_read(m3ua_as, RC) == []].

%% @hidden
%% 	Answer an ASPAC or ASPIA with an ERR naming the routing contexts
%% 	that are not defined, and leave the asp as it was.
refuse_asptm(Type, ErrorCode, RCs, StateName,
		#statedata{ep = EP, assoc = Assoc, count = Count} = StateData) ->
	Message = case Type of
		?ASPTMASPAC ->
			aspac;
		?ASPTMASPIA ->
			aspia
	end,
	?LOG_NOTICE("ASP traffic maintenance refused",
			#{layer => m3ua, ep => EP, assoc => Assoc, state => StateName,
			message => Message, rcs => RCs, reason => ErrorCode}),
	Refused = maps:get(asptm_refused, Count, 0),
	NewCount = maps:put(asptm_refused, Refused + 1, Count),
	send_error(ErrorCode, RCs, StateName,
			StateData#statedata{count = NewCount}).

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
send_error(ErrorCode, StateName, StateData) ->
	send_error(ErrorCode, [], StateName, StateData).
%% @hidden
%% 	The same, naming the routing contexts the error is about.
send_error(ErrorCode, RCs, StateName,
		#statedata{socket = Socket, peer_addr = PeerAddr, peer_port = PeerPort,
		ppid = Ppid, receiver = Receiver, active = Active,
		ep = EP, assoc = Assoc, count = Count} = StateData) ->
	P0 = m3ua_codec:add_parameter(?ErrorCode, ErrorCode, []),
	P1 = case RCs of
		[] ->
			P0;
		_ ->
			m3ua_codec:add_parameter(?RoutingContext, RCs, P0)
	end,
	ErrorParams = m3ua_codec:parameters(P1),
	ErrorMsg = #m3ua{class = ?MGMTMessage,
			type = ?MGMTError, params = ErrorParams},
	Packet = m3ua_codec:m3ua(ErrorMsg),
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
		registered = Registered, cb_state = CbState,
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
					{NewCbState, CbCount} = lifecycle(register, CbArgs, StateData),
					NewStateData = StateData#statedata{rks = NewRKs,
							registered = [NewRC | lists:delete(NewRC, Registered)],
							cb_state = NewCbState, count = CbCount},
					RegResult = {?RegistrationResult, RR},
					reg_request(T, StateName, NewStateData, [RegResult | RegResults], Notifies);
				{atomic, {reg, AsState, #registration_result{rc = NewRC} = RR, Notify}} ->
					NewRKs = update_rks(NewRC, RK, AsState, RKs),
					CbArgs = [NewRC, NA, SortedKeys, Mode, CbState],
					{NewCbState, CbCount} = lifecycle(register, CbArgs, StateData),
					NewStateData = StateData#statedata{rks = NewRKs,
							registered = [NewRC | lists:delete(NewRC, Registered)],
							cb_state = NewCbState, count = CbCount},
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
			case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, RegResPacket) of
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
					%% A server active or pending keeps its state: a process
					%% registering while the server waits T(r) is the
					%% standby it waits for, and lowering it to inactive
					%% here ended the wait with nobody told.
					NewAS = case AsState of
						active ->
							AS#m3ua_as{asp = NewSGPs};
						pending ->
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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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

%% @hidden
%% 	This association's row in m3ua_status: all of it on entry to a
%% 	state, and what changes without one -- counters, the state of the
%% 	application servers -- once a second.
publish(StateName, #statedata{ep = EP, ep_name = EpName, assoc = Assoc,
		peer_addr = PeerAddr, peer_port = PeerPort} = StateData) ->
	Now = erlang:system_time(millisecond),
	m3ua_status:association((published(StateData, Now))#{ep => EP,
			name => EpName, assoc_id => Assoc, peer => {[PeerAddr], PeerPort},
			asp_state => StateName, since => Now}).
%% @hidden
publish(StateData) ->
	m3ua_status:association(published(StateData,
			erlang:system_time(millisecond))).
%% @hidden
published(#statedata{rks = RKs, count = Count}, Now) ->
	#{contexts => maps:from_list([{RC, AsState} || {RC, _, AsState} <- RKs]),
			counters => Count, updated => Now}.

%% @hidden
%% 	m3ua:start/3's `{copy, {Module, Function, Arg}}', kept where the
%% 	send and receive paths reach it without the state data, which not
%% 	every one of them has to hand. Nothing is kept without the option,
%% 	and then copy/2 costs a dictionary read.
copying(undefined, _EpName, _Assoc) ->
	ok;
copying({Module, Function, Arg}, EpName, Assoc) ->
	_ = put('$m3ua_copy', {Module, Function, Arg, EpName, Assoc}),
	ok.

%% @hidden
%% 	Hand one whole M3UA message, as on the wire, to the copy function
%% 	in this process. It is the caller's and is not to block; an
%% 	exception in it costs that copy, is counted under copy_raised, and
%% 	is said at error the first time, since a copy that fails once will
%% 	most likely fail for every message.
copy(Direction, Packet) ->
	case get('$m3ua_copy') of
		undefined ->
			ok;
		{Module, Function, Arg, EpName, Assoc} ->
			Copy = #{name => EpName, assoc => Assoc, dir => Direction,
					message => iolist_to_binary(Packet)},
			try Module:Function(Arg, Copy) of
				_ ->
					ok
			catch
				Class:Reason:Stacktrace ->
					case get('$m3ua_copy_raised') of
						undefined ->
							?LOG_ERROR("Copy raised",
									#{layer => m3ua, name => EpName,
									assoc => Assoc, function => {Module, Function},
									class => Class, reason => Reason,
									stacktrace => Stacktrace}),
							_ = put('$m3ua_copy_raised', 1);
						N ->
							_ = put('$m3ua_copy_raised', N + 1)
					end,
					ok
			end
	end.

%% @hidden
%% 	Every M3UA message this process sends goes through here, so that
%% 	each one sent is copied.
send(Socket, Peer, Stream, Ppid, Packet) ->
	case m3ua_sctp:send(Socket, Peer, Stream, Ppid, Packet) of
		ok ->
			copy(sent, Packet);
		Other ->
			Other
	end.

%% @hidden
%% 	The counters, with the copies that raised.
counters(Counters) ->
	case get('$m3ua_copy_raised') of
		undefined ->
			Counters;
		N ->
			Counters#{copy_raised => N}
	end.

-spec data_stream(SLS, NumStreams) -> Stream
	when
		SLS :: byte(),
		NumStreams :: non_neg_integer(),
		Stream :: non_neg_integer().
%% @doc The stream a DATA goes on when the caller named none.
%%
%% 	RFC4666, Section-1.4.7: "The DATA message MUST NOT be sent on stream
%% 	0." This used to answer `SLS rem NumStreams', which put an SLS of 0,
%% 	and every multiple of the stream count, on stream 0; osmo-stp
%% 	answers each with an ERR (Invalid Stream Identifier). The SLS now
%% 	spreads over streams 1 to NumStreams - 1. An association with a
%% 	single outbound stream has no other: DATA still goes on stream 0
%% 	there, against the rule, rather than nowhere.
%% @hidden
data_stream(SLS, NumStreams) when NumStreams > 1 ->
	1 + SLS rem (NumStreams - 1);
data_stream(_SLS, _NumStreams) ->
	0.

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
		Result :: {ok, AsState, Notify} | {error, Reason},
		AsState :: down | inactive | active | pending,
		Notify :: [{Fsm :: pid(), AsState}],
		Reason :: term().
%% @hidden
%% 	Put this asp in the application server of `RC', in `AspState'.
%% 	`Notify' names each member to be told the server's new state, and
%% 	is empty where it has none.
reg_tables(RC, RK, Name, AspState) ->
	Fsm = self(),
	F = fun() ->
			AS = case mnesia:read(m3ua_as, RC, write) of
				[] ->
					#m3ua_as{rc = RC, rk = RK, name = Name};
				[#m3ua_as{} = AS0] ->
					AS0
			end,
			#m3ua_as{asp = ASPs, state = AsState, min_asp = Min} = AS,
			NewASPs = case lists:keymember(Fsm, #m3ua_as_asp.fsm, ASPs) of
				true ->
					ASPs;
				false ->
					[#m3ua_as_asp{fsm = Fsm, state = AspState} | ASPs]
			end,
			NewAsState = raise_as_state(AsState, NewASPs, Min),
			NewAS = AS#m3ua_as{rk = RK, name = Name, asp = NewASPs,
					state = NewAsState},
			mnesia:write(NewAS),
			ASP = #m3ua_asp{fsm = Fsm, rc = RC, rk = RK},
			mnesia:write(ASP),
			Notify = case NewAsState of
				AsState ->
					[];
				_ ->
					[{Member, NewAsState}
							|| #m3ua_as_asp{fsm = Member} <- NewASPs]
			end,
			{NewAsState, Notify}
	end,
	case mnesia:transaction(F) of
		{atomic, {Joined, Told}} ->
			{ok, Joined, Told};
		{aborted, Reason} ->
			{error, Reason}
	end.

%% @hidden
%% 	The state an application server is raised to by a member joining
%% 	it in a state of its own -- a registration by layer management,
%% 	which may come after the asp's ASPAC. That used to leave the record
%% 	down with an active asp in it until the next ASPAC or ASPIA. Only
%% 	raised here: lowering it is for the ASPIA, ASPDN and deregistration
%% 	that take a member out of service (state_traffic_maint2/2 and
%% 	deregister1/3), which also hold an active server with fewer active
%% 	asps than its minimum where this, starting from nothing, would not.
raise_as_state(AsState, ASPs, Min) ->
	NumActive = length([A || #m3ua_as_asp{state = active} = A <- ASPs]),
	NumUp = length([A || #m3ua_as_asp{state = S} = A <- ASPs, S /= down]),
	Joined = if
		NumActive > 0, NumActive >= Min ->
			active;
		NumUp > 0 ->
			inactive;
		true ->
			down
	end,
	case as_rank(Joined) > as_rank(AsState) of
		true ->
			Joined;
		false ->
			AsState
	end.

%% @hidden
%% 	Tell each member of the application server of `RC' of its new
%% 	state, as state_traffic_maint1/3 does.
notify(RC, Notify) ->
	F = fun({Fsm, active}) ->
				gen_statem:cast(Fsm, {'M-NOTIFY', as_active, RC});
			({Fsm, pending}) ->
				gen_statem:cast(Fsm, {'M-NOTIFY', as_pending, RC});
			({Fsm, _}) ->
				gen_statem:cast(Fsm, {'M-NOTIFY', as_inactive, RC})
	end,
	lists:foreach(F, Notify).

%% @hidden
as_rank(down) -> 0;
as_rank(inactive) -> 1;
as_rank(pending) -> 1;
as_rank(active) -> 2.

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
	case send(Socket, {PeerAddr, PeerPort}, 0, Ppid, Packet) of
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
%% 	A callback of the association's own life: asp_up, asp_down,
%% 	asp_active, asp_inactive and register. These used to be matched
%% 	against {ok, State} and nothing else, so an exception in one, or
%% 	any other answer -- register may answer {error, Reason} by its
%% 	spec -- ended the association over what had already happened on
%% 	the wire. Now an exception is said and counted as on the traffic
%% 	path (contain1/6); an error from register is said at notice and
%% 	the registration stands, as deregister/5's does; any other answer
%% 	is a fault of the callback's, said at error and counted with the
%% 	exceptions. In each case the state the callback had is kept.
lifecycle(Handler, CbArgs, #statedata{callback = CbMod, cb_state = CbState,
		count = Count, ep = EP, assoc = Assoc}) ->
	F = fun() -> m3ua_callback:cb(Handler, CbMod, CbArgs) end,
	case contain1(Handler, F, {ok, CbState}, Count, EP, Assoc) of
		{{ok, NewCbState}, Count1} ->
			{NewCbState, Count1};
		{{error, Reason}, Count1} when Handler == register ->
			?LOG_NOTICE("Registration refused by callback",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rc => hd(CbArgs), reason => Reason}),
			{CbState, Count1};
		{Answer, Count1} ->
			?LOG_ERROR("Callback answered outside its contract",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					callback => Handler, answer => Answer}),
			Raised = maps:get(callback_raised, Count1, 0),
			{CbState, maps:put(callback_raised, Raised + 1, Count1)}
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
%% 	`RK' undefined is a change of state alone (M-NOTIFY), which keeps
%% 	the routing key already held, whatever the state was before.
update_rks(RC, RK, AsState, RKs) ->
	case lists:keytake(RC, 1, RKs) of
		{value, {RC, RK1, _OldState}, RKs1} when RK == undefined ->
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
		{atomic, {NotifyFsms, Recovery}} ->
			%% T(r) belongs to layer management and not to this state
			%% machine, which the ASPDN or association loss that set it
			%% running may well end.
			case Recovery of
				start ->
					gen_server:cast(m3ua, {'T(r)', start, RC});
				stop ->
					gen_server:cast(m3ua, {'T(r)', stop, RC});
				none ->
					ok
			end,
			F3 = fun({Fsm, displaced}) ->
						ok = gen_statem:cast(Fsm, {'M-DISPLACE', RC});
					({Fsm, pending}) ->
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
			%% This used to answer a stop tuple where every caller
			%% expects the state data, so the state machine died later,
			%% of a badrecord that said nothing of the cause.
			?LOG_ERROR("Application server state not updated",
					#{layer => m3ua, ep => EP, assoc => Assoc,
					rc => RC, event => Event, reason => Reason}),
			state_traffic_maint1(T, Event, StateData)
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
	Fpending = fun(#m3ua_as_asp{fsm = Fsm, state = inactive}, Acc) ->
				[{Fsm, pending} | Acc];
			(_, Acc) ->
				Acc
	end,
	Tr = application:get_env(m3ua, recovery_timer, ?RECOVERY_TIMER),
	case mnesia:read(m3ua_as, RC, write) of
		[] ->
			{[], none};
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
					%% RFC 4666 4.3.4.3: in override one process carries.
					%% One going active takes the place of any that was,
					%% which moves to inactive and is told Alternate ASP
					%% Active. Both were left active, and DATA could go
					%% to either: seen on NG-STP's live node on
					%% 2026-09-29, where the one displaced then kept the
					%% server from going pending when the other left.
					{Rest, Displaced} = case {Event, AS#m3ua_as.rk} of
						{asp_active, {_, _, override}} ->
							lists:mapfoldl(fun
										(#m3ua_as_asp{state = active,
												fsm = F} = A, D) ->
											{A#m3ua_as_asp{state = inactive},
													[{F, displaced} | D]};
										(A, D) ->
											{A, D}
									end, [], RemAsp);
						_ ->
							{RemAsp, []}
					end,
					NewAsps = [NewAsp | Rest],
					{Notify0, Recovery} = case lists:foldl(Fcount, {0, 0}, NewAsps) of
						%% AC2PN (RFC 4666 4.3.2): the last active process
						%% gone, the server waits T(r) for another before
						%% it is inactive or down, and the processes still
						%% inactive are told it is pending (4.3.4.4), which
						%% is their cue to take over.
						{0, _} when AsState == active, Tr > 0 ->
							NewAS = AS#m3ua_as{state = pending, asp = NewAsps},
							mnesia:write(NewAS),
							{lists:foldl(Fpending, [], NewAsps), start};
						%% Pending until T(r) or an active process says
						%% otherwise, whatever else changes meanwhile.
						{0, _} when AsState == pending ->
							NewAS = AS#m3ua_as{asp = NewAsps},
							mnesia:write(NewAS),
							{[], none};
						%% PN2AC.
						{NumActive, _} when AsState == pending, NumActive > 0 ->
							NewAS = AS#m3ua_as{state = active, asp = NewAsps},
							mnesia:write(NewAS),
							{lists:foldl(Factive, [], NewAsps), stop};
						{0, 0} when AsState == down ->
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							{[], none};
						{0, 0} ->
							NewAS = AS#m3ua_as{state = down, asp = NewAsps},
							mnesia:write(NewAS),
							{lists:foldl(Fdown, [], NewAsps), none};
						{0, NumInactive} when NumInactive > 0, AsState == inactive ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							{[], none};
						{0, NumInactive} when NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							{lists:foldl(Finactive, [], NewAsps), none};
						{NumActive, NumInactive} when AsState == inactive,
								NumActive < Min, NumInactive > 0 ->
							NewAS = AS#m3ua_as{state = inactive, asp = NewAsps},
							mnesia:write(NewAS),
							{[], none};
						{NumActive, _NumInactive}
								when AsState == inactive, NumActive >= Min ->
							NewAS = AS#m3ua_as{state = active, asp = NewAsps},
							mnesia:write(NewAS),
							{lists:foldl(Factive, [], NewAsps), none};
						{_NumActive, _NumInactive} ->
							NewAS = AS#m3ua_as{asp = NewAsps},
							mnesia:write(NewAS),
							{[], none}
					end,
					{Displaced ++ Notify0, Recovery};
				false ->
					{[], none}
			end
	end.

%% @hidden
%% 	Whether this process is still active in a server other than `RC'.
carrying_elsewhere(RC, RKs) ->
	Fsm = self(),
	lists:any(fun({RC1, _, _}) when RC1 =/= RC ->
				try mnesia:dirty_read(m3ua_as, RC1) of
					[#m3ua_as{asp = ASPs}] ->
						lists:any(fun(#m3ua_as_asp{fsm = F, state = S}) ->
									F == Fsm andalso S == active
								end, ASPs);
					_ ->
						false
				catch
					exit:_ ->
						false
				end;
			(_) ->
				false
			end, RKs).
