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
	ok = application:start(snmp),
	ok = application:start(inets),
	ok = application:start(m3ua),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(_Config) ->
	ok = application:stop(m3ua),
	ok = application:stop(inets),
	ok = application:stop(snmp),
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
			connect_options, stop_endpoint, lm_stray, reconnect_in_place,
			endpoint_gives_up, lm_restart, callback_raised,
			undecodable, unexpected, registration_results, ack_timeout,
			inactive_timeout, sgp_undecodable, sgp_unexpected,
			sgp_asp_up_inactive, sgp_asp_up_active, sgp_deregister, sgp_dereg_req,
			sgp_deregister_local, asp_deregister,
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
	%% An Affected Point Code with a mask other than zero.
	invalid_parameter_value = Send(<<1, 0, ?SSNMMessage, ?SSNMDUNA,
			16:32, ?AffectedPointCode:16, 8:16, 1, 0:24>>),
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

sgp_asp_up_active() ->
	[{userdata, [{doc, "An ASP UP at an active asp is acknowledged, answered with an ERR, and leaves the asp inactive (RFC 4666 4.3.4.1)."}]}].

sgp_asp_up_active(_Config) ->
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
	ok = gen_sctp:close(Peer).

sgp_deregister() ->
	[{userdata, [{doc, "ASP DOWN, and ASP UP at an active asp, deregister the routing keys the asp registered (RFC 4666 4.3.4)."}]}].

sgp_deregister(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
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
	[] = as_asps(RC1),
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
	[] = as_asps(RC2),
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
	[] = as_asps(RC1),
	[_] = as_asps(RC2),
	%% Once gone, it is not registered.
	[{RC1, not_registered}] = raw_dereg(Peer, PeerAssoc, [RC1]),
	{ok, #{dereg_in := 3, dereg_rsp_out := 3}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

sgp_deregister_local() ->
	[{userdata, [{doc, "M-RK_DEREG at a signalling gateway takes its asp out of the application server, with nothing sent."}]}].

sgp_deregister_local(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_asp(),
	ok = raw_put(Peer, PeerAssoc, raw_msg(?ASPSMMessage, ?ASPSMASPUP)),
	#m3ua{} = raw_expect(Peer, ?ASPSMMessage, ?ASPSMASPUPACK),
	RC = raw_register(Peer, PeerAssoc),
	[_] = as_asps(RC),
	ok = m3ua:deregister(EP, Assoc, RC),
	[] = as_asps(RC),
	{error, not_registered} = m3ua:deregister(EP, Assoc, RC),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

asp_deregister() ->
	[{userdata, [{doc, "M-RK_DEREG at an asp sends a DEREG REQ and answers with the DEREG RSP's result for its routing context."}]}].

asp_deregister(_Config) ->
	{Peer, PeerAssoc, EP, Assoc} = raw_sg(),
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
	[_] = as_asps(RC),
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
	[_] = as_asps(RC),
	%% Deregistered: it is not.
	ok = Dereg(),
	ok = raw_put(Peer, PeerAssoc, raw_dereg_rsp(RC, deregistered)),
	ok = receive {deregister, Result2} -> Result2 after 4000 -> timeout end,
	[] = as_asps(RC),
	{ok, #{dereg_out := 2, dereg_rsp_in := 2}} = m3ua:getcount(EP, Assoc),
	ok = m3ua:stop(EP),
	ok = gen_sctp:close(Peer).

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
	Keys = [{rand:uniform(16383), [], []}],
	RK = m3ua_codec:routing_key(#m3ua_routing_key{na = 0,
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
as_asps(RC) ->
	[#m3ua_as{asp = ASPs}] = mnesia:dirty_read(m3ua_as, RC),
	ASPs.

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
	{ok, EP} = m3ua:start(callback(make_ref()), 0,
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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

asp_active_to_inactive() ->
	[{userdata, [{doc, "Make ASP active to inactive state"}]}].

asp_active_to_inactive(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

mtp_cast() ->
	[{userdata, [{doc, "Send MTP Transfer Message asynchronously"}]}].

mtp_cast(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(callback(RefS), Port, []),
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	#m3ua_as{state = inactive, asp = Asps4} = get_as(RC),
	1 = count_state(active, Asps4),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP2, Assoc2]),
	#m3ua_as{state = inactive, asp = Asps5} = get_as(RC),
	2 = count_state(active, Asps5),
	ok = rpc:call(AsNode, m3ua, asp_active, [ClientEP3, Assoc3]),
	#m3ua_as{state = active, asp = Asps6} = get_as(RC),
	3 = count_state(active, Asps6),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	#m3ua_as{state = active, asp = Asps1} = get_as(RC),
	true = is_all_state(active, Asps1),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	#m3ua_as{state = active, asp = Asps2} = get_as(RC),
	1 = count_state(active, Asps2),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	#m3ua_as{state = down, asp = Asps3} = get_as(RC),
	true = is_all_state(down, Asps3),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP1, Assoc1]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP2, Assoc2]),
	ok = rpc:call(AsNode, m3ua, asp_down, [ClientEP3, Assoc3]),
	{_, as_inactive} = wait(RefC1),
	{_, as_inactive} = wait(RefC2),
	{_, as_inactive} = wait(RefC3),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP1]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP2]),
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP3]),
	ok = m3ua:stop(ServerEP),
	ok = slave:stop(AsNode).

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

slave_as() ->
	Path1 = filename:dirname(code:which(m3ua)),
	Path2 = filename:dirname(code:which(?MODULE)),
	ErlFlags = "-pa " ++ Path1 ++ " -pa " ++ Path2,
	{ok, Host} = inet:gethostname(),
	Node = "as" ++ integer_to_list(erlang:unique_integer([positive])),
	slave:start_link(Host, Node, ErlFlags).

ssnm_pause_resume() ->
	[{userdata, [{doc, "A signalling gateway tells an ASP that SS7 "
			"destinations have become unavailable and available again "
			"(RFC 4666 3.4.1, 3.4.2). They arrive as the MTP-PAUSE and "
			"MTP-RESUME indications of the ASP's callbacks"}]}].

ssnm_pause_resume(_Config) ->
	Port = rand:uniform(64511) + 1024,
	RefS = make_ref(),
	{ok, ServerEP} = m3ua:start(sgp_cb(RefS), Port, []),
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
		{RefC, pause, _, [[APC]]} ->
			ok
	after
		4000 ->
			ct:fail(no_pause_indication)
	end,
	ok = m3ua:dava(Sgp, [RC], [APC]),
	receive
		{RefC, resume, _, [[APC]]} ->
			ok
	after
		4000 ->
			ct:fail(no_resume_indication)
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = slave:stop(AsNode).

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
	{ok, AsNode} = slave_as(),
	{ok, _} = rpc:call(AsNode, m3ua_app, install, [[AsNode]]),
	ok = rpc:call(AsNode, application, start, [snmp]),
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
		{RefS, audit, _, [[APC]]} ->
			ok
	after
		4000 ->
			ct:fail(no_audit_indication)
	end,
	%% The gateway answers, which is the whole point of being asked.
	ok = m3ua:dava(Sgp, [RC], [APC]),
	receive
		{RefC, resume, _, [[APC]]} ->
			ok
	after
		4000 ->
			ct:fail(no_resume_indication)
	end,
	ok = rpc:call(AsNode, m3ua, stop, [ClientEP]),
	ok = m3ua:stop(ServerEP),
	ok = slave:stop(AsNode).
