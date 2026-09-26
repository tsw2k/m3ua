%%% m3ua_connect_fsm.erl
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
%%% @doc This {@link //stdlib/gen_statem. gen_statem} behaviour callback
%%% 	module implements the socket handler for outgoing SCTP connections
%%%   in the {@link //m3ua. m3ua} application.
%%%
-module(m3ua_connect_fsm).
-copyright('Copyright (c) 2015-2025 SigScale Global Inc.').

-behaviour(gen_statem).

%% export the callbacks needed for gen_statem behaviour
-export([init/1, callback_mode/0, terminate/3, code_change/4]).

%% export the gen_statem state callbacks
-export([connecting/3, connected/3]).

-include("m3ua.hrl").
-include_lib("kernel/include/inet_sctp.hrl").
-include_lib("kernel/include/logger.hrl").

-record(statedata,
		{sup :: undefined | pid(),
		name :: term(),
		fsm_sup :: undefined | pid(),
		socket :: undefined | m3ua_sctp:sock(),
		receiver :: undefined | pid(),
		options :: [tuple()],
		cb_options :: term(),
		role :: sgp | asp,
		static :: boolean(),
		use_rc :: boolean(),
		local_addr :: undefined | inet:ip_address(),
		local_port :: undefined | inet:port_number(),
		remote_addr :: inet:ip_address(),
		remote_port :: inet:port_number(),
		remote_opts :: [gen_sctp:option()],
		assoc :: gen_sctp:assoc_id(),
		fsm :: undefined | pid(),
		callback :: {Module :: atom(), State :: term()}}).

-define(RETRY_WAIT, 8000).
-define(ERROR_WAIT, 60000).

%%----------------------------------------------------------------------
%%  The m3ua_connect_fsm gen_statem callbacks
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
init([Sup, Callback, Opts] = _Args) ->
	{Name, Opts1} = case lists:keytake(name, 1, Opts) of
		{value, {name, R1}, O1} ->
			{R1, O1};
		false ->
			{make_ref(), Opts}
	end,
	{Role, Opts2} = case lists:keytake(role, 1, Opts1) of
		{value, {role, sgp}, O2} ->
			{sgp, O2};
		{value, {role, asp}, O2} ->
			{asp, O2};
		false ->
			{sgp, Opts1}
	end,
	{Static, Opts3} = case lists:keytake(static, 1, Opts2) of
		{value, {static, R3}, O3} ->
			{R3, O3};
		false ->
			{false, Opts2}
	end,
	{UseRC, Opts4} = case lists:keytake(use_rc, 1, Opts3) of
		{value, {use_rc, R4}, O4} ->
			{R4, O4};
		false ->
			{true, Opts3}
	end,
	{CbOpts, Opts5} = case lists:keytake(cb_opts, 1, Opts4) of
		{value, {cb_opts, R5}, O5} ->
			{R5, O5};
		false ->
			{[], Opts4}
	end,
	PpiOptions = [{sctp_events, #sctp_event_subscribe{adaptation_layer_event = true}},
			{sctp_default_send_param, #sctp_sndrcvinfo{ppid = 3}},
			{sctp_adaptation_layer, #sctp_setadaptation{adaptation_ind = 3}}],
	Opts6 = case lists:keytake(ppi, 1, Opts5) of
		{value, {ppi, false}, O6} ->
			O6;
		{value, {ppi, true}, O6} ->
			[O6] ++ PpiOptions;
		false ->
			Opts5 ++ PpiOptions
	end,
	case lists:keytake(connect, 1, Opts6) of
		{value, {connect, Raddr, Rport, Ropts}, O7} ->
			Options = nodelay(buffered([{active, once}, {reuseaddr, true} | O7])),
			process_flag(trap_exit, true),
			StateData = #statedata{sup = Sup, role = Role,
					name = Name, static = Static, use_rc = UseRC,
					options = Options, cb_options = CbOpts, callback = Callback,
					remote_addr = Raddr, remote_port = Rport,
					remote_opts = Ropts},
			{ok, connecting, StateData, {timeout, 0, timeout}};
		false ->
			{stop, badarg}
	end.

-spec connecting(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>connecting</b> state.
%% @private
%%
connecting(timeout, EventContent,
		#statedata{fsm_sup = undefined} = StateData) ->
	connecting(timeout, EventContent, get_sup(StateData));
connecting(timeout, _EventContent, #statedata{options = LocalOptions,
		remote_addr = RemoteAddress, remote_port = RemotePort,
		remote_opts = ConnectOptions, name = Name} = StateData) ->
	case m3ua_sctp:open(LocalOptions) of
		{ok, Socket} ->
			case m3ua_sctp:sockname(Socket) of
				{ok, {LocalAddress, LocalPort}} ->
					case m3ua_sctp:connect_init(Socket,
							RemoteAddress, RemotePort, ConnectOptions) of
						ok ->
							Receiver = m3ua_receiver:start(Socket, self(), once),
							NewStateData = StateData#statedata{socket = Socket,
									receiver = Receiver,
									local_addr = LocalAddress,
									local_port = LocalPort},
							{next_state, connecting, NewStateData};
						{error, ReasonConnect} ->
							?LOG_WARNING("Connect failed",
									#{layer => m3ua, ep => self(), name => Name,
									remote => {RemoteAddress, RemotePort},
									reason => ReasonConnect}),
							?LOG_DEBUG("Connect failed",
									#{layer => m3ua, ep => self(),
									options => ConnectOptions}),
							m3ua_sctp:close(Socket),
							NewStateData = StateData#statedata{socket = undefined,
									local_addr = undefined,
									local_port = undefined},
							{next_state, connecting, NewStateData,
										{timeout, ?ERROR_WAIT, timeout}}
					end;
				{error, ReasonPort} ->
					?LOG_ERROR("Socket has no local address",
							#{layer => m3ua, ep => self(), name => Name,
							reason => ReasonPort}),
					m3ua_sctp:close(Socket),
					{stop, ReasonPort}
			end;
		{error, ReasonOpen} ->
			?LOG_ERROR("Socket not opened",
					#{layer => m3ua, ep => self(), name => Name,
					reason => ReasonOpen}),
			?LOG_DEBUG("Socket not opened",
					#{layer => m3ua, ep => self(), options => LocalOptions}),
			{stop, ReasonOpen}
	end;
connecting(cast, {'M-SCTP_RELEASE', request, Ref, From},
		#statedata{socket = Socket} = StateData) ->
	gen_server:cast(From, {'M-SCTP_RELEASE', confirm, Ref, m3ua_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, StateData};
connecting(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, connecting, StateData).

-spec connected(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events received in the <b>connected</b> state.
%% @private
%%
connected(cast, {'M-SCTP_RELEASE', request, Ref, From},
		#statedata{socket = Socket} = StateData) ->
	gen_server:cast(From,
			{'M-SCTP_RELEASE', confirm, Ref, m3ua_sctp:close(Socket)}),
	{stop, {shutdown, {self(), release}}, StateData};
connected(EventType, EventContent, StateData) ->
	handle_event(EventType, EventContent, connected, StateData).

-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		StateName :: atom(), StateData :: #statedata{}) ->
	any().
%% @doc Cleanup and exit.
%% @see //stdlib/gen_statem:terminate/3
%% @private
%%
terminate(_Reason, _StateName, #statedata{socket = undefined}) ->
	ok;
terminate(_Reason, _StateName, #statedata{socket = Socket} = StateData) ->
	case m3ua_sctp:close(Socket) of
		ok ->
			ok;
		{error, Reason1} ->
			?LOG_WARNING("Socket not closed",
					#{layer => m3ua, ep => self(),
					name => StateData#statedata.name, socket => Socket,
					reason => Reason1})
	end.

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

-spec handle_event(EventType :: gen_statem:event_type(),
		EventContent :: term(), StateName :: atom(),
		StateData :: #statedata{}) ->
	Result :: gen_statem:event_handler_result(atom()).
%% @doc Handle events common to all states.
%% @hidden
handle_event({call, From}, getassoc, connecting,
		#statedata{assoc = undefined} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, []}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, getassoc, connected,
		#statedata{assoc = undefined} = StateData) ->
	{next_state, connected, StateData, {reply, From, []}};
handle_event({call, From}, getassoc, connecting,
		#statedata{assoc = Assoc} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, [Assoc]}, {timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, getassoc, connected,
		#statedata{assoc = Assoc} = StateData) ->
	{next_state, connected, StateData, {reply, From, [Assoc]}};
handle_event({call, From}, {getstat, undefined}, connecting,
		#statedata{socket = Socket} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, m3ua_sctp:getstat(Socket)},
			{timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, {getstat, undefined}, connected,
		#statedata{socket = Socket} = StateData) ->
	{next_state, connected, StateData,
			{reply, From, m3ua_sctp:getstat(Socket)}};
handle_event({call, From}, {getstat, Options}, connecting,
		#statedata{socket = Socket} = StateData) ->
	{next_state, connecting, StateData,
			[{reply, From, m3ua_sctp:getstat(Socket, Options)},
			{timeout, ?RETRY_WAIT, timeout}]};
handle_event({call, From}, {getstat, Options}, connected,
		#statedata{socket = Socket} = StateData) ->
	{next_state, connected, StateData,
			{reply, From, m3ua_sctp:getstat(Socket, Options)}};
handle_event({call, From}, getep, StateName,
		#statedata{name = Name, role = Role,
		local_addr = Laddr, local_port = Lport,
		remote_addr = Raddr, remote_port = Rport} = StateData) ->
	Reply = {Name, client, Role, {Laddr, Lport}, {Raddr, Rport}},
	{next_state, StateName, StateData, {reply, From, Reply}};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_assoc_change{state = comm_up,
		assoc_id = Assoc} = AssocChange}}, connecting,
		#statedata{socket = Socket} = StateData) ->
	NewStateData = StateData#statedata{socket = Socket, assoc = Assoc},
	handle_connect(AssocChange, NewStateData);
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort,
		{_AncData, #sctp_assoc_change{state = _Reason}}}, connecting,
		#statedata{socket = Socket, receiver = Receiver} = StateData) ->
	m3ua_receiver:stop(Receiver),
	m3ua_sctp:close(Socket),
	NewStateData = StateData#statedata{socket = undefined,
			receiver = undefined},
	{next_state, connecting, NewStateData,
			{timeout, ?RETRY_WAIT, timeout}};
handle_event(info, {sctp, Socket, _PeerAddr, _PeerPort, {_AncData, Event}},
		StateName, #statedata{socket = Socket,
		receiver = Receiver} = StateData)
		when is_record(Event, sctp_adaptation_event);
		is_record(Event, sctp_paddr_change) ->
	%% Linux queues the adaptation layer indication ahead of the
	%% association's own comm_up, so this arrives while still
	%% connecting and says nothing about whether the association will
	%% come up. Note it by asking for the next message.
	m3ua_receiver:replenish(Receiver, once),
	{next_state, StateName, StateData};
handle_event(info, {'EXIT', Receiver, Reason}, _StateName,
		#statedata{receiver = Receiver, socket = Socket} = StateData)
		when Receiver /= undefined ->
	_ = m3ua_sctp:close(Socket),
	{stop, {shutdown, {self(), {receiver, Reason}}}, StateData};
handle_event(info, {'EXIT', Fsm, {shutdown, {{EP, Assoc}, Reason}}},
		_StateName, #statedata{socket = Socket, fsm = Fsm,
		remote_addr = Address, remote_port = Port} = StateData) ->
	%% The association ended in an orderly way -- lost, shut down,
	%% released -- and the state machine that carried it said so. Connect
	%% again from here rather than by dying: every death of this process
	%% is a restart its supervisor counts, and ten a minute take the
	%% endpoint down. A crash of the state machine still takes this
	%% process with it, below, and is counted.
	_ = m3ua_sctp:close(Socket),
	?LOG_NOTICE("Association ended, connecting again",
			#{layer => m3ua, ep => EP, assoc => Assoc,
			remote => {Address, Port}, reason => Reason}),
	NewStateData = StateData#statedata{socket = undefined,
			receiver = undefined, fsm = undefined, assoc = undefined,
			local_addr = undefined, local_port = undefined},
	{next_state, connecting, NewStateData, {timeout, 0, timeout}};
handle_event(info, {'EXIT', Fsm, Reason}, _StateName,
		#statedata{socket = undefined, fsm = Fsm} = StateData) ->
	{stop, Reason, StateData};
handle_event(info, {'EXIT', Fsm, Reason}, _StateName,
		#statedata{socket = Socket, fsm = Fsm} = StateData) ->
	m3ua_sctp:close(Socket),
	{stop, Reason, StateData};
%% What is left linked is the layer manager, which m3ua_sup restarts on
%% its own and whose successor links this endpoint again. Its death is
%% no reason for the endpoint to die. Waiting to try again, the wait is
%% asked for again: an event timeout is cancelled by any event.
handle_event(info, {'EXIT', _Pid, _Reason}, connecting,
		#statedata{socket = undefined} = StateData) ->
	{next_state, connecting, StateData,
			{timeout, ?RETRY_WAIT, timeout}};
handle_event(info, {'EXIT', _Pid, _Reason}, StateName, StateData) ->
	{next_state, StateName, StateData};
handle_event(cast, _Event, _StateName, StateData) ->
	{stop, unimplemented, StateData}.

%% @hidden
get_sup(#statedata{role = asp, sup = Sup} = StateData) ->
	Children = supervisor:which_children(Sup),
	{_, AspSup, _, _} = lists:keyfind(m3ua_asp_sup, 1, Children),
	StateData#statedata{fsm_sup = AspSup};
get_sup(#statedata{role = sgp, sup = Sup} = StateData) ->
	Children = supervisor:which_children(Sup),
	{_, SgpSup, _, _} = lists:keyfind(m3ua_sgp_sup, 1, Children),
	StateData#statedata{fsm_sup = SgpSup}.

%% @hidden
handle_connect(AssocChange, #statedata{socket = Socket,
		receiver = Receiver, fsm_sup = Sup, remote_addr = Address,
		remote_port = Port, name = Name, cb_options = CbOpts,
		callback = Cb, static = Static,
		use_rc = UseRC} = StateData) ->
	ok = m3ua_receiver:stop(Receiver),
	case supervisor:start_child(Sup, [[Socket, Address, Port,
			AssocChange, self(), Name, Cb, Static, UseRC, CbOpts], []]) of
		{ok, Fsm} ->
			case m3ua_sctp:controlling_process(Socket, Fsm) of
				ok ->
					link(Fsm),
					NewStateData = StateData#statedata{fsm = Fsm,
							receiver = undefined},
					{next_state, connected, NewStateData};
				{error, Reason} ->
					{stop, Reason, StateData}
			end;
		{error, Reason} ->
			{stop, Reason, StateData}
	end.

%% @hidden
%% The kernel's buffers unless the caller named its own; see the note
%% at ?M3UA_RECBUF in m3ua.hrl for the measurement behind the default.
buffered(Options) ->
	Rec = case lists:keymember(recbuf, 1, Options) of
		true -> [];
		false -> [{recbuf, ?M3UA_RECBUF}]
	end,
	Snd = case lists:keymember(sndbuf, 1, Options) of
		true -> [];
		false -> [{sndbuf, ?M3UA_SNDBUF}]
	end,
	Rec ++ Snd ++ Options.

%% @hidden
%% Nagle off unless the caller asked otherwise. With it on, a message
%% sent while an earlier one is still unacknowledged waits for the
%% peer's SACK, and a delayed SACK is 200 ms: on the live link of the
%% sibling M2PA transport the replies of the NG-STP node were held for
%% exactly that, p50 200.0 ms over 6,874 link tests, until m2pa turned
%% it off. Signalling wants the message out, not the packet full.
nodelay(Options) ->
	case lists:keymember(sctp_nodelay, 1, Options) of
		true ->
			Options;
		false ->
			[{sctp_nodelay, true} | Options]
	end.

