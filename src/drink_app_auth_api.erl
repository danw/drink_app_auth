%%%-------------------------------------------------------------------
%%% File    : drink_app_auth_api.erl
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

-module (drink_app_auth_api).

-include ("app_auth.hrl").
-compile (export_all).

% Public App API ------------
app_register(Name, Owner, Description, RequestedPerms)
        when is_atom(Name), is_list(Owner), is_list(Description), is_list(RequestedPerms) ->
    drink_app_auth_appdb:new(#app{ name = Name, owner = Owner, description = Description,
                                   owner_only = true, trusted = false, requested_perms = RequestedPerms }).

app_delete(Name) when is_atom(Name) ->
    drink_app_auth_appdb:delete(Name).

app_get(Name) ->
    drink_app_auth_appdb:get(Name).

app_modify(App = #app{})  ->
    drink_app_auth_appdb:modfiy(App).

app_list() ->
    drink_app_auth_appdb:list().

% Invalidate all keys for an app (AppKey, SessionKeys, LoginKeys)
app_invalidate_keys(Name) when is_atom(Name) ->
    ok.

% Public Auth API ------------
% Request from app for UserName authentication
auth_request(AppKey, UserName) when is_list(AppKey), is_list(UserName) ->
    {ok, sessionKey}.

auth_cancel(SessionKey) when is_list(SessionKey) ->
    ok.

% Response to app / polling
auth_link_app(AppKey, SessionKey) when is_list(AppKey), is_list(SessionKey) ->
    {ok, loginKey}.

% App coming in later
auth_login(LoginKey) when is_list(LoginKey) ->
    ok.

auth_destroy(LoginKey) when is_list(LoginKey) ->
    ok.

% Public Link API -----------------
% Approval from user(through web) that the Perms can be granted
user_approve(SessionKey, UserName, Perms) when is_list(SessionKey), is_list(UserName), is_list(Perms) ->
    {ok}.

user_reject(SessionKey) when is_list(SessionKey) ->
    ok.

user_approved_apps(UserName) when is_list(UserName) ->
    [].%{Name, Perms}].

user_modify_perms(UserName, Name, Perms) when is_list(UserName), is_atom(Name), is_list(Perms) ->
    ok.

user_remove_app(UserName, Name) when is_list(UserName), is_atom(Name) ->
    ok.
