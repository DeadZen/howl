%% @doc Supervise the rts_write FSM.
-module(howl_entity_read_fsm_sup).
-behavior(supervisor).

-include("howl.hrl").

-export([start_read_fsm/1,
         start_link/0]).

-export([init/1]).

start_read_fsm(Args) ->
    ?PRINT({start_read_fsm, Args}),
    supervisor:start_child(?MODULE, Args).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ReadFsm = {undefined,
	       {
		 howl_entity_read_fsm, start_link, []},
	       temporary, 5000, worker, [howl_entity_read_fsm]},
    {ok, 
     {
       {simple_one_for_one, 10, 10}, [ReadFsm]}}.
