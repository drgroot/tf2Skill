#TF2 Skill
###A TrueSkill implementation for Team Fortress 2

TF2 Skill is an adaptation of [Microsoft's TrueSkill][5] ranking system into source games. This plugin has only been tested and designed to work with Team Fortress 2. 

##Dependencies/Requirements
* [SourceSockets Extension][3]
* [Sourcemod Updater Plugin][4]
* MySQL database
* Python >= 2.7
   * [TrueSkill][1]  module
   * [PyMySQL][2] module

##Features
* **Non-point based** - Functions as an ELO derived match making system.
* **Lightweight** - Little overhead and very compact and optimal coding.
* **Threaded** - Support for simultaneous servers all using the same listener.
* **Logging** - The plugin maintains full logs of all errors, warnings and information.
* **AutoUpdate** - The plugin will automatically update itself when updates are available. You will always have the most up-to-date version of the plugin.

##CVar/Command List

```javascript
sm_trueskill_version // public CVar shows the plugin version
sm_trueskill_minClients 16    //minimum number of clients required to track ranking
sm_trueskill_server "dev.yusufali.ca" //ip or hostname of server running python script
sm_trueskill_port "5000" //socket port to interact with the python daemon
```

##Installation
Download the .smx file and save to the plugins directory into your sourcemod plugins folder. Edit the **default** entry in `addons/sourcemod/configs/databases.cfg`:

```javascript
   "default"
   {
      "driver" "mysql"
      "host"   "<mysql host>"
      "database"   "<mysql database>"
      "user"   "<mysql username>"
      "pass"    "<mysql password>"
   }
```

Similarly, on the server running the python daemon, edit `config.file.sample` and then rename it to `config.file`

##Running The Daemon
To begin applying TrueSkill calculations, simply run the python script in a screen session or using an init script. Below is a sample to start the daemon

```bash
screen
python trueSkill.py
```

For linux systems, an init script has been supplied as `trueSkill`. This ofcourse needs to be modified to your system setup (user, path). To use the init script on debian based systems:

```bash
ln -s /path/to/trueSkill_init /etc/init.d/trueSkill  # make symbolic link
update-rc.d /etc/init.d/trueSkill defaults  # add to startup parameters
/etc/init.d/trueSkill start # starts the trueskill service
/etc/init.d/trueSkill status # ensure its running
```

Sometimes, the daemon may break and shutdown. A non-daemonized script has also been provided to run to calculate rankings for events that were not accounted for.

```bash
python trueSkill_noDaemon.py
```
**To have OCD about it runing** run this script daily (using a crontab or something) to ensure it runs daily. This is overkill, and I highly recommend against this practice. 

##Website Interface
Example Website Interface: [PlayTF2][6]

There are no official website interfaces that I have designed for this ranking system (because it is a trivial task). Later in the future I plan to design an official website interface for this plugin.

However, because I understand that most people want their own website interface, the code from [PlayTF2][6] website should be used as a reference. See this [repository](https://github.com/yusuf-a/hlstatsx) for examples.

Feel free to use it as a reference or just rip the website and use it as your own

##Additional Information

* [ChangeLog][7]
* [Previous Releases][8]
* SourceCode: [GitHub][9] or [My Website][10]


[1]: http://trueskill.org/
[2]: https://pypi.python.org/pypi/PyMySQL
[3]: https://forums.alliedmods.net/showthread.php?t=67640
[4]: https://forums.alliedmods.net/showthread.php?t=169095
[5]: http://research.microsoft.com/en-us/projects/trueskill/
[6]: http://playtf2.com/stats/
[7]: https://github.com/yusuf-a/tf2Skill/commits/master
[8]: https://github.com/yusuf-a/tf2Skill/releases
[9]: https://github.com/yusuf-a/tf2Skill
[10]: http://yusufali.ca/repos/tf2Skill.git/