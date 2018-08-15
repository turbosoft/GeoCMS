<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="page_common.jsp"></jsp:include>

<title>GeoCMS</title>

<script type="text/javascript">

$(function() {
	var $search = $('#search_bar');//Cache the element for faster DOM searching since we are using it more than once
	original_val = $search.val(); //Get the original value to test against. We use .val() to grab value="Search"
	$search.focus(function(){ //When the user tabs/clicks the search box.
		if($(this).val()===original_val){ //If the value is still the default, in this case, "Search"
			$(this).val('');//If it is, set it to blank
		}
	})
	.blur(function(){//When the user tabs/clicks out of the input
		if($(this).val()===''){//If the value is blank (such as the user clicking in it and clicking out)...
			$(this).val(original_val); //... set back to the original value
		}
	});
	
});

//search
function search() {
	var text = $('#search_bar').val();

	if(text.length == 0) {
// 		jAlert("검색어를 입력해 주세요.", "정보");
		jAlert("Please enter a search term.", "Info");
	}
	else {
		var boardChk, imageChk, videoChk, check, display;
		
// 		boardChk = $('#search_board').attr('checked');
		boardChk = false;
		imageChk = $('#search_image').attr('checked');
		videoChk = $('#search_video').attr('checked');
		if(!boardChk && !imageChk && !videoChk){
// 			jAlert("키워드 대상을 선택해 주세요.", "정보");
			jAlert("Please select a keyword target.", "Info");
			return;
		}
		
		if(projectImage != 1 && projectVideo != 1){
			$('input[name=search_check2]').attr('checked',false);
			$('input[name=search_check2]').attr('disabled',true);
		}
		
		if($('input[name=search_check1]').attr('checked') && $('input[name=search_check2]').attr('checked')) check = "all";
		else if(!$('input[name=search_check1]').attr('checked') && !$('input[name=search_check2]').attr('checked')) {
// 			jAlert("키워드 대상을 선택해 주세요.", "정보"); }
			jAlert("Please select a keyword target.", "Info"); }
		else {
			if($('input[name=search_check1]').attr('checked')) check = "content";
			if($('input[name=search_check2]').attr('checked')) check = "anno";
		}

		display = $('#display').val();

		if(check.length>0 && display.length>0) {
			searchPageInit(text, boardChk, imageChk, videoChk, check, display);
		}
// 		else jAlert('검색 조건이 잘못 되었습니다.', '정보');
		else{
			jAlert('Invalid search criteria.', 'Info');
		}
	}
}

function changeSearchKind(){
// 	var board_chk = $('#search_board').attr('checked');
	var board_chk = false;
	var image_chk = $('#search_image').attr('checked');
	var video_chk = $('#search_video').attr('checked');
	
	if((image_chk == true && projectImage == 1) || (video_chk == true && projectVideo == 1)){
		$('input[name=search_check2]').attr('disabled',false);
	}
	if((projectImage == 1 && projectVideo == 1 && image_chk == false && video_chk == false) ||
			(image_chk == false && projectVideo != 1) || (video_chk == false && projectImage != 1)){
		$('input[name=search_check2]').attr('checked',false);
		$('input[name=search_check2]').attr('disabled',true);
	}
}
</script>

</head>
<body bgcolor='#FFF'>
	<div id='search_div' style='position:absolute; left:10px; top:150px; width:409px; height:748px; display:block; border:1px solid #999;'>
		
		<input id='search_bar' type='text' name='search_bar' value='Search for..' onKeyPress='submit(event);' style='display:none; position:absolute; left:130px; top:20px; width:560px; height:30px; font-family:Comic Sans MS; font-size:20px;'></input>
		
		<table style='position:absolute; left:5px; top:10px; width:397px; border:1px solid #999;' >
			<tr bgcolor='#e5e5e5'>
				<td align='center' width=100 rowspan='4'><label style='font-size:13px;'><b>Searching<br/>Option</b></label>&nbsp;</td>
				<td align='center' width=80><label style='font-size:12px;'><b>Search</b></label></td>
				<td>
<!-- 					<div style="float:left;"><input type="checkbox" id="search_board" checked onclick="changeSearchKind();"/><label style="color:#000; font-size:12px;">Board</label></div> -->
					<div style="float:left;"><input type="checkbox" id="search_image" checked onclick="changeSearchKind();"/><label style="color:#000; font-size:12px;">Image</label></div>
					<div style="float:left;"><input type="checkbox" id="search_video" checked onclick="changeSearchKind();"/><label style="color:#000; font-size:12px;">Video</label></div>
				</td>
			</tr>
			<tr bgcolor='#e5e5e5'>
				<td align='center' width=70><label style='font-size:12px;'><b>Target</b></label></td>
				<td><input type="checkbox" name="search_check1" checked/><label style="color:#000; font-size:12px;">Title/Content</label>
					<input type="checkbox" name="search_check2" checked/><label style="color:#000; font-size:12px;">Annotation</label></td>
			</tr>
			<tr bgcolor='#e5e5e5'>
				<td align='center' width=70><label style='font-size:12px;'><b>Display</b></label></td>
				<td>&nbsp;&nbsp;&nbsp;<label style="color:#000; font-size:12px;">Limit result count</label>
					<input id='display' type='text' value='100' style='width:30px;'></input></td>
			</tr>
		</table>
		
		<div id='search_result' style='position:absolute; left:5px; top:100px; width:395px; height:638px; display:block; border:1px solid #999999; overflow-y:scroll;'>
			 <jsp:include page="search/search.jsp"/>
		</div>
	</div>
</body>
</html>