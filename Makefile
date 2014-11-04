CC = ./addons/sourcemod/scripting/spcomp
INC = addons/sourcemod/scripting/include

compile: addons/sourcemod/scripting/trueskill.sp
	$(CC) addons/sourcemod/scripting/trueskill.sp -oaddons/sourcemod/plugins/trueskill.smx -i$(INC)