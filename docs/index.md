#TF2 Skill

##Overview
TF2 Skill is an adaptation of [Microsoft's TrueSkill][1] ranking system into source games. This plugin has been only tested with Team Fortress 2.

An example population distribution as a result of using TrueSkill can be viewed [here][2]

Example Website Interface: [PlayTF2][7]

## Features

* **Non-point based** - Functions as an ELO derived match making system.
* **Threaded** - Support for simultaneous servers all using the same listener.
* **AutoUpdate** - The plugin will automatically update itself when updates are available. You will always have the most up-to-date version of the plugin.

##CVar/Command List

```javascript
sm_trueskill_version // public CVar shows the plugin version
sm_trueskill_minClients 16    //minimum number of clients required to track ranking
sm_trueskill_url "http://server.com/trueskill.php" //url to trueskill php file
sm_trueskill_global "50" //minimum rank to display globally to the server, 0 for off
```

##Dependencies/Requirements
* [SteamTools Extension][3]
* [Sourcemod Updater Plugin][4]
* MySQL database
* Python >= 2.7
   * [TrueSkill][5]  module
   * [PyMySQL][6] module

[1]: http://research.microsoft.com/en-us/projects/trueskill/
[2]: http://www.playtf2.com/plot/
[3]: https://forums.alliedmods.net/showthread.php?t=129763
[4]: https://forums.alliedmods.net/showthread.php?t=169095
[5]: http://trueskill.org/
[6]: https://pypi.python.org/pypi/PyMySQL
[7]: http://playtf2.com/stats/