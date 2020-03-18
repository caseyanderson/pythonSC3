/*

receiver.scd (v1)
SC receives message (beginning with "/engine") from Python

*/

s.options.outDevice_("Built-in Output"); // or s.options.outDevice_("UltraLite mk3 Hybrid");
s.options.memSize = 2097152;

s.waitForBoot({

    SynthDef( \sin, { | amp = 0.0, attack = 0.01, freq = 333, release = 1, sus = 2, trig = 0 |
	    var env, sig;

        env = Env.linen( attack, sus, release ).kr( Done.freeSelf, trig );
        sig = SinOsc.ar([ freq, freq * 0.999 ], 0.0, amp );
	    Out.ar( 0, env * sig  );
    }).add;

    ~dur = { exprand( 0.5, 6.0 )};

    OSCFunc( { | msg |
		var dur, freq, fund = 200;
        // msg.postln;

		freq = msg[1] * fund;
		dur = ~dur.value;
		( "freq is" + freq + "dur is" + dur ).postln;
		Synth.new( \sin, [ \amp, 0.9, \freq, freq, \sus, dur, \trig, 1 ] );
	}, "/engine" );
});
