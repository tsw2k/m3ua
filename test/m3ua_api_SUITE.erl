%%% m3ua_api_SUITE.erl
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
%%%  Test suite for the m3ua API.
%%%
-module(m3ua_api_SUITE).
-copyright('Copyright (c) 2015-2025 SigScale Global Inc.').

%% common_test required callbacks
-export([suite/0, sequences/0, all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).

-compile(export_all).

-include("m3ua.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("kernel/include/inet_sctp.hrl").

%%---------------------------------------------------------------------
%%  Test server callback functions
%%---------------------------------------------------------------------

-spec suite() -> DefaultData :: [tuple()].
%% Require variables and set default values for the suite.
%%
suite() ->
	[{timetrap, {minutes, 1}}].

-spec init_per_suite(Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before the whole suite.
%%
init_per_suite(Config) ->
	PrivDir = ?config(priv_dir, Config),
	application:load(mnesia),
	ok = application:set_env(mnesia, dir, PrivDir),
	{ok, [m3ua_asp, m3ua_as]} = m3ua_app:install(),
	ok = application:start(inets),
	ok = application:start(m3ua),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(_Config) ->
	ok = application:stop(m3ua),
	ok = application:stop(inets),
	ok = application:stop(mnesia).

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before each test case.
%%
init_per_testcase(TC, Config)
		when TC == getcount; TC == asp_active; TC == asp_active_to_down;
		TC == asp_active_to_inactive; TC == mtp_transfer;
		TC == mtp_cast; TC == asp_up_indication;
		TC == asp_active_indication; TC == asp_inactive_indication;
		TC == asp_down_indication; TC == sg_state_active;
		TC == as_state_active; TC == sg_state_down; TC == as_state_down ->
	case is_alive() of
			true ->
				Config;
			false ->
				{skip, not_alive}
	end;
init_per_testcase(_TestCase, Config) ->
	Config.

-spec end_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> any().
%% Cleanup after each test case.
%%
end_per_testcase(_TestCase, _Config) ->
	_ = application:unset_env(m3ua, recovery_timer),
	ok.

-spec sequences() -> Sequences :: [{SeqName :: atom(), Testcases :: [atom()]}].
%% Group test cases into a test sequence.
%%
sequences() ->
	[].

-spec all() -> TestCases :: [Case :: atom()].
%% Returns a list of all test cases in this test suite.
%%
all() ->
	[start, stop, listen, connect, release, protocol_identifier,
			connect_options, connect_device, sctp_timers, stop_endpoint, lm_stray,
			reconnect_in_place,
			listen_not_accepted, connect_not_taken, asp_states,
			endpoint_gives_up, lm_restart, callback_raised, asp_up_ack_unexpected,
			asp_drst_dupu, asp_restricted_congestion,
			undecodable, unexpected, registration_results, ack_timeout,
			inactive_timeout, sgp_undecodable, sgp_unexpected,
			sgp_asp_up_inactive, sgp_aspia_inactive, sgp_asptm_rc, sgp_asp_up_active, sgp_deregister, sgp_dereg_req,
			sgp_transfer_rc, sgp_static_register, lifecycle_contained,
			asp_sgp_one_node, copy_messages, asp_register_down,
			sgp_register_down, asp_request_in_place, sgp_as_pending,
			sgp_as_pending_on_loss, sgp_override_takeover, asp_alternate_active,
			sgp_deregister_local, sgp_deregister_named, asp_deregister,
			getstat_ep, getstat_assoc,
			getcount, asp_up, asp_down, register, asp_active,
			asp_inactive_to_down, asp_active_to_down,
			asp_active_to_inactive, get_sctp_status, get_ep,
			mtp_transfer, mtp_cast,
			asp_up_indication, asp_active_indication,
			asp_inactive_indication, asp_down_indication,
			sg_state_active, as_state_active, sg_state_down, as_state_down,
			ssnm_pause_resume, ssnm_audit].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

start() ->
	[{userdata, [{doc, "Open an SCTP endpoint."}]}].

start(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}),
	true = is_process_alive(EP),
	ok = m3ua:stop(EP).

stop() ->
	[{userdata, [{doc, "Close an SCTP endpoint."}]}].

stop(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}),
	true = is_process_alive(EP),
	ok = m3ua:stop(EP),
	false = is_process_alive(EP).

listen() ->
	[{userdata, [{doc, "Open an SCTP server endpoint."}]}].

listen(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}, 0, [{ip, {127,0,0,1}}]),
	true = is_process_alive(EP),
	ok = m3ua:stop(EP),
	false = is_process_alive(EP).

connect() ->
	[{userdata, [{doc, "Connect client SCTP endpoint to server."}]}].

connect(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, [{role, sgp}]),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[_Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

release() ->
	[{userdata, [{doc, "Release SCTP association."}]}].

release(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:sctp_release(ClientEP, Assoc),
	%ok = m3ua:stop(ClientEP), % hangs
	ok = m3ua:stop(ServerEP).

asp_up() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) up."}]}].

asp_up(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

asp_down() ->
	[{userdata, [{doc, "Bring Application Server Process (ASP) down."}]}].

asp_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

protocol_identifier() ->
	[{userdata, [{doc, "The M3UA payload protocol identifier reaches the peer."}]}].

protocol_identifier(_Config) ->
	%% A plain SCTP socket standing in for a signalling gateway. The
	%% point is to read what goes on the wire rather than ask m3ua
	%% what it believes it sent: the identifier is how a peer tells
	%% M3UA from anything else sharing the port, and it can be sent as
	%% zero without one association failing to come up or one message
	%% failing to arrive. m2pa carried a zero for a while for exactly
	%% that reason -- nothing was watching this.
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer, true),
	{ok, {_, Port}} = inet:sockname(Peer),
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	ok = receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = comm_up}}} ->
			ok
	after
		4000 ->
			{error, no_association}
	end,
	%% The association is registered a moment after it comes up, and
	%% the peer's comm_up is not that moment.
	[Assoc] = assoc(EP, 40),
	%% ASP UP is the first thing m3ua puts on the wire, and nothing
	%% here will acknowledge it, so ask for it and do not wait.
	_ = spawn(fun() -> catch m3ua:asp_up(EP, Assoc) end),
	3 = receive
		{sctp, Peer, _, _, {[#sctp_sndrcvinfo{ppid = Ppid}], Data}}
				when is_binary(Data) ->
			Ppid
	after
		4000 ->
			{error, nothing_sent}
	end,
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

undecodable() ->
	[{userdata, [{doc, "A message that will not decode is answered with an ERR, and the association stays up."}]}].

undecodable(_Config) ->
	undecodable1(raw_sg()).

sgp_undecodable() ->
	[{userdata, [{doc, "A message that will not decode reaching a signalling gateway is answered with an ERR, and the association stays up."}]}].

sgp_undecodable(_Config) ->
	undecodable1(raw_asp()).

%% @hidden
%% 	Nothing here depends on which end m3ua is: check/1 reads the
%% 	message before either state machine sees it.
undecodable1({Peer, PeerAssoc, EP, Assoc}) ->
	Send = fun(Packet) -> raw_send(Peer, PeerAssoc, Packet) end,
	invalid_version = Send(<<2, 0, ?ASPSMMessage, ?ASPSMBEAT, 8:32>>),
	protocol_error = Send(<<1, 0, ?ASPSMMessage, ?ASPSMBEAT, 12:32>>),
	unsupported_message_class = Send(<<1, 0, 7, 1, 8:32>>),
	unsupported_message_type = Send(<<1, 0, ?ASPSMMessage, 9, 8:32>>),
	%% Heartbeat Data claiming eight octets of value with four present.
	parameter_field_error = Send(<<1, 0, ?ASPSMMessage, ?ASPSMBEAT,
			16:32, ?HeartbeatData:16, 12:16, 0:32>>),
	%% An Affected Point Code of six octets, a point code and a half.
	invalid_parameter_value = Send(<<1, 0, ?SSNMMessage, ?SSNMDUNA,
			20:32, ?AffectedPointCode:16, 10:16, 0, 0:24, 0:16, 0:16>>),
	%% A Status nobody defined.
	invalid_parameter_value = Send(<<1, 0, ?MGMTMessage, ?MGMTNotify,
			16:32, ?Status:16, 8:16, 9:16, 9:16>>),
	%% A NTFY without its Status, and DATA without its Protocol Data.
	missing_parameter = Send(<<1, 0, ?MGMTMessage, ?MGMTNotify, 8:32>>),
	missing_parameter = Send(<<1, 0, ?TransferMessage,
			?TransferMessageData, 8:32>>),
	%% An ERR with an error code nobody defined is not answered.
	nothing_sent = Send(<<1, 0, ?MGMTMessage, ?MGMTError,
			16:32, ?ErrorCode:16, 8:16, 99:32>>),
	[Assoc] = m3ua:get_assoc(EP),
	{ok, #{undecodable_in := 10, error_out := 9}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

unexpected() ->
	[{userdata, [{doc, "A message no clause takes in this state is answered with an ERR, and the association stays up."}]}].

unexpected(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	Send = fun(Packet) -> raw_send(Peer, PeerAssoc, Packet) end,
	%% The asp is down: nothing has been asked of the peer, so neither
	%% an acknowledgement nor traffic is expected yet.
	unexpected_message = Send(<<1, 0, ?ASPSMMessage, ?ASPSMBEATACK, 8:32>>),
	unexpected_message = Send(<<1, 0, ?ASPTMMessage, ?ASPTMASPIAACK, 8:32>>),
	unexpected_message = Send(<<1, 0, ?TransferMessage, ?TransferMessageData,
			28:32, ?ProtocolData:16, 20:16, 1:32, 2:32, 3, 2, 0, 0, "abcd">>),
	[Assoc] = m3ua:get_assoc(EP),
	{ok, #{unexpected_in := 3, error_out := 3}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

registration_results() ->
	[{userdata, [{doc, "A REG RSP is taken for the result naming the routing key asked for."}]}].

registration_results(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	Self = self(),
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(AspUpAck)),
	ok = receive {asp_up, UpResult} -> UpResult after 4000 -> timeout end,
	Keys = [{rand:uniform(16383), [], []}],
	_ = spawn(fun() ->
			Self ! {register, m3ua:register(EP, Assoc,
					undefined, 0, Keys, loadshare)}
	end),
	#m3ua{class = ?RKMMessage, type = ?RKMREGREQ,
			params = ReqParams} = raw_get(Peer),
	RoutingKey = m3ua_codec:fetch_parameter(?RoutingKey,
			m3ua_codec:parameters(ReqParams)),
	#m3ua_routing_key{lrk_id = LrkId} = m3ua_codec:routing_key(RoutingKey),
	Other = {?RegistrationResult, #registration_result{
			lrk_id = LrkId bxor 1, status = invalid_rk}},
	RC = rand:uniform(16#ffff),
	Ours = {?RegistrationResult, #registration_result{
			lrk_id = LrkId, status = registered, rc = RC}},
	%% An answer naming only another key -- a late one, say -- is not
	%% ours, and the request still waits.
	RegRsp1 = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP, params = [Other]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(RegRsp1)),
	%% An answer naming ours among others is taken for ours.
	RegRsp2 = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP,
			params = [Other, Ours]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(RegRsp2)),
	{ok, RC} = receive {register, RegResult} -> RegResult after 4000 -> timeout end,
	{ok, #{unexpected_in := 1}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

ack_timeout() ->
	[{userdata, [{doc, "A request times out while other messages keep arriving."}]}].

ack_timeout(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	Self = self(),
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	%% No ASP UP ACK, but a BEAT every half second for five seconds:
	%% each would have cancelled a gen_fsm timeout, and the request
	%% would have waited for ever.
	BeatMsg = #m3ua{class = ?ASPSMMessage, type = ?ASPSMBEAT, params = <<>>},
	Beat = m3ua_codec:m3ua(BeatMsg),
	F = fun F(0) ->
				no_answer;
			F(N) ->
				ok = raw_put(Peer, PeerAssoc, Beat),
				receive
					{asp_up, Result} ->
						Result
				after
					500 ->
						F(N - 1)
				end
	end,
	{error, timeout} = F(10),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

inactive_timeout() ->
	[{userdata, [{doc, "An ASP Inactive that is never acknowledged times out, and the layer manager survives it."}]}].

inactive_timeout(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	LM = whereis(m3ua),
	Self = self(),
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	AspUpAck = #m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(AspUpAck)),
	ok = receive {asp_up, UpResult} -> UpResult after 4000 -> timeout end,
	_ = spawn(fun() -> Self ! {asp_active, m3ua:asp_active(EP, Assoc)} end),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC} = raw_get(Peer),
	AspAcAck = #m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(AspAcAck)),
	ok = receive {asp_active, AcResult} -> AcResult after 4000 -> timeout end,
	%% No ASPIA ACK. The confirmation the timeout sends is the one the
	%% layer manager takes; a malformed one would kill it.
	_ = spawn(fun() -> Self ! {asp_inactive, m3ua:asp_inactive(EP, Assoc)} end),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPIA} = raw_get(Peer),
	{error, timeout} = receive
		{asp_inactive, IaResult} ->
			IaResult
	after
		4000 ->
			no_answer
	end,
	LM = whereis(m3ua),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_unexpected() ->
	[{userdata, [{doc, "A message no clause takes at a signalling gateway is answered with an ERR, and the association stays up."}]}].

sgp_unexpected(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	Send = fun(Packet) -> raw_send(Peer, PeerAssoc, Packet) end,
	%% The sgp is down, and takes neither acknowledgements nor what a
	%% signalling gateway sends rather than receives.
	unexpected_message = Send(<<1, 0, ?ASPSMMessage, ?ASPSMBEATACK, 8:32>>),
	unexpected_message = Send(<<1, 0, ?ASPTMMessage, ?ASPTMASPAC, 8:32>>),
	unexpected_message = Send(<<1, 0, ?MGMTMessage, ?MGMTNotify,
			16:32, ?Status:16, 8:16, 1:16, 3:16>>),
	unexpected_message = Send(<<1, 0, ?SSNMMessage, ?SSNMDUNA,
			16:32, ?AffectedPointCode:16, 8:16, 0, 1:24>>),
	[Assoc] = m3ua:get_assoc(EP),
	{ok, #{unexpected_in := 4, error_out := 4}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_asp_up_inactive() ->
	[{userdata, [{doc, "An ASP UP at an inactive asp is acknowledged and nothing more (RFC 4666 4.3.4.1)."}]}].

sgp_asp_up_inactive(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	AspUp = raw_msg(?ASPSMMessage, ?ASPSMASPUP),
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} = raw_get(Peer),
	inactive = m3ua:asp_status(EP, Assoc),
	%% Again, as an ASP whose T(ack) ran out would send it: the same ACK,
	%% and no ERR after it.
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} = raw_get(Peer),
	nothing_sent = raw_get(Peer),
	inactive = m3ua:asp_status(EP, Assoc),
	{ok, Counts} = m3ua:getcount(EP, Assoc),
	#{up_in := 2, up_ack_out := 2} = Counts,
	false = maps:is_key(error_out, Counts),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_aspia_inactive() ->
	[{userdata, [{doc, "An ASPIA at an inactive asp is acknowledged, not answered with an ERR, and changes nothing (RFC 4666 4.3.4.4)."}]}].

sgp_aspia_inactive(_Config) ->
	RC = configured_as(),
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	inactive = m3ua:asp_status(EP, Assoc),
	%% As an asp displaced in an override server sends it, having missed
	%% or crossed the NTFY: an acknowledgement, and no ERR after it.
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPIA)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPIAACK),
	nothing_sent = raw_get(Peer),
	inactive = m3ua:asp_status(EP, Assoc),
	{ok, Counts} = m3ua:getcount(EP, Assoc),
	#{inactive_in := 1, inactive_ack_out := 1} = Counts,
	false = maps:is_key(error_out, Counts),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	ok = m3ua:as_delete(RC).

sgp_asptm_rc() ->
	[{userdata, [{doc, "An ASPAC or ASPIA naming a routing context not defined here is answered with an ERR naming it, and changes nothing (RFC 4666 4.3.4.3, 4.3.4.4)."}]}].

sgp_asptm_rc(_Config) ->
	RC = configured_as(),
	Bogus = unused_rc(),
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	Named = fun(Type, RCs) ->
			m3ua_codec:m3ua(#m3ua{class = ?ASPTMMessage, type = Type,
					params = m3ua_codec:parameters([{?RoutingContext, RCs}])})
	end,
	Error = fun() ->
			#m3ua{class = ?MGMTMessage, type = ?MGMTError,
					params = Params} = raw_expect(Peer, ?MGMTMessage, ?MGMTError),
			Parameters = m3ua_codec:parameters(Params),
			{m3ua_codec:fetch_parameter(?ErrorCode, Parameters),
					m3ua_codec:get_parameter(?RoutingContext, Parameters, [])}
	end,
	%% ASPAC for a context nobody defined: refused, still inactive.
	ok = raw_put(Peer, PeerAssoc, Named(?ASPTMASPAC, [Bogus])),
	{no_configured_as_for_asp, [Bogus]} = Error(),
	inactive = m3ua:asp_status(EP, Assoc),
	%% One naming it among one that is defined: refused whole.
	ok = raw_put(Peer, PeerAssoc, Named(?ASPTMASPAC, [RC, Bogus])),
	{no_configured_as_for_asp, [Bogus]} = Error(),
	inactive = m3ua:asp_status(EP, Assoc),
	%% ASPIA for it: Invalid Routing Context.
	ok = raw_put(Peer, PeerAssoc, Named(?ASPTMASPIA, [Bogus])),
	{invalid_routing_context, [Bogus]} = Error(),
	%% The defined one alone is taken, and the ACK names it (4.3.4.3).
	ok = raw_put(Peer, PeerAssoc, Named(?ASPTMASPAC, [RC])),
	#m3ua{params = AckParams} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	[RC] = m3ua_codec:get_parameter(?RoutingContext,
			m3ua_codec:parameters(AckParams), undefined),
	active = m3ua:asp_status(EP, Assoc),
	{ok, #{asptm_refused := 3}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	ok = m3ua:as_delete(RC).

%% @hidden
%% 	An application server configured for a case to have one defined:
%% 	an ASPAC or ASPIA naming no routing context is refused where there
%% 	is none at all.
configured_as() ->
	RC = unused_rc(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(make_ref(), RC, undefined, Keys, loadshare, 1, 1),
	RC.

sgp_asp_up_active() ->
	[{userdata, [{doc, "An ASP UP at an active asp is acknowledged, answered with an ERR, and leaves the asp inactive (RFC 4666 4.3.4.1)."}]}].

sgp_asp_up_active(_Config) ->
	RC = configured_as(),
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	AspUp = m3ua_codec:m3ua(#m3ua{class = ?ASPSMMessage,
			type = ?ASPSMASPUP, params = <<>>}),
	AspAc = m3ua_codec:m3ua(#m3ua{class = ?ASPTMMessage,
			type = ?ASPTMASPAC, params = <<>>}),
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, AspAc),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPACACK} = raw_get(Peer),
	active = m3ua:asp_status(EP, Assoc),
	%% The ASP UP again, while active: an acknowledgement first, then
	%% the ERR, and the asp is inactive.
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} = raw_get(Peer),
	#m3ua{class = ?MGMTMessage, type = ?MGMTError,
			params = Params} = raw_get(Peer),
	unexpected_message = m3ua_codec:fetch_parameter(?ErrorCode,
			m3ua_codec:parameters(Params)),
	inactive = m3ua:asp_status(EP, Assoc),
	{ok, #{up_in := 2, up_ack_out := 2, error_out := 1}}
			= m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	ok = m3ua:as_delete(RC).

sgp_deregister() ->
	[{userdata, [{doc, "ASP DOWN, and ASP UP at an active asp, deregister the routing keys the asp registered (RFC 4666 4.3.4)."}]}].

sgp_deregister(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(dereg_callback()),
	AspUp = raw_msg(?ASPSMMessage, ?ASPSMASPUP),
	AspDown = raw_msg(?ASPSMMessage, ?ASPSMASPDN),
	AspActive = raw_msg(?ASPTMMessage, ?ASPTMASPAC),
	%% Register, then ASP DOWN: the asp leaves the application server
	%% it joined. asp_status/2 is answered only once the ASP DOWN has
	%% been dealt with in full, acknowledgement and all.
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC1 = raw_register(Peer, PeerAssoc),
	[_] = as_asps(RC1),
	ok = raw_put(Peer, PeerAssoc, AspDown),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPDNACK),
	down = m3ua:asp_status(EP, Assoc),
	removed = as_asps(RC1),
	RC1 = deregistered_rc(),
	%% Register again, go active, then ASP UP: the same.
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC2 = raw_register(Peer, PeerAssoc),
	ok = raw_put(Peer, PeerAssoc, AspActive),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	active = m3ua:asp_status(EP, Assoc),
	[_] = as_asps(RC2),
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	#m3ua{} = raw_expect(Peer, ?MGMTMessage, ?MGMTError),
	inactive = m3ua:asp_status(EP, Assoc),
	removed = as_asps(RC2),
	RC2 = deregistered_rc(),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_dereg_req() ->
	[{userdata, [{doc, "A DEREG REQ is answered for each routing context in it (RFC 4666 4.4.2)."}]}].

sgp_dereg_req(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC1 = raw_register(Peer, PeerAssoc),
	RC2 = raw_register(Peer, PeerAssoc),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	%% Not while active in it.
	[{RC1, asp_currently_active}] = raw_dereg(Peer, PeerAssoc, [RC1]),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPIA)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPIAACK),
	%% Inactive, it may; a context nobody has is invalid.
	Bogus = unused_rc(),
	[{RC1, deregistered}, {Bogus, invalid_rc}]
			= raw_dereg(Peer, PeerAssoc, [RC1, Bogus]),
	removed = as_asps(RC1),
	[_] = as_asps(RC2),
	%% The application server its REG REQ made went with it (4.4.2).
	[{RC1, invalid_rc}] = raw_dereg(Peer, PeerAssoc, [RC1]),
	{ok, #{dereg_in := 3, dereg_rsp_out := 3}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_transfer_rc() ->
	[{userdata, [{doc, "A signalling gateway names the routing context its routing key matches, after the application server has changed state as well as before, and sends DATA on a stream other than 0."}]}].

sgp_transfer_rc(_Config) ->
	Ref = make_ref(),
	{Peer, PeerAssoc, EP, _Assoc} = raw_asp(sgp_cb(Ref)),
	Sgp = wait(Ref),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	DPC = rand:uniform(16383),
	OPC = rand:uniform(16383),
	RC = raw_register(Peer, PeerAssoc, undefined, [{DPC, [], []}]),
	%% ASPAC makes the application server active, and the NTFY that
	%% says so used to take the routing key with it: a DATA sent after
	%% it named no routing context, and deregistering crashed the sgp.
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = m3ua:transfer(Sgp, 1, undefined, OPC, DPC, 0, 3, 0, <<"sgp">>),
	#m3ua{params = Params} = raw_expect(Peer,
			?TransferMessage, ?TransferMessageData),
	[RC] = m3ua_codec:fetch_parameter(?RoutingContext,
			m3ua_codec:parameters(Params)),
	%% No stream named: the SLS picks one, and never stream 0
	%% (RFC 4666 1.4.7), which an SLS of 0 used to.
	ok = m3ua:transfer(Sgp, undefined, undefined, OPC, DPC, 0, 3, 0, <<"sgp">>),
	Stream = data_stream(Peer),
	true = is_integer(Stream) andalso Stream > 0,
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_static_register() ->
	[{userdata, [{doc, "A routing key registered by layer management at a static gateway after ASPAC makes its application server active at once, and says so."}]}].

sgp_static_register(_Config) ->
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {static, true}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer, {127,0,0,1}, Port, []),
	[Assoc] = assoc(EP, 40),
	%% Configured before, so that an ASPAC naming no routing context is
	%% taken (RFC 4666 4.3.4.3).
	RC = unused_rc(),
	Name = make_ref(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(Name, RC, undefined, Keys, loadshare, 1, 1),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	active = m3ua:asp_status(EP, Assoc),
	%% Joined only now, the way a gateway learns of a peer with a static
	%% key: after it has gone active.
	{ok, RC} = m3ua:register(EP, Assoc, RC, undefined, Keys, loadshare, Name),
	[#m3ua_as{state = active, asp = [#m3ua_as_asp{state = active}]}] =
			mnesia:dirty_read(m3ua_as, RC),
	#m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params} = raw_get(Peer),
	as_active = m3ua_codec:fetch_parameter(?Status,
			m3ua_codec:parameters(Params)),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	ok = m3ua:as_delete(RC).

lifecycle_contained() ->
	[{userdata, [{doc, "A callback of the association's own life that raises, refuses or answers wrongly costs the association nothing."}]}].

lifecycle_contained(_Config) ->
	Fup = fun(_State, _Pid) -> erlang:error(lifecycle_contained) end,
	Fregister = fun(_RC, _NA, _Keys, _TMT, _State, _Pid) -> {error, refused} end,
	Factive = fun(_State, _Pid) -> not_a_tuple end,
	Fterminate = fun(_Reason, _State, _Pid) -> erlang:error(lifecycle_contained) end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{asp_up = Fup,
			register = Fregister, asp_active = Factive, terminate = Fterminate},
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(Callback),
	%% Raised in asp_up: acknowledged, and inactive all the same.
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	inactive = m3ua:asp_status(EP, Assoc),
	%% Refused by register: the registration stands.
	RC = raw_register(Peer, PeerAssoc),
	[_] = as_asps(RC),
	%% Answered wrongly by asp_active: active all the same.
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	active = m3ua:asp_status(EP, Assoc),
	{ok, #{callback_raised := 2, up_in := 1, active_in := 1}}
			= m3ua:getcount(EP, Assoc),
	%% Raised in terminate: stopped all the same.
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_sgp_one_node() ->
	[{userdata, [{doc, "An ASP and its gateway on one node go active together, and a stray cast or call costs an association nothing."}]}].

asp_sgp_one_node(_Config) ->
	%% Both share the m3ua_as table here, so the gateway counts the ASP
	%% among the members it tells of the application server's state.
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(remote_cb(RefS), 0,
			[{role, sgp}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(ServerEP),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(remote_cb(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	Sgp = wait(RefS),
	Asp = wait(RefC),
	[Assoc] = assoc(ClientEP, 40),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, RC} = m3ua:register(ClientEP, Assoc, undefined, undefined,
			Keys, loadshare),
	ok = m3ua:asp_active(ClientEP, Assoc),
	ct:sleep(200),
	true = is_process_alive(Asp),
	active = m3ua:asp_status(ClientEP, Assoc),
	%% The gateway's server has the gateway's process alone in it, not
	%% the asp beside it as well.
	[#m3ua_as{state = active, asp = [#m3ua_as_asp{fsm = Sgp}]}] =
			mnesia:dirty_read(m3ua_as, RC),
	%% Nothing either state machine was written for.
	ok = gen_statem:cast(Asp, lifecycle_contained),
	ok = gen_statem:cast(Sgp, lifecycle_contained),
	{error, unexpected_request} = gen_statem:call(Asp, lifecycle_contained),
	{error, unexpected_request} = gen_statem:call(Sgp, lifecycle_contained),
	true = is_process_alive(Asp),
	true = is_process_alive(Sgp),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

copy_messages() ->
	[{userdata, [{doc, "With {copy, MFA} every M3UA message received or sent is handed to the function whole, and one that raises costs the copy, not the association."}]}].

copy_messages(_Config) ->
	Name = make_ref(),
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{name, Name}, {role, sgp}, {ip, {127,0,0,1}},
			{copy, {?MODULE, copied, self()}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer, {127,0,0,1}, Port, []),
	[Assoc] = assoc(EP, 40),
	AspUp = raw_msg(?ASPSMMessage, ?ASPSMASPUP),
	ok = raw_put(Peer, PeerAssoc, AspUp),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	%% What arrived, as it arrived, and what went out.
	#{name := Name, assoc := Assoc, message := AspUp} = copied(received),
	#{name := Name, assoc := Assoc, message := AspUpAck} = copied(sent),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUPACK} =
			m3ua_codec:m3ua(AspUpAck),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	%% A copy function that raises: acknowledged all the same.
	{ok, EP2} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {ip, {127,0,0,1}},
			{copy, {?MODULE, copied, raise}}]),
	{_, server, sgp, {_, Port2}} = m3ua:get_ep(EP2),
	{ok, Peer2} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc2}} =
			gen_sctp:connect(Peer2, {127,0,0,1}, Port2, []),
	[Assoc2] = assoc(EP2, 40),
	ok = raw_put(Peer2, PeerAssoc2, AspUp),
	#m3ua{} = raw_expect(Peer2, ?ASPSMMessage, ?ASPSMASPUPACK),
	inactive = m3ua:asp_status(EP2, Assoc2),
	{ok, #{copy_raised := 2}} = m3ua:getcount(EP2, Assoc2),
	ok = m3ua:stop(EP2),
	ok = gen_sctp:close(Peer2).

%% @hidden
%% 	The copy function copy_messages gives, and the case's wait for it.
copied(raise, _Copy) ->
	erlang:error(copy_messages);
copied(Pid, Copy) ->
	Pid ! {copied, Copy}.
%% @hidden
copied(Direction) ->
	receive
		{copied, #{dir := Direction} = Copy} ->
			Copy
	after
		4000 ->
			timeout
	end.

asp_register_down() ->
	[{userdata, [{doc, "A registration asked of an ASP that is down is refused at once, and sends nothing."}]}].

asp_register_down(_Config) ->
	{Peer, _PeerAssoc, EP, Assoc} = raw_sg(),
	down = m3ua:asp_status(EP, Assoc),
	Keys = [{rand:uniform(16383), [], []}],
	{Micro, {error, asp_down}} = timer:tc(m3ua, register,
			[EP, Assoc, undefined, undefined, Keys, loadshare]),
	true = Micro < 1000000,
	nothing_sent = raw_get(Peer),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_register_down() ->
	[{userdata, [{doc, "At a gateway, a static registration made before the peer's ASPUP is taken and carried into service by it; any other is refused at once."}]}].

sgp_register_down(_Config) ->
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {static, true}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer, {127,0,0,1}, Port, []),
	[Assoc] = assoc(EP, 40),
	down = m3ua:asp_status(EP, Assoc),
	RC = unused_rc(),
	Name = make_ref(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(Name, RC, undefined, Keys, override, 1, 2),
	%% Registered the moment the association is up, before the ASPUP:
	%% discarded here once, and the call timed out.
	{Micro, {ok, RC}} = timer:tc(m3ua, register,
			[EP, Assoc, RC, undefined, Keys, override, Name]),
	true = Micro < 1000000,
	[#m3ua_as{asp = [#m3ua_as_asp{state = down}]}] =
			mnesia:dirty_read(m3ua_as, RC),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = as_state(RC, active, 20),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	ok = m3ua:as_delete(RC),
	%% Not static: a registration is a REG REQ, for an asp that is up.
	{ok, EP2} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port2}} = m3ua:get_ep(EP2),
	{ok, Peer2} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up}} =
			gen_sctp:connect(Peer2, {127,0,0,1}, Port2, []),
	[Assoc2] = assoc(EP2, 40),
	{Micro2, {error, asp_down}} = timer:tc(m3ua, register,
			[EP2, Assoc2, unused_rc(), undefined, Keys, override, Name]),
	true = Micro2 < 1000000,
	ok = m3ua:stop(EP2),
	ok = gen_sctp:close(Peer2).

asp_request_in_place() ->
	[{userdata, [{doc, "Asked for the state it is already in, an ASP answers at once and sends nothing."}]}].

asp_request_in_place(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	{Micro0, ok} = timer:tc(m3ua, asp_down, [EP, Assoc]),
	true = Micro0 < 1000000,
	nothing_sent = raw_get(Peer),
	{error, asp_down} = m3ua:asp_active(EP, Assoc),
	Self = self(),
	spawn_link(fun() -> Self ! {up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUP),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUPACK)),
	receive {up, ok} -> ok after 2000 -> ct:fail(asp_up) end,
	{_, ok} = timer:tc(m3ua, asp_up, [EP, Assoc]),
	{_, ok} = timer:tc(m3ua, asp_inactive, [EP, Assoc]),
	nothing_sent = raw_get(Peer),
	spawn_link(fun() -> Self ! {active, m3ua:asp_active(EP, Assoc)} end),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPAC),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPACACK)),
	receive {active, ok} -> ok after 2000 -> ct:fail(asp_active) end,
	active = m3ua:asp_status(EP, Assoc),
	%% The live node's case: asp_active again never answered.
	{Micro, ok} = timer:tc(m3ua, asp_active, [EP, Assoc]),
	true = Micro < 1000000,
	{_, ok} = timer:tc(m3ua, asp_up, [EP, Assoc]),
	nothing_sent = raw_get(Peer),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_as_pending() ->
	[{userdata, [{doc, "An override AS whose last active ASP goes inactive is pending for T(r), and the inactive one is told: taken over within it, the AS is active again; not, it is inactive."}]}].

sgp_as_pending(_Config) ->
	ok = application:set_env(m3ua, recovery_timer, 600),
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {static, true}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	RC = unused_rc(),
	Name = make_ref(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(Name, RC, undefined, Keys, override, 1, 2),
	Connect = fun() ->
				{ok, P} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
				{ok, #sctp_assoc_change{state = comm_up, assoc_id = PA}} =
						gen_sctp:connect(P, {127,0,0,1}, Port, []),
				ok = raw_put(P, PA, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
				#m3ua{} = raw_expect(P, ?ASPSMMessage, ?ASPSMASPUPACK),
				{P, PA}
			end,
	{Peer1, PeerAssoc1} = Connect(),
	{Peer2, PeerAssoc2} = Connect(),
	Assocs = assoc(EP, 40),
	2 = length(Assocs),
	ok = lists:foreach(fun(A) ->
				{ok, RC} = m3ua:register(EP, A, RC, undefined, Keys,
						override, Name)
			end, Assocs),
	ok = raw_put(Peer1, PeerAssoc1, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer1, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = as_state(RC, active, 20),
	flush_sctp(Peer2),
	%% The active one goes: pending, and the standby is told so.
	ok = raw_put(Peer1, PeerAssoc1, raw_msg(?ASPTMMessage, ?ASPTMASPIA)),
	#m3ua{} = raw_expect(Peer1, ?ASPTMMessage, ?ASPTMASPIAACK),
	ok = as_state(RC, pending, 20),
	as_pending = raw_notify(Peer2, as_pending),
	%% Taken over within T(r): active again, and it stays so past T(r).
	ok = raw_put(Peer2, PeerAssoc2, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer2, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = as_state(RC, active, 20),
	timer:sleep(800),
	[#m3ua_as{state = active}] = mnesia:dirty_read(m3ua_as, RC),
	%% Not taken over: pending, then inactive once T(r) runs out.
	flush_sctp(Peer1),
	ok = raw_put(Peer2, PeerAssoc2, raw_msg(?ASPTMMessage, ?ASPTMASPIA)),
	#m3ua{} = raw_expect(Peer2, ?ASPTMMessage, ?ASPTMASPIAACK),
	ok = as_state(RC, pending, 20),
	ok = as_state(RC, inactive, 40),
	as_inactive = raw_notify(Peer1, as_inactive),
	ok = application:unset_env(m3ua, recovery_timer),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer1),
	ok = gen_sctp:close(Peer2),
	ok = m3ua:as_delete(RC).

sgp_as_pending_on_loss() ->
	[{userdata, [{doc, "The active ASP's association lost is the same as its ASPDN: the AS is pending for T(r) and the standby is told, naming the AS by its routing context."}]}].

sgp_as_pending_on_loss(_Config) ->
	ok = application:set_env(m3ua, recovery_timer, 600),
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {static, true}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	RC = unused_rc(),
	Name = make_ref(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(Name, RC, undefined, Keys, override, 1, 2),
	Connect = fun() ->
				{ok, P} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
				{ok, #sctp_assoc_change{state = comm_up, assoc_id = PA}} =
						gen_sctp:connect(P, {127,0,0,1}, Port, []),
				ok = raw_put(P, PA, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
				#m3ua{} = raw_expect(P, ?ASPSMMessage, ?ASPSMASPUPACK),
				{P, PA}
			end,
	{Peer1, PeerAssoc1} = Connect(),
	{Peer2, _PeerAssoc2} = Connect(),
	ok = lists:foreach(fun(A) ->
				{ok, RC} = m3ua:register(EP, A, RC, undefined, Keys,
						override, Name)
			end, assoc(EP, 40)),
	ok = raw_put(Peer1, PeerAssoc1, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer1, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = as_state(RC, active, 20),
	flush_sctp(Peer2),
	ok = gen_sctp:close(Peer1),
	ok = as_state(RC, pending, 20),
	#m3ua{params = Params} = raw_notify_msg(Peer2, as_pending),
	Parameters = m3ua_codec:parameters(Params),
	[RC] = m3ua_codec:fetch_parameter(?RoutingContext, Parameters),
	ok = as_state(RC, inactive, 40),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer2),
	ok = m3ua:as_delete(RC).

sgp_override_takeover() ->
	[{userdata, [{doc, "In an override AS a second ASP going active takes the first one's place: the first is inactive and told Alternate ASP Active, and the second leaving afterwards makes the AS pending."}]}].

sgp_override_takeover(_Config) ->
	ok = application:set_env(m3ua, recovery_timer, 600),
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
			[{role, sgp}, {static, true}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	RC = unused_rc(),
	Name = make_ref(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(Name, RC, undefined, Keys, override, 1, 2),
	Connect = fun() ->
				{ok, P} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
				{ok, #sctp_assoc_change{state = comm_up, assoc_id = PA}} =
						gen_sctp:connect(P, {127,0,0,1}, Port, []),
				ok = raw_put(P, PA, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
				#m3ua{} = raw_expect(P, ?ASPSMMessage, ?ASPSMASPUPACK),
				{P, PA}
			end,
	{Peer1, PeerAssoc1} = Connect(),
	[Assoc1] = assoc(EP, 40),
	{Peer2, PeerAssoc2} = Connect(),
	[Assoc2] = assoc(EP, 40) -- [Assoc1],
	ok = lists:foreach(fun(A) ->
				{ok, RC} = m3ua:register(EP, A, RC, undefined, Keys,
						override, Name)
			end, [Assoc1, Assoc2]),
	ok = raw_put(Peer1, PeerAssoc1, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer1, ?ASPTMMessage, ?ASPTMASPACACK),
	ok = as_state(RC, active, 20),
	flush_sctp(Peer1),
	%% The second takes over: the first is told, and is inactive.
	ok = raw_put(Peer2, PeerAssoc2, raw_msg(?ASPTMMessage, ?ASPTMASPAC)),
	#m3ua{} = raw_expect(Peer2, ?ASPTMMessage, ?ASPTMASPACACK),
	#m3ua{params = Params} = raw_notify_msg(Peer1, alternate_asp_active),
	[RC] = m3ua_codec:fetch_parameter(?RoutingContext,
			m3ua_codec:parameters(Params)),
	ok = wait_status(EP, Assoc1, inactive, 20),
	active = m3ua:asp_status(EP, Assoc2),
	[#m3ua_as{state = active, asp = Members}] = mnesia:dirty_read(m3ua_as, RC),
	[active, inactive] = lists:sort([S || #m3ua_as_asp{state = S} <- Members]),
	%% The second leaving is the last active one leaving: pending.
	ok = raw_put(Peer2, PeerAssoc2, raw_msg(?ASPTMMessage, ?ASPTMASPIA)),
	#m3ua{} = raw_expect(Peer2, ?ASPTMMessage, ?ASPTMASPIAACK),
	ok = as_state(RC, pending, 20),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer1),
	ok = gen_sctp:close(Peer2),
	ok = m3ua:as_delete(RC).

asp_alternate_active() ->
	[{userdata, [{doc, "An active ASP told Alternate ASP Active by its gateway is inactive, as if its own ASPIA had been acknowledged, and asp_inactive then answers at once."}]}].

asp_alternate_active(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	Self = self(),
	spawn_link(fun() -> Self ! {up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUP),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUPACK)),
	receive {up, ok} -> ok after 2000 -> ct:fail(asp_up) end,
	spawn_link(fun() -> Self ! {active, m3ua:asp_active(EP, Assoc)} end),
	#m3ua{} = raw_expect(Peer, ?ASPTMMessage, ?ASPTMASPAC),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPACACK)),
	receive {active, ok} -> ok after 2000 -> ct:fail(asp_active) end,
	P0 = m3ua_codec:add_parameter(?Status, alternate_asp_active, []),
	P1 = m3ua_codec:add_parameter(?RoutingContext, [unused_rc()], P0),
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(#m3ua{class = ?MGMTMessage,
			type = ?MGMTNotify, params = P1})),
	ok = wait_status(EP, Assoc, inactive, 20),
	nothing_sent = raw_get(Peer),
	{Micro, ok} = timer:tc(m3ua, asp_inactive, [EP, Assoc]),
	true = Micro < 1000000,
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

%% @hidden
wait_status(_EP, _Assoc, _State, 0) ->
	{error, timeout};
wait_status(EP, Assoc, State, N) ->
	case m3ua:asp_status(EP, Assoc) of
		State ->
			ok;
		_ ->
			timer:sleep(50),
			wait_status(EP, Assoc, State, N - 1)
	end.

%% @hidden
%% 	The NTFY carrying `Status', whole.
raw_notify_msg(Peer, Status) ->
	case raw_get(Peer) of
		#m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params} = M ->
			case m3ua_codec:fetch_parameter(?Status,
					m3ua_codec:parameters(Params)) of
				Status ->
					M;
				_Other ->
					raw_notify_msg(Peer, Status)
			end;
		nothing_sent ->
			nothing_sent;
		_Other ->
			raw_notify_msg(Peer, Status)
	end.

%% @hidden
%% 	Wait for an application server to reach a state, 50 ms at a time.
as_state(_RC, _State, 0) ->
	{error, timeout};
as_state(RC, State, N) ->
	case mnesia:dirty_read(m3ua_as, RC) of
		[#m3ua_as{state = State}] ->
			ok;
		_ ->
			timer:sleep(50),
			as_state(RC, State, N - 1)
	end.

%% @hidden
%% 	`Status' once a raw peer receives a NTFY carrying it, passing over
%% 	anything else; `nothing_sent' if none comes.
raw_notify(Peer, Status) ->
	case raw_get(Peer) of
		#m3ua{class = ?MGMTMessage, type = ?MGMTNotify, params = Params} ->
			case m3ua_codec:fetch_parameter(?Status,
					m3ua_codec:parameters(Params)) of
				Status ->
					Status;
				_Other ->
					raw_notify(Peer, Status)
			end;
		nothing_sent ->
			nothing_sent;
		_Other ->
			raw_notify(Peer, Status)
	end.

%% @hidden
flush_sctp(Peer) ->
	receive
		{sctp, Peer, _, _, _} ->
			flush_sctp(Peer)
	after
		100 ->
			ok
	end.

%% @hidden
%% 	The stream the next DATA arrives on, passing over the NTFY an sgp
%% 	sends as an application server changes state. That NTFY goes on
%% 	stream 0 and may come after the DATA was asked for: taking it for
%% 	the DATA failed this case more often than not.
data_stream(Peer) ->
	receive
		{sctp, Peer, _, _, {[#sctp_sndrcvinfo{stream = S}], Data}}
				when is_binary(Data) ->
			case m3ua_codec:m3ua(Data) of
				#m3ua{class = ?TransferMessage, type = ?TransferMessageData} ->
					S;
				#m3ua{class = ?MGMTMessage, type = ?MGMTNotify} ->
					data_stream(Peer);
				Other ->
					{unexpected, Other}
			end
	after
		1000 ->
			nothing_sent
	end.

sgp_deregister_local() ->
	[{userdata, [{doc, "M-RK_DEREG at a signalling gateway takes its asp out of the application server, with nothing sent."}]}].

sgp_deregister_local(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(dereg_callback()),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC = raw_register(Peer, PeerAssoc),
	[_] = as_asps(RC),
	ok = m3ua:deregister(EP, Assoc, RC),
	removed = as_asps(RC),
	RC = deregistered_rc(),
	{error, not_registered} = m3ua:deregister(EP, Assoc, RC),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_deregister_named() ->
	[{userdata, [{doc, "An application server layer management configured stays when its last registered asp leaves (RFC 4666 4.4.2)."}]}].

sgp_deregister_named(_Config) ->
	{Peer, PeerAssoc, EP, _Assoc} = raw_asp(),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC = unused_rc(),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _} = m3ua:as_add(make_ref(), RC, 0, Keys, loadshare, 1, 1),
	RC = raw_register(Peer, PeerAssoc, RC, Keys),
	[_] = as_asps(RC),
	[{RC, deregistered}] = raw_dereg(Peer, PeerAssoc, [RC]),
	%% Still there, empty, and this asp no member of it.
	[] = as_asps(RC),
	[{RC, not_registered}] = raw_dereg(Peer, PeerAssoc, [RC]),
	ok = m3ua:as_delete(RC),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_deregister() ->
	[{userdata, [{doc, "M-RK_DEREG at an asp sends a DEREG REQ and answers with the DEREG RSP's result for its routing context."}]}].

asp_deregister(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(dereg_callback()),
	Self = self(),
	%% Up and registered, the gateway's side played by hand.
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUPACK)),
	ok = receive {asp_up, UpResult} -> UpResult after 4000 -> timeout end,
	Keys = [{rand:uniform(16383), [], []}],
	_ = spawn(fun() ->
			Self ! {register, m3ua:register(EP, Assoc,
					undefined, 0, Keys, loadshare)}
	end),
	#m3ua{class = ?RKMMessage, type = ?RKMREGREQ,
			params = ReqParams} = raw_get(Peer),
	RoutingKey = m3ua_codec:fetch_parameter(?RoutingKey,
			m3ua_codec:parameters(ReqParams)),
	#m3ua_routing_key{lrk_id = LrkId} = m3ua_codec:routing_key(RoutingKey),
	RC = unused_rc(),
	RegRsp = #m3ua{class = ?RKMMessage, type = ?RKMREGRSP,
			params = [{?RegistrationResult, #registration_result{
			lrk_id = LrkId, status = registered, rc = RC}}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(RegRsp)),
	{ok, RC} = receive {register, RegResult} -> RegResult after 4000 -> timeout end,
	[_] = asp_registered(RC),
	Dereg = fun() ->
			_ = spawn(fun() ->
					Self ! {deregister, m3ua:deregister(EP, Assoc, RC)}
			end),
			#m3ua{class = ?RKMMessage, type = ?RKMDEREGREQ,
					params = DeregParams} = raw_get(Peer),
			[RC] = m3ua_codec:fetch_parameter(?RoutingContext,
					m3ua_codec:parameters(DeregParams)),
			ok
	end,
	%% Refused by the peer: the status is the reason, and the asp is
	%% still in the application server.
	ok = Dereg(),
	ok = raw_put(Peer, PeerAssoc, raw_dereg_rsp(RC, asp_currently_active)),
	{error, asp_currently_active} = receive
		{deregister, Result1} ->
			Result1
	after
		4000 ->
			timeout
	end,
	[_] = asp_registered(RC),
	%% Deregistered: it is not.
	ok = Dereg(),
	ok = raw_put(Peer, PeerAssoc, raw_dereg_rsp(RC, deregistered)),
	ok = receive {deregister, Result2} -> Result2 after 4000 -> timeout end,
	[] = asp_registered(RC),
	RC = deregistered_rc(),
	{ok, #{dereg_out := 2, dereg_rsp_in := 2}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

%% @hidden
%% 	The suite's callback, telling this process of each deregistration.
dereg_callback() ->
	Self = self(),
	Fdereg = fun(RC, _NA, _Keys, _TMT, State, _Pid) ->
				Self ! {deregistered, RC},
				{ok, State}
	end,
	(callback(make_ref()))#m3ua_fsm_cb{deregister = Fdereg}.

%% @hidden
deregistered_rc() ->
	receive
		{deregistered, RC} ->
			RC
	after
		4000 ->
			timeout
	end.

%% @hidden
raw_dereg_rsp(RC, Status) ->
	DeregRsp = #m3ua{class = ?RKMMessage, type = ?RKMDEREGRSP,
			params = [{?DeregistrationResult,
			#deregistration_result{rc = RC, status = Status}}]},
	m3ua_codec:m3ua(DeregRsp).

%% @hidden
%% 	Send a DEREG REQ and answer the results of the DEREG RSP.
raw_dereg(Peer, PeerAssoc, RCs) ->
	Params = m3ua_codec:parameters([{?RoutingContext, RCs}]),
	DeregReq = #m3ua{class = ?RKMMessage, type = ?RKMDEREGREQ,
			params = Params},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(DeregReq)),
	#m3ua{params = RspParams} = raw_expect(Peer, ?RKMMessage, ?RKMDEREGRSP),
	[{RC, Status} || #deregistration_result{rc = RC, status = Status}
			<- m3ua_codec:get_all_parameter(?DeregistrationResult,
			m3ua_codec:parameters(RspParams))].

%% @hidden
unused_rc() ->
	RC = rand:uniform(16#ffffffff),
	case mnesia:dirty_read(m3ua_as, RC) of
		[] ->
			RC;
		_ ->
			unused_rc()
	end.

%% @hidden
%% 	Register one routing key with a REG REQ and answer the routing
%% 	context the REG RSP gives it.
raw_register(Peer, PeerAssoc) ->
	raw_register(Peer, PeerAssoc, undefined, [{rand:uniform(16383), [], []}]).
%% @hidden
raw_register(Peer, PeerAssoc, RC0, Keys) ->
	RK = m3ua_codec:routing_key(#m3ua_routing_key{rc = RC0, na = 0,
			tmt = loadshare, key = Keys, lrk_id = 1}),
	Params = m3ua_codec:parameters([{?RoutingKey, RK}]),
	RegReq = #m3ua{class = ?RKMMessage, type = ?RKMREGREQ, params = Params},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(RegReq)),
	#m3ua{params = RspParams} = raw_expect(Peer, ?RKMMessage, ?RKMREGRSP),
	[#registration_result{status = registered, rc = RC}] =
			m3ua_codec:get_all_parameter(?RegistrationResult,
			m3ua_codec:parameters(RspParams)),
	RC.

%% @hidden
%% 	The asps of this node registered for `RC'. An asp is not a member
%% 	of the server in m3ua_as, which is a gateway's list.
asp_registered(RC) ->
	mnesia:dirty_match_object(m3ua_asp, #m3ua_asp{fsm = '_', rc = RC, rk = '_'}).

%% @hidden
as_asps(RC) ->
	case mnesia:dirty_read(m3ua_as, RC) of
		[#m3ua_as{asp = ASPs}] ->
			ASPs;
		[] ->
			removed
	end.

%% @hidden
%% 	The same plain SCTP socket as protocol_identifier/1, standing in
%% 	for a signalling gateway so as to put on the wire what m3ua
%% 	would never send itself.
raw_sg() ->
	raw_sg(callback(make_ref())).
%% @hidden
raw_sg(Callback) ->
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer, true),
	{ok, {_, Port}} = inet:sockname(Peer),
	{ok, EP} = m3ua:start(Callback, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	PeerAssoc = receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = comm_up,
				assoc_id = Id}}} ->
			Id
	after
		4000 ->
			{error, no_association}
	end,
	[Assoc] = assoc(EP, 40),
	{Peer, PeerAssoc, EP, Assoc}.

%% @hidden
%% 	A plain SCTP socket standing in for an application server
%% 	process, connected to an m3ua signalling gateway listening on a
%% 	port of its own choosing.
raw_asp() ->
	raw_asp(callback(make_ref())).
%% @hidden
raw_asp(Callback) ->
	{ok, EP} = m3ua:start(Callback, 0,
			[{role, sgp}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer, {127,0,0,1}, Port, []),
	[Assoc] = assoc(EP, 40),
	{Peer, PeerAssoc, EP, Assoc}.

%% @hidden
%% 	Send a message and answer the error code of the ERR it draws.
raw_send(Peer, PeerAssoc, Packet) ->
	ok = raw_put(Peer, PeerAssoc, Packet),
	case raw_get(Peer) of
		#m3ua{class = ?MGMTMessage, type = ?MGMTError, params = Params} ->
			Parameters = m3ua_codec:parameters(Params),
			m3ua_codec:fetch_parameter(?ErrorCode, Parameters);
		nothing_sent ->
			nothing_sent
	end.

%% @hidden
raw_put(Peer, PeerAssoc, Packet) ->
	SndRcvInfo = #sctp_sndrcvinfo{assoc_id = PeerAssoc, ppid = 3},
	gen_sctp:send(Peer, SndRcvInfo, Packet).

%% @hidden
%% 	The next message of a class and type, passing over any NTFY an
%% 	sgp sends as the state of an application server changes.
raw_expect(Peer, Class, Type) ->
	case raw_get(Peer) of
		#m3ua{class = Class, type = Type} = M3UA ->
			M3UA;
		#m3ua{class = ?MGMTMessage, type = ?MGMTNotify} ->
			raw_expect(Peer, Class, Type);
		Other ->
			{unexpected, Other}
	end.

%% @hidden
raw_msg(Class, Type) ->
	m3ua_codec:m3ua(#m3ua{class = Class, type = Type, params = <<>>}).

%% @hidden
raw_get(Peer) ->
	receive
		{sctp, Peer, _, _, {[#sctp_sndrcvinfo{}], Data}}
				when is_binary(Data) ->
			m3ua_codec:m3ua(Data)
	after
		1000 ->
			nothing_sent
	end.

sctp_timers() ->
	[{userdata, [{doc, "Sockets take the ITP's SCTP timers unless the options name others, and a peer address option that asks for more than is offered is refused."}]}].

sctp_timers(_Config) ->
	%% The defaults, read back from the socket.
	{ok, Sock1} = m3ua_sctp:open(m3ua_sctp:timers([{ip, {127,0,0,1}}])),
	{ok, <<_:32, 1000:32/native, 1000:32/native, 1000:32/native>>} =
			socket:getopt_native(Sock1, {132, 0}, <<0:128>>),
	{ok, <<_:32, _:1024, 30000:32/native, 4:16/native, _/binary>>} =
			socket:getopt_native(Sock1, {132, 9}, <<0:(152 * 8)>>),
	{ok, #{max_init_timeo := 1000}} = socket:getopt(Sock1, {sctp, initmsg}),
	ok = m3ua_sctp:close(Sock1),
	%% One named by the caller stands; the others are still defaulted.
	RtoInfo = #sctp_rtoinfo{initial = 3000, max = 3000, min = 2000},
	{ok, Sock2} = m3ua_sctp:open(m3ua_sctp:timers([{ip, {127,0,0,1}},
			{sctp_rtoinfo, RtoInfo}])),
	{ok, <<_:32, 3000:32/native, 3000:32/native, 2000:32/native>>} =
			socket:getopt_native(Sock2, {132, 0}, <<0:128>>),
	{ok, #{max_init_timeo := 1000}} = socket:getopt(Sock2, {sctp, initmsg}),
	ok = m3ua_sctp:close(Sock2),
	%% Only HB.interval and Path.Max.Retrans are offered.
	Params = #sctp_paddrparams{sackdelay = 100},
	{error, {{sctp_peer_addr_params, Params}, enoprotoopt}} =
			m3ua_sctp:open([{ip, {127,0,0,1}}, {sctp_peer_addr_params, Params}]).

connect_options() ->
	[{userdata, [{doc, "The options given with connect reach the socket."}]}].

connect_options(_Config) ->
	%% One the socket can take: the association comes up.
	{ok, Peer1} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer1, true),
	{ok, {_, Port1}} = inet:sockname(Peer1),
	{ok, EP1} = m3ua:start(callback(make_ref()), 0, [{role, asp},
			{connect, {127,0,0,1}, Port1, [{sctp_nodelay, true}]}]),
	ok = comm_up(Peer1),
	ok = m3ua:stop(EP1),
	ok = gen_sctp:close(Peer1),
	%% One it cannot: no association is asked for. These options used
	%% to be dropped unread, and the association came up regardless.
	{ok, Peer2} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer2, true),
	{ok, {_, Port2}} = inet:sockname(Peer2),
	{ok, EP2} = m3ua:start(callback(make_ref()), 0, [{role, asp},
			{connect, {127,0,0,1}, Port2, [{no_such_option, true}]}]),
	no_association = comm_up(Peer2),
	%% Stopped while it has no socket at all.
	ok = m3ua:stop(EP2),
	ok = gen_sctp:close(Peer2).

stop_endpoint() ->
	[{userdata, [{doc, "A stopped endpoint is gone, not restarted, and can be found by name until then."}]}].

stop_endpoint(_Config) ->
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer, true),
	{ok, {_, Port}} = inet:sockname(Peer),
	%% A connecting endpoint: once stopped it does not come back and
	%% connect again.
	Name1 = make_ref(),
	{ok, EP1} = m3ua:start(callback(make_ref()), 0, [{name, Name1},
			{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	ok = comm_up(Peer),
	[EP1] = named(Name1),
	ok = m3ua:stop(EP1),
	[] = named(Name1),
	no_association = comm_up(Peer),
	{error, not_found} = m3ua:stop(EP1),
	%% A listening one: the same.
	Name2 = make_ref(),
	{ok, EP2} = m3ua:start(callback(make_ref()), 0,
			[{name, Name2}, {ip, {127,0,0,1}}]),
	[EP2] = named(Name2),
	ok = m3ua:stop(EP2),
	[] = named(Name2),
	ok = gen_sctp:close(Peer).

lm_stray() ->
	[{userdata, [{doc, "The layer manager survives a call, cast or message it has no clause for."}]}].

lm_stray(_Config) ->
	LM = whereis(m3ua),
	{error, unexpected_request} = gen_server:call(m3ua, no_such_request),
	ok = gen_server:cast(m3ua, no_such_request),
	m3ua ! no_such_message,
	%% A call is answered only after what was sent before it.
	{error, unexpected_request} = gen_server:call(m3ua, no_such_request),
	LM = whereis(m3ua).

reconnect_in_place() ->
	[{userdata, [{doc, "A connect endpoint whose association ends connects again as the same process."}]}].

reconnect_in_place(_Config) ->
	{Peer, PeerAssoc, EP, _Assoc} = raw_sg(),
	ok = gen_sctp:abort(Peer, #sctp_assoc_change{assoc_id = PeerAssoc}),
	ok = comm_up(Peer),
	%% The same endpoint, not one its supervisor started in its place,
	%% and an association of its own again.
	true = is_process_alive(EP),
	[_] = assoc(EP, 40),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

endpoint_gives_up() ->
	[{userdata, [{doc, "An endpoint whose supervisor gives up takes only itself down."}]}].

endpoint_gives_up(_Config) ->
	LM = whereis(m3ua),
	{ok, Other} = m3ua:start(callback(make_ref()), 0, [{ip, {127,0,0,1}}]),
	Name = make_ref(),
	{ok, _} = m3ua:start(callback(make_ref()), 0,
			[{name, Name}, {ip, {127,0,0,1}}]),
	%% Its supervisor allows ten restarts a minute; the eleventh is one
	%% too many.
	Kill = fun Kill(0) ->
				ok;
			Kill(N) ->
				case named(Name) of
					[EP] ->
						exit(EP, kill),
						timer:sleep(50),
						Kill(N - 1);
					[] ->
						ok
				end
	end,
	ok = Kill(12),
	timer:sleep(100),
	[] = named(Name),
	%% Everything else is where it was.
	true = lists:member(Other, m3ua:get_ep()),
	LM = whereis(m3ua),
	ok = m3ua:stop(Other).

lm_restart() ->
	[{userdata, [{doc, "The layer manager restarts alone: endpoints and associations stay up, and the new one knows them."}]}].

lm_restart(_Config) ->
	{Peer, _PeerAssoc, EP, Assoc} = raw_sg(),
	LM = whereis(m3ua),
	exit(LM, kill),
	LM2 = new_lm(LM, 40),
	true = is_pid(LM2),
	%% The new manager has the association again, from its own record:
	%% getcount/2 goes through it.
	{ok, _} = counted(EP, Assoc, 40),
	true = is_process_alive(EP),
	%% And the association was never touched.
	ok = receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = State}}}
				when State /= comm_up ->
			{association, State}
	after
		0 ->
			ok
	end,
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

%% @hidden
new_lm(_LM, 0) ->
	undefined;
new_lm(LM, N) ->
	case whereis(m3ua) of
		LM2 when is_pid(LM2), LM2 /= LM ->
			LM2;
		_ ->
			timer:sleep(50),
			new_lm(LM, N - 1)
	end.

%% @hidden
counted(EP, Assoc, 0) ->
	m3ua:getcount(EP, Assoc);
counted(EP, Assoc, N) ->
	case catch m3ua:getcount(EP, Assoc) of
		{ok, Counts} ->
			{ok, Counts};
		_ ->
			timer:sleep(50),
			counted(EP, Assoc, N - 1)
	end.

callback_raised() ->
	[{userdata, [{doc, "An exception in a callback on the traffic path loses that message, not the association."}]}].

callback_raised(_Config) ->
	Self = self(),
	Frecv = fun(_Stream, _RC, _OPC, _DPC, _NI, _SI, _SLS, Data, State, _Pid) ->
				case Data of
					<<"boom">> ->
						error(boom);
					_ ->
						Self ! {recv, Data},
						{ok, once, State}
				end
	end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{recv = Frecv},
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(Callback),
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUPACK)),
	ok = receive {asp_up, UpResult} -> UpResult after 4000 -> timeout end,
	_ = spawn(fun() -> Self ! {asp_active, m3ua:asp_active(EP, Assoc)} end),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPACACK)),
	ok = receive {asp_active, AcResult} -> AcResult after 4000 -> timeout end,
	Transfer = fun(Data) ->
			ProtocolData = #protocol_data{opc = 1, dpc = 2, si = 3,
					ni = 2, sls = 0, data = Data},
			m3ua_codec:m3ua(#m3ua{class = ?TransferMessage,
					type = ?TransferMessageData,
					params = [{?ProtocolData, ProtocolData}]})
	end,
	ok = raw_put(Peer, PeerAssoc, Transfer(<<"boom">>)),
	ok = raw_put(Peer, PeerAssoc, Transfer(<<"fine">>)),
	%% The second arrives: the first cost itself and nothing else.
	<<"fine">> = receive {recv, Data} -> Data after 4000 -> timeout end,
	[Assoc] = m3ua:get_assoc(EP),
	{ok, #{callback_raised := 1, transfer_in := 2}}
			= m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_up_ack_unexpected() ->
	[{userdata, [{doc, "An ASP UP ACK that answers no ASP UP leaves the asp inactive, and from down or active it asks to go back (RFC 4666 4.3.4.1)."}]}].

asp_up_ack_unexpected(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
	Self = self(),
	AspUpAck = raw_msg(?ASPSMMessage, ?ASPSMASPUPACK),
	Error = fun() ->
			#m3ua{class = ?MGMTMessage, type = ?MGMTError,
					params = Params} = raw_get(Peer),
			m3ua_codec:fetch_parameter(?ErrorCode,
					m3ua_codec:parameters(Params))
	end,
	_ = spawn(fun() -> Self ! {asp_up, m3ua:asp_up(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPUP} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, AspUpAck),
	ok = receive {asp_up, UpResult} -> UpResult after 4000 -> timeout end,
	%% Inactive: nothing to do and nothing said.
	ok = raw_put(Peer, PeerAssoc, AspUpAck),
	nothing_sent = raw_get(Peer),
	inactive = asp_status(EP, Assoc, inactive, 40),
	%% Active: inactive, an ERR, and an ASPAC to be active again.
	_ = spawn(fun() -> Self ! {asp_active, m3ua:asp_active(EP, Assoc)} end),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPACACK)),
	ok = receive {asp_active, AcResult} -> AcResult after 4000 -> timeout end,
	ok = raw_put(Peer, PeerAssoc, AspUpAck),
	unexpected_message = Error(),
	#m3ua{class = ?ASPTMMessage, type = ?ASPTMASPAC} = raw_get(Peer),
	inactive = m3ua:asp_status(EP, Assoc),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPTMMessage, ?ASPTMASPACACK)),
	active = asp_status(EP, Assoc, active, 40),
	%% Down, as after an ASP UP whose ACK came too late: inactive, an ERR,
	%% and an ASPDN to be down again.
	_ = spawn(fun() -> Self ! {asp_down, m3ua:asp_down(EP, Assoc)} end),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN} = raw_get(Peer),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPDNACK)),
	ok = receive {asp_down, DnResult} -> DnResult after 4000 -> timeout end,
	ok = raw_put(Peer, PeerAssoc, AspUpAck),
	unexpected_message = Error(),
	#m3ua{class = ?ASPSMMessage, type = ?ASPSMASPDN} = raw_get(Peer),
	inactive = m3ua:asp_status(EP, Assoc),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPDNACK)),
	down = asp_status(EP, Assoc, down, 40),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

%% @hidden
%% 	The asp's state once it is `State', or what it is after `N' tries:
%% 	a message from the peer reaches it by another way than the query.
asp_status(EP, Assoc, _State, 0) ->
	m3ua:asp_status(EP, Assoc);
asp_status(EP, Assoc, State, N) ->
	case m3ua:asp_status(EP, Assoc) of
		State ->
			State;
		_ ->
			timer:sleep(50),
			asp_status(EP, Assoc, State, N - 1)
	end.

asp_drst_dupu() ->
	[{userdata, [{doc, "A DRST reaches the asp's user as MTP-RESUME, a DUPU as unavailable_user (RFC 4666 5.4, 5.5.2.3.4)."}]}].

asp_drst_dupu(_Config) ->
	Self = self(),
	Fresume = fun(_Stream, _RCs, APCs, State, _Pid) ->
				Self ! {resume, lists:flatten(APCs)},
				{ok, State}
	end,
	Funavailable = fun(_Stream, _RCs, APCs, User, Cause, State, _Pid) ->
				Self ! {unavailable_user, APCs, User, Cause},
				{ok, State}
	end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{resume = Fresume,
			unavailable_user = Funavailable},
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(Callback),
	APC = rand:uniform(16#ffffff) - 1,
	Drst = #m3ua{class = ?SSNMMessage, type = ?SSNMDRST,
			params = [{?AffectedPointCode, [APC]}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(Drst)),
	[APC] = receive {resume, APCs1} -> APCs1 after 4000 -> timeout end,
	Dupu = #m3ua{class = ?SSNMMessage, type = ?SSNMDUPU,
			params = [{?AffectedPointCode, [APC]},
			{?UserCause, {isup, unequipped_remote_user}}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(Dupu)),
	{[APC], isup, unequipped_remote_user} = receive
		{unavailable_user, APCs2, User, Cause} ->
			{APCs2, User, Cause}
	after
		4000 ->
			timeout
	end,
	%% Neither answered with an ERR, as both used to be.
	nothing_sent = raw_get(Peer),
	{ok, #{drst_in := 1, dupu_in := 1}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_restricted_congestion() ->
	[{userdata, [{doc, "DRST reaches restricted/4 and SCON congestion/5 with its level where the callback takes them, resume/4 and status/4 where it does not."}]}].

asp_restricted_congestion(_Config) ->
	Self = self(),
	Frestricted = fun(_Stream, _RCs, APCs, State, _Pid) ->
				Self ! {restricted, APCs},
				{ok, State}
	end,
	Fcongestion = fun(_Stream, _RCs, APCs, Level, State, _Pid) ->
				Self ! {congestion, APCs, Level},
				{ok, State}
	end,
	Fstatus = fun(_Stream, _RCs, APCs, State, _Pid) ->
				Self ! {status, APCs},
				{ok, State}
	end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{restricted = Frestricted,
			congestion = Fcongestion, status = Fstatus},
	{Peer, PeerAssoc, EP, _Assoc} = raw_sg(Callback),
	APC = rand:uniform(16#ffffff) - 1,
	Drst = #m3ua{class = ?SSNMMessage, type = ?SSNMDRST,
			params = [{?AffectedPointCode, [APC]}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(Drst)),
	{restricted, [APC]} = receive {restricted, _} = R -> R after 4000 -> timeout end,
	Scon = #m3ua{class = ?SSNMMessage, type = ?SSNMSCON,
			params = [{?AffectedPointCode, [APC]}, {?CongestionIndications, 2}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(Scon)),
	{congestion, [APC], 2} = receive {congestion, _, _} = C1 -> C1 after 4000 -> timeout end,
	Scon0 = #m3ua{class = ?SSNMMessage, type = ?SSNMSCON,
			params = [{?AffectedPointCode, [APC]}]},
	ok = raw_put(Peer, PeerAssoc, m3ua_codec:m3ua(Scon0)),
	{congestion, [APC], undefined} = receive {congestion, _, _} = C2 -> C2 after 4000 -> timeout end,
	nothing_sent = raw_get(Peer),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer),
	%% Without congestion/5 an SCON goes to status/4, as it did.
	Callback2 = (callback(make_ref()))#m3ua_fsm_cb{status = Fstatus},
	{Peer2, PeerAssoc2, EP2, _Assoc2} = raw_sg(Callback2),
	ok = raw_put(Peer2, PeerAssoc2, m3ua_codec:m3ua(Scon)),
	{status, [APC]} = receive {status, _} = S -> S after 4000 -> timeout end,
	ok = m3ua:stop(EP2),
	ok = gen_sctp:close(Peer2).

listen_not_accepted() ->
	[{userdata, [{doc, "An association a listening endpoint cannot take on costs that association, not the endpoint."}]}].

listen_not_accepted(_Config) ->
	%% The callback refuses while this process is registered under
	%% the name; the first association is refused that way.
	Finit = fun(_Module, _Fsm, _EP, _EpName, _Assoc, _Options, _Pid) ->
				case whereis(m3ua_api_refuse) of
					undefined ->
						{ok, once, []};
					_ ->
						{error, refused}
				end
	end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{init = Finit},
	{ok, EP} = m3ua:start(Callback, 0, [{role, sgp}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	true = register(m3ua_api_refuse, self()),
	{ok, Peer1} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up}} =
			gen_sctp:connect(Peer1, {127,0,0,1}, Port, []),
	ok = receive
		{sctp, Peer1, _, _, {_, #sctp_assoc_change{state = State}}}
				when State /= comm_up ->
			ok
	after
		4000 ->
			still_up
	end,
	true = unregister(m3ua_api_refuse),
	%% The endpoint is the same, and takes the next one.
	true = is_process_alive(EP),
	{ok, Peer2} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer2, {127,0,0,1}, Port, []),
	[_] = assoc(EP, 40),
	ok = raw_put(Peer2, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer2, ?ASPSMMessage, ?ASPSMASPUPACK),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer1),
	ok = gen_sctp:close(Peer2).

connect_not_taken() ->
	[{userdata, [{doc, "An association a connecting endpoint cannot hand to a state machine costs that association, and the endpoint connects again."}]}].

connect_not_taken(_Config) ->
	%% The callback refuses while this process is registered under
	%% the name; the first association is refused that way.
	Finit = fun(_Module, _Fsm, _EP, _EpName, _Assoc, _Options, _Pid) ->
				case whereis(m3ua_api_refuse) of
					undefined ->
						{ok, once, []};
					_ ->
						{error, refused}
				end
	end,
	Callback = (callback(make_ref()))#m3ua_fsm_cb{init = Finit},
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer, true),
	{ok, {_, Port}} = inet:sockname(Peer),
	true = register(m3ua_api_refuse, self()),
	{ok, EP} = m3ua:start(Callback, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	ok = comm_up(Peer),
	ok = receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = State}}}
				when State /= comm_up ->
			ok
	after
		4000 ->
			still_up
	end,
	true = unregister(m3ua_api_refuse),
	%% The endpoint is the same, and connects again once it has waited.
	true = is_process_alive(EP),
	ok = receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = comm_up}}} ->
			ok
	after
		12000 ->
			no_association
	end,
	[_] = assoc(EP, 40),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_states() ->
	[{userdata, [{doc, "Each endpoint and association is readable with no process asked: by name, state as it changes, counters within a second, and gone when it goes."}]}].

asp_states(_Config) ->
	Name = make_ref(),
	Ref = make_ref(),
	{ok, EP} = m3ua:start(sgp_cb(Ref), 0,
			[{name, Name}, {role, sgp}, {ip, {127,0,0,1}}]),
	{_, server, sgp, {_, Port}} = m3ua:get_ep(EP),
	%% Listening, nothing carried.
	[#{ep := EP, mode := listen, role := sgp, local_port := Port,
			assoc_state := down, ended := 0}] = named_states(Name),
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	{ok, #sctp_assoc_change{state = comm_up, assoc_id = PeerAssoc}} =
			gen_sctp:connect(Peer, {127,0,0,1}, Port, []),
	Sgp = wait(Ref),
	[Assoc] = assoc(EP, 40),
	[#{assoc_state := up, assoc_id := Assoc, asp_state := down,
			peer := {[{127,0,0,1}], _}, since := Since1}] = named_states(Name),
	%% The state as it changes: asp_status/2 is answered after the
	%% transition, and so after the row it writes on the way in.
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	inactive = m3ua:asp_status(EP, Assoc),
	[#{asp_state := inactive, since := Since2}] = named_states(Name),
	true = Since2 >= Since1,
	%% Read while the state machine can answer nothing.
	ok = sys:suspend(Sgp),
	{Micro, [#{asp_state := inactive}]} = timer:tc(fun() -> named_states(Name) end),
	true = Micro < 100000,
	ok = sys:resume(Sgp),
	%% The counters within a second or so.
	ct:sleep(1500),
	[#{counters := #{up_in := 1, up_ack_out := 1}}] = named_states(Name),
	%% The association gone: the endpoint says it has ended one.
	ok = gen_sctp:close(Peer),
	[#{assoc_state := down, ended := 1}] = gone(Name, 40),
	ok = m3ua:stop(EP),
	[] = named_states(Name),
	%% A connecting endpoint with nobody to answer it.
	{ok, Closed} = gen_sctp:open([{ip, {127,0,0,1}}]),
	{ok, {_, ClosedPort}} = inet:sockname(Closed),
	ok = gen_sctp:close(Closed),
	Name2 = make_ref(),
	{ok, EP2} = m3ua:start(callback(make_ref()), 0, [{name, Name2},
			{role, asp}, {connect, {127,0,0,1}, ClosedPort, []}]),
	[#{ep := EP2, mode := connect, role := asp, assoc_state := connecting,
			remote := {[{127,0,0,1}], ClosedPort}}] = named_states(Name2),
	ok = m3ua:stop(EP2),
	[] = named_states(Name2).

%% @hidden
named_states(Name) ->
	[State || {N, State} <- m3ua:asp_states(), N == Name].

%% @hidden
%% 	The states of `Name' once the association it carried has ended and
%% 	been counted. The state machine takes its row away as it
%% 	terminates, and the endpoint counts the end when the exit reaches
%% 	it, after: a read between the two sees neither.
gone(Name, 0) ->
	named_states(Name);
gone(Name, N) ->
	case named_states(Name) of
		[#{assoc_state := down, ended := Ended}] = States when Ended > 0 ->
			States;
		_ ->
			ct:sleep(50),
			gone(Name, N - 1)
	end.

%% @hidden
%% 	The endpoints started with `Name'. One stopping or restarting
%% 	meanwhile answers nothing rather than failing the case.
named(Name) ->
	F = fun(EP) ->
			try m3ua:get_ep(EP) of
				Info ->
					element(1, Info) =:= Name
			catch
				_:_ ->
					false
			end
	end,
	try m3ua:get_ep() of
		EPs ->
			lists:filter(F, EPs)
	catch
		_:_ ->
			timer:sleep(20),
			named(Name)
	end.

connect_device() ->
	[{userdata, [{doc, "A device given with connect is bound into, and the association comes up."}]}].

connect_device(_Config) ->
	%% Loopback stands in for a VRF: the point is that a device named
	%% with the connect options reaches the socket and the association
	%% still comes up. Whether it went on before the bind, which is what
	%% a VRF needs, shows only on a host with one.
	{ok, Peer} = gen_sctp:open([{active, true}, {ip, {127,0,0,1}}]),
	ok = gen_sctp:listen(Peer, true),
	{ok, {_, Port}} = inet:sockname(Peer),
	{ok, EP} = m3ua:start(callback(make_ref()), 0, [{role, asp},
			{connect, {127,0,0,1}, Port, [{device, "lo"}]}]),
	ok = comm_up(Peer),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

%% @hidden
comm_up(Peer) ->
	receive
		{sctp, Peer, _, _, {_, #sctp_assoc_change{state = comm_up}}} ->
			ok
	after
		2000 ->
			no_association
	end.

%% @hidden
assoc(_EP, 0) ->
	[];
assoc(EP, N) ->
	case m3ua:get_assoc(EP) of
		[] ->
			timer:sleep(50),
			assoc(EP, N - 1);
		Assocs ->
			Assocs
	end.

getstat_ep() ->
	[{userdata, [{doc, "Get SCTP option statistics for an endpoint."}]}].

getstat_ep(_Config) ->
	{ok, EP} = m3ua:start(#m3ua_fsm_cb{}),
	{ok, OptionValues} = m3ua:getstat(EP),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	ok = m3ua:stop(EP).

getstat_assoc() ->
	[{userdata, [{doc, "Get SCTP option statistics for an association."}]}].

getstat_assoc(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	{ok, OptionValues} = m3ua:getstat(ClientEP, Assoc),
	F = fun({Option, Value}) when is_atom(Option), is_integer(Value) ->
				true;
			(_) ->
				false
	end,
	true = lists:all(F, OptionValues),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

getcount() ->
	[{userdata, [{doc, "Get M3UA statistics for an ASP."}]}].

getcount(_Config) ->
	Port = rand:uniform(64511) + 1024,
	NA = 0,
	Keys = [{rand:uniform(16383), [], []}],
	Mode = loadshare,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	{ok, _RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, NA, Keys, Mode]),
	{ok, #{up_out := 1, up_ack_in := 1}} = rpc:call(AsNode, m3ua,
			getcount, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	{ok, #{active_out := 1, active_ack_in := 1}} = rpc:call(AsNode,
			m3ua, getcount, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_inactive, [ClientEP, Assoc]),
	{ok, #{inactive_out := 1, inactive_ack_in := 1}} = rpc:call(AsNode,
			m3ua, getcount, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP, Assoc]),
	{ok, #{down_out := 1, down_ack_in := 1}} = rpc:call(AsNode,
			m3ua, getcount, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

register() ->
	[{userdata, [{doc, "Register a routing key."}]}].

register(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	Keys = [{rand:uniform(16383), [7,8], []}],
	{ok, RC} = m3ua:register(ClientEP, Assoc,
			undefined, undefined, Keys, loadshare),
	true = is_integer(RC),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

asp_active() ->
	[{userdata, [{doc, "Make Application Server Process (ASP) active."}]}].

asp_active(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_inactive_to_down() ->
	[{userdata, [{doc, "Make ASP inactive to down state"}]}].

asp_inactive_to_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = m3ua:asp_up(ClientEP, Assoc),
	ok = m3ua:asp_down(ClientEP, Assoc),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

asp_active_to_down() ->
	[{userdata, [{doc, "Make ASP active to down state"}]}].

asp_active_to_down(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_active_to_inactive() ->
	[{userdata, [{doc, "Make ASP active to inactive state"}]}].

asp_active_to_inactive(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_inactive, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

get_sctp_status() ->
	[{userdata, [{doc, "Get SCTP status of an association"}]}].
get_sctp_status(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	RefC = make_ref(),
	{ok, ClientEP} = m3ua:start(callback(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	{ok, #sctp_status{assoc_id = Assoc}} = m3ua:sctp_status(ClientEP, Assoc),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

get_ep() ->
	[{userdata, [{doc, "Get SCTP endpoints."}]}].

get_ep(_Config) ->
	Port = rand:uniform(64511) + 1024,
	{ok, ServerEP} = m3ua:start(#m3ua_fsm_cb{}, Port, []),
	{ok, ClientEP} = m3ua:start(#m3ua_fsm_cb{}, 0,
			[{name, Port}, {role, asp},
			{connect, {127,0,0,1}, Port, []}]),
	EndPoints = m3ua:get_ep(),
	true = lists:member(ServerEP, EndPoints),
	true = lists:member(ClientEP, EndPoints),
	{_, server, sgp, {{0,0,0,0}, Port}} = m3ua:get_ep(ServerEP),
	{Port, client, asp, {{0,0,0,0}, _},
			{{127,0,0,1}, Port}} = m3ua:get_ep(ClientEP),
	ok = m3ua:stop(ClientEP),
	ok = m3ua:stop(ServerEP).

mtp_transfer() ->
	[{userdata, [{doc, "Send MTP Transfer Message"}]}].

mtp_transfer(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefTS = make_ref(),
	SgpRecv = fun(Stream, RC, OPC, DPC, NI, SI, SLS, Data, _State, Pid) ->
				Pid ! {RefTS, [Stream, RC, DPC, OPC, NI, SI, SLS, Data]},
				{ok, once, []}
	end,
	RefS = make_ref(),
	CbS = callback(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{recv = SgpRecv},
			Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	Asp = wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	DPC = rand:uniform(16383),
	Keys = [{DPC, [], []}],
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	Stream = 1,
	OPC = rand:uniform(16383),
	NI = rand:uniform(4),
	SI = rand:uniform(10),
	SLS = rand:uniform(255),
	Data = crypto:strong_rand_bytes(100),
	ok = rpc:call(AsNode, m3ua, transfer, [Asp, Stream, RC, OPC, DPC, NI, SI, SLS, Data]),
	receive
		{RefTS, [Stream, RC, DPC, OPC, NI, SI, SLS, Data]} ->
			ok
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

mtp_cast() ->
	[{userdata, [{doc, "Send MTP Transfer Message asynchronously"}]}].

mtp_cast(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	CbC = remote_cb(RefC),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[CbC#m3ua_fsm_cb{send = fun ?MODULE:cb_send/13}, 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	Asp = wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	DPC = rand:uniform(16383),
	Keys = [{DPC, [], []}],
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	OPC = rand:uniform(16383),
	NI = rand:uniform(4),
	SI = rand:uniform(10),
	SLS = rand:uniform(255),
	Data = crypto:strong_rand_bytes(100),
	RefCast = m3ua:cast(Asp, undefined, RC, OPC, DPC, NI, SI, SLS, Data),
	receive
		{RefCast, [_Stream, RC, DPC, OPC, NI, SI, SLS, Data]} ->
			ok
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_up_indication() ->
	[{userdata, [{doc, "Received M-ASP_UP indication"}]}].

asp_up_indication(_Config) ->
	RefU = make_ref(),
	Fup = fun(_, Pid) ->
		Pid ! RefU,
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	CbS = callback(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{asp_up = Fup}, Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	wait(RefU),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_active_indication() ->
	[{userdata, [{doc, "Received M-ASP_ACTIVE indication"}]}].

asp_active_indication(_Config) ->
	RefA = make_ref(),
	Fact = fun(_, Pid) ->
		Pid ! RefA,
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	CbS = callback(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{asp_active = Fact}, Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register, [ClientEP, Assoc,
			undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	wait(RefA),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_inactive_indication() ->
	[{userdata, [{doc, "Received M-ASP_INACTIVE indication"}]}].

asp_inactive_indication(_Config) ->
	RefI = make_ref(),
	Finact = fun(_, Pid) ->
		Pid ! RefI,
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	CbS = callback(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{asp_inactive = Finact},
			Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register, [ClientEP, Assoc,
			undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_inactive, [ClientEP, Assoc]),
	wait(RefI),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

asp_down_indication() ->
	[{userdata, [{doc, "Received M-ASP_DOWN indication"}]}].

asp_down_indication(_Config) ->
	RefD = make_ref(),
	Fdown = fun(_, Pid) ->
		Pid ! RefD,
		{ok, []}
	end,
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	CbS = callback(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{asp_down = Fdown}, Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	Keys = [{rand:uniform(16383), [], []}],
	{ok, _RC} = rpc:call(AsNode, m3ua, register, [ClientEP, Assoc,
			undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP, Assoc]),
	wait(RefD),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

sg_state_active() ->
	[{userdata, [{doc, "SG traffic maintenance for AS state"}]}].

sg_state_active(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefS),
	wait(RefS),
	wait(RefC1),
	wait(RefC2),
	wait(RefC3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	#m3ua_as{state = down, asp = []} = get_as(RC),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps1} = get_as(RC),
	true = is_all_state(inactive, Asps1),
	1 = length(Asps1),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps2} = get_as(RC),
	true = is_all_state(inactive, Asps2),
	2 = length(Asps2),
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	#m3ua_as{state = inactive, asp = Asps3} = get_as(RC),
	true = is_all_state(inactive, Asps3),
	3 = length(Asps3),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	#m3ua_as{state = inactive, asp = Asps4} = as_until(RC,
			fun(#m3ua_as{asp = A}) -> count_state(active, A) == 1 end),
	1 = count_state(active, Asps4),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	#m3ua_as{state = inactive, asp = Asps5} = as_until(RC,
			fun(#m3ua_as{asp = A}) -> count_state(active, A) == 2 end),
	2 = count_state(active, Asps5),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps6} = as_until(RC,
			fun(#m3ua_as{asp = A}) -> count_state(active, A) == 3 end),
	3 = count_state(active, Asps6),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

as_state_active() ->
	[{userdata, [{doc, "AS traffic maintenance for AS state"}]}].

as_state_active(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefS),
	wait(RefS),
	wait(RefC1),
	wait(RefC2),
	wait(RefC3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RC1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RC2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RC3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	{_, as_active} = wait(RefC1),
	{_, as_active} = wait(RefC2),
	{_, as_active} = wait(RefC3),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

sg_state_down() ->
	[{userdata, [{doc, "SG state maintenance for AS state"}]}].

sg_state_down(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefS),
	wait(RefS),
	wait(RefC1),
	wait(RefC2),
	wait(RefC3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RC1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RC2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RC3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps1} = as_until(RC,
			fun(#m3ua_as{asp = A}) -> count_state(active, A) == 3 end),
	true = is_all_state(active, Asps1),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	#m3ua_as{state = active, asp = Asps2} = as_until(RC,
			fun(#m3ua_as{asp = A}) -> count_state(active, A) == 1 end),
	1 = count_state(active, Asps2),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	#m3ua_as{state = down, asp = Asps3} = as_until(RC,
			fun(#m3ua_as{state = S}) -> S == down end),
	true = is_all_state(down, Asps3),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

as_state_down() ->
	[{userdata, [{doc, "AS state maintenance for AS state"}]}].

as_state_down(_Config) ->
	MinAsps = 3,
	MaxAsps = 5,
	Mode = loadshare,
	NA = rand:uniform(4294967295),
	DPC = rand:uniform(16777215),
	SIs = [rand:uniform(255) || _ <- lists:seq(1, 5)],
	OPCs = [rand:uniform(16777215) || _ <- lists:seq(1, 5)],
	Keys = m3ua:sort([{DPC, SIs, OPCs}]),
	RC = rand:uniform(4294967295),
	Name = make_ref(),
	{ok, _AS} = m3ua:as_add(Name, RC, NA, Keys, Mode, MinAsps, MaxAsps),
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC1 = make_ref(),
	{ok, ClientEP1} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC1), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC2 = make_ref(),
	{ok, ClientEP2} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC2), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	RefC3 = make_ref(),
	{ok, ClientEP3} = rpc:call(AsNode, m3ua, start,
			[remote_cb(RefC3), 0, [{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	wait(RefS),
	wait(RefS),
	wait(RefS),
	wait(RefC1),
	wait(RefC2),
	wait(RefC3),
	[Assoc1] = m3ua:get_assoc(ClientEP1),
	[Assoc2] = m3ua:get_assoc(ClientEP2),
	[Assoc3] = m3ua:get_assoc(ClientEP3),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP3, Assoc3]),
	{ok, _RC1} = rpc:call(AsNode, m3ua, register,
			[ClientEP1, Assoc1, undefined, NA, Keys, Mode]),
	{ok, _RC2} = rpc:call(AsNode, m3ua, register,
			[ClientEP2, Assoc2, undefined, NA, Keys, Mode]),
	{ok, _RC3} = rpc:call(AsNode, m3ua, register,
			[ClientEP3, Assoc3, undefined, NA, Keys, Mode]),
	%% ASP DOWN deregisters what each registered (RFC 4666 4.3.4.2), so
	%% the first two leave the application server as they go, and only
	%% the last is in it to be told that it is down. The server was
	%% configured, so it stays, with no asp in it.
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	{_, as_inactive} = wait(RefC3),
	[#m3ua_as{state = down, asp = []}] = mnesia:dirty_read(m3ua_as, RC),
	nothing = receive {RefC1, _, _} -> RefC1 after 1000 -> nothing end,
	nothing = receive {RefC2, _, _} -> RefC2 after 0 -> nothing end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

callback(Ref) ->
	Finit = fun(_Module, _Asp, _EP, _EpName, _Assoc, _Options, Pid) ->
				Pid ! Ref,
				{ok, once, []}
	end,
	Fnotify = fun(RCs, Status, _AspID, State, Pid) ->
				Pid ! {Ref, RCs, Status},
				{ok, State}
	end,
	#m3ua_fsm_cb{init = Finit, notify = Fnotify, extra = [self()]}.

wait(Ref) ->
	receive
		Ref ->
			ok;
		{Ref, Pid} ->
			Pid;
		{Ref, RC, Status} ->
			{RC, Status}
	end.

remote_cb(Ref) ->
	Finit = fun ?MODULE:cb_init/8,
	Fnotify = fun ?MODULE:cb_notify/6,
	#m3ua_fsm_cb{init = Finit, notify = Fnotify, extra = [Ref, self()]}.

%% @hidden
%% A gateway callback that reports the SGP process it runs in.  The
%% SSNM API is called with that process, so a case that sends one has
%% to be told it, and callback/1 above reports only that it started.
sgp_cb(Ref) ->
	#m3ua_fsm_cb{init = fun ?MODULE:cb_init/8, extra = [Ref, self()]}.

%% @hidden
%% An ASP callback that reports the SSNM indications it is given.
remote_ssnm_cb(Ref) ->
	Cb = remote_cb(Ref),
	Cb#m3ua_fsm_cb{pause = fun ?MODULE:cb_pause/6,
			resume = fun ?MODULE:cb_resume/6}.

cb_pause(_Stream, RCs, APCs, State, Ref, Pid) ->
	Pid ! {Ref, pause, RCs, APCs},
	{ok, State}.

cb_resume(_Stream, RCs, APCs, State, Ref, Pid) ->
	Pid ! {Ref, resume, RCs, APCs},
	{ok, State}.

cb_audit(_Stream, RCs, APCs, State, Ref, Pid) ->
	Pid ! {Ref, audit, RCs, APCs},
	{ok, State}.

cb_init(_Module, _Asp, _EP, _EpName, _Assoc, _Options, Ref, Pid) ->
	Pid ! {Ref, self()},
	{ok, once, []}.

cb_notify(RCs, Status, _AspID, State, Ref, Pid) ->
	Pid ! {Ref, RCs, Status},
	{ok, State}.

cb_send(From, Ref, Stream,
		RC, OPC, DPC, NI, SI, SLS, Data, _State, _Ref, _Pid) ->
	From ! {Ref, [Stream, RC, DPC, OPC, NI, SI, SLS, Data]},
	{ok, once, []}.

cb_send(_Module, _Asp, _EP, _EpName, _Assoc, Ref, Pid) ->
	Pid ! {Ref, self()},
	{ok, once, []}.

is_all_state(IsAspState, Asps) ->
	F = fun(#m3ua_as_asp{state = AspState}) when AspState == IsAspState ->
			true;
		(_) ->
			false
	end,
	lists:all(F, Asps).

count_state(IsAspState, Asps) ->
	F = fun(#m3ua_as_asp{state = AspState}, Acc) when AspState == IsAspState ->
				Acc + 1;
			(_, Acc) ->
				Acc
	end,
	lists:foldl(F, 0, Asps).

%% @hidden
%% 	The application server of `RC' once `F' holds of it, or as it is
%% 	after two seconds. The gateway acknowledges an ASPAC or ASPDN
%% 	before it records what follows from it, so a read straight after
%% 	the acknowledgement may come too soon.
as_until(RC, F) ->
	as_until(RC, F, 40).
%% @hidden
as_until(RC, _F, 0) ->
	get_as(RC);
as_until(RC, F, N) ->
	AS = get_as(RC),
	case F(AS) of
		true ->
			AS;
		false ->
			ct:sleep(50),
			as_until(RC, F, N - 1)
	end.

get_as(RC) ->
	F = fun() ->
			[#m3ua_as{}] = mnesia:read(m3ua_as, RC, read)
	end,
	case mnesia:transaction(F) of
		{atomic, [AS]} ->
			AS;
		{aboarted, Reason} ->
			Reason
	end.

%% @hidden
%% 	A node of its own for an application server process, on this host,
%% 	with m3ua and this suite in its code path and this node's cookie.
%% 	peer rather than slave, which goes in OTP 31.
as_node() ->
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(?MODULE)),
	Name = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	peer:start_link(#{name => Name,
			args => ["-pa", Path1, "-pa", Path2,
					"-setcookie", atom_to_list(erlang:get_cookie())]}).

ssnm_pause_resume() ->
	[{userdata, [{doc, "A signalling gateway tells an ASP that SS7 "
			"destinations have become unavailable and available again "
			"(RFC 4666 3.4.1, 3.4.2). They arrive as the MTP-PAUSE and "
			"MTP-RESUME indications of the ASP's callbacks"}]}].

ssnm_pause_resume(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(sgp_cb(RefS), Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_ssnm_cb(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Sgp = wait(RefS),
	_Asp = wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	DPC = rand:uniform(16383),
	Keys = [{DPC, [], []}],
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	APC = rand:uniform(16383),
	ok = m3ua:duna(Sgp, [RC], [APC]),
	receive
		{RefC, pause, _, [APC]} ->
			ok
	after
		4000 ->
			ct:fail(no_pause_indication)
	end,
	ok = m3ua:dava(Sgp, [RC], [APC]),
	receive
		{RefC, resume, _, [APC]} ->
			ok
	after
		4000 ->
			ct:fail(no_resume_indication)
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).

ssnm_audit() ->
	[{userdata, [{doc, "An ASP audits the state of SS7 destinations "
			"(RFC 4666 3.4.3). The gateway is asked through its audit "
			"callback, since only it knows, and answers with a DAVA "
			"(4.4.1.5). Before this the audit had no clause at all and "
			"took the association down with it"}]}].

ssnm_audit(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	CbS = sgp_cb(RefS),
	{ok, ServerEP} = m3ua:start(CbS#m3ua_fsm_cb{
			audit = fun ?MODULE:cb_audit/6}, Port, []),
	{ok, AsPeer, AsNode} = as_node(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [inets]),
	ok = rpc:call(AsNode, application, start, [m3ua]),
	RefC = make_ref(),
	{ok, ClientEP} = rpc:call(AsNode, m3ua, start,
			[remote_ssnm_cb(RefC), 0,
			[{role, asp}, {connect, {127,0,0,1}, Port, []}]]),
	Sgp = wait(RefS),
	Asp = wait(RefC),
	[Assoc] = m3ua:get_assoc(ClientEP),
	ok = rpc:call(AsNode, m3ua, asp_up, [ClientEP, Assoc]),
	DPC = rand:uniform(16383),
	Keys = [{DPC, [], []}],
	{ok, RC} = rpc:call(AsNode, m3ua, register,
			[ClientEP, Assoc, undefined, undefined, Keys, loadshare]),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP, Assoc]),
	APC = rand:uniform(16383),
	ok = rpc:call(AsNode, m3ua, daud, [Asp, [RC], [APC]]),
	receive
		{RefS, audit, _, [APC]} ->
			ok
	after
		4000 ->
			ct:fail(no_audit_indication)
	end,
	%% The gateway answers, which is the whole point of being asked.
	ok = m3ua:dava(Sgp, [RC], [APC]),
	receive
		{RefC, resume, _, [APC]} ->
			ok
	after
		4000 ->
			ct:fail(no_resume_indication)
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = peer:stop(AsPeer).
