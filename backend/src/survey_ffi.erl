-module(survey_ffi).

-export([current_timestamp/0]).

current_timestamp() ->
    Now = erlang:system_time(second),
    list_to_binary(calendar:system_time_to_rfc3339(Now)).
