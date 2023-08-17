-module(convolutional_code_v0_0_02).
-behaviour(gen_statem).

-export([stop/0, start_link/0]).
-export([init/1, callback_mode/0, handle_event/4, terminate/3, code_change/4]).
-export([message_input/0,message_to_binary_conversion/0,get_message_to_binary_conversion/0,complete_bits/0,binary_correction/0,get_final_output/0,bxor_head_to_registers/0]).

stop() ->
    gen_statem:stop(convolutional_code_v0_0_02).

start_link() ->
    gen_statem:start_link({local, convolutional_code_v0_0_02}, convolutional_code_v0_0_02, [], []).

message_input() ->
    gen_statem:call(convolutional_code_v0_0_02,message_input).

message_to_binary_conversion() ->
    gen_statem:cast(convolutional_code_v0_0_02,message_to_binary_conversion).

get_message_to_binary_conversion() ->
    gen_statem:cast(convolutional_code_v0_0_02,get_message_to_binary_conversion).

complete_bits() ->
    gen_statem:cast(convolutional_code_v0_0_02,complete_bits).

binary_correction() ->
    gen_statem:cast(convolutional_code_v0_0_02,binary_correction).

get_final_output() ->
    gen_statem:cast(convolutional_code_v0_0_02,get_final_output).

bxor_head_to_registers() ->
    gen_statem:cast(convolutional_code_v0_0_02,bxor_head_to_registers).

init(_Args) ->
    State = wait,
    {ok, State, []}.

%% state_functions | handle_event_function | [_, state_enter].
callback_mode() ->
    handle_event_function.

handle_event({call,From},message_input,wait,_Data) ->
    {ok,Message} = io:read("Message: "),
    convolutional_code_v0_0_02:message_to_binary_conversion(),
    {
        next_state,{convert_message_to_binary,Message,[]},_Data,[{reply,From,done}]
    };

handle_event(cast,message_to_binary_conversion,{convert_message_to_binary,Message,Message_conversion_storage},_Data) ->
    % io:format("1st event ~n"),
    case Message of
        [] ->
            convolutional_code_v0_0_02:get_message_to_binary_conversion(),
            {
                next_state,{get_message_to_binary_conversion,Message,Message_conversion_storage},_Data
            };

        _else ->
            convolutional_code_v0_0_02:complete_bits(),
            {
                next_state,{complete_bits,Message,Message_conversion_storage},_Data
            }

    end;

handle_event(cast,get_message_to_binary_conversion,{get_message_to_binary_conversion,[],Message_conversion_storage},_Data) ->
    % io:format("2nd event ~n"),
    Message_conversion = lists:reverse(lists:flatten(Message_conversion_storage)),
    convolutional_code_v0_0_02:binary_correction(),
    {
        next_state,{binary_correction,Message_conversion,[],0,0},_Data
    };

handle_event(cast,complete_bits,{complete_bits,Message,Message_conversion_storage},_Data) ->
    % io:format("3rd event ~n"),
    [Message_head|Message_tail] = Message,
    Message_to_binary_conversion = integer_to_binary(Message_head,2),
    Message_bits_completion = lists:reverse(string:right(binary_to_list(Message_to_binary_conversion),8,$0)),
    convolutional_code_v0_0_02:message_to_binary_conversion(),
    {
        next_state,{convert_message_to_binary,Message_tail,[Message_bits_completion|Message_conversion_storage]},_Data
    };

handle_event(cast,binary_correction,{binary_correction,Message_conversion,Output_storage,Initial_shift,Second_shift},_Data) ->
    % io:format("4th event ~n"),
    case Message_conversion of
        [] ->
            convolutional_code_v0_0_02:get_final_output(),
            {
                next_state,{get_final_output,Message_conversion,Output_storage,Initial_shift,Second_shift},_Data
            };

        _else ->
            convolutional_code_v0_0_02:bxor_head_to_registers(),
            {
                next_state,{bxor_head_to_registers,Message_conversion,Output_storage,Initial_shift,Second_shift},_Data
            }
    
    end;

handle_event(cast,get_final_output,{get_final_output,[],Output_storage,_,_},_Data) ->
    % io:format("5th event ~n"),
    Output_to_binary_conversion = lists:concat(lists:reverse(Output_storage)),
    Bitstring_output = list_to_binary(Output_to_binary_conversion),
    io:format("~p~n",[Bitstring_output]),
    {
        next_state,wait,_Data
    };

handle_event(cast,bxor_head_to_registers,{bxor_head_to_registers,Message_conversion,Output_storage,Initial_shift,Second_shift},_Data) ->
    % io:format("6th event ~n"),
    [Message_conversion_head|Message_conversion_tail] = Message_conversion,
    Message_conversion_initial_return = list_to_integer([Message_conversion_head]) bxor Second_shift,
    Message_conversion_next_return = list_to_integer([Message_conversion_head]) bxor Initial_shift bxor Second_shift,
    Initial_and_next_return_concatenation = lists:concat([Message_conversion_initial_return,Message_conversion_next_return]),
    Message_conversion_next_head_shift = list_to_integer([Message_conversion_head]),
    convolutional_code_v0_0_02:binary_correction(),
    {
        next_state,{binary_correction,Message_conversion_tail,[Initial_and_next_return_concatenation|Output_storage],Message_conversion_next_head_shift,Initial_shift},_Data
    };

handle_event(_EventType, _EventContent, _State, _Data) ->
    keep_state_and_data.

terminate(_Reason, _State, _Data) ->
    ok.

code_change(_OldVsn, State, Data, _Extra) ->
    {ok, State, Data}.
