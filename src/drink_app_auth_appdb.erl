%%%-------------------------------------------------------------------
%%% File    : drink_app_auth_appdb.erl
%%% Author  : Dan Willemsen <dan@csh.rit.edu>
%%% Purpose : 
%%%
%%%
%%% edrink, Copyright (C) 2010 Dan Willemsen
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%                         
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%-------------------------------------------------------------------

-module (drink_app_auth_appdb).
-behaviour (gen_server).

-export ([start_link/0]).
-export ([init/1, terminate/2, code_change/3]).
-export ([handle_call/3, handle_cast/2, handle_info/2]).

-export ([new/1, delete/1, get/1, modify/1, list/0]).

-include ("app_auth.hrl").
-record (state, {}).

start_link () ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init ([]) ->
    case filelib:is_file("mnesia_data/schema.DAT") of
        false -> mnesia:create_schema([node()]);
        true -> ok
    end,
    ok = mnesia:start(),
    case mnesia:create_table(auth_appdb, [
            {disc_copies, [node()]},
            {ram_copies, []},
            {record_name, app},
            {attributes, record_info(fields, app)}]) of
        {atomic, ok} -> ok;
        {aborted, {already_exists, _}} -> ok;
        E -> error_logger:error_msg("Got mnesia error: ~p~n", [E])
    end,
    {ok, #state{}}.

terminate (_Reason, _State) ->
    ok.

code_change (_OldVsn, State, _Extra) ->
    {ok, State}.

handle_cast (_Request, State) -> {noreply, State}.

handle_call ({new, App}, _From, State) ->
    case mnesia:transaction(fun() ->
        case mnesia:read(auth_appdb, App#app.name) of
            [_App] -> {abort, mnesia};
            [] -> mnesia:write(auth_appdb, App, write)
        end
    end) of
        {atomic, ok} ->
            dw_events:send(auth_apps, {app_new, App}),
            {reply, ok, State};
        _ -> {reply, {error, mnesia}, State}
    end;
handle_call ({delete, Name}, _From, State) ->
    case mnesia:transaction(fun() -> mnesia:delete({auth_appdb, Name}) end) of
        {atomic, ok} -> 
            dw_events:send(auth_apps, {app_deleted, Name}),
            {reply, ok, State};
        _ -> {reply, {error, mnesia}, State}
    end;
handle_call ({get, Name}, _From, State) ->
    case mnesia:transaction(fun() -> mnesia:read(auth_appdb, Name) end) of
        {atomic, [App]} -> {reply, {ok, App}, State};
        {atomic, []} -> {reply, {error, not_found}, State};
        _ -> {reply, {error, mnesia}, State}
    end;
handle_call ({modify, App}, _From, State) ->
    {reply, {error, not_implemented}, State};
handle_call ({list}, _From, State) ->
    case mnesia:transaction(fun() -> mnesia:all_keys(auth_appdb) end) of
        {atomic, List} -> {reply, {ok, List}, State};
        _ -> {reply, {error, mnesia}, State}
    end;
handle_call (_Request, _From, State) -> {noreply, State}.

handle_info (_Info, State) -> {noreply, State}.

new(App = #app{}) ->
    gen_server:call(?MODULE, {new, App}).
delete(Name) ->
    gen_server:call(?MODULE, {delete, Name}).
get(Name) ->
    gen_server:call(?MODULE, {get, Name}).
modify(App = #app{}) ->
    gen_server:call(?MODULE, {modify, App}).
list() ->
    gen_server:call(?MODULE, {list}).

