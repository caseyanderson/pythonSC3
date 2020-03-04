/*
    receiver.scd
    SC receives message (beginning with "/engine") from Python

*/

s.options.memSize = 2097152;
s.waitForBoot({

    SynthDef( \sin, { | amp = 0.0, freq = 333, trig = 0 |
	    var env, sig;

	    env = EnvGen.kr( Env.asr( 0.001, 0.9, 0.001 ), trig, doneAction: 0 );
	    sig = SinOsc.ar( [ freq, freq * 0.999 ], 0.0, amp ) * env;
	    Out.ar( 0, sig  );
    }).add;

    s.sync;

    h = Synth( \sin, [ \amp, 0.8, \trig, 1 ] );

    x = OSCFunc( { | msg, time, addr, port |

	    ( "freq is " + msg[1] ).postln;
	    h.set( \freq, msg[1] );
    }, "/engine" );
});