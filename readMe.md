## LockVisualizer

Creds to [DisPlayers-Audio-Visualizers](https://github.com/agilie/DisPlayers-Audio-Visualizers) for the visualizers, [Mitsuha](https://github.com/c0ldra1n/Mitsuha) for the AudioUnitRender hook, [CustomLockscreenDuration](https://github.com/Nosskirneh/CustomLockscreenDuration) for disabling lockscreen sleeping, and [TypeStatus](https://github.com/hbang/TypeStatus) for the [LightMessaging](https://github.com/rpetrich/LightMessaging) example


![demo](https://raw.githubusercontent.com/ipadkid358/LockVisualizer/master/demo.jpeg)


LockVisualizer has a couple of complementary features, and other things to ensure the tweak works well. First thing I worked on, was disabling sleeping on the lockscreen when music was playing. Then I removed the music view when a notification comes up. These are personal preferences, as well as for practical reasons. This tweak works by sending mach messages from mediaserverd to SpringBoard. The next aspect was to mitigate crashes that seemed to occur when scrubbing through videos in WebViews. This crash was fixed, and performance was improved, by not sending messages unless the playing screen was visible.
