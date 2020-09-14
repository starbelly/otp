#!/bin/bash

#erlperf 'crypto:equal_const_time(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' 'crypto:old_equal_const_time(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' --samples 100 --warmup 1

erlperf 'crypto:equal_const_time(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' 'binary:secure_compare(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' --samples 100 --warmup 1

# erlperf 'crypto:equal_const_time(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' 'crypto:secure_compare(<<"onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>, <<"twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx">>).' --samples 100 --warmup 1


#erlperf 'crypto:equal_const_time("onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx").' 'crypto:old_equal_const_time("onexxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "twoxxxxxxxxxxxxxxxxxxxxxxxxxxxxx").' --samples 100 --warmup 1
