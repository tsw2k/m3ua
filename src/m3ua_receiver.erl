%%% m3ua_receiver.erl
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
%%% @doc The receive side of one socket in the {@link //m3ua. m3ua}
%%% 	application.
%%%
%%% 	The `socket' module has no active mode: nothing arrives in a
%%% 	mailbox, a process asks. So this process asks, and hands what
%%% 	comes to its owner in the messages `gen_sctp' used to send --
%%%
%%% ```
%%% {sctp, Socket, FromIP, FromPort, {AncData, Data}}
%%% {sctp_error, Socket, FromIP, FromPort, {AncData, Notification}}
%%% '''
%%%
%%% 	-- so the four state machines keep every `handle_info/3' clause
%%% 	they already have. A transport swap that also rewrote the receive
%%% 	path would be two changes arriving as one, and the second would
%%% 	be reviewed as though it were the first.
%%%
%%% 	== Which of the two ==
%%%
%%% 	`gen_sctp' sends `sctp_error' for a send failure and for the
%%% 	peer's own error report, and `sctp' for everything else. That
%%% 	split is not a detail of the transport: m3ua stops an association
%%% 	on `sctp_error' and carries on for the rest, so getting it wrong
%%% 	would either drop links that are fine or keep links that are not.
%%%
%%% 	== The allowance ==
%%%
%%% 	`{active, once}' is what m3ua asks for and what a callback may
%%% 	change. It is reproduced by counting: this process reads at most
%%% 	its allowance and then waits to be told to carry on, which the
%%% 	state machines do after each message exactly as they used to call
%%% 	`inet:setopts/2'. `{active, true}' is unbounded, and is left
%%% 	unbounded rather than quietly capped -- a caller who asks for it
%%% 	should get what they asked for, including the memory it costs.
%%%
%%% 	Unlike `gen_sctp' nothing is sent when the allowance runs out.
%%% 	`gen_sctp' announces `{sctp_passive, Socket}' there, and no state
%%% 	machine in this application has ever had a clause for it, so
%%% 	sending one would turn a spent allowance into a crash.
%%%
%%% @end
-module(m3ua_receiver).
-copyright('Copyright (c) 2026 MTX Connect S.a r.l.').

-export([start/3, stop/1, replenish/2]).

%% @private
-export([init/3]).

-include_lib("kernel/include/inet_sctp.hrl").

-record(state,
		{socket :: m3ua_sctp:sock(),
		owner :: pid(),
		allowance :: non_neg_integer() | infinity}).

%%----------------------------------------------------------------------
%%  The m3ua_receiver API
%%----------------------------------------------------------------------

-spec start(Socket, Owner, Active) -> pid()
	when
		Socket :: m3ua_sctp:sock(),
		Owner :: pid(),
		Active :: true | false | once | pos_integer().
%% @doc Start reading `Socket' on behalf of `Owner'.
%%
%% 	Linked: a receiver that dies has taken its owner's only way of
%% 	hearing anything with it, and a state machine carrying on deaf is
%% 	worse than one that restarts.
start(Socket, Owner, Active) ->
	spawn_link(?MODULE, init, [Socket, Owner, allowance(Active)]).

-spec stop(Receiver :: pid()) -> ok.
%% @doc Give up reading.
%%
%% 	Used where a socket changes hands: whatever has not been read
%% 	stays in the receive buffer, and the new owner's receiver reads it.
stop(Receiver) ->
	Receiver ! stop,
	ok.

-spec replenish(Receiver, Active) -> ok
	when
		Receiver :: pid(),
		Active :: true | false | once | pos_integer().
%% @doc Allow `Active' more messages.
%%
%% 	Adds rather than replaces, which is what `inet:setopts/2' did for
%% 	`{active, N}', and which lets an owner top up before the allowance
%% 	is spent -- so the bound costs no pause in the ordinary case.
replenish(Receiver, Active) ->
	Receiver ! {replenish, allowance(Active)},
	ok.

%%----------------------------------------------------------------------
%%  Internal functions
%%----------------------------------------------------------------------

%% @private
init(Socket, Owner, Allowance) ->
	loop(#state{socket = Socket, owner = Owner, allowance = Allowance}).

%% @hidden
loop(#state{allowance = 0} = State) ->
	loop(wait(State));
loop(#state{socket = Socket, owner = Owner} = State) ->
	case m3ua_sctp:recvmsg(Socket, nowait) of
		{ok, {Address, Port, AncData, Data}} ->
			Owner ! {tag(Data), Socket, Address, Port, {AncData, Data}},
			loop(spend(State));
		{select, {select_info, _, Ref}} ->
			loop(select(State, Ref));
		{error, timeout} ->
			loop(State);
		{error, closed} ->
			ok;
		{error, Reason} ->
			exit({recv, Reason})
	end.

%% @hidden
%% 	The two gen_sctp told apart, told apart the same way.
tag(#sctp_send_failed{}) ->
	sctp_error;
tag(#sctp_remote_error{}) ->
	sctp_error;
tag(_Other) ->
	sctp.

%% @hidden
spend(#state{allowance = infinity} = State) ->
	State;
spend(#state{allowance = Allowance} = State) ->
	State#state{allowance = Allowance - 1}.

%% @hidden
%% 	Nothing to read yet. The runtime will say when there is, and until
%% 	then this is the one place the owner can top the allowance up
%% 	without the message being read late.
select(#state{socket = Socket} = State, Ref) ->
	receive
		{'$socket', Socket, select, Ref} ->
			State;
		{'$socket', Socket, abort, {Ref, closed}} ->
			exit(normal);
		{'$socket', Socket, abort, {Ref, Reason}} ->
			exit({recv, Reason});
		{replenish, Count} ->
			select(topped_up(State, Count), Ref);
		stop ->
			_ = socket:cancel(Socket, {select_info, recvmsg, Ref}),
			exit(normal)
	end.

%% @hidden
wait(#state{} = State) ->
	receive
		{replenish, Count} ->
			topped_up(State, Count);
		stop ->
			exit(normal)
	end.

%% @hidden
topped_up(#state{allowance = infinity} = State, _Count) ->
	State;
topped_up(#state{} = State, infinity) ->
	State#state{allowance = infinity};
topped_up(#state{allowance = Allowance} = State, Count) ->
	State#state{allowance = Allowance + Count}.

%% @hidden
allowance(true) -> infinity;
allowance(false) -> 0;
allowance(once) -> 1;
allowance(N) when is_integer(N), N > 0 -> N;
allowance(_Other) -> 1.
