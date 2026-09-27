%%% m3ua_status.erl
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
%%% @doc The state of each endpoint and association in the
%%% 	{@link //m3ua. m3ua} application, where it can be read without
%%% 	asking any process.
%%%
%%% 	A management walk every few seconds must not wait on a state
%%% 	machine that is busy, or on one that is gone, and m3ua's calls --
%%% 	asp_status/2, getcount/2 -- ask the state machines. Here each
%%% 	process writes its own row into one ETS table, and
%%% 	{@link asp_states/0} reads the table and nothing else. The node's
%%% 	MIB is built on it, and on the m3ua_as table, outside m3ua.
%%%
%%% 	== Who writes what ==
%%%
%%% 	An endpoint writes its row when it starts and when what it holds
%%% 	changes; an asp or sgp state machine writes its row when it enters
%%% 	a state, and its counters once a second. Nothing is written per
%%% 	message: the counters are the ones the state machine keeps anyway
%%% 	(m3ua:getcount/2). Each process writes only under its own pid, so
%%% 	a read, merge and insert by that process loses nothing, and each
%%% 	deletes its rows as it terminates. A process killed outright leaves
%%% 	its row behind; a read passes over the rows of a process that is
%%% 	no longer alive.
%%%
%%% 	The table belongs to `m3ua_sup', which lives as long as the
%%% 	application, rather than to the layer manager, which may be
%%% 	restarted while the endpoints go on.
%%% @end
-module(m3ua_status).
-copyright('Copyright (c) 2026 MTX Connect S.a r.l.').

-export([asp_states/0]).

%% @private
-export([new/0, endpoint/1, association/1, forget/0]).

-define(TABLE, m3ua_status).

-type asp_state() :: #{name := term(),
		ep := pid(),
		mode := connect | listen,
		role := asp | sgp,
		local_port => inet:port_number(),
		remote => {[inet:ip_address()], inet:port_number()},
		assoc_state := up | connecting | down,
		ended := non_neg_integer(),
		assoc_id => gen_sctp:assoc_id(),
		peer => {[inet:ip_address()], inet:port_number()},
		asp_state => down | inactive | active,
		since => integer(),
		contexts => #{0..4294967295 => atom()},
		counters => #{atom() => non_neg_integer()},
		updated => integer()}.
-export_type([asp_state/0]).

%%----------------------------------------------------------------------
%%  The m3ua_status API
%%----------------------------------------------------------------------

-spec asp_states() -> [{Name, State}]
	when
		Name :: term(),
		State :: asp_state().
%% @doc Every endpoint, and each association on it, as last written.
%%
%% 	`Name' is the one given to m3ua:start/3 with `{name, Name}'. There
%% 	is one element for each association an endpoint carries; an
%% 	endpoint that carries none has one of its own, with `assoc_state'
%% 	`connecting' where it connects and `down' where it listens.
%%
%% 	From the endpoint: `ep', `mode' (connect or listen), `role' (asp or
%% 	sgp), `local_port', `remote' (connect only) and `ended', the number
%% 	of associations that have ended on it. From the association's
%% 	state machine: `assoc_id', `peer', `asp_state' (down, inactive or
%% 	active, for the association as a whole), `since', when it entered
%% 	that state, `contexts', the state of each application server it is
%% 	in as it was last told, `counters', those of m3ua:getcount/2, and
%% 	`updated', when these were written, at most a second behind. Times
%% 	are milliseconds of system time. A key is absent until it is known.
%%
%% 	No process is asked.
asp_states() ->
	Rows = try
		ets:tab2list(?TABLE)
	catch
		error:badarg ->
			[]
	end,
	Endpoints = [{EP, Row} || {{endpoint, EP}, Row} <- Rows,
			is_process_alive(EP)],
	Associations = [Row#{fsm => Fsm} || {{association, Fsm}, Row} <- Rows,
			is_process_alive(Fsm)],
	lists:flatmap(fun({EP, Row}) ->
				asp_states(EP, Row, Associations)
			end, Endpoints).

%% @hidden
asp_states(EP, #{name := Name, mode := Mode} = Row, Associations) ->
	Endpoint = Row#{ep => EP},
	case [A || #{ep := E} = A <- Associations, E == EP] of
		[] when Mode == connect ->
			[{Name, Endpoint#{assoc_state => connecting}}];
		[] ->
			[{Name, Endpoint#{assoc_state => down}}];
		Carried ->
			[{Name, (maps:merge(Endpoint,
					maps:without([ep, fsm, name], A)))#{assoc_state => up}}
					|| A <- Carried]
	end.

%%----------------------------------------------------------------------
%%  The m3ua_status private API
%%----------------------------------------------------------------------

-spec new() -> ok.
%% @doc Create the table, in the calling process.
%% @private
new() ->
	_ = ets:new(?TABLE, [set, public, named_table,
			{read_concurrency, true}, {write_concurrency, true}]),
	ok.

-spec endpoint(Fields :: map()) -> ok.
%% @doc Write, over what was written before, the calling endpoint's row.
%% @private
endpoint(Fields) ->
	write({endpoint, self()}, Fields).

-spec association(Fields :: map()) -> ok.
%% @doc Write, over what was written before, the calling asp or sgp
%% 	state machine's row.
%% @private
association(Fields) ->
	write({association, self()}, Fields).

-spec forget() -> ok.
%% @doc Remove the calling process's rows.
%% @private
forget() ->
	try
		true = ets:delete(?TABLE, {endpoint, self()}),
		true = ets:delete(?TABLE, {association, self()}),
		ok
	catch
		error:badarg ->
			ok
	end.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

%% @hidden
%% 	A table that is not there -- m3ua_sup gone, or a state machine
%% 	started outside the application, as a test may -- costs the status
%% 	and nothing else.
write(Key, Fields) ->
	try
		Row = case ets:lookup(?TABLE, Key) of
			[{Key, Old}] ->
				maps:merge(Old, Fields);
			[] ->
				Fields
		end,
		true = ets:insert(?TABLE, {Key, Row}),
		ok
	catch
		error:badarg ->
			ok
	end.
