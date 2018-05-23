## LockVisualizer

Thanks to [DisPlayers-Audio-Visualizers](https://github.com/agilie/DisPlayers-Audio-Visualizers) for the visualizers, [Mitsuha](https://github.com/c0ldra1n/Mitsuha) for the AudioUnitRender hook, [CustomLockscreenDuration](https://github.com/Nosskirneh/CustomLockscreenDuration) for disabling lockscreen sleeping, and [TypeStatus](https://github.com/hbang/TypeStatus) for the [LightMessaging](https://github.com/rpetrich/LightMessaging) example


![demo](https://raw.githubusercontent.com/ipadkid358/LockVisualizer/master/demo.png)

### Additional Features

LockVisualizer has a couple of complementary features, and other things to ensure the tweak works well. These are personal preferences, as well as for practical reasons.

1. Disabling sleeping on the lockscreen when music was playing

2. Hide the music view when a notification comes up

3. Hide status bar when music view is showing

4. Move music controls from the top of the screen to closer to the home button, to allow easier access to the controls, and a more appealing visualizer

5. Change the volume slider control "thumb" from the defualt, to a much thinner version, to match the rest of the lockscreen feel

### Challanges

The first challange was getting the music buffer information from `mediaserverd` to SpringBoard. After looking at different IPC options, I decided on mach messages becuase of the extreme speed they operate at. The AudioUnitRender function is called over eighty times a second (only brief testing has gone into this), so the data needed to get to SpringBoard in milliseconds. The second obstacle was getting the data before it was freed, but without causing any audio buffering. The solution was to have two buffers. One is copied into on the main thread, and the second is copied into on a background thread from the first buffer. This allowed the function to complete quickly enough for there to be no audio buffering, and still getting the data. After extensive testing, the largest possible audio buffer that was passed in, was 16K, so each buffer is pre-allocated with 16K and filled up as needed.
