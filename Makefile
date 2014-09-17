CC = ./spcomp

compile: scripting/trueskill.sp
	$(CC) scripting/trueskill.sp -oplugins/trueskill.smx
