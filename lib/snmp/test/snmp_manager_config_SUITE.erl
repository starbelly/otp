%% 
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2004-2025. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%% 

%%----------------------------------------------------------------------
%% Purpose:
%% 
%% Test:
%% ts:run().
%% ts:run(snmp, [batch]).
%% ts:run(snmp, snmp_manager_config_SUITE, [batch]).
%% 
%%----------------------------------------------------------------------
-module(snmp_manager_config_SUITE).


%%----------------------------------------------------------------------
%% Include files
%%----------------------------------------------------------------------
-include_lib("common_test/include/ct.hrl").
-include("snmp_test_lib.hrl").
-include_lib("snmp/src/manager/snmpm_usm.hrl").
-include_lib("snmp/src/app/snmp_internal.hrl").


%%----------------------------------------------------------------------
%% External exports
%%----------------------------------------------------------------------
%% -compile(export_all).

-export([
         suite/0, all/0, groups/0,
	 init_per_suite/1,    end_per_suite/1, 
	 init_per_group/2,    end_per_group/2, 
	 init_per_testcase/2, end_per_testcase/2, 


	 simple_start_and_stop/1,
	 start_without_mandatory_opts1/1,
	 start_without_mandatory_opts2/1,
	 start_with_all_valid_opts/1,
	 start_with_unknown_opts/1,
	 start_with_incorrect_opts/1,
	 start_with_invalid_manager_conf_file1/1,
	 start_with_invalid_users_conf_file1/1,
	 start_with_invalid_agents_conf_file1/1,
	 start_with_invalid_usm_conf_file1/1,
         start_with_create_db_and_dir_opt/1,

	
	 simple_system_op/1,

	
	 register_user_using_file/1,
	 register_user_using_function/1,
	 register_user_failed_using_function1/1,

	
	 register_agent_using_file/1,
	 register_agent_using_function/1,
	 register_agent_failed_using_function1/1,

	
	 register_usm_user_using_file/1,
	 register_usm_user_using_function/1,
	 register_usm_user_failed_using_function1/1,
	 update_usm_user_info/1, 

	
	 create_and_increment/1,

	
	 stats_create_and_increment/1,

	
	 otp_7219/1, 
	 
	 otp_8395_1/1, 
	 otp_8395_2/1, 
	 otp_8395_3/1, 
	 otp_8395_4/1

	]).


%%----------------------------------------------------------------------
%% Internal exports
%%----------------------------------------------------------------------
-export([
        ]).


%%----------------------------------------------------------------------
%% Macros
%%----------------------------------------------------------------------


%%----------------------------------------------------------------------
%% Records
%%----------------------------------------------------------------------


%%======================================================================
%% Common Test interface functions
%%======================================================================

suite() -> 
    [{ct_hooks, [ts_install_cth]}].


all() -> 
    [
     {group, start_and_stop},
     {group, normal_op},
     {group, tickets}
    ].

groups() -> 
    [
     {start_and_stop, [], start_and_stop_cases()},
     {normal_op,      [], normal_op_cases()},
     {system,         [], system_cases()},
     {users,          [], users_cases()},
     {agents,         [], agents_cases()},
     {usm_users,      [], usm_users_cases()},
     {counter,        [], counter_cases()},
     {stats_counter,  [], stats_counter_cases()},
     {tickets,        [], tickets_cases()},
     {otp_8395,       [], otp_8395_cases()}
    ].

start_and_stop_cases() ->
    [
     simple_start_and_stop, 
     start_without_mandatory_opts1,
     start_without_mandatory_opts2,
     start_with_all_valid_opts,
     start_with_unknown_opts,
     start_with_incorrect_opts,
     start_with_create_db_and_dir_opt,
     start_with_invalid_manager_conf_file1,
     start_with_invalid_users_conf_file1,
     start_with_invalid_agents_conf_file1,
     start_with_invalid_usm_conf_file1
    ].

normal_op_cases() ->
    [
     {group, system}, 
     {group, agents}, 
     {group, users},
     {group, usm_users}, 
     {group, counter},
     {group, stats_counter}
    ].

system_cases() ->
    [
     simple_system_op
    ].

users_cases() ->
    [
     register_user_using_file, 
     register_user_using_function,
     register_user_failed_using_function1
    ].

agents_cases() ->
    [
     register_agent_using_file,
     register_agent_using_function,
     register_agent_failed_using_function1
    ].

usm_users_cases() ->
    [
     register_usm_user_using_file,
     register_usm_user_using_function,
     register_usm_user_failed_using_function1,
     update_usm_user_info
    ].

counter_cases() ->
    [
     create_and_increment
    ].

stats_counter_cases() ->
    [
     stats_create_and_increment
    ].

tickets_cases() ->
    [
     otp_7219,
     {group, otp_8395}
    ].

otp_8395_cases() ->
    [
     otp_8395_1,
     otp_8395_2,
     otp_8395_3,
     otp_8395_4
    ].


init_per_suite(Config0) when is_list(Config0) ->

    ?IPRINT("init_per_suite -> entry with"
            "~n      Config0: ~p", [Config0]),

    case ?LIB:init_per_suite(Config0) of
        {skip, _} = SKIP ->
            SKIP;

        Config1 ->

            Config2 = snmp_test_lib:init_suite_top_dir(?MODULE, Config1), 

            %% We need one on this node also
            snmp_test_sys_monitor:start(),

            ?IPRINT("init_per_suite -> try ensure snmpm_config not running"),

            config_ensure_not_running(),

            ?IPRINT("init_per_suite -> end when"
                    "~n   Config: ~p", [Config2]),

            Config2
    end.

end_per_suite(Config0) when is_list(Config0) ->

    ?IPRINT("end_per_suite -> entry with"
            "~n   Config0: ~p", [Config0]),

    snmp_test_sys_monitor:stop(),
    Config1 = ?LIB:end_per_suite(Config0),

    ?IPRINT("end_per_suite -> end"),

    Config1.


init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.


init_per_testcase(Case, Config) when is_list(Config) ->
    ?IPRINT("init_per_testcase -> entry with"
            "~n   Config: ~p", [Config]),

    snmp_test_global_sys_monitor:reset_events(),

    SuiteTopDir = ?config(snmp_suite_top_dir, Config),
    CaseTopDir  = filename:join(SuiteTopDir, atom_to_list(Case)),
    ok    = file:make_dir(CaseTopDir),

    ?IPRINT("init_per_testcase -> CaseTopDir: ~p", [CaseTopDir]),
    MgrTopDir   = filename:join(CaseTopDir, "manager/"),
    ok    = file:make_dir(MgrTopDir),
    MgrConfDir  = filename:join(MgrTopDir, "conf/"),
    ok    = file:make_dir(MgrConfDir),
    MgrDbDir    = filename:join(MgrTopDir, "db/"),
    case Case of
	start_with_create_db_and_dir_opt ->
	    ok;
	_ ->
	    ok = file:make_dir(MgrDbDir)
    end,
    MgrLogDir   = filename:join(MgrTopDir,   "log/"),
    ok    = file:make_dir(MgrLogDir),
    Config1 = [{case_top_dir,     CaseTopDir},
               {manager_dir,      MgrTopDir},
               {manager_conf_dir, MgrConfDir},
               {manager_db_dir,   MgrDbDir},
               {manager_log_dir,  MgrLogDir} | Config],

    ?IPRINT("init_per_testcase -> done when"
            "~n   Config1:  ~p", [Config1]),

    Config1.


end_per_testcase(_Case, Config) when is_list(Config) ->

    ?IPRINT("end_per_testcase -> entry with"
            "~n   Config: ~p", [Config]),

    ?IPRINT("system events during test: "
            "~n   ~p", [snmp_test_global_sys_monitor:events()]),

    %% The cleanup is removed due to some really disgusting NFS behaviour...
    %% Also, it can always be useful to retain "all the stuff" after
    %% the test case in case of debugging...
    Config.


%%======================================================================
%% Test functions
%%======================================================================

%% 
%% ---
%% 

simple_start_and_stop(suite) -> [];
simple_start_and_stop(doc) ->
    "Start the snmp manager config process with the \n"
	"minimum setof options (config dir).";
simple_start_and_stop(Conf) when is_list(Conf) ->
    put(tname, "SIMPLE_START_AND_STOP"),
    process_flag(trap_exit, true),
    Pre = fun() ->
                  %% Since this is the first test case in this
                  %% suite, we (possibly) need to do some cleanup...
                  ?IPRINT("~w:pre -> ensure config not already running",
                          [?FUNCTION_NAME]),
                  config_ensure_not_running()
          end,
    TC  = fun(_) ->
                  ?IPRINT("~w:tc -> begin", [?FUNCTION_NAME]),
                  do_simple_start_and_stop(Conf)
          end,
    Post = fun(_) ->
                   ?IPRINT("~w:post -> ensure config not still running",
                           [?FUNCTION_NAME]),
                   config_ensure_not_running()
           end,
    ?TC_TRY(?FUNCTION_NAME, Pre, TC, Post).

do_simple_start_and_stop(Conf) when is_list(Conf) ->
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir   = ?config(manager_db_dir, Conf),

    ?IPRINT("~w -> try write \"standard\" manager config to"
            "~n   ~p", [?FUNCTION_NAME, ConfDir]),
    write_manager_conf(ConfDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    ?IPRINT("~w -> try start with basic opts", [?FUNCTION_NAME]),
    {ok, _Pid} = snmpm_config:start_link(Opts),

    ?IPRINT("~w -> try stop", [?FUNCTION_NAME]),
    ok = snmpm_config:stop(),

    ?IPRINT("~w -> done", [?FUNCTION_NAME]),
    ok.


%% 
%% ---
%% 

start_without_mandatory_opts1(suite) -> [];
start_without_mandatory_opts1(doc) ->
    "Start the snmp manager config process with some of the \n"
	"mandatory options missing.";
start_without_mandatory_opts1(Conf) when is_list(Conf) ->
    put(tname, "START-WO-MAND-OPTS-1"),
    put(verbosity, trace),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    write_manager_conf(ConfDir),
    

    %% config, but no dir:
    ?IPRINT("config option, but no dir"),
    Opts = [{priority, normal}, 
	    {config, [{verbosity, trace}, {db_dir, DbDir}]}, {mibs, []}],
    {error, {missing_mandatory,dir}} = config_start(Opts),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_without_mandatory_opts2(suite) -> [];
start_without_mandatory_opts2(doc) ->
    "Start the snmp manager config process with some of the \n"
	"mandatory options missing.";
start_without_mandatory_opts2(Conf) when is_list(Conf) ->
    put(tname, "START-WO-MAND-OPTS-2"),
    put(verbosity,trace),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),

    write_manager_conf(ConfDir),
    

    %% Second set of options (no config):
    ?IPRINT("no config option"),
    Opts = [{priority, normal}, 
	    {mibs, []}],
    {error, {missing_mandatory,config,[dir, db_dir]}} =
	config_start(Opts),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_all_valid_opts(suite) -> [];
start_with_all_valid_opts(doc) ->
    "Start the snmp manager config process with the \n"
	"complete set of all the valid options.";
start_with_all_valid_opts(Conf) when is_list(Conf) ->
    put(tname, "START-W-ALL-VALID-OPTS"),
    put(tname,swavo),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),
    LogDir  = ?config(manager_log_dir, Conf),
    StdMibDir = filename:join(code:priv_dir(snmp), "mibs") ++ "/",

    write_manager_conf(ConfDir),
    

    %% Third set of options (no versions):
    ?IPRINT("all options"),
    NetIfOpts  = [{module,    snmpm_net_if}, 
		  {verbosity, trace},
		  {options,   [{recbuf,   30000},
			       {bind_to,  false},
			       {no_reuse, false}]}],
    ServerOpts = [{timeout,   ?SECS(10)},
                  {verbosity, trace},
                  {cbproxy,   permanent},
                  {netif_sup, {?SECS(60), ?SECS(5)}}],
    NoteStoreOpts = [{timeout,   ?SECS(20)},
                     {verbosity, trace}],
    ConfigOpts = [{dir,           ConfDir},
                  {verbosity,     trace},
                  {db_dir,        DbDir},
                  {db_init_error, create}],
    Mibs = [join(StdMibDir, "SNMP-NOTIFICATION-MIB"),
	    join(StdMibDir, "SNMP-USER-BASED-SM-MIB")],
    Prio = normal,
    ATL  = [{type,   read_write}, 
	    {dir,    LogDir}, 
	    {size,   {10,10240}},
	    {repair, true}],
    Vsns = [v1,v2,v3],
    Opts = [{config,          ConfigOpts},
	    {net_if,          NetIfOpts},
	    {server,          ServerOpts},
	    {note_store,      NoteStoreOpts},
	    {audit_trail_log, ATL},
	    {priority,        Prio}, 
	    {mibs,            Mibs},
	    {versions,        Vsns}],
    {ok, _Pid} = config_start(Opts),
    ok = config_stop(),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_unknown_opts(suite) -> [];
start_with_unknown_opts(doc) ->
    "Start the snmp manager config process when some of\n"
	"the options are unknown.";
start_with_unknown_opts(Conf) when is_list(Conf) ->
    put(tname, "START-W-UNKNOWN-OPTS"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),
    LogDir  = ?config(manager_log_dir, Conf),
    StdMibDir = filename:join(code:priv_dir(snmp), "mibs") ++ "/",

    write_manager_conf(ConfDir),
    

    %% Third set of options (no versions):
    ?IPRINT("all options"),
    NetIfOpts  = [{module,    snmpm_net_if}, 
		  {verbosity, trace},
		  {options,   [{recbuf,   30000},
			       {bind_to,  false},
			       {no_reuse, false}]}],
    ServerOpts = [{timeout, 10000}, {verbosity, trace}],
    NoteStoreOpts = [{timeout, 20000}, {verbosity, trace}],
    ConfigOpts = [{dir, ConfDir}, {verbosity, trace}, {db_dir, DbDir}],
    Mibs = [join(StdMibDir, "SNMP-NOTIFICATION-MIB"),
	    join(StdMibDir, "SNMP-USER-BASED-SM-MIB")],
    Prio = normal,
    ATL  = [{type,   read_write}, 
	    {dir,    LogDir}, 
	    {size,   {10,10240}},
	    {repair, true}],
    Vsns = [v1,v2,v3],
    Opts = [{config,          ConfigOpts},
	    {net_if,          NetIfOpts},
	    {server,          ServerOpts},
	    {note_store,      NoteStoreOpts},
	    {audit_trail_log, ATL},
	    {unknown_option,  "dummy value"},
	    {priority,        Prio}, 
	    {mibs,            Mibs},
	    {versions,        Vsns}],
    {ok, _Pid} = config_start(Opts),

    ?IPRINT("(config) started - now stop"),
    ok = config_stop(),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_incorrect_opts(suite) -> [];
start_with_incorrect_opts(doc) ->
    "Start the snmp manager config process when some of\n"
	"the options has incorrect values.";
start_with_incorrect_opts(Conf) when is_list(Conf) -> 
    put(tname, "START-W-INCORRECT-OPTS"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),
    LogDir  = ?config(manager_log_dir, Conf),
    StdMibDir = filename:join(code:priv_dir(snmp), "mibs") ++ "/",

    write_manager_conf(ConfDir),
    
    ConfigOpts = [{verbosity,trace}, {dir, ConfDir}, {db_dir, DbDir}],

    ?IPRINT("net-if - incorrect module"),
    NetIfOpts1 = [{module, snmpm_user}],  %% Behaviour check will fail
    Opts01     = [{config, ConfigOpts}, {versions, [v1]}, 
		   {net_if, NetIfOpts1}],
    {error, Reason01} = config_start(Opts01),
    ?IPRINT("net-if (module) res: ~p", [Reason01]),
    
    ?IPRINT("net-if - incorrect verbosity"),
    NetIfOpts2  = [{verbosity, invalid_verbosity}],
    Opts02      = [{config, ConfigOpts}, {versions, [v1]}, 
		   {net_if, NetIfOpts2}],
    {error, Reason02} = config_start(Opts02),
    ?IPRINT("net-if (verbosity) res: ~p", [Reason02]),

    ?IPRINT("net-if - incorrect options"),
    NetIfOpts3 = [{options, invalid_options}],
    Opts03     = [{config, ConfigOpts}, {versions, [v1]}, 
		  {net_if, NetIfOpts3}],
    {error, Reason03} = config_start(Opts03),
    ?IPRINT("net-if (options) res: ~p", [Reason03]),
		   
    ?IPRINT("server - incorrect timeout (1)"),
    ServerOpts1 = [{timeout, invalid_timeout}],
    Opts08      = [{config, ConfigOpts}, {versions, [v1]}, 
		   {server, ServerOpts1}],
    {error, Reason08} = config_start(Opts08),
    ?IPRINT("server (timeout) res: ~p", [Reason08]),

    ?IPRINT("server - incorrect timeout (2)"),
    ServerOpts2 = [{timeout, 0}],
    Opts09      = [{config, ConfigOpts}, {versions, [v1]}, 
		   {server, ServerOpts2}],
    {error, Reason09} = config_start(Opts09),
    ?IPRINT("server (timeout) res: ~p", [Reason09]),

    ?IPRINT("server - incorrect timeout (3)"),
    ServerOpts3 = [{timeout, -1000}],
    Opts10      = [{config, ConfigOpts}, 
		   {versions, [v1]}, 
		   {server, ServerOpts3}],
    {error, Reason10} = config_start(Opts10),
    ?IPRINT("server (timeout) res: ~p", [Reason10]),

    ?IPRINT("server - incorrect verbosity"),
    ServerOpts4 = [{verbosity, invalid_verbosity}],
    Opts11      = [{config, ConfigOpts}, 
		   {versions, [v1]}, 
		   {server, ServerOpts4}],
    {error, Reason11} = config_start(Opts11),
    ?IPRINT("server (verbosity) res: ~p", [Reason11]),

    ?IPRINT("note-store - incorrect timeout (1)"),
    NoteStoreOpts1 = [{timeout, invalid_timeout}],
    Opts12         = [{config, ConfigOpts}, 
		      {versions, [v1]}, 
		      {note_store, NoteStoreOpts1}],
    {error, Reason12} = config_start(Opts12),
    ?IPRINT("note-store (timeout) res: ~p", [Reason12]),

    ?IPRINT("note-store - incorrect timeout (2)"),
    NoteStoreOpts2 = [{timeout, 0}],
    Opts13         = [{config, ConfigOpts}, 
		      {versions, [v1]}, 
		      {note_store, NoteStoreOpts2}],
    {error, Reason13} = config_start(Opts13),
    ?IPRINT("note-store (timeout) res: ~p", [Reason13]),

    ?IPRINT("note-store - incorrect timeout (3)"),
    NoteStoreOpts3 = [{timeout, -2000}],
    Opts14         = [{config, ConfigOpts}, 
		      {versions, [v1]}, 
		      {note_store, NoteStoreOpts3}],
    {error, Reason14} = config_start(Opts14),
    ?IPRINT("note-store (timeout) res: ~p", [Reason14]),

    ?IPRINT("note-store - incorrect verbosity"),
    NoteStoreOpts4 = [{timeout, 20000}, {verbosity, invalid_verbosity}],
    Opts15         = [{config, ConfigOpts}, 
		      {versions, [v1]}, 
		      {note_store, NoteStoreOpts4}],
    {error, Reason15} = config_start(Opts15),
    ?IPRINT("note-store (verbosity) res: ~p", [Reason15]),

    ?IPRINT("config - incorrect dir (1)"),
    ConfigOpts1 = [{dir, invalid_dir}],
    Opts16      = [{config, ConfigOpts1}, 
		   {versions, [v1]}],
    {error, Reason16} = config_start(Opts16),
    ?IPRINT("config (dir) res: ~p", [Reason16]),

    ?IPRINT("config - incorrect dir (2)"),
    ConfigOpts2 = [{dir, "/invalid/dir"}],
    Opts17      = [{config, ConfigOpts2}, 
		   {versions, [v1]}],
    {error, Reason17} = config_start(Opts17),
    ?IPRINT("config (dir) res: ~p", [Reason17]),

    ?IPRINT("config - incorrect verbosity"),
    ConfigOpts3 = [{dir, ConfDir}, {verbosity, invalid_verbosity}],
    Opts18      = [{config, ConfigOpts3}, 
		   {versions, [v1]}],
    {error, Reason18} = config_start(Opts18),
    ?IPRINT("config (verbosity) res: ~p", [Reason18]),

    ?IPRINT("mibs - incorrect mibs (1)"),
    Mibs1  = invalid_mibs,
    Opts19 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {mibs, Mibs1}],
    {error, Reason19} = config_start(Opts19),
    ?IPRINT("mibs (mibs) res: ~p", [Reason19]),

    ?IPRINT("mibs - incorrect mibs (2)"),
    Mibs2  = [join(StdMibDir, "INVALID-MIB")],
    Opts20 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {mibs, Mibs2}],
    {error, Reason20} = config_start(Opts20),
    ?IPRINT("mibs (mibs) res: ~p", [Reason20]),

    ?IPRINT("prio - incorrect prio"),
    Prio1 = invalid_prio,
    Opts21 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {priority, Prio1}],
    {error, Reason21} = config_start(Opts21),
    ?IPRINT("prio (prio) res: ~p", [Reason21]),

    ?IPRINT("atl - incorrect type"),
    ATL1  = [{type,   invalid_type}, 
	     {dir,    LogDir}, 
	     {size,   {10,10240}},
	     {repair, true}],
    Opts22 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL1}],
    {error, Reason22} = config_start(Opts22),
    ?IPRINT("atl (type) res: ~p", [Reason22]),

    ?IPRINT("atl - incorrect dir (1)"),
    ATL2  = [{type,   read_write}, 
	     {dir,    invalid_dir}, 
	     {size,   {10,10240}},
	     {repair, true}],
    Opts23 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL2}],
    {error, Reason23} = config_start(Opts23),
    ?IPRINT("atl (dir) res: ~p", [Reason23]),

    ?IPRINT("atl - incorrect dir (2)"),
    ATL3  = [{type,   read_write}, 
	     {dir,    "/invalid/dir"}, 
	     {size,   {10,10240}},
	     {repair, true}],
    Opts24 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL3}],
    {error, Reason24} = config_start(Opts24),
    ?IPRINT("atl (dir) res: ~p", [Reason24]),

    ?IPRINT("atl - incorrect size (1)"),
    ATL4  = [{type,   read_write}, 
	     {dir,    LogDir}, 
	     {size,   invalid_size},
	     {repair, true}],
    Opts25 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL4}],
    {error, Reason25} = config_start(Opts25),
    ?IPRINT("atl (size) res: ~p", [Reason25]),

    ?IPRINT("atl - incorrect size (2)"),
    ATL5  = [{type,   read_write}, 
	     {dir,    LogDir}, 
	     {size,   {10,invalid_file_size}},
	     {repair, true}],
    Opts26 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL5}],
    {error, Reason26} = config_start(Opts26),
    ?IPRINT("atl (size) res: ~p", [Reason26]),

    ?IPRINT("atl - incorrect size (3)"),
    ATL6  = [{type,   read_write}, 
	     {dir,    LogDir}, 
	     {size,   {invalid_file_num,10240}},
	     {repair, true}],
    Opts27 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL6}],
    {error, Reason27} = config_start(Opts27),
    ?IPRINT("atl (size) res: ~p", [Reason27]),

    ?IPRINT("atl - incorrect repair"),
    ATL7  = [{type,   read_write}, 
	     {dir,    LogDir}, 
	     {size,   {10,10240}},
	     {repair, invalid_repair}],
    Opts28 = [{config, ConfigOpts}, 
	      {versions, [v1]}, 
	      {audit_trail_log, ATL7}],
    {error, Reason28} = config_start(Opts28),
    ?IPRINT("atl (repair) res: ~p", [Reason28]),

    ?IPRINT("version - incorrect versions (1)"),
    Vsns1  = invalid_vsns,
    Opts29 = [{config, ConfigOpts}, 
	      {versions, Vsns1}],
    {error, Reason29} = config_start(Opts29),
    ?IPRINT("versions (versions) res: ~p", [Reason29]),

    ?IPRINT("version - incorrect versions (2)"),
    Vsns2  = [v1,v2,v3,v9],
    Opts30 = [{config, ConfigOpts}, 
	      {versions, Vsns2}],
    {error, Reason30} = config_start(Opts30),
    ?IPRINT("versions (versions) res: ~p", [Reason30]),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_invalid_manager_conf_file1(suite) -> [];
start_with_invalid_manager_conf_file1(doc) ->
    "Start with invalid manager config file (1).";
start_with_invalid_manager_conf_file1(Conf) when is_list(Conf) -> 
    put(tname, "START-W-INV-MGR-CONF-FILE-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    %% --
    ?IPRINT("write manager config file with invalid IP address (1)"),
    write_manager_conf(ConfDir, 
		       "arne-anka", "4001", "500", "\"bmkEngine\""),
    {error, Reason11} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason11]),
    {failed_reading, _, _, 1, {parse_error, _}} = Reason11,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid IP address (2)"),
    write_manager_conf(ConfDir, 
		       "arne_anka", "4001", "500", "\"bmkEngine\""),
    {error, Reason12} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason12]),
    {failed_check, _, _, 2, {bad_address, _}} = Reason12,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid IP address (3)"),
    write_manager_conf(ConfDir, 
		       "9999", "4001", "500", "\"bmkEngine\""),
    {error, Reason13} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason13]),
    {failed_check, _, _, 2, {bad_address, _}} = Reason13,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid port (2)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "kalle-anka", "500", "\"bmkEngine\""),
    {error, Reason21} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason21]),
    {failed_reading, _, _, 2, {parse_error, _}} = Reason21,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid port (1)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "-1", "500", "\"bmkEngine\""),
    {error, Reason22} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason22]),
    io:format("Reason22: ~p~n", [Reason22]),
   {failed_check, _, _, 3, {bad_port, _}} = Reason22,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid port (3)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "\"kalle-anka\"", "500", "\"bmkEngine\""),
    {error, Reason23} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason23]),
    {failed_check, _, _, 3, {bad_port, _}} = Reason23,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid EngineID (1)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "500", "bmkEngine"),
    {error, Reason31} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason31]),
    {failed_check, _, _, 5, {invalid_string, _}} = Reason31,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid EngineID (2)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "500", "{1,2,3}"),
    {error, Reason32} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason32]),
    {failed_check, _, _, 5, {invalid_string, _}} = Reason32,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid EngineID (3)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "500", "10101"),
    {error, Reason33} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason33]),
    {failed_check, _, _, 5, {invalid_string, _}} = Reason33,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid MMS (1)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "483", "\"bmkEngine\""),
    {error, Reason41} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason41]),
    {failed_check, _, _, 4, {invalid_integer, _}} = Reason41,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid MMS (2)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "-1", "\"bmkEngine\""),
    {error, Reason42} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason42]),
    {failed_check, _, _, 4, {invalid_integer, _}} = Reason42,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid MMS (3)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "\"kalle-anka\"", "\"bmkEngine\""),
    {error, Reason43} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason43]),
    {failed_check, _, _, 4, {invalid_integer, _}} = Reason43,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with invalid MMS (4)"),
    write_manager_conf(ConfDir, 
		       "[134,138,177,189]", "4001", "kalle_anka", "\"bmkEngine\""),
    {error, Reason44} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason44]),
    {failed_check, _, _, 4, {invalid_integer, _}} = Reason44,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with unknown option"),
    write_manager_conf(ConfDir, 
		       "{kalle, anka}."),
    {error, Reason51} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51]),
    {failed_check, _, _, 1, {unknown_config, _}} = Reason51,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write manager config file with unknown option"),
    write_manager_conf(ConfDir, 
		       "kalle_anka."),
    {error, Reason52} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason52]),
    {failed_check, _, _, 1, {unknown_config, _}} = Reason52,
    config_ensure_not_running(),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_invalid_users_conf_file1(suite) -> [];
start_with_invalid_users_conf_file1(doc) ->
    "Start with invalid users config file.";
start_with_invalid_users_conf_file1(Conf) when is_list(Conf) -> 
    put(tname, "START-W-INV-USER-CONF-FILE-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir   = ?config(manager_db_dir, Conf),

    verify_dir_existing(conf, ConfDir),
    verify_dir_existing(db,   DbDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    write_manager_conf(ConfDir),

    %% --
    ?IPRINT("write users config file with invalid module (1)"),
    write_users_conf(ConfDir, [{"kalle", "kalle", "dummy"}]),
    {error, Reason11} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason11]),
    {failed_check, _, _, _, {bad_module, kalle}} = Reason11,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid module (1)"),
    write_users_conf(ConfDir, [{"kalle", "snmpm", "dummy"}]),
    {error, Reason12} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason12]),
    {failed_check, _, _, _, {bad_module, _}} = Reason12,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid module (2)"),
    write_users_conf(ConfDir, [{"kalle1", "10101", "dummy"}]),
    {error, Reason13} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason13]),
    {failed_check, _, _, _, {bad_module, _}} = Reason13,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user tuple (1)"),
    write_users_conf2(ConfDir, "{kalle, snmpm_user_default}."),
    {error, Reason21} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason21]),
    {failed_check, _, _, _, {bad_user_config, _}} = Reason21,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user tuple (2)"),
    write_users_conf2(ConfDir, "{kalle, snmpm_user_default, kalle, [], olle}."),
    {error, Reason22} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason22]),
    {failed_check, _, _, _, {bad_user_config, _}} = Reason22,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user tuple (3)"),
    write_users_conf2(ConfDir, "snmpm_user_default."),
    {error, Reason23} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason23]),
    {failed_check, _, _, _, {bad_user_config, _}} = Reason23,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user tuple (4)"),
    write_users_conf2(ConfDir, "[kalle, snmpm_user_default, kalle]."),
    {error, Reason24} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason24]),
    {failed_check, _, _, _, {bad_user_config, _}} = Reason24,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user agent default config (1)"),
    write_users_conf2(ConfDir, "{kalle, snmpm_user_default, kalle, olle}."),
    {error, Reason31} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason31]),
    {failed_check, _, _, _, {bad_default_agent_config, _}} = Reason31,
    config_ensure_not_running(),

    %% --
    ?IPRINT("write users config file with invalid user agent default config (2)"),
    write_users_conf2(ConfDir, "{kalle, snmpm_user_default, kalle, [olle]}."),
    {error, Reason32} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason32]),
    %% {failed_check, _, _, _, {bad_default_agent_config, _}} = Reason32,
    case Reason32 of
	{failed_check, _, _, _, {bad_default_agent_config, _}} ->
	    ok;
	{A, B, C, D} ->
	    exit({bad_error, A, B, C, D})
    end,
    config_ensure_not_running(),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_invalid_agents_conf_file1(suite) -> [];
start_with_invalid_agents_conf_file1(doc) ->
    "Start with invalid agents config file.";
start_with_invalid_agents_conf_file1(Conf) when is_list(Conf) -> 
    put(tname, "START-W-INV-AGS-CONF-FILE-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir   = ?config(manager_db_dir, Conf),

    verify_dir_existing(conf, ConfDir),
    verify_dir_existing(db,   DbDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    write_manager_conf(ConfDir),

    write_users_conf(ConfDir, [{"swiacf", "snmpm_user_default", "dummy"}]),
    
    Agent0 = {"swiacf", "\"targ-hobbes\"", "\"comm1\"", 
	      "[192,168,0,100]", "162", "\"bmkEngine\"", "1500", "484", "v1",
	      "any", "\"initial\"", "noAuthNoPriv"},

    %% --
    ?IPRINT("[test 11] write agents config file with invalid user (1)"),
    Agent11 = setelement(1, Agent0, "kalle-anka"),
    write_agents_conf(ConfDir, [Agent11]),
    case config_start(Opts) of
	{error, Reason11} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason11]),
	    {failed_reading, _, _, _, {parse_error, _}} = Reason11,
	    config_ensure_not_running();
	OK_11 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "11", OK_11}})
    end,

    %% --
    ?IPRINT("[test 21] write agents config file with invalid target name (1)"),
    Agent21 = setelement(2, Agent0, "targ-hobbes"),
    write_agents_conf(ConfDir, [Agent21]),
    case config_start(Opts) of
	{error, Reason21} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason21]),
	    {failed_reading, _, _, _, {parse_error, _}} = Reason21,
	    config_ensure_not_running();
	OK_21 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "21", OK_21}})
    end,

    %% --
    ?IPRINT("[test 22] write agents config file with invalid target name (2)"),
    Agent22 = setelement(2, Agent0, "targ_hobbes"),
    write_agents_conf(ConfDir, [Agent22]),
    case config_start(Opts) of
	{error, Reason22} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason22]),
	    {failed_check, _, _, _, {invalid_string, _}} = Reason22,
	    config_ensure_not_running();
	OK_22 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "22", OK_22}})
    end,

    %% --
    ?IPRINT("[test 23] write agents config file with invalid target name (3)"),
    Agent23 = setelement(2, Agent0, "10101"),
    write_agents_conf(ConfDir, [Agent23]),
    case config_start(Opts) of
	{error, Reason23} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason23]),
	    {failed_check, _, _, _, {invalid_string, _}} = Reason23,
	    config_ensure_not_running();
	OK_23 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "23", OK_23}})
    end,

    %% --
    ?IPRINT("[test 31] write agents config file with invalid community (1)"),
    Agent31 = setelement(3, Agent0, "targ-hobbes"),
    write_agents_conf(ConfDir, [Agent31]),
    case config_start(Opts) of
	{error, Reason31} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason31]),
	    {failed_reading, _, _, _, {parse_error, _}} = Reason31,
	    config_ensure_not_running();
	OK_31 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "31", OK_31}})
    end,

    %% --
    ?IPRINT("[test 32] write agents config file with invalid community (2)"),
    Agent32 = setelement(3, Agent0, "targ_hobbes"),
    write_agents_conf(ConfDir, [Agent32]),
    case config_start(Opts) of
	{error, Reason32} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason32]),
	    {failed_check, _, _, _, {invalid_string, _}} = Reason32,
	    config_ensure_not_running();
	OK_32 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "32", OK_32}})
    end,

    %% --
    ?IPRINT("[test 33] write agents config file with invalid community (3)"),
    Agent33 = setelement(3, Agent0, "10101"),
    write_agents_conf(ConfDir, [Agent33]),
    case config_start(Opts) of
	{error, Reason33} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason33]),
	    {failed_check, _, _, _, {invalid_string, _}} = Reason33,
	    config_ensure_not_running();
	OK_33 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "33", OK_33}})
    end,

    %% --
    ?IPRINT("[test 51] write agents config file with invalid ip (1)"),
    Agent51 = setelement(4, Agent0, "kalle_anka"),
    write_agents_conf(ConfDir, [Agent51]),
    case config_start(Opts) of
	{error, Reason51} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason51]),
	    {failed_check, _, _, _, {bad_domain, _}} = Reason51,
	    config_ensure_not_running();
	OK_51 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "51", OK_51}})
    end,

    %% --
    ?IPRINT("[test 52] write agents config file with invalid ip (2)"),
    Agent52 = setelement(4, Agent0, "10101"),
    write_agents_conf(ConfDir, [Agent52]),
    case config_start(Opts) of
	{error, Reason52} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason52]),
	    {failed_check, _, _, _, {bad_address, _}} = Reason52,
	    config_ensure_not_running();
	OK_52 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "52", OK_52}})
    end,

    %% --
    ?IPRINT("[test 53] write agents config file with invalid ip (3)"),
    Agent53 = setelement(4, Agent0, "[192,168,0]"),
    write_agents_conf(ConfDir, [Agent53]),
    case config_start(Opts) of
	{error, Reason53} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason53]),
	    {failed_check, _, _, _, {bad_address, _}} = Reason53,
	    config_ensure_not_running();
	OK_53 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "53", OK_53}})
    end,

    %% --
    ?IPRINT("[test 54] write agents config file with invalid ip (4)"),
    Agent54 = setelement(4, Agent0, "[192,168,0,100,99]"),
    write_agents_conf(ConfDir, [Agent54]),
    case config_start(Opts) of
	{error, Reason54} ->
	    ?IPRINT("start failed (as expected): ~p", [Reason54]),
	    {failed_check, _, _, _, {bad_address, _}} = Reason54,
	    config_ensure_not_running();
	OK_54 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "54", OK_54}})
    end,

    %% --
    ?IPRINT("[test 55] write agents config file with invalid ip (5)"),
    Agent55 = setelement(4, Agent0, "[192,168,0,arne]"),
    write_agents_conf(ConfDir, [Agent55]),
    {error, Reason55} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason55]),
    {failed_check, _, _, _, {bad_address, _}} = Reason55,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 61] write agents config file with invalid port (1)"),
    Agent61 = setelement(5, Agent0, "kalle_anka"),
    write_agents_conf(ConfDir, [Agent61]),
    {error, Reason61} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason61]),
    {failed_check, _, _, _, {bad_address, _}} = Reason61,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 62] write agents config file with invalid port (2)"),
    Agent62 = setelement(5, Agent0, "-1"),
    write_agents_conf(ConfDir, [Agent62]),
    {error, Reason62} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason62]),
    {failed_check, _, _, _, {bad_address, _}} = Reason62,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 63] write agents config file with invalid port (3)"),
    Agent63 = setelement(5, Agent0, "\"100\""),
    write_agents_conf(ConfDir, [Agent63]),
    {error, Reason63} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason63]),
    {failed_check, _, _, _, {bad_address, _}} = Reason63,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 71] write agents config file with invalid engine-id (1)"),
    Agent71 = setelement(6, Agent0, "kalle_anka"),
    write_agents_conf(ConfDir, [Agent71]),
    {error, Reason71} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason71]),
    {failed_check, _, _, _, {invalid_string, _}} = Reason71,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 72] write agents config file with invalid engine-id (2)"),
    Agent72 = setelement(6, Agent0, "10101"),
    write_agents_conf(ConfDir, [Agent72]),
    {error, Reason72} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason72]),
    {failed_check, _, _, _, {invalid_string, _}} = Reason72,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 81] write agents config file with invalid timeout (1)"),
    Agent81 = setelement(7, Agent0, "kalle_anka"),
    write_agents_conf(ConfDir, [Agent81]),
    {error, Reason81} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason81]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason81,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 82] write agents config file with invalid timeout (2)"),
    Agent82 = setelement(7, Agent0, "-1"),
    write_agents_conf(ConfDir, [Agent82]),
    {error, Reason82} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason82]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason82,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 83] write agents config file with invalid timeout (3)"),
    Agent83 = setelement(7, Agent0, "{1000, 1, 10, kalle}"),
    write_agents_conf(ConfDir, [Agent83]),
    {error, Reason83} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason83]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason83,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 84] write agents config file with invalid timeout (4)"),
    Agent84 = setelement(7, Agent0, "{1000, -1, 10, 10}"),
    write_agents_conf(ConfDir, [Agent84]),
    {error, Reason84} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason84]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason84,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 85] write agents config file with invalid timeout (5)"),
    Agent85 = setelement(7, Agent0, "{1000, 1, -100, 10}"),
    write_agents_conf(ConfDir, [Agent85]),
    {error, Reason85} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason85]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason85,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 86] write agents config file with invalid timeout (6)"),
    Agent86 = setelement(7, Agent0, "{1000, 1, 100, -1}"),
    write_agents_conf(ConfDir, [Agent86]),
    {error, Reason86} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason86]),
    {failed_check, _, _, _, {invalid_timer, _}} = Reason86,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 91] write agents config file with invalid max-message-size (1)"),
    Agent91 = setelement(8, Agent0, "483"),
    write_agents_conf(ConfDir, [Agent91]),
    {error, Reason91} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason91]),
    {failed_check, _, _, _, {invalid_packet_size, _}} = Reason91,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 92] write agents config file with invalid max-message-size (2)"),
    Agent92 = setelement(8, Agent0, "kalle_anka"),
    write_agents_conf(ConfDir, [Agent92]),
    {error, Reason92} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason92]),
    {failed_check, _, _, _, {invalid_packet_size, _}} = Reason92,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test A1] write agents config file with invalid version (1)"),
    AgentA1 = setelement(9, Agent0, "1"),
    write_agents_conf(ConfDir, [AgentA1]),
    {error, ReasonA1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [ReasonA1]),
    {failed_check, _, _, _, {bad_version, _}} = ReasonA1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test A2] write agents config file with invalid version (2)"),
    AgentA2 = setelement(9, Agent0, "v30"),
    write_agents_conf(ConfDir, [AgentA2]),
    {error, ReasonA2} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [ReasonA2]),
    {failed_check, _, _, _, {bad_version, _}} = ReasonA2,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test B1] write agents config file with invalid sec-model (1)"),
    AgentB1 = setelement(10, Agent0, "\"any\""),
    write_agents_conf(ConfDir, [AgentB1]),
    {error, ReasonB1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [ReasonB1]),
    {failed_check, _, _, _, {invalid_sec_model, _}} = ReasonB1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test B2] write agents config file with invalid sec-model (2)"),
    AgentB2 = setelement(10, Agent0, "v3"),
    write_agents_conf(ConfDir, [AgentB2]),
    {error, ReasonB2} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [ReasonB2]),
    {failed_check, _, _, _, {invalid_sec_model, _}} = ReasonB2,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test C1] write agents config file with invalid sec-name (1)"),
    AgentC1 = setelement(11, Agent0, "initial"),
    write_agents_conf(ConfDir, [AgentC1]),
    case config_start(Opts) of
	{error, ReasonC1} ->
	    ?IPRINT("start failed (as expected): ~p", [ReasonC1]),
	    {failed_check, _, _, _, {bad_sec_name, _}} = ReasonC1,
	    config_ensure_not_running();
	OK_C1 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "C1", OK_C1}})
    end,

    %% --
    ?IPRINT("[test C2] write agents config file with invalid sec-name (2)"),
    AgentC2 = setelement(11, Agent0, "10101"),
    write_agents_conf(ConfDir, [AgentC2]),
    case config_start(Opts) of
	{error, ReasonC2} ->
	    ?IPRINT("start failed (as expected): ~p", [ReasonC2]),
	    {failed_check, _, _, _, {bad_sec_name, _}} = ReasonC2,
	    config_ensure_not_running();
	OK_C2 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "C2", OK_C2}})
    end,

    %% --
    ?IPRINT("[test D1] write agents config file with invalid sec-level (1)"),
    AgentD1 = setelement(12, Agent0, "\"noAuthNoPriv\""),
    write_agents_conf(ConfDir, [AgentD1]),
    case config_start(Opts) of
	{error, ReasonD1} ->
	    ?IPRINT("start failed (as expected): ~p", [ReasonD1]),
	    {failed_check, _, _, _, {invalid_sec_level, _}} = ReasonD1,
	    config_ensure_not_running();
	OK_D1 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "D1", OK_D1}})
    end,

    %% --
    ?IPRINT("[test D2] write agents config file with invalid sec-level (2)"),
    AgentD2 = setelement(12, Agent0, "99"),
    write_agents_conf(ConfDir, [AgentD2]),
    case config_start(Opts) of
	{error, ReasonD2} ->
	    ?IPRINT("start failed (as expected): ~p", [ReasonD2]),
	    {failed_check, _, _, _, {invalid_sec_level, _}} = ReasonD2,
	    config_ensure_not_running();
	OK_D2 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "D2", OK_D2}})
    end,

    %% --
    ?IPRINT("[test E1] write agents config file with invalid agent (1)"),
    write_agents_conf2(ConfDir, "{swiacf, \"targ-hobbes\"}."),
    case config_start(Opts) of
	{error, ReasonE1} ->
	    ?IPRINT("start failed (as expected): ~p", [ReasonE1]),
	    {failed_check, _, _, _, {bad_agent_config, _}} = ReasonE1,
	    config_ensure_not_running();
	OK_E1 ->
	    config_ensure_not_running(),
	    exit({error, {unexpected_success, "E1", OK_E1}})
    end,

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_invalid_usm_conf_file1(suite) -> [];
start_with_invalid_usm_conf_file1(doc) ->
    "Start with invalid usm config file.";
start_with_invalid_usm_conf_file1(Conf) when is_list(Conf) -> 
    put(tname, "START-W-INV-USM-CONF-FILE-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    case ?CRYPTO_START() of
        ok ->
            case ?CRYPTO_SUPPORT() of
                {no, Reason} ->
                    ?SKIP({unsupported_encryption, Reason});
                yes ->
                    ok
            end;
        {error, Reason} ->
            ?SKIP({failed_starting_crypto, Reason})
    end,
     
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    Opts = [{versions, [v1,v2,v3]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    write_manager_conf(ConfDir),

    write_users_conf(ConfDir, [{"swiacf", "snmpm_user_default", "dummy"}]),
    
    Usm0 = {"\"bmkEngine\"", "\"swiusmcf\"", 
	    "usmNoAuthProtocol", "[]",
	    "usmNoPrivProtocol", "[]"},

    Usm1 = {"\"bmkEngine\"", "\"swiusmcf\"", "\"kalle\"", 
	    "usmNoAuthProtocol", "[]",
	    "usmNoPrivProtocol", "[]"},

    %% --
    ?IPRINT("[test 11] write usm config file with invalid engine-id (1)"),
    Usm11 = setelement(1, Usm0, "kalle-anka"),
    write_usm_conf(ConfDir, [Usm11]),
    {error, Reason11} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason11]),
    {failed_reading, _, _, _, {parse_error, _}} = Reason11,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 12] write usm config file with invalid engine-id (2)"),
    Usm12 = setelement(1, Usm0, "kalle_anka"),
    write_usm_conf(ConfDir, [Usm12]),
    {error, Reason12} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason12]),
    {failed_check, _, _, _, {bad_usm_engine_id, _}} = Reason12,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 13] write usm config file with invalid engine-id (3)"),
    Usm13 = setelement(1, Usm1, "10101"),
    write_usm_conf(ConfDir, [Usm13]),
    {error, Reason13} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason13]),
    {failed_check, _, _, _, {bad_usm_engine_id, _}} = Reason13,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 21] write usm config file with invalid user-name (1)"),
    Usm21 = setelement(2, Usm0, "kalle_anka"),
    write_usm_conf(ConfDir, [Usm21]),
    {error, Reason21} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason21]),
    {failed_check, _, _, _, {bad_usm_user_name, _}} = Reason21,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 22] write usm config file with invalid user-name (1)"),
    Usm22 = setelement(2, Usm1, "10101"),
    write_usm_conf(ConfDir, [Usm22]),
    {error, Reason22} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason22]),
    {failed_check, _, _, _, {bad_usm_user_name, _}} = Reason22,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 31] write usm config file with invalid sec-name (1)"),
    Usm31 = setelement(3, Usm1, "kalle_anka"),
    write_usm_conf(ConfDir, [Usm31]),
    {error, Reason31} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason31]),
    {failed_check, _, _, _, {bad_usm_sec_name, _}} = Reason31,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 32] write usm config file with invalid sec-name (2)"),
    Usm32 = setelement(3, Usm1, "10101"),
    write_usm_conf(ConfDir, [Usm32]),
    {error, Reason32} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason32]),
    {failed_check, _, _, _, {bad_usm_sec_name, _}} = Reason32,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 41] write usm config file with invalid auth-protocol (1)"),
    Usm41 = setelement(3, Usm0, "\"usmNoAuthProtocol\""),
    write_usm_conf(ConfDir, [Usm41]),
    {error, Reason41} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason41]),
    {failed_check, _, _, _, {invalid_auth_protocol, _}} = Reason41,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 42] write usm config file with invalid auth-protocol (2)"),
    Usm42 = setelement(3, Usm0, "kalle"),
    write_usm_conf(ConfDir, [Usm42]),
    {error, Reason42} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason42]),
    {failed_check, _, _, _, {invalid_auth_protocol, _}} = Reason42,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 43] write usm config file with invalid auth-protocol (3)"),
    Usm43 = setelement(3, Usm0, "10101"),
    write_usm_conf(ConfDir, [Usm43]),
    {error, Reason43} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason43]),
    {failed_check, _, _, _, {invalid_auth_protocol, _}} = Reason43,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.1] write (auth md5) usm config file with invalid auth-key (1)"),
    Usm51_1 = setelement(3, Usm0, "usmHMACMD5AuthProtocol"),
    write_usm_conf(ConfDir, [Usm51_1]),
    {error, Reason51_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason51_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.2] write (auth md5) usm config file with invalid auth-key (2)"),
    Usm51_2 = setelement(4, Usm51_1, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]"),
    write_usm_conf(ConfDir, [Usm51_2]),
    {error, Reason51_2} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51_2]),
    {failed_check, _, _, _, {invalid_auth_key, _, 15}} = Reason51_2,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.3] write (auth md5) usm config file with invalid auth-key (3)"),
    Usm51_3 = setelement(4, Usm51_1, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]"),
    write_usm_conf(ConfDir, [Usm51_3]),
    {error, Reason51_3} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51_3]),
    {failed_check, _, _, _, {invalid_auth_key, _, 17}} = Reason51_3,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.4] write (auth md5) usm config file with invalid auth-key (4)"),
    Usm51_4 = setelement(4, Usm51_1, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,kalle]"),
    write_usm_conf(ConfDir, [Usm51_4]),
    maybe_start_crypto(),  %% Make sure it's started...
    {error, Reason51_4} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason51_4]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason51_4,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.5] write (auth md5) usm config file with invalid auth-key (5)"),
    Usm51_5 = setelement(4, Usm51_1, "arne_anka"),
    write_usm_conf(ConfDir, [Usm51_5]),
    {error, Reason51_5} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51_5]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason51_5,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 51.6] write (auth md5) usm config file with invalid auth-key (6)"),
    Usm51_6 = setelement(4, Usm51_1, "10101"),
    write_usm_conf(ConfDir, [Usm51_6]),
    {error, Reason51_6} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason51_6]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason51_6,
    config_ensure_not_running(),



    %% -- (auth) SHA --
    ?IPRINT("[test 52.1] write (auth sha) usm config file with invalid auth-key (1)"),
    Usm52_1 = setelement(3, Usm0, "usmHMACSHAAuthProtocol"),
    write_usm_conf(ConfDir, [Usm52_1]),
    {error, Reason52_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason52_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason52_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 52.2] write (auth sha) usm config file with invalid auth-key (2)"),
    Usm52_2 = setelement(4, Usm52_1, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]"),
    write_usm_conf(ConfDir, [Usm52_2]),
    {error, Reason52_2} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason52_2]),
    {failed_check, _, _, _, {invalid_auth_key, _, 16}} = Reason52_2,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 52.3] write (auth sha) usm config file with invalid auth-key (3)"),
    Usm52_3 = setelement(4, Usm52_1, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,ka]"),
    write_usm_conf(ConfDir, [Usm52_3]),
    ok = maybe_start_crypto(),
    {error, Reason52_3} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason52_3]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason52_3,
    config_ensure_not_running(),



    %% -- (auth) SHA-224 --
    ?IPRINT("[test 53.1] write (auth sha224) usm config file with invalid auth-key (1)"),
    Usm53_1 = setelement(3, Usm0, "usmHMAC128SHA224AuthProtocol"),
    write_usm_conf(ConfDir, [Usm53_1]),
    {error, Reason53_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason53_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason53_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 53.2] write (auth sha224) usm config file with valid auth-key (2)"),
    Usm53_2 = setelement(4, Usm53_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8]"),
    write_usm_conf(ConfDir, [Usm53_2]),
    {ok, _} = config_start(Opts),
    ?IPRINT("expected start success"),
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 53.3] write (auth sha224) usm config file with invalid auth-key (3)"),
    Usm53_3 = setelement(4, Usm53_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]"),
    write_usm_conf(ConfDir, [Usm53_3]),
    {error, Reason53_3} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason53_3]),
    {failed_check, _, _, _, {invalid_auth_key, _, 27}} = Reason53_3,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 53.4] write (auth sha224) usm config file with invalid auth-key (4)"),
    Usm53_4 = setelement(4, Usm53_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,ka]"),
    write_usm_conf(ConfDir, [Usm53_4]),
    ok = maybe_start_crypto(),
    {error, Reason53_4} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason53_4]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason53_4,
    config_ensure_not_running(),


    %% -- (auth) SHA-256 --
    ?IPRINT("[test 54.1] write (auth sha256) usm config file with invalid auth-key (1)"),
    Usm54_1 = setelement(3, Usm0, "usmHMAC192SHA256AuthProtocol"),
    write_usm_conf(ConfDir, [Usm54_1]),
    {error, Reason54_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason54_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason54_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 54.2] write (auth sha256) usm config file with valid auth-key (2)"),
    Usm54_2 = setelement(4, Usm54_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2]"),
    write_usm_conf(ConfDir, [Usm54_2]),
    {ok, _} = config_start(Opts),
    ?IPRINT("expected start success"),
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 54.3] write (auth sha256) usm config file with invalid auth-key (3)"),
    Usm54_3 = setelement(4, Usm54_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1]"),
    write_usm_conf(ConfDir, [Usm54_3]),
    {error, Reason54_3} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason54_3]),
    {failed_check, _, _, _, {invalid_auth_key, _, 31}} = Reason54_3,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 54.4] write (auth sha256) usm config file with invalid auth-key (4)"),
    Usm54_4 = setelement(4, Usm54_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,ka]"),
    write_usm_conf(ConfDir, [Usm54_4]),
    ok = maybe_start_crypto(),
    {error, Reason54_4} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason54_4]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason54_4,
    config_ensure_not_running(),


    %% -- (auth) SHA-384 --
    ?IPRINT("[test 55.1] write (auth sha384) usm config file with invalid auth-key (1)"),
    Usm55_1 = setelement(3, Usm0, "usmHMAC256SHA384AuthProtocol"),
    write_usm_conf(ConfDir, [Usm55_1]),
    {error, Reason55_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason55_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason55_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 55.2] write (auth sha384) usm config file with valid auth-key (2)"),
    Usm55_2 = setelement(4, Usm55_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8]"),
    write_usm_conf(ConfDir, [Usm55_2]),
    {ok, _} = config_start(Opts),
    ?IPRINT("expected start success"),
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 55.3] write (auth sha384) usm config file with invalid auth-key (3)"),
    Usm55_3 = setelement(4, Usm55_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]"),
    write_usm_conf(ConfDir, [Usm55_3]),
    {error, Reason55_3} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason55_3]),
    {failed_check, _, _, _, {invalid_auth_key, _, 47}} = Reason55_3,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 55.4] write (auth sha384) usm config file with invalid auth-key (4)"),
    Usm55_4 = setelement(4, Usm55_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,ka]"),
    write_usm_conf(ConfDir, [Usm55_4]),
    ok = maybe_start_crypto(),
    {error, Reason55_4} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason55_4]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason55_4,
    config_ensure_not_running(),


    %% -- (auth) SHA-512 --
    ?IPRINT("[test 56.1] write (auth sha512) usm config file with invalid auth-key (1)"),
    Usm56_1 = setelement(3, Usm0, "usmHMAC384SHA512AuthProtocol"),
    write_usm_conf(ConfDir, [Usm56_1]),
    {error, Reason56_1} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason56_1]),
    {failed_check, _, _, _, {invalid_auth_key, _, _}} = Reason56_1,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 56.2] write (auth sha512) usm config file with valid auth-key (2)"),
    Usm56_2 = setelement(4, Usm56_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4]"),
    write_usm_conf(ConfDir, [Usm56_2]),
    {ok, _} = config_start(Opts),
    ?IPRINT("expected start success"),
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 56.3] write (auth sha512) usm config file with invalid auth-key (3)"),
    Usm56_3 = setelement(4, Usm56_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3]"),
    write_usm_conf(ConfDir, [Usm56_3]),
    {error, Reason56_3} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason56_3]),
    {failed_check, _, _, _, {invalid_auth_key, _, 63}} = Reason56_3,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 56.4] write (auth sha512) usm config file with invalid auth-key (4)"),
    Usm56_4 = setelement(4, Usm56_1,
                         "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,ka]"),
    write_usm_conf(ConfDir, [Usm56_4]),
    ok = maybe_start_crypto(),
    {error, Reason56_4} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason56_4]),
    {failed_check, _, _, _, {invalid_auth_key, _}} = Reason56_4,
    config_ensure_not_running(),


    %% --
    ?IPRINT("[test 61] write usm config file with invalid priv-protocol (1)"),
    Usm61 = setelement(5, Usm0, "\"usmNoPrivProtocol\""),
    write_usm_conf(ConfDir, [Usm61]),
    {error, Reason61} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason61]),
    {failed_check, _, _, _, {invalid_priv_protocol, _}} = Reason61,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 62] write usm config file with invalid priv-protocol (2)"),
    Usm62 = setelement(5, Usm0, "kalle"),
    write_usm_conf(ConfDir, [Usm62]),
    {error, Reason62} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason62]),
    {failed_check, _, _, _, {invalid_priv_protocol, _}} = Reason62,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 63] write usm config file with invalid priv-protocol (3)"),
    Usm63 = setelement(5, Usm0, "10101"),
    write_usm_conf(ConfDir, [Usm63]),
    {error, Reason63} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason63]),
    {failed_check, _, _, _, {invalid_priv_protocol, _}} = Reason63,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 71] write usm config file with invalid priv-key (1)"),
    Usm71 = setelement(5, Usm0, "usmDESPrivProtocol"),
    write_usm_conf(ConfDir, [Usm71]),
    {error, Reason71} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason71]),
    {failed_check, _, _, _, {invalid_priv_key, _, _}} = Reason71,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 72] write usm config file with invalid priv-key (2)"),
    Usm72 = setelement(6, Usm71, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5]"),
    write_usm_conf(ConfDir, [Usm72]),
    {error, Reason72} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason72]),
    {failed_check, _, _, _, {invalid_priv_key, _, 15}} = Reason72,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 73] write usm config file with invalid priv-key (3)"),
    Usm73 = setelement(6, Usm71, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7]"),
    write_usm_conf(ConfDir, [Usm73]),
    {error, Reason73} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason73]),
    {failed_check, _, _, _, {invalid_priv_key, _, 17}} = Reason73,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 74] write usm config file with invalid priv-key (4)"),
    Usm74 = setelement(6, Usm71, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,kalle]"),
    write_usm_conf(ConfDir, [Usm74]),
    ok = maybe_start_crypto(),
    {error, Reason74} = config_start(Opts),
    ok = maybe_stop_crypto(),
    ?IPRINT("start failed (as expected): ~p", [Reason74]),
    {failed_check, _, _, _, {invalid_priv_key, _}} = Reason74,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 75] write usm config file with invalid priv-key (5)"),
    Usm75 = setelement(6, Usm71, "arne_anka"),
    write_usm_conf(ConfDir, [Usm75]),
    {error, Reason75} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason75]),
    {failed_check, _, _, _, {invalid_priv_key, _}} = Reason75,
    config_ensure_not_running(),

    %% --
    ?IPRINT("[test 76] write usm config file with invalid priv-key (6)"),
    Usm76 = setelement(6, Usm71, "10101"),
    write_usm_conf(ConfDir, [Usm76]),
    {error, Reason76} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason76]),
    {failed_check, _, _, _, {invalid_priv_key, _}} = Reason76,
    config_ensure_not_running(),

    %% --
    %% <CRYPTO-MODIFICATIONS>
    %% The crypto application do no longer need to be started
    %% explicitly (all of it is as of R14 implemented with NIFs).
    case (catch crypto:version()) of
	{'EXIT', {undef, _}} ->
	    ?IPRINT("[test 77] write usm config file with valid priv-key "
	      "when crypto not started (7)"),
	    Usm77 = setelement(6, Usm71, "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]"),
	    write_usm_conf(ConfDir, [Usm77]),
	    {error, Reason77} = config_start(Opts),
	    ?IPRINT("start failed (as expected): ~p", [Reason77]),
	    {failed_check, _, _, _, {unsupported_crypto, _}} = Reason77,
	    config_ensure_not_running();
	_ ->
	    %% This function is only present in version 2.0 or greater.
	    %% The crypto app no longer needs to be explicitly started
	    ok
    end,
    %% </CRYPTO-MODIFICATIONS>

    %% --
    ?IPRINT("[test 78] write usm config file with invalid usm (1)"),
    write_usm_conf2(ConfDir, "{\"bmkEngine\", \"swiusmcf\"}."),
    {error, Reason81} = config_start(Opts),
    ?IPRINT("start failed (as expected): ~p", [Reason81]),
    {failed_check, _, _, _, {bad_usm_config, _}} = Reason81,
    config_ensure_not_running(),
   
    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

start_with_create_db_and_dir_opt(suite) -> [];
start_with_create_db_and_dir_opt(doc) ->
    "Start the snmp manager config process with the\n"
        "create_db_and_dir option.";
start_with_create_db_and_dir_opt(Conf) when is_list(Conf) ->
    put(tname, "START-W-CRE-DB-AND-DIR-OPT"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),
    true = not filelib:is_dir(DbDir) and not filelib:is_file(DbDir),
    write_manager_conf(ConfDir),

    ?IPRINT("verify nonexistent db_dir"),
    ConfigOpts01 = [{verbosity,trace}, {dir, ConfDir}, {db_dir, DbDir}],
    {error, Reason01} = config_start([{config, ConfigOpts01}]),
    ?IPRINT("nonexistent db_dir res: ~p", [Reason01]),
    {invalid_conf_db_dir, _, not_found} = Reason01,

    ?IPRINT("verify nonexistent db_dir gets created"),
    ConfigOpts02 = [{db_init_error, create_db_and_dir} | ConfigOpts01],
    {ok, _Pid} = config_start([{config, ConfigOpts02}]),
    true = filelib:is_dir(DbDir),
    ?IPRINT("verified: nonexistent db_dir was correctly created"),
    ok = config_stop(),

    ?IPRINT("done"),
    ok.

%% 
%% ---
%% 


simple_system_op(suite) -> [];
simple_system_op(doc) -> 
    "Access some of the known system info and some \n"
	"system info that does not exist.";
simple_system_op(Conf) when is_list(Conf) ->
    put(tname, "SIMPLE-SYS-OP"),
    ?IPRINT("start"),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    write_manager_conf(ConfDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    ?IPRINT("start config"),
    {ok, _Pid}         = config_start(Opts),
    
    ?IPRINT("retrieve various configs"),
    {ok, _Time}        = snmpm_config:system_start_time(),
    {ok, _EngineId}    = snmpm_config:get_engine_id(),
    {ok, _MMS}         = snmpm_config:get_engine_max_message_size(),

    ?IPRINT("attempt to retrieve nonexisting"),
    {error, not_found} = snmpm_config:system_info(kalle),
    
    ok = config_stop(),
    config_ensure_not_running(),

    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 



%% 
%% ---
%% 

register_user_using_file(suite) -> [];
register_user_using_file(doc) ->
    "Register user using the 'users.conf' file.";
register_user_using_file(Conf) when is_list(Conf) -> 
    put(tname, "REG-USER-USING-FILE"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%% 
%% ---
%% 

register_user_using_function(suite) -> [];
register_user_using_function(doc) ->
    "Register user using the API (function).";
register_user_using_function(Conf) when is_list(Conf) -> 
    put(tname, "REG-USER-USING-FUNC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%% 
%% ---
%% 

register_user_failed_using_function1(suite) -> [];
register_user_failed_using_function1(doc) ->
    "Register user failed using incorrect arguments to API (function).";
register_user_failed_using_function1(Conf) when is_list(Conf) -> 
    put(tname, "REG-USER-FAIL-USING-FUNC-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%% 
%% ---
%% 



%% 
%% ---
%% 

%% This test case tests that we can "register" agents using a config file.
%% So, starting the config process is part of the actual test, but even
%% if the test fails, we want to make sure the config process is actually
%% stop'ed. So, we put config stop in the post.

register_agent_using_file(suite) -> [];
register_agent_using_file(doc) ->
    "Register agents using the 'agents'conf' file.";
register_agent_using_file(Conf) when is_list(Conf) -> 
    put(tname, "REG-AG-USING-FILE"),
    process_flag(trap_exit, true),
    Pre  = fun()  -> ok end,
    Case = fun(_) -> do_register_agent_using_file(Conf) end,
    Post = fun(_) ->
                   ?IPRINT("stop config process"),
                   ok = snmpm_config:stop(),
                   config_ensure_not_running(),
                   ok
           end,
    ?TC_TRY(register_agent_using_file, Pre, Case, Post).

do_register_agent_using_file(Conf) ->
    ?IPRINT("start"),
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],


    %% --
    ?IPRINT("write manager config file"),
    write_manager_conf(ConfDir),

    %% --
    ?IPRINT("write users config file"),
    UserId1 = raufi1,
    UserId1Str = str(UserId1),
    UserId2 = raufi2,
    UserId2Str = str(UserId2),
    User1 = {UserId1Str, "snmpm_user_default", "dummy1"},
    User2 = {UserId2Str, "snmpm_user_default", "dummy2", "[{version, v1}]"},
    write_users_conf(ConfDir, [User1, User2]),

    %% --
    ?IPRINT("write agents config file"),
    AgentAddr1 = [192,168,0,101],
    AgentAddr1Str = str(AgentAddr1),
    AgentPort1 = 162,
    AgentPort1Str = str(AgentPort1),
    EngineID1 = "bmkEngine1",
    EngineID1Str = str(EngineID1),
    MMS1 = 1024,
    MMS1Str = str(MMS1),
    AgentAddr2 = [192,168,0,102],
    AgentAddr2Str = str(AgentAddr2),
    AgentPort2 = 162,
    AgentPort2Str = str(AgentPort2),
    EngineID2 = "bmkEngine2",
    EngineID2Str = str(EngineID2),
    MMS2 = 512,
    MMS2Str = str(MMS2),
    Agent1Str = {UserId1Str, "\"targ-hobbes1\"", "\"comm\"", 
		 AgentAddr1Str, AgentPort1Str, EngineID1Str, 
		 "1000", MMS1Str, "v1",
		 "any", "\"initial\"", "noAuthNoPriv"},
    Agent2Str = {UserId2Str, "\"targ-hobbes2\"", "\"comm\"", 
		 AgentAddr2Str, AgentPort2Str, EngineID2Str, 
		 "1500", MMS2Str, "v1",
		 "any", "\"initial\"", "noAuthNoPriv"},
    write_agents_conf(ConfDir, [Agent1Str, Agent2Str]),

    %% --
    ?IPRINT("start the config process"),
    {ok, _Pid} = config_start(Opts),

    %% --
    ?IPRINT("which agents"),
    [_, _] = All = snmpm_config:which_agents(),
    ?IPRINT("all agents: ~n   ~p", [All]),
    [A1]         = snmpm_config:which_agents(UserId1),
    ?IPRINT("agents belonging to ~w: ~n   ~p", [UserId1, A1]),
    [A2]         = snmpm_config:which_agents(UserId2),
    ?IPRINT("agents belonging to ~w: ~n   ~p", [UserId2, A2]),

    %% --
    ?IPRINT("All info for agent <~w,~w>", [AgentAddr1, AgentPort1]),
    {ok, AllInfo1} =
	snmpm_config:agent_info(AgentAddr1, AgentPort1, all),
    ?IPRINT("all agent info for agent: ~n   ~p", [AllInfo1]),
    
    %% --
    ?IPRINT("EngineID (~p) for agent <~w,~w>", [EngineID1, AgentAddr1, AgentPort1]),
    {ok, EngineID1} =
	snmpm_config:agent_info(AgentAddr1, AgentPort1, engine_id),
    
    
    %% --
    ?IPRINT("All info for agent <~w,~w>", [AgentAddr2, AgentPort2]),
    {ok, AllInfo2} =
	snmpm_config:agent_info(AgentAddr2, AgentPort2, all),
    ?IPRINT("all agent info for agent: ~n   ~p", [AllInfo2]),
    
    %% --
    ?IPRINT("EngineID (~p) for agent <~w,~w>", [EngineID2, AgentAddr2, AgentPort2]),
    {ok, EngineID2} =
	snmpm_config:agent_info(AgentAddr2, AgentPort2, engine_id),

    %% --
    {ok, MMS2} =
	snmpm_config:agent_info(AgentAddr2, AgentPort2, max_message_size),
    NewMMS21 = 2048,
    ?IPRINT("try update agent info max-message-size to ~w for agent <~w,~w>", 
      [NewMMS21, AgentAddr2, AgentPort2]),
    ok = update_agent_info(UserId2, AgentAddr2, AgentPort2,
                                 max_message_size, NewMMS21),
    {ok, NewMMS21} =
	snmpm_config:agent_info(AgentAddr2, AgentPort2, max_message_size),

    %% --
    ?IPRINT("try (and fail) to update agent info max-message-size to ~w "
      "for agent <~w,~w> " 
      "with user ~w (not owner)", 
      [NewMMS21, AgentAddr2, AgentPort2, UserId1]),
    {error, Reason01} =
	update_agent_info(UserId1, AgentAddr2, AgentPort2,
                          max_message_size, NewMMS21),
    ?IPRINT("expected failure. Reason01: ~p", [Reason01]), 
    {ok, NewMMS21} =
	snmpm_config:agent_info(AgentAddr2, AgentPort2, max_message_size),

    %% --
    NewMMS22 = 400,
    ?IPRINT("try (and fail) to update agent info max-message-size to ~w "
      "for agent <~w,~w>", 
      [NewMMS22, AgentAddr2, AgentPort2]),
    {error, Reason02} =
	update_agent_info(UserId1, AgentAddr2, AgentPort2,
                          max_message_size, NewMMS22),
    ?IPRINT("expected failure. Reason02: ~p", [Reason02]), 

    %% --
    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

register_agent_using_function(suite) -> [];
register_agent_using_function(doc) ->
    "Register agents using the API (function).";
register_agent_using_function(Conf) when is_list(Conf) -> 
    put(tname, "REG-AG-USING-FUNC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%% 
%% ---
%% 

register_agent_failed_using_function1(suite) -> [];
register_agent_failed_using_function1(doc) ->
    "Register agents failing using the API (function) with incorrect "
	"config (1).";
register_agent_failed_using_function1(Conf) when is_list(Conf) -> 
    put(tname, "REG-AG-FAIL-USING-FUNC-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%%
%% ---
%% 



%% 
%% ---
%% 

register_usm_user_using_file(suite) -> [];
register_usm_user_using_file(doc) ->
    "Register usm user using the 'usm.conf' file.";
register_usm_user_using_file(Conf) when is_list(Conf) -> 
    put(tname, "REG-USM-USER-USING-FILE"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    case ?CRYPTO_START() of
        ok ->
            case ?CRYPTO_SUPPORT() of
                {no, Reason} ->
                    ?SKIP({unsupported_encryption, Reason});
                yes ->
                    ok
            end;
        {error, Reason} ->
            ?SKIP({failed_starting_crypto, Reason})
    end,
     
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir   = ?config(manager_db_dir, Conf),

    Opts = [{versions, [v3]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    %% --
    ?IPRINT("write manager config file"),
    write_manager_conf(ConfDir),

    %% --
    ?IPRINT("write usm user config file"),
    SecEngineID = "loctzp's engine",
    SecName1    = "samu_auth1",
    UserName1   = SecName1,
    UsmUser1 = {"\"" ++ SecEngineID ++ "\"", 
		"\"" ++ UserName1 ++ "\"", 
		"\"" ++ SecName1 ++ "\"", 
		"usmHMACMD5AuthProtocol", "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]",
		"usmNoPrivProtocol", "[]"},

    SecName2    = "samu_auth2",
    UserName2   = "samu",
    UsmUser2 = {"\"" ++ SecEngineID ++ "\"", 
		"\"" ++ UserName2 ++ "\"", 
		"\"" ++ SecName2 ++ "\"", 
		"usmHMACMD5AuthProtocol", "[1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]",
		"usmNoPrivProtocol", "[]"},
    write_usm_conf(ConfDir, [UsmUser1, UsmUser2]),

    %% --
    ?IPRINT("start the config process"),
    {ok, _Pid} = config_start(Opts),

    %% --
    ?IPRINT("lookup 1 (ok)"),
    {ok, #usm_user{name = UserName1} = User1} =
	snmpm_config:get_usm_user_from_sec_name(SecEngineID, SecName1),
    ?IPRINT("User: ~p", [User1]),

    ?IPRINT("lookup 2 (ok)"),
    {ok, #usm_user{name = UserName2} = User2} =
	snmpm_config:get_usm_user_from_sec_name(SecEngineID, SecName2),
    ?IPRINT("User: ~p", [User2]),

    ?IPRINT("lookup 3 (error)"),
    {error, not_found} =
	snmpm_config:get_usm_user_from_sec_name(SecEngineID, SecName2 ++ "_1"),

    %% --
    ?IPRINT("stop config process"),
    ok = snmpm_config:stop(),
    config_ensure_not_running(),

    %% --
    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

register_usm_user_using_function(suite) -> [];
register_usm_user_using_function(doc) ->
    "Register usm user using the API (function).";
register_usm_user_using_function(Conf) when is_list(Conf) -> 
    put(tname, "REG-USM-USER-USING-FUNC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    case ?CRYPTO_START() of
        ok ->
            case ?CRYPTO_SUPPORT() of
                {no, Reason} ->
                    ?SKIP({unsupported_encryption, Reason});
                yes ->
                    case snmp_misc:is_crypto_supported(aes_cfb128) of
                        true ->
                            ok;
                        false ->
                            ?SKIP({unsupported_crypto, aes_cfb128})
                    end
            end;
        {error, Reason} ->
                    ?SKIP({failed_starting_crypto, Reason})
    end,
     
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    Opts = [{versions, [v3]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    %% --
    ?IPRINT("write manager config file"),
    write_manager_conf(ConfDir),

    %% --
    ?IPRINT("start the config process"),
    {ok, _Pid} = config_start(Opts),

    %% --
    ?IPRINT("register usm user's"),
    EngineID   = "loctzp's engine",

    ?IPRINT("register user 1 (ok)"),
    UserName1  = "samu_auth1",
    SecName1   = UserName1, 
    UsmConfig1 = [{sec_name, SecName1},
		  {auth,     usmHMACMD5AuthProtocol},
		  {auth_key, [1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]},
		  {priv,     usmNoPrivProtocol}],

    ok = snmpm_config:register_usm_user(EngineID, UserName1, UsmConfig1),
    ?IPRINT("try register user 1 again (error)"),
    {error, {already_registered, EngineID, UserName1}} =
	snmpm_config:register_usm_user(EngineID, UserName1, UsmConfig1),
    
    ?IPRINT("register user 2 (ok)"),
    UserName2  = "samu_auth2",
    SecName2   = UserName2, 
    UsmConfig2 = [{auth,     usmHMACMD5AuthProtocol},
		  {auth_key, [1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]},
		  {priv,     usmNoPrivProtocol}],
    ok = snmpm_config:register_usm_user(EngineID, UserName2, UsmConfig2),
    
    ?IPRINT("register user 3 (ok)"),
    UserName3  = "samu3",
    SecName3   = "samu_auth3",
    UsmConfig3 = [{sec_name, SecName3},
		  {auth,     usmHMACMD5AuthProtocol},
		  {auth_key, [1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]},
		  {priv,     usmNoPrivProtocol}],
    ok = snmpm_config:register_usm_user(EngineID, UserName3, UsmConfig3),

    ?IPRINT("register user 4 (ok)"),
    UserName4  = "samu4",
    SecName4   = "samu_auth4",
    UsmConfig4 = [{sec_name, SecName4},
		  {auth,     usmHMACMD5AuthProtocol},
		  {auth_key, [1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6]},
		  {priv,     usmAesCfb128Protocol},
                  {priv_key, [190,54,66,227,33,171,152,0,133,223,204,155,109,111,77,44]}],
    ok = snmpm_config:register_usm_user(EngineID, UserName4, UsmConfig4),

    ?IPRINT("lookup 1 (ok)"),
    {ok, #usm_user{name = UserName1} = User1} =
	snmpm_config:get_usm_user_from_sec_name(EngineID, SecName1),
    ?IPRINT("User: ~p", [User1]),

    ?IPRINT("lookup 2 (ok)"),
    {ok, #usm_user{name = UserName2} = User2} =
	snmpm_config:get_usm_user_from_sec_name(EngineID, SecName2),
    ?IPRINT("User: ~p", [User2]),

    ?IPRINT("lookup 3 (ok)"),
    {ok, #usm_user{name = UserName3} = User3} =
	snmpm_config:get_usm_user_from_sec_name(EngineID, SecName3),
    ?IPRINT("User: ~p", [User3]),

    ?IPRINT("lookup 4 (ok)"),
    {ok, #usm_user{name = UserName4} = User4} =
	snmpm_config:get_usm_user_from_sec_name(EngineID, SecName4),
    ?IPRINT("User: ~p", [User4]),

    ?IPRINT("lookup 5 (error)"),
    {error, not_found} =
	snmpm_config:get_usm_user_from_sec_name(EngineID, SecName4 ++ "_1"),

    %% --
    ?IPRINT("stop config process"),
    ok = snmpm_config:stop(),
    config_ensure_not_running(),

    %% --
    ?IPRINT("done"),
    ok.


%% 
%% ---
%% 

register_usm_user_failed_using_function1(suite) -> [];
register_usm_user_failed_using_function1(doc) ->
    "Register usm user failed using incorrect arguments to API (function).";
register_usm_user_failed_using_function1(Conf) when is_list(Conf) -> 
    put(tname, "REG-USM-USER-FAIL-USING-FUNC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    case ?CRYPTO_START() of
        ok ->
            case ?CRYPTO_SUPPORT() of
                {no, Reason} ->
                    ?SKIP({unsupported_encryption, Reason});
                yes ->
                    ok
            end;
        {error, Reason} ->
            ?SKIP({failed_starting_crypto, Reason})
    end,
     
    _ConfDir = ?config(manager_conf_dir, Conf),
    _DbDir = ?config(manager_db_dir, Conf),
    ?SKIP(not_yet_implemented).


%%
%% ---
%% 

update_usm_user_info(suite) -> [];
update_usm_user_info(doc) ->
    "Update usm user info.";
update_usm_user_info(Conf) when is_list(Conf) -> 
    put(tname, "UPD-USM-USER-INFO"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    ?IPRINT("Start crypto and ensure support"),
    case ?CRYPTO_START() of
        ok ->
            case ?CRYPTO_SUPPORT() of
                {no, Reason} ->
                    ?SKIP({unsupported_encryption, Reason});
                yes ->
                    case snmp_misc:is_crypto_supported(aes_cfb128) of
                        true ->
                            ok;
                        false ->
                            ?SKIP({unsupported_crypto, aes_cfb128})
                    end
            end;
        {error, Reason} ->
            ?SKIP({failed_starting_crypto, Reason})
    end,
     
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir   = ?config(manager_db_dir, Conf),

    ?IPRINT("write manager config"),
    write_manager_conf(ConfDir),

    Opts = [{versions, [v3]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    ?IPRINT("Start config server"),
    {ok, _Pid} = snmpm_config:start_link(Opts),

    ?IPRINT("Register usm user"),
    EngineID   = "engine",
    UsmUser    = "UsmUser",
    SecName    = UsmUser, 
    AuthProto  = usmHMACMD5AuthProtocol,
    AuthKey    = [1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6],
    PrivProto1 = usmNoPrivProtocol,
    UsmConfig  = [{sec_name, SecName},
                  {auth,     AuthProto},
                  {auth_key, AuthKey},
                  {priv,     PrivProto1}],
    ok = snmpm_config:register_usm_user(EngineID, UsmUser, UsmConfig),

    ?IPRINT("verify user user config"),
    {ok, AuthProto}  = snmpm_config:usm_user_info(EngineID, UsmUser, auth),
    {ok, AuthKey}    = snmpm_config:usm_user_info(EngineID, UsmUser, auth_key),
    {ok, PrivProto1} = snmpm_config:usm_user_info(EngineID, UsmUser, priv),

    ?IPRINT("usm user update 1"),
    PrivProto2 = usmAesCfb128Protocol,
    PrivKey2   = [190,54,66,227,33,171,152,0,133,223,204,155,109,111,77,44],
    ok = snmpm_config:update_usm_user_info(EngineID, UsmUser, priv, PrivProto2),
    ok = snmpm_config:update_usm_user_info(EngineID, UsmUser, priv_key, PrivKey2),

    ?IPRINT("verify updated user user config after update 1"),
    {ok, AuthProto}  = snmpm_config:usm_user_info(EngineID, UsmUser, auth),
    {ok, AuthKey}    = snmpm_config:usm_user_info(EngineID, UsmUser, auth_key),
    {ok, PrivProto2} = snmpm_config:usm_user_info(EngineID, UsmUser, priv),
    {ok, PrivKey2}   = snmpm_config:usm_user_info(EngineID, UsmUser, priv_key),

    ?IPRINT("usm user update 2"),
    PrivProto3 = PrivProto1,
    ok = snmpm_config:update_usm_user_info(EngineID, UsmUser, priv, PrivProto3),

    ?IPRINT("verify updated user user config after update 2"),
    {ok, AuthProto}  = snmpm_config:usm_user_info(EngineID, UsmUser, auth),
    {ok, AuthKey}    = snmpm_config:usm_user_info(EngineID, UsmUser, auth_key),
    {ok, PrivProto3}  = snmpm_config:usm_user_info(EngineID, UsmUser, priv),

    ?IPRINT("Stop config server"),
    ok = snmpm_config:stop(),

    ?IPRINT("done"),
    ok.


%%
%% ---
%% 



%% 
%% ---
%% 

create_and_increment(suite) -> [];
create_and_increment(doc) ->
    "Create and increment counters.";
create_and_increment(Conf) when is_list(Conf) -> 
    put(tname, "CRE-AND-INC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    write_manager_conf(ConfDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    {ok, _Pid} = snmpm_config:start_link(Opts),

    %% Random init
    ?SNMP_RAND_SEED(),

    StartVal = rand:uniform(2147483647),
    IncVal   = 42, 
    EndVal   = StartVal + IncVal,

    StartVal = snmpm_config:cre_counter(test_id, StartVal),
    EndVal   = snmpm_config:incr_counter(test_id, IncVal),

    ok = snmpm_config:stop(),
    config_ensure_not_running(),
    ok.


%% 
%% ---
%% 



%% 
%% ---
%% 

stats_create_and_increment(suite) -> [];
stats_create_and_increment(doc) ->
    "Create and increment statistics counters.";
stats_create_and_increment(Conf) when is_list(Conf) -> 
    put(tname, "STATS-CRE-AND-INC"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    
    ConfDir = ?config(manager_conf_dir, Conf),
    DbDir = ?config(manager_db_dir, Conf),

    write_manager_conf(ConfDir),

    Opts = [{versions, [v1]}, 
	    {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    {ok, _Pid} = snmpm_config:start_link(Opts),

    ?IPRINT("stats table (1): ~p", [ets:tab2list(snmpm_stats_table)]),
    0  = snmpm_config:maybe_cre_stats_counter(stats1, 0),
    ?IPRINT("stats table (2): ~p", [ets:tab2list(snmpm_stats_table)]),
    ok = snmpm_config:maybe_cre_stats_counter(stats1, 0),
    ?IPRINT("stats table (3): ~p", [ets:tab2list(snmpm_stats_table)]),
    1  = snmpm_config:maybe_cre_stats_counter(stats2, 1),
    ?IPRINT("stats table (4): ~p", [ets:tab2list(snmpm_stats_table)]),
    10 = snmpm_config:cre_stats_counter(stats3, 10),
    ?IPRINT("stats table (5): ~p", [ets:tab2list(snmpm_stats_table)]),

    Stats1Inc = fun() -> snmpm_config:incr_stats_counter(stats1, 1) end,
    10 = loop(10, -1, Stats1Inc),
    ?IPRINT("stats table (6): ~p", [ets:tab2list(snmpm_stats_table)]),
    
    ok = snmpm_config:reset_stats_counter(stats1),

    10 = loop(10, -1, Stats1Inc),

    ok = snmpm_config:stop(),
    config_ensure_not_running(),
    ok.


loop(0, Acc, _) ->
    Acc;
loop(N, _, F) when (N > 0) andalso is_function(F) ->
    Acc = F(),
    loop(N-1, Acc, F).


%%======================================================================
%% Ticket test-cases
%%======================================================================



otp_7219(suite) ->
    [];
otp_7219(doc) ->
    "Test-case for ticket OTP-7219";
otp_7219(Config) when is_list(Config) ->
    put(tname, "OTP-7219"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    ConfDir = ?config(manager_conf_dir, Config),
    DbDir   = ?config(manager_db_dir, Config),

    ?IPRINT("write manager configuration"),
    write_manager_conf(ConfDir),

    Opts1 = [{versions, [v1]}, 
	     {inform_request_behaviour, user}, 
	     {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    ?IPRINT("start manager config"),
    {ok, _Pid1} = snmpm_config:start_link(Opts1),

    ?IPRINT("get some manager config"),
    {ok, {user, _}} = snmpm_config:system_info(net_if_irb),

    ?IPRINT("stop manager config"),
    ok = snmpm_config:stop(),
    config_ensure_not_running(),

    IRB_TO = 15322, 
    Opts2 = [{versions, [v1]}, 
	     {inform_request_behaviour, {user, IRB_TO}}, 
	     {config, [{verbosity, trace}, {dir, ConfDir}, {db_dir, DbDir}]}],

    ?IPRINT("start manager config"),
    {ok, _Pid2} = snmpm_config:start_link(Opts2),

    ?IPRINT("get some manager config"),
    {ok, {user, IRB_TO}} = snmpm_config:system_info(net_if_irb),

    ?IPRINT("stop manager config"),
    ok = snmpm_config:stop(),
    config_ensure_not_running(),

    ?IPRINT("done"),
    ok.




otp_8395_1(suite) -> [];
otp_8395_1(doc) ->
    "OTP-8395(1)";
otp_8395_1(Conf) when is_list(Conf) ->
    put(tname, "OTP-8395-1"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    otp8395(Conf, false, ok),
    ok.

otp_8395_2(suite) -> [];
otp_8395_2(doc) ->
    "OTP-8395(2)";
otp_8395_2(Conf) when is_list(Conf) ->
    put(tname, "OTP-8395-2"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    otp8395(Conf, true, ok),
    ok.

otp_8395_3(suite) -> [];
otp_8395_3(doc) ->
    "OTP-8395(3)";
otp_8395_3(Conf) when is_list(Conf) ->
    put(tname, "OTP-8395-3"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),
    otp8395(Conf, gurka, error),
    ok.

otp8395(Conf, SeqNoVal, Expect) ->
    ConfDir   = ?config(manager_conf_dir, Conf),
    DbDir     = ?config(manager_db_dir, Conf),
    LogDir    = ?config(manager_log_dir, Conf),
    StdMibDir = filename:join(code:priv_dir(snmp), "mibs") ++ "/",
    
    write_manager_conf(ConfDir),
    
    %% Third set of options (no versions):
    ?IPRINT("all options"),
    NetIfOpts  = [{module,    snmpm_net_if}, 
		  {verbosity, trace},
		  {options,   [{recbuf,   30000},
			       {bind_to,  false},
			       {no_reuse, false}]}],
    ServerOpts = [{timeout, 10000}, {verbosity, trace}],
    NoteStoreOpts = [{timeout, 20000}, {verbosity, trace}],
    ConfigOpts = [{dir, ConfDir}, {verbosity, trace}, {db_dir, DbDir}],
    Mibs = [join(StdMibDir, "SNMP-NOTIFICATION-MIB"),
	    join(StdMibDir, "SNMP-USER-BASED-SM-MIB")],
    Prio = normal,
    ATL  = [{type,   read_write}, 
	    {dir,    LogDir}, 
	    {size,   {10,10240}},
	    {repair, true},
	    {seqno,  SeqNoVal}],
    Vsns = [v1,v2,v3],
    Opts = [{config,          ConfigOpts},
	    {net_if,          NetIfOpts},
	    {server,          ServerOpts},
	    {note_store,      NoteStoreOpts},
	    {audit_trail_log, ATL},
	    {priority,        Prio}, 
	    {mibs,            Mibs},
	    {versions,        Vsns}],
    
    case config_start(Opts) of
	{ok, _Pid} when (Expect =:= ok) ->
	    ok = config_stop(),
	    ok;
	{ok, _Pid} when (Expect =/= ok) ->
	    config_stop(),
	    exit({unexpected_started_config, SeqNoVal});
	_Error when (Expect =/= ok) ->
	    ok; 
	Error when (Expect =:= ok) ->
	    exit({unexpected_failed_starting_config, SeqNoVal, Error})
    end,
    ?IPRINT("done"),
    ok.


otp_8395_4(suite) -> [];
otp_8395_4(doc) ->
    "OTP-8395(4)";
otp_8395_4(Conf) when is_list(Conf) ->
    put(tname, "OTP-8395-4"),
    ?IPRINT("start"),
    process_flag(trap_exit, true),

    snmp:print_version_info(),

    ConfDir   = ?config(manager_conf_dir, Conf),
    DbDir     = ?config(manager_db_dir, Conf),
    LogDir    = ?config(manager_log_dir, Conf),
    StdMibDir = filename:join(code:priv_dir(snmp), "mibs") ++ "/",
    
    write_manager_conf(ConfDir),
    
    %% Third set of options (no versions):
    ?IPRINT("all options"),
    NetIfOpts  = [{module,    snmpm_net_if}, 
		  {verbosity, trace},
		  {options,   [{recbuf,   30000},
			       {bind_to,  false},
			       {no_reuse, false}]}],
    ServerOpts = [{timeout, 10000}, {verbosity, trace}],
    NoteStoreOpts = [{timeout, 20000}, {verbosity, trace}],
    ConfigOpts = [{dir, ConfDir}, {verbosity, trace}, {db_dir, DbDir}],
    Mibs = [join(StdMibDir, "SNMP-NOTIFICATION-MIB"),
	    join(StdMibDir, "SNMP-USER-BASED-SM-MIB")],
    Prio = normal,
    ATL  = [{type,   read_write}, 
	    {dir,    LogDir}, 
	    {size,   {10,10240}},
	    {repair, true},
	    {seqno,  true}],
    Vsns = [v1,v2,v3],
    Opts = [{config,          ConfigOpts},
	    {net_if,          NetIfOpts},
	    {server,          ServerOpts},
	    {note_store,      NoteStoreOpts},
	    {audit_trail_log, ATL},
	    {priority,        Prio}, 
	    {mibs,            Mibs},
	    {versions,        Vsns}],
    
    {ok, _Pid} = config_start(Opts),
    
    Counter   = otp_8395_4, 
    Initial   = 10,
    Increment = 2, 
    Max       = 20,
    
    %% At this call the counter does *not* exist. The call creates
    %% it with the initial value!

    Val1 = Initial, 
    Val1 = otp8395_incr_counter(Counter, Initial, Increment, Max),

    %% Now it exist, make sure another call does the expected increment
    
    Val2 = Initial + Increment, 
    Val2 = otp8395_incr_counter(Counter, Initial, Increment, Max),

    ok = config_stop(),

    ?IPRINT("done"),
    ok.
    

otp8395_incr_counter(Counter, Initial, Increment, Max) ->
    snmpm_config:increment_counter(Counter, Initial, Increment, Max).


%%======================================================================
%% Internal functions
%%======================================================================

update_agent_info(UserId, Addr, Port, Item, Val)  ->
    case snmpm_config:agent_info(Addr, Port, target_name) of
	{ok, TargetName} ->
	    snmpm_config:update_agent_info(UserId, TargetName, [{Item, Val}]);
	Error ->
	    Error
    end.

config_start(Opts) ->
    (catch snmpm_config:start_link(Opts)).

config_stop() ->
    (catch snmpm_config:stop()).

config_ensure_not_running() ->
    ?ENSURE_NOT_RUNNING(snmpm_config,
                        fun() -> snmpm_config:stop() end,
                        1000).


%% ------

join(Dir, File) ->
    filename:join(Dir, File).


%% ------

write_manager_conf(Dir) ->
    Port = "5000",
    MMS  = "484",
    EngineID = "\"mgrEngine\"",
    Str = lists:flatten(
	    io_lib:format("%% Minimum manager config file\n"
			  "{port,             ~s}.\n"
			  "{max_message_size, ~s}.\n"
			  "{engine_id,        ~s}.\n",
			  [Port, MMS, EngineID])),
    write_manager_conf(Dir, Str).

write_manager_conf(Dir, IP, Port, MMS, EngineID) ->
    Str = lists:flatten(
	    io_lib:format("{address,          ~s}.\n"
			  "{port,             ~s}.\n"
			  "{max_message_size, ~s}.\n"
			  "{engine_id,        ~s}.\n",
			  [IP, Port, MMS, EngineID])),
    write_manager_conf(Dir, Str).

write_manager_conf(Dir, Str) ->
    write_conf_file(Dir, "manager.conf", Str).


write_users_conf(Dir, Users) ->
    F = fun({UserId, UserMod, UserData}) -> %% Old format
		lists:flatten(
		  io_lib:format("{~s, ~s, ~s, ~s}.~n", 
				[UserId, UserMod, UserData, "[]"]));
	   ({UserId, UserMod, UserData, DefaultAgentConfig}) -> %% New format
		lists:flatten(
		  io_lib:format("{~s, ~s, ~s, ~s}.~n", 
				[UserId, UserMod, UserData, DefaultAgentConfig]))
	end,
    Str = lists:flatten([F(User) || User <- Users]),
    write_conf_file(Dir, "users.conf", Str).

write_users_conf2(Dir, Str) ->
    write_conf_file(Dir, "users.conf", Str).


write_agents_conf(Dir, Agents) ->
    F = fun({UserId,
	     TargetName, Comm, 
	     Ip, Port, EngineID, 
	     Timeout, MMS, 
	     Version, SecModel, SecName, SecLevel}) ->
		lists:flatten(
		  io_lib:format("{~s, ~n"
				" ~s, ~s, ~n"
				" ~s, ~s, ~s, ~n"
				" ~s, ~s, ~n"
				" ~s, ~s, ~s, ~s}.~n", 
				[UserId, 
				 TargetName, Comm, 
				 Ip, Port, EngineID, 
				 Timeout, MMS, 
				 Version, SecModel, SecName, SecLevel]))
	end,
    Str = lists:flatten([F(Agent) || Agent <- Agents]),
    write_conf_file(Dir, "agents.conf", Str).

write_agents_conf2(Dir, Str) ->
    write_conf_file(Dir, "agents.conf", Str).


write_usm_conf(Dir, Usms) ->
    F = fun({EngineID, UserName, SecName, AuthP, AuthKey, PrivP, PrivKey}) ->
		lists:flatten(
		  io_lib:format("{~s, ~s, ~s, ~n"
				" ~s, ~s, ~n"
				" ~s, ~s}.~n", 
				[EngineID, UserName, SecName, 
				 AuthP, AuthKey, 
				 PrivP, PrivKey]));
	   ({EngineID, UserName, AuthP, AuthKey, PrivP, PrivKey}) ->
		lists:flatten(
		  io_lib:format("{~s, ~s, ~n"
				" ~s, ~s, ~n"
				" ~s, ~s}.~n", 
				[EngineID, UserName, 
				 AuthP, AuthKey, 
				 PrivP, PrivKey]));
	   (Usm) ->
		exit({invalid_usm, Usm})
	end,
    Str = lists:flatten([F(Usm) || Usm <- Usms]),
    write_conf_file(Dir, "usm.conf", Str).

write_usm_conf2(Dir, Str) ->
    write_conf_file(Dir, "usm.conf", Str).


write_conf_file(Dir, File, Str) ->
    case file:open(filename:join(Dir, File), write) of
	{ok, Fd} ->
	    ok = io:format(Fd, "~s", [Str]),
	    file:close(Fd);
	{error, Reason} ->
	    Info = 
		[{dir, Dir, case (catch file:read_file_info(Dir)) of
				{ok, FI} -> 
				    FI;
				_ ->
				    undefined
			    end},
		 {file, File}], 
	    exit({failed_writing_conf_file, Info, Reason})
    end.


maybe_start_crypto() ->
    case (catch crypto:version()) of
	{'EXIT', {undef, _}} ->
	    %% This is the version of crypto before the NIFs...
	    ?CRYPTO_START();
	_ ->
	    %% No need to start this version of crypto..
	    ok
    end.

maybe_stop_crypto() ->
    case (catch crypto:version()) of
	{'EXIT', {undef, _}} ->
	    %% This is the version of crypto before the NIFs...
	    application:stop(crypto);
	_ ->
	    %% There is nothing to stop in this version of crypto..
	    ok
    end.


%% ------

verify_dir_existing(DirName, Dir) ->
    case file:read_file_info(Dir) of
	{ok, _} ->
	    ok;
	{error, Reason} ->
	    exit({non_existing_dir, DirName, Dir, Reason})
    end.


%% ------

str(X) ->
    ?F("~w", [X]).

