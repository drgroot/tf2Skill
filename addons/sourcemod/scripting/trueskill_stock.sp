
public gotDB( Handle o, Handle h, const char[] e, any data){
	if( h == null )
		LogError("Database failure: %s", e)
	else
		db = h
}

public OnLibraryAdded(	const char[] name	){
	 if(	StrEqual( name, "updater" )	){
		Updater_AddPlugin( UPDATE_URL )
	 }
}
public Updater_OnPluginUpdated(){
	ReloadPlugin()
}

char[] getSteamID( client, bool validate=true ){
	char steam_id[STEAMID]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3 , steam_id, STEAMID, validate )
	return steam_id
}

char[] esc_getSteamID( client, bool validate=true ){
	char steam_id[STEAMID*2+1]
	GetClientAuthId( client, AuthIdType:AuthId_Steam3 , steam_id, STEAMID, validate )
	SQL_EscapeString( db, steam_id, steam_id, sizeof(steam_id)  )
	return steam_id
}

int getPlayerID( client ){
	return FindStringInArray( players, getSteamID( client ) )
}

/* prints an error given handle and error string */
printTErr( Handle hndle, const char[] error ){
	if( hndle == null ){
		LogError( "TrueSkill - Query Failed: %s", error )
		return 0
	}
	return 1
}

/*
	
	HANDLES CURL TO REMOTE WHEN NEEDED

*/
public T_query(Handle:owner,Handle:hndle,const String:error[],any:data){
	printTErr(hndle, error );

	if(data != 0){
		char query[QUERY_SIZE]
		char url[100]; GetConVarString( sm_url, url, sizeof(url) )

		Format(	query,sizeof( query ),"%s?group=%d", url, data	)
		HTTPRequestHandle send = Steam_CreateHTTPRequest( HTTPMethod_GET, query )
		Steam_SendHTTPRequest( send, onComplete )
	}
}
public onComplete( HTTPRequestHandle req, bool success, HTTPStatusCode status ){
	if( !success || status != HTTPStatusCode_OK ){
		LogError( "TrueSkill -  post failed" )
	}

	Steam_ReleaseHTTPRequest( req )
}