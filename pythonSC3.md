# Python to Supercollider
*Spring 2020, Casey Anderson*

### Reference

* [SuperCollider](https://supercollider.github.io/)
* [SCBook](http://supercolliderbook.net/)
* [SCMailing Lists](http://www.birmingham.ac.uk/facilities/BEAST/research/supercollider/mailinglist.aspx)
* [OpenSoundControl](http://opensoundcontrol.org/)
* [pyOSC3](https://github.com/Qirky/pyOSC3)


## Setup

### Install SuperCollider3

1. Go [here](https://supercollider.github.io/download.html) to download `SuperCollider`
2. Once your download is complete install the program


### Install pyOSC3
*This sections assumes an existing installation of* `Python 3` *and* `pip3`. *For instructions, go [here](https://gist.github.com/caseyanderson/0c1f508acaac2f2afd77966af44f7dee)*.

Run the following command in the terminal to install [pyOSC3](https://github.com/Qirky/pyOSC3): `pip3 install pyOSC3`


## OSC + SuperCollider Overview

### OSC

[OpenSoundControl](http://opensoundcontrol.org/introduction-osc) (or `OSC`) is a network-based protocol for communication between multiple computers or multiple programs on the same computer.

Communicating via `OSC` typically involves sending messages (with some network [IP] address) to a receiver (if there is a receiver currently listening). If there is no receiver the messages the sender outputs simply disappear. Our audio engine and receiver will live in `SuperCollider` and our controller/message sender will live in `Python`.


### SuperCollider

SC has three components:

1. `sclang`: an interpreted programming language
2. `scserver`: the server receives information from `sclang` and produces sound
3. `scide`: an editor for `sclang`

The window that says `post` is the console/post window. Messages/Errors from SC will appear there.


## Communicating from Python to SC (Demo)

This section describes the basic usage procedure for `receiver.scd` and `sender.py`. An explanation of the code in each file can be found in the subsequent section ([Communicating from SC to Python (Analysis)](https://github.com/caseyanderson/pythonSC3/blob/master/pythonSC3.md#communicating-from-sc-to-python-analysis)).

### SuperCollider

1. Copy and paste the example below (`receiver.scd`), featuring a simple `SynthDef` and `OSCFunc`, into a new `SuperCollider` window

    ```supercollider
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

        x = OSCFunc( { | msg, time, addr, port |
            var dur, freq, fund = 200, partial;

            freq = msg[1] * fund;
            dur = ~dur.value;
            ( "freq is" + freq + "dur is" + dur ).postln;
            Synth.new( \sin, [ \amp, 0.9, \freq, freq, \sus, dur, \trig, 1 ] );
        }, "/engine" );
    });
    ```

2. Select all of the code in `receiver.scd` (**Command+A**) and run it (**Shift+Enter**). You should see something like this in the `post`:

    ![](assets/server_boot.png)


### Python

1. Copy the example below (`sender.py`) to your clipboard

    ```python
    import pyOSC3
    import argparse

    # parse command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--freq", type=float, help="the frequency", default=200.0)
    parser.add_argument("--addr", type=str, help="the address", default="engine")
    parser.add_argument("--port", type=int, help="the listener's port number", default=57120)
    args = parser.parse_args()

    # create OSCClient
    client = pyOSC3.OSCClient()
    client.connect(('127.0.0.1', args.port))

    # adding the address
    msg = pyOSC3.OSCMessage()
    address = ''.join(["/", str(args.addr)])

    # constructing the message
    msg.setAddress(str(address))
    msg.append(args.freq)

    # sending the message to SC
    client.send(msg)
    ```

2. In the terminal, open your preferred text editor (I like `vim` but you might want to use `nano` [`nano` is similar to "conventional" text editors, `vim` is rather different): `sudo nano sender.py`
3. Paste the code in your clipboard into nano (**Command+V**)
4. **Ctl-x** to exit, **y** to save changes, **Enter** to leave the filename the same
5. Double check the permissions on that file: `ls -l sender.py`. You should see something like this in the Terminal:

    ![](assets/before_chmod.png)

    Looking more closely at the output of `ls -l sender.py` we see the following file permissions:

    ![](assets/permissions.png)


6. The last dash in that image is currently empty. We need to make it `executable`, which will replace the last dash with an `x`: `sudo chmod +x sender.py`
7. Check permissions once more to confirm that `sender.py` is now `executable` (the output of your terminal should resemble the image below, note the `x` at the end of the file permission output): `ls -l sender.py`

    ![](assets/after_chmod.png)

8. In the terminal, run `sender.py` to change the frequency of the playing sine tone: `python3 sender.py`
9. Run `sender.py` one more time, but pick your own frequency (note: it **has** to be a `float`): `python3 sender.py --freq 400.0`


## Communicating from SC to Python (Analysis)

### receiver.scd

#### UGens

([this](https://doc.sccode.org/Guides/UGens-and-Synths.html) article is referenced throughout)

A `UGen`, or unit generator, is an object that processes or generates sounds. SuperCollider ships with an extensive collection of pre-defined `UGens` which one can explore [here](https://doc.sccode.org/Guides/Tour_of_UGens.html).

A `UGen` is created by sending the `UGen` class a `.ar` or `.kr` message.

*For example*

* `SinOsc.ar` will result in an `audio rate` Sine Oscillator
* `SinOsc.kr` will result in a `control rate` Sine Oscillator

Not all `UGens` can be instantiated at both audio and control rate, though, so it is best practice to double check the Class Methods for each `UGen` prior to use. Follow along by typing `SinOsc` in an empty `SC` window, selecting it, and hitting **Command+D** to look the selection up in the documentation.

*For Example*

![](assets/SinOscClassMethods.png)

As one can see in the docs, the `SinOsc` `UGen` can be instantiated at both `audio` and `control rate`.


#### SynthDefs

([this](http://doc.sccode.org/Classes/SynthDef.html) article is referenced throughout)

A `SynthDef`, or `Synth Definition`, tells the server how to generate audio and translates that information to bite code. `SynthDef`s describe the structure of a `Synth`, or a client-side representation of a synth node on the server. The relationship between a `SynthDef` and a `Synth` is similar to the relationship between a cake recipe and the cake produced by following that recipe.

*For Example*

```supercollider
SynthDef( \sin, { | amp = 0.0, attack = 0.01, freq = 333, release = 1, sus = 2, trig = 0 |
    var env, sig;

    env = EnvGen.kr( Env.linen( attack, sus, release ), trig, doneAction: 2 );
    sig = SinOsc.ar( [ freq, freq * 0.999 ], 0.0, amp ) * env;
    Out.ar( 0, sig  );
}).add;
```

The above `SynthDef` shows an example of the usage of two critical arguments:

* `name`: a `Symbol` (beginning with `\`) or `String` (surrounded by "") used to identify the `SynthDef`
* `ugenGraphFunc`: a `Function` specifying how the `SynthDef`'s `UGens` interact

The example SynthDef above is named `\sin`. Note: it's important to be consistent when naming SynthDef's, a `Symbol` and a `String` cannot be used interchangeably.

The `ugenGraphFunc` dictates most of the characteristics of our `SynthDef`. Following along as we go through it line-by-line:

1. first we set arguments, to be used later in the SynthDef, and default values for those arguments. Note that I am using the `|` notation to surround my list of arguments

    `| amp = 0.0, attack = 0.01, freq = 333, release = 1, sus = 2, trig = 0 |`

2. next we declare two variables: `env` and `sig`

    * `env = EnvGen.kr( Env.linen( attack, sus, release ), trig, doneAction: 2 )`

        1. the `env` variable stores the `SynthDef`'s `Envelope Generator`, `EnvGen.kr`, here set to generate a `linear` Envelope with `Env.linen`. There are lots of different `Envelope` instances, which one can explore [here](http://doc.sccode.org/Classes/Env.html). Since `\sin` uses a fixed duration envelope we have to provide it with `attack`, `sustain`, and `release` durations
        2. the `trig` argument gates, or starts, the `Envelope`. Note that this defaults to `0`
        3. `doneActions`: `doneActions` tell the `scserver` what to do when the `Synth` is done. In this case the `scserver` will `free`, or remove, the `Synth` at the end of the `Envelope` (where duration is `attack` + `sustain` + `release`)

    * `sig = SinOsc.ar( [ freq, freq * 0.999 ], 0.0, amp )`

        1. we use `multichannel expansion` on the `SinOsc` `frequency` argument to create a slight throb, via difference tones, and to convert our `Mono` `Synth` to `Stereo`
        2. we set `phase` to 0.0
        3. we use the argument `amp` to create a placeholder for the `SinOsc` `amplitude`, allowing one to change the volume of a `Synth` instance while it is running


### sender.py

explanations go here


!!!!!!!!!
OLD DRAFT EXPLANATIONS BELOW, REWRITE!

SC has an optimized way of taking in information about `UGens` (building blocks for dealing with control or audio information) and their interconnections: `SynthDef`s (i.e. `Synth Definitions`). A `SynthDef` tells the server how to generate audio and translates that information to bite code. You can think of a `SynthDef` and its resulting `Synth`s in a similar manner that one thinks about classes and instances: a `SynthDef` is the recipe that defines a particular instance (or multiple instances) of a (lot of) playing `Synth`(s).

The first thing we need to do is create a `SynthDef` that will let our server know how to create a Sine Wave. We name our sine wave (ex: `\sin`), and then define its arguments and their defaults (in this case, I am declaring arguments named `amp` [amplitude], `freq` [frequency], and `trig` [or trigger, which I use for gating], and setting their default values). I then create two variables, `env` (short for envelope, or what will allow our synth to turn on or off [though that is not really what it is doing, but it will sound that way to us]) and `sig` (short for signal).

The `env` variable contains two `UGen`s: `EnvGen`, which controls how my envelope behaves, and `Env`, which controls what type of envelope I am using. Here I am using an `asr` (attack, sustain, release) envelope. When the `EnvGen` activates the `Env`, it will have an `attack` of 0.001 (seconds) and will then `sustain` at an amplitude of 0.9 (notice that I am not using my `amp` argument here...more on that later [fyi: amplitude in SC is always a floating point number between 0.0 and 1.0]). When the `EnvGen` is deactivated, the `Env` will release (turn off) in 0.001 seconds.

The `EnvGen` controls when the `Env` is active. If active (i.e. if my `trig` argument is set to 1) it will apply the Envelope to the `SinOsc`, causing it to start playing. If inactive (i.e. if my `trig` argument is set to 0), it will either do nothing (i.e. we will get no sound), or if it was already playing, will stop playing my `SinOsc` (releasing, or fading out, the sound in 0.001 seconds).

Notice that `EnvGen` gets a `.kr` here, which means it is a control rate `UGen`. Control rate `UGen`s do not generate audio, but instead operate on audio. `doneActions` (seemingly the least reliable part of SC...) control what happens to the Synth when it is finished. In this case, my `doneAction` is set to 0, which means "do nothing when the envelope is finished." Generally, the only two `doneActions` you need to worry about are "0" or "2" (2 frees the enclosed synth, i.e. deletes it from the server). Seriously, these never seem reliable and I hate them. Unfortunately, you need them (particularly for envelopes).

The `sig` variable contains our signal generator, in this case a `SinOsc UGen`. You can check the help file on `SinOsc` if you want, but, basically, all I am doing in here is taking in a frequency (via the `freq` argument), setting the phase to 0.0, and creating a placeholder for `amp`, which will control the volume of my `SinOsc`. One nice thing about SC is multi-channel expansion: I am using an array of two `freq` arguments here, though one is multiplying whatever that argument is set by 0.999. This will do two things: one, it will create stereo `SinOsc`'s, simply by inserting an array of two `freq`'s, and two, one will be 0.001 hz lower than the other, which will produce a slight phase cancellation (which I think is more fun than a boring sine tone). The `sig` variable is, finally, multiplied by the `env` variable, which is what will allow our `SinOsc` to have an attack or release.

The last part of this that we need to be worried about is the `Out UGen`. As you can probably imagine, this is what actually converts the digital information associated with the interaction of the above `UGen`s in my `SynthDef` into audio that can be played out of speakers. Here you can specify the number of channels the `Out UGen` will run the synth on (since we have two here, it will be stereo), and then also specify what is actually being played out. I added another volume scaling instance here, multiplying my `sig` variable by 0.6, to give the synths more head-room.

Once the `SynthDef` is sent to the server, we can tell the server to create an instance of this `Synth` by assigning it to a variable (in this case `h`), and simply typing the following: `h = Synth( \sin );`. Notice that I also took this opportunity to set the `amp` argument I mentioned earlier to 0.4, which again functioned to give my playing synth more headroom (that way if I wanted to run four of these I would be less likely to get distortion).

Now that we have assigned an instance of `Synth(\sin)` to `h`, we can alter `h` on the fly. If you were to type `h.set( \amp, 0.9 )`, you could change the amplitude level of that particular instance of the `Synth`. `.set` is what is going to give us the ability to change the frequency from iPython without having to stop the `Synth`.

The `OSCFunc` here is assigned to a variable (`x`), so I could reference it elsewhere if I wanted to. I have set the `OSCFunc` to respond to any message being sent over the server prepended with the message <code>'\print'</code>. For our purposes, we can ignore the time and responder arguments, and simply focus on <code>msg</code>, which is where we will receive frequency data from <code>pyOSC</code>.
<br/>In order to do this, I created a variable called <code>pyFreq</code>, and set it to store whatever value comes in at position 1 in the <code>msg</code> array. I am also converting that number to a floating point one, though, apparently, <code>pyOSC</code> passes this information along for us (so this part is redundant). I then post <code>pyFreq</code> to the post window (so I can monitor what frequency my <code>SinOsc</code> is playing), and use <code>h.set</code> to set the symbol <code>freq</code>, from our <code>SynthDef \sin</code>, to <code>pyFreq</code>. The last thing we have to do is add the responder to the server. Go ahead and execute all of this code, and let's move back to iPython.
## step six
Launch iPython via the command line. Here is the code we are going to use:

<pre><code>In [1]: import OSC
In [2]: import time, random
In [3]: client = OSC.OSCClient()
In [4]: client.connect( ( '127.0.0.1', 57120 ) )
In [5]: msg = OSC.OSCMessage()
In [6]: msg.setAddress("/print")
In [7]: msg.append(500)
In [8]: client.send(msg)</code></pre>

Great! Now we can set the frequency of our <code>SinOsc</code> from iPython via <code>OSC</code>. If you are curious how the <code>msg</code> is formatted, prior to sending out to SC, simply type <code>msg</code> in the command line and hit enter. When you do so, you should see something like this:
<pre><code>Out[12]: ['/print', ',i', 500]</code></pre>
The simplest way to change the frequency that SC is playing would be to do the following:
<pre>In [18]: msg[0] = 4000
In [19]: client.send(msg)</pre>
However, it would be more convenient to define a new function that will handle changing frequencies, or could play a melody, or whatever.
<br/>While this is a pretty stripped down example, it suggests nice possibilities for us. For example, since Python is good at scraping data from the web relatively quickly (which SC, for example, does not really do at all [to my knowledge]), we could easily create a SynthDef that will "read" the news to us by sending the results of our scraping to SC and calling the .speak function on that data. Even better, at least for me, is the possibility of both reading, misreading/chopping/stuttering text from the web while simultaneously making horrible noises (which will likely be the next tutorial to follow up on this). Huzzah!
