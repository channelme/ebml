%%
%%

-module(ebml_test).

-include_lib("eunit/include/eunit.hrl").

tokens_test() ->
    ?assertMatch({ok, [], _}, ebml:tokens(<<>>)),
    ok.

token_test_webm_test() ->
    {ok, Data} = file:read_file("test/data/test.webm"),

    {ok, Tokens, State} = ebml:tokens(Data),
    ?assertEqual(1212, length(Tokens)),

    %% Check if there is no leftover data.
    ?assertEqual(<<>>, ebml:data(State)), 

    %% Check if we parsed to the end of the file.
    ?assertEqual(size(Data), ebml:offset(State)), 

    ok.

token_test_split_webm_test() ->
    {ok, Data} = file:read_file("test/data/test.webm"),

    <<D1:10000/binary, D2/binary>> = Data,

    {ok, Tokens1, S1} = ebml:tokens(D1),
    {ok, Tokens2, S2} = ebml:tokens(D2, S1),

    ?assertEqual(1212, length(Tokens1 ++ Tokens2)),

    %% Check if there is no leftover data.
    ?assertEqual(<<>>, ebml:data(S2)), 

    %% Check if we parsed to the end of the file.
    ?assertEqual(size(Data), ebml:offset(S2)), 

    ok.

token_test_split_and_get_data_webm_test() ->
    {ok, Data} = file:read_file("test/data/test.webm"),

    <<D1:10000/binary, D2/binary>> = Data,

    {ok, Tokens1, S1} = ebml:tokens(D1),
    {LeftOver, S2} = ebml:get_data(S1),
    {ok, Tokens2, S3} = ebml:tokens(<<LeftOver/binary, D2/binary>>, S2),

   ?assertEqual(1212, length(Tokens1 ++ Tokens2)),

    %% Check if there is no leftover data.
    ?assertEqual(<<>>, ebml:data(S2)), 

    %% Check if we parsed to the end of the file.
    ?assertEqual(4375, ebml:offset(S1)), 
    ?assertEqual(0, ebml:offset(S2)), 
    ?assertEqual(size(Data), 4375 + ebml:offset(S3)), 

    ok.

