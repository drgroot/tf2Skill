#Plugin

A precompiled version of the plugin will always be available in the `addons/sourcemod/plugins/` directory

#Installation

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

#Compiling

Should you need to compile the plugin, the dependencies should be included in the `scripting/include` directory. If not, you may have to grab them.