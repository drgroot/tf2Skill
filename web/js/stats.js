var Str_row = "<tr><td>{0}</td><td class='playerName' id='{1}'>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>"
var cur_page = 1

$(function(){
	populate(cur_page)

	$("#prev").click(function(){cur_page--; populate(cur_page)})
	$("#next").click(function(){cur_page++; populate(cur_page)})

	function showAlt(){$(this).replaceWith(this.alt)};
	function addShowAlt(selector){$(selector).error(showAlt).attr("src", $(selector).src)};
	addShowAlt("img");
})

function populate(page){
	if(page <1){
		cur_page = 1
		return
	}

	$.post('mod/list.php', {page: cur_page}, function(rows){
		rows = JSON.parse( rows )

		$("table").find("tr:gt(0)").remove();
		for(var index in rows){
			var player = rows[index]
			
			var rank = 15*(page -1) + parseInt(index) + 1

			var row = Str_row.format(rank, player.player_id, player.name, parseInt(player.elo), player.kills, player.deaths)
			$('table tr:last').after(row);
		}

		$(".playerName").click(function(){
			window.location.href = window.location.href.replace('index.html','') + 'player.html?player_id={0}'.format($(this).attr('id'))
		})
	})
}