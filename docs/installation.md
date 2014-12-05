#Plugin Installation

Download the .smx file and save it to the plugins directory into your sourcemod plugins folder. Edit the **default** entry in `addons/sourcemod/configs/databases.cfg`:

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



#MySQL Database Setup

A MySQL database is used to store and track all player data.

Import `trueSkill.sql` into your MySQL database



#Scripts Setup

Place the files in the scripts folder as set in the `sm_trueskill_url` CVar. 
Edit `config.file.sample` and then rename it to `config.file`
To test that it works, browse to the url specified in the `sm_trueskill_url` CVar. If the page doesn't show and error, then it has been successfully installed.




#Website Interface

There are no official website interfaces that I have designed for this ranking system. Later in the future I plan to design an official website interface for this plugin.

However, because I understand that most people want their own website interface, the code from [PlayTF2][1] website should be used as a reference. See this [repository][2] for examples.

Feel free to use it as a reference or just rip the website and use it as your own

[1]: http://playtf2.com/stats/
[2]: https://github.com/yusuf-a/playtf2