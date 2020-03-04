/*

receiver.scd (v1)
SC receives message (beginning with "/engine") from Python

*/

s.options.memSize = 2097152;
s.waitForBoot({

    SynthDef( \sin, { | amp = 0.0, attack = 0.01, freq = 333, release = 1, sus = 2, trig = 0 |
	    var env, sig;

	    env = EnvGen.kr( Env.linen( attack, sus, release ), trig, doneAction: 2 );
	    sig = SinOsc.ar( [ freq, freq * 0.999 ], 0.0, amp ) * env;
	    Out.ar( 0, sig  );
    }).add;

    s.sync;

	~dur = {exprand(0.5, 6.0)};

    Synth.new( \sin, [ \amp, 0.9, \trig, 0 ] );

    x = OSCFunc( { | msg, time, addr, port |
		var dur, freq, fund = 200, partial;

		freq = msg[1] * fund;
		dur = ~dur.value;

		( "freq is" + freq + "dur is" + dur ).postln;

		Synth.new( \sin, [ \amp, 0.9, \freq, freq, \sus, ~dur.value, \trig, 1 ] );

	}, "/engine" );
});