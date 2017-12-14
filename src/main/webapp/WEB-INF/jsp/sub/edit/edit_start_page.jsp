<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript">
var select_mode = 0;		//편집할 객체 선택 여부 (0:편집 객체 없음, 1:이동편집 객체 선택, 2:사이즈 편집 객체 선택)
var select_edit_id = "";	//편집 객체
var select_edit_num = 0;	//편집 객체의 배열에서의 위치
var tempTabArr = null;		//tabArr 임시저장
var tempOldNameArr = null	//tabArr 임시저장(이름 변경 전)
var tempTabTypeArr = null;	//tabTypeArr 임시저장
var tempTabNumArr = null;	//tabNumArr 임시저장
var tempTabName = "";		//tabName 임시저장
var tempTabelHeight = 0;	//이미지 테이블1의 높이 임시저장
var imgType1 = "";

$(function(){
	$('#menus').mousemove(function(event){
		var x = event.pageX;
		var y = event.pageY;
		
		if(select_mode == 1){
			$('.select_edit').css("left", x - ($('.select_edit').width()/2));
			$('.select_edit').css("top", y - ($('.select_edit').height()/2));
		}else if(select_mode == 2){
			resizeImageTable(y);
		}
		event.preventDefault();
	});
	
	$('#menus').mouseup(function(event){
		if(select_mode == 1){
			var x = event.pageX;
			var y = event.pageY;
			find_move_obj(x);
			$('.select_edit').remove();
			select_mode = 0;
		}if(select_mode == 2){
			select_mode = 0;
		}
		event.preventDefault();
	});
	
	$('body').mousedown();
	
	$('body').mouseup();
});

//편집 모드
function contentMove(){
	if(editMode == 0){
		$('#editPopBtn').css('display', 'block');
		$('#moreViewImg').css('display', 'none');
		
		editMode = 1;										//편집모드로 변경(편집모드 : 1 , 편집불가: 0)
		iconSetting();										//아이콘 변경
		tempTabArr = jQuery.extend([], tabArr);
		tempTabTypeArr = jQuery.extend([], tabTypeArr);		//탭 타입 메뉴 임시저장 하기
		tempTabNumArr = jQuery.extend([], tabNumArr);
		tempOldNameArr = jQuery.extend([], tabArr);			//tabArr oloName 임시저장
		tempTabName = nowTabName;
		
		$('#tabRadio_'+tempTabName).attr('checked',true);	//첫 번째 탭 선택
		var tmpIdx = $.inArray(tempTabName, tempTabArr);	//현재 선택 탭 배열번호
		imgType1 = tempTabTypeArr[tmpIdx];					//현재 선택 탭 list type
		
		if(nowRightTabName == 'content'){
			if(imgType1 == "gellery"){
				nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/150);	//현재 컨텐츠 갯수
			}else{
				nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/102);	//현재 컨텐츠 갯수
			}
		}else{
			nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/26)-2;	//현재 컨텐츠 갯수
		}
		
		tempTabelHeight = tempTabNumArr[tmpIdx];
		nowTabelHeight = tempTabelHeight;			//탭 테이블의 높이를 현재 테이블 높이로 저장
		
		$('.tabDiv').animate({width : "+=15"});				//라디오 버튼 추가로 인한 탭 너비 조절
		totalHeaderWidth += (15 * (tabArr.length-2));		//라디오 버튼 추가로 인한 탭 너비 조절
		
		if(totalHeaderWidth > $('#tabHeader').width()){
			$('.moveIcon').css('display', 'block');
			$('#tabHeader_long').css('margin-left', '30px');
		}
		
		tabMaxMoveNum = $('#tabHeader').width();
		tabMoveNum = 0;
		
		//openApi 메뉴와 latest 테이블 view 여부
		var idx = $.inArray('OpenApi', menuArr);
		if(idx >= 0){
			$('#view_OpenApi').attr('checked', true);
		}
		var idx1 = $.inArray('latestUpload', menuArr);
		if(idx1 >= 0){
			$('#view_latestUpload').attr('checked', true);
		}
		
		editModeEvent();

		//임시 테이블 셋팅
		if(nowRightTabName == 'content'){
			editLeftSetting(imgType1, nowContnetNum, nowTabelHeight, 1);
		}else{
			editLeftBoardSetting(nowContnetNum, nowTabelHeight, 1);
		}
	}else{
		editExit();	//편집모드 빠져나가기
	}
}

//Edit Mode Event 초기화 및 이벤트 막기
function editModeEvent(){
	//편집 객체 초기화
	$('.over_edit').remove();
	$('.select_edit').remove();
	select_mode = 0;
	select_edit_id = "";
	
	$("a").attr("href", "#");	//a 객체 이벤트 초기화
	$(".menu_images").attr("onclick", null);	//메뉴 이미지 객체 이벤트 초기화
	$('.tabsClass').attr("onclick", null);	//메뉴 이미지 객체 이벤트 초기화
	
	$(".editing").css("display","block");	//객체 편집모드에 만  버튼이미지 보이기
	moveObjView();
}

//편집 가능한 객체 보여주기
function moveObjView(){
	var editWidth = 0;	//편집 객체 너비
	var editHeight = 0; //편집 객체 높이
	var editLeft = 0;   //편집 객체 left
	var editTop = 0;    //편집 객체 top
	var editCursor= "move"; //객체 마우스 오버시 커서 
	var innerHTMLStr = "";
	
	//image_table
	editWidth = $('#left_list_table_1').width() + 38;
	editHeight = $('#left_list_table_1').height();
	editLeft = 0;
	editTop = 160;
	editCursor = "s-resize";
	
	innerHTMLStr += "<div id='left_list_table_1_view' class='over_edit'";	//이미지 리스트 영역
	innerHTMLStr += "style='position:absolute; width:" + editWidth + "px;height:" + editHeight + "px; left:" + editLeft + "px; top:" + editTop + "px;background-color:#999;opacity:0.3;z-index:998;'></div>";
	innerHTMLStr += "<div id='left_list_table_1_resize' class='over_edit' ";	//이미지 리스트 조절 영역
	innerHTMLStr += "style='position:absolute; width:" + editWidth + "px;height:20px; left:" + editLeft + "px; top:" + (editTop +editHeight) + "px;background-color:red;opacity:0.3;cursor:" + editCursor + ";z-index:999;'></div>";
	
	$('#menus').append(innerHTMLStr);
	$(".over_edit").mousedown(function(){ edit_move(this.id);});
	$(".tabsClass").mousedown(function(){ edit_move(this.id);});
}

//메뉴아이템을 클릭했을때 이벤트
function edit_move(objId){
	if(objId != null && objId != ""){
		if($.inArray( objId , tempTabArr ) > -1){
			select_mode = 1;
			select_edit_id = objId;
			
			var editWidth = $('#'+objId).parent().width();
			var editHeight = $('#'+objId).parent().height();
			var editLeft = $('#'+objId).parent().offset().left;
			var editTop = $('#'+objId).parent().offset().top;
			
			var innerHTMLStr = "";
			innerHTMLStr = "<div class='select_edit' style='position:absolute; width:" + editWidth + "px;height:" + editHeight + "px; left:" + editLeft + "px; top:" + editTop+ "px; ";
			innerHTMLStr += "background-color:yellow;z-index:999;opacity:0.5;'> " + select_edit_id + " </div>";
			$('#menus').append(innerHTMLStr);
		}else if(objId == "left_list_table_1_resize"){
			select_mode = 2;
			select_edit_id = objId.replace("_resize","");
		}
	}
}

//편집 객체 위치 변경
function find_move_obj(x){
	var tpNum = tempTabArr.length-1; //바꿀 위치 번호
	
	for(var i=0;i<tempTabArr.length;i++){
		var x_half = 0;
		
		if(tempTabArr[i] == select_edit_id){
			select_edit_num = i;
		}
		
		if(i < tempTabArr.length-1){
			x_half = ($('#'+tempTabArr[i+1]).offset().left) + ($('#'+tempTabArr[i+1]).width()/2);
		}
		
		if(i == 0 && x < $('#'+tempTabArr[i]).offset().left + ($('#'+tempTabArr[i]).width()/2)){
			tpNum = 0;
		}else if(x > $('#'+tempTabArr[i]).offset().left && x <  x_half){
			tpNum = i+1;
		}
	}
	
	var tempArray = new Array();
	var tempTypeArray = new Array();
	var tempNumArray = new Array();
	var tempOldNameArray = new Array();
	var cnt = 0;
	if(select_edit_num < tpNum){
		for(var i=0;i<tempTabArr.length;i++){
			if(i>= select_edit_num+1 && i < tpNum){
				tempArray[cnt] = tempTabArr[cnt+1];
				tempTypeArray[cnt] = tempTabTypeArr[cnt+1];//
				tempNumArray[cnt] = tempTabNumArr[cnt+1];//
				tempOldNameArray[cnt] = tempOldNameArr[cnt+1];//
			}else if(i == tpNum){
				tempArray[cnt] = tempTabArr[select_edit_num];
				tempTypeArray[cnt] = tempTabTypeArr[select_edit_num];//
				tempNumArray[cnt] = tempTabNumArr[select_edit_num];//
				tempOldNameArray[cnt] = tempOldNameArr[select_edit_num];//
				tempArray[++cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else if( i != select_edit_num){
				tempArray[cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else{
				cnt--;
			}
			cnt++;
		}
	}else if(select_edit_num > tpNum){
		for(var i=0;i<tempTabArr.length;i++){
			if(i == select_edit_num){
				cnt--;
			}else if(i > tpNum && i != select_edit_num){
				tempArray[cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else if(i == tpNum){
				tempArray[cnt] = tempTabArr[select_edit_num];
				tempTypeArray[cnt] = tempTabTypeArr[select_edit_num];//
				tempNumArray[cnt] = tempTabNumArr[select_edit_num];//
				tempOldNameArray[cnt] = tempOldNameArr[select_edit_num];//
				tempArray[++cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else{
				tempArray[cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}
			cnt++;
		}
	}else{
		tempArray = tempTabArr;
		tempTypeArray = tempTabTypeArr;//
		tempNumArray = tempTabNumArr;//
		tempOldNameArray = tempOldNameArr;//
	}
	
	tempTabArr = tempArray;
	tempTabTypeArr = tempTypeArray;//
	tempTabNumArr = tempNumArray;//
	tempOldNameArr = tempOldNameArray;//
	tabSetting();
}

var nowContnetNum = 0;
var nowTabelHeight = 0;
//이미지 테이블 사이즈 조절
function resizeImageTable(y){
	var editHeingt = $('#'+select_edit_id).height();
	var editTop = $('#'+select_edit_id).offset().top;
// 	y = y-editTop;
	y = Math.floor(y-editTop);
	
	var tempSNum = 0;
	var tempNum = 0;
	if(nowRightTabName == 'content'){
		if(imgType1 == "gellery"){
//	 		tempSNum = 126;
			tempSNum = 150;
		}else{
			tempSNum = 102;
		}
		tempNum = Math.floor((y-25)/tempSNum);
	}else{
		tempSNum = 26;
		tempNum = Math.floor((y-25)/tempSNum)-1;
	}
	
// 	var tempNum = Math.floor((y-25)/tempSNum);
	if(y + editTop > 895 || y < 140){
		return;
	}

	nowTabelHeight = y;	//now tab height setting y
	$('#'+select_edit_id).css('height', y);
	$('#'+select_edit_id+"_view").css('height', y);
	$('#'+select_edit_id+"_resize").css('top',  y + editTop -6);
	
	if(tempNum > 0 && (tempNum > nowContnetNum || tempNum < nowContnetNum)){
		nowContnetNum = tempNum;
		
		if(nowRightTabName == 'content'){
			editLeftSetting(imgType1, nowContnetNum, nowTabelHeight, 1);
		}else{
			editLeftBoardSetting(nowContnetNum, nowTabelHeight, 1)
		}
	}else if(tempNum > 0 ){
		if(nowRightTabName == 'content'){
			editlatestSetting(imgType1);
		}else{
			editlatestBoardSetting();
		}
	}
}

//edit mode sample content list1
function editLeftSetting(eimgType1, eContnetNum, eNowTabelHeight, eTableNum){
	var target = document.getElementById('left_list_table_'+eTableNum);
// 	var blankImg = 'images/blank(100x70).PNG';
	var blankImg = 'images/geoImg/sharkzone.jpg';
	
	if(eTableNum == 1){
		$('#left_list_table_1').empty();
	}
	
	var max_row = eContnetNum;							//image table image width
	var max_cell = (eimgType1 == "gellery")?3:1;		//image table image width
	var imgWidth = (eimgType1 == "gellery")?100:120;	//image table image width
	var imgHeight = (eimgType1 == "gellery")?110:73;	//image table image height
	var totalArrCnt = (eimgType1 == "gellery")?eContnetNum*3:eContnetNum;
// 	$('#'+obj.table_name).attr("border","0");

	for(var i=0; i<totalArrCnt; i++) {
 		//image add
		var img_row;
		if(i % max_cell == 0){
			img_row = target.insertRow(-1);
		}
		
		var img_cell = img_row.insertCell(-1);
		var innerHTMLStr = "";
		innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:3px solid gray'/>";
		 if(eimgType1 == "gellery"){innerHTMLStr += "<div style='margin-left: 10px;font-size:12px;border: 3px solid gray;width: 100px;line-height: 20px;margin-top: -13px;'>&nbsp&nbsp&nbsp</div>";}
		img_cell.innerHTML = innerHTMLStr;
	}
	
	if(eTableNum == 1){
		//paging area draw
		img_row = target.insertRow(-1);
		var img_cell = img_row.insertCell(-1);
		img_cell.colSpan = '3';
		img_cell.height = '18px';
		img_cell.setAttribute('style', 'font-size: 13px; width: 400px;');
		var innerHTMLStr = "<div id='pagingDiv' style='line-height:20px;'>paging area</div>";
		img_cell.innerHTML = innerHTMLStr;
		editlatestSetting(eimgType1);
	}
	
	if(eimgType1 != "gellery"){
		$('#left_list_table_'+ eTableNum +'  tbody tr td').css('width', '400px');
		$('#left_list_table_'+ eTableNum +'  tbody tr td').css('border-bottom', '1px solid gray');
		$('#left_list_table_'+ eTableNum +'  tbody tr:last-child td').css('border-bottom', 'none');
	}
}

//edit mode sample content list2
function editlatestSetting(eImgType){
	//latest table draw
	var eTableH = 800 - $('#imageMoveArea').children().first().height() - $('#tabHeader').height() - Number(nowTabelHeight) - 60;
	var etableT = Number(nowTabelHeight) + 220;
	var eTableN = Math.floor((eImgType == "gellery")?eTableH/150: eTableH/102);
	
	$('#left_list_table_2').empty();
	$('#latestUpload').css('top', (Number(nowTabelHeight)+200) +"px");
	$('#image_latest_list').css('top', (etableT)+"px");

	if(eTableN > 0){
		$('#latestUpload').css('display', 'block');
		editLeftSetting(eImgType, eTableN, nowTabelHeight, 2);
	}else{
		$('#latestUpload').css('display', 'none');
	}
}

//edit mode sample boaard list1
function editLeftBoardSetting(bNowContnetNum, bNowTabelHeight, eTableNum){
	if(eTableNum == 1){
		$('#left_list_table_1').empty();
	}
	
	var innerHTMLStr = "";
	innerHTMLStr += "<tr style='height:25px;'>";
// 	innerHTMLStr += "<td width='200'>제목</td>";
// 	innerHTMLStr += "<td width='70'>작성자</td>";
// 	innerHTMLStr += "<td width='100'>작성일</td>";
	innerHTMLStr += "<td width='200'>TITLE</td>";
	innerHTMLStr += "<td width='70'>WRITER</td>";
	innerHTMLStr += "<td width='100'>DATE</td>";
	innerHTMLStr += "<tr class='tr_line' bgcolor='#D2D2D2'><td colspan='3'></td></tr>";
	innerHTMLStr += "<tr class='tr_line' bgcolor='#82B5DF'><td colspan='3'></td></tr>";

	for(var i=0;i<bNowContnetNum;i++){
		innerHTMLStr += "<tr style='text-align:center;height:25px;'>";
		innerHTMLStr += "<td style='text-align:left;'> TEST TEXT ...</td><td>sample</td><td>2016.10.10</td>";
		innerHTMLStr += "</tr><tr class='tr_line' bgcolor='#D2D2D2'><td colspan='3'></td></tr>";
	}
	$('#left_list_table_'+eTableNum).append(innerHTMLStr);
	$('#left_list_table_'+eTableNum).attr('border', '0');
	
	if(eTableNum == 1){
		//paging area draw
		innerHTMLStr = "";
		innerHTMLStr += "<tr>";
		innerHTMLStr += "<td colspan='3'style='font-size: 13px; width: 400px;'>";
		innerHTMLStr += "<div id='pagingDiv' style='line-height:20px;'>paging area</div>";
		innerHTMLStr += "</td></tr>";
		$('#left_list_table_'+eTableNum).append(innerHTMLStr);
		editlatestBoardSetting();
	}
}

//edit mode sample boaard list2
function editlatestBoardSetting(){
	//latest table draw
	var eTableH = 800 - $('#imageMoveArea').children().first().outerHeight() - $('#tabHeader').height() - Number(nowTabelHeight) - 100;
	var eTableN = Math.floor(eTableH/26)-1;
	
	$('#left_list_table_2').empty();
	$('#latestUpload').css('top', (Number(nowTabelHeight)+200) +"px");
	$('#image_latest_list').css('top', (Number(nowTabelHeight) + 220)+"px");
	
	if(eTableN > 0){
		$('#latestUpload').css('display', 'block');
		editLeftBoardSetting(eTableN, nowTabelHeight, 2)
	}else{
		$('#latestUpload').css('display', 'none');
	}
}

//편집 모드 버튼 이벤트
function editBtnEvent(kind){
	if(editMode != 1){
		return;
	}

	if(kind == "SAVE"){	//save 버튼 클릭 이벤트
		var oldTabIdx = $.inArray(tempTabName, tempTabArr);
		tempTabNumArr[oldTabIdx] = nowTabelHeight;
		
		tabArr = tempTabArr;
		tabTypeArr = tempTabTypeArr;
		tabNumArr = tempTabNumArr;
		
		var apiCheck = $('#view_OpenApi').attr('checked')==true?1:0;
		var latestCheck = $('#view_latestUpload').attr('checked')==true?1:0;
		
		if(nowRightTabName == 'content'){
			setObj.contentTab = replaceArray(tabArr);
			setObj.contentTabType = replaceArray(tabTypeArr);
			setObj.contentNum = replaceArray(tabNumArr);
		}else if(nowRightTabName == 'board'){
			setObj.boardTab = replaceArray(tabArr);
			setObj.boardNum = replaceArray(tabNumArr);
		}
		setObj.openAPI = apiCheck;
		setObj.latestView = latestCheck;
		
		var Url			= baseRoot() + "cms/updateBase/";
		var param		= loginToken + "/" + setObj.contentTab + "/" + setObj.contentTabType + "/" + setObj.boardTab + "/" + setObj.contentNum 
							+ "/" + setObj.boardNum + "/" + setObj.openAPI + "/" + setObj.latestView + "/" + setObj.mapZoom;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "get"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				saveTabModify();
			}
		});
		
	}else if(kind == "CANCEL"){ //cancel 버튼 클릭
		editExit();
		setTimeout(function(){
			contentMove();
		},200);
		
	}
}

//수정 사항 저장
function saveTabModify(){
	
	var Url			= baseRoot() + "cms/updateTabName/";
	var param		= loginToken + "/" + tempOldNameArr + "/" + tempTabArr + "/" + nowRightTabName;
	var callBack	= "?callback=?";

	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			
			if(data.Code == '100'){
				editExit();
// 				jAlert("저장 되었습니다.", '정보');
				jAlert("Saved.", 'Info');
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//ui reload
function reloadModify(){
	menuSetting();		//메뉴 설정
	tabSetting();		//상단 리스트 TAB 설정
}

//array replace
function replaceArray(arr){
	var tmp = JSON.stringify(arr);
	tmp = tmp.replace(/\"/g,"");
	tmp = tmp.replace(/\[/g,"");
	tmp = tmp.replace(/\]/g,"");
	return tmp;
}

//exit 버튼 클릭 이벤트 , 편집 모드 빠져나가기
function editExit(){
	editMode = 0;		//편집 불가 모드로 변경
	nowTabName = "";
	$('#image_map').css('z-index',10);	//구글 맵 이벤트 복구
	tabSetting();		//상단 리스트 TAB 설정
	menuSetting();		//메뉴 설정
	
	$('#editPopBtn').css('display',"none");	//편집 창 숨기기
	$('#moreViewImg').css('display', 'block'); //더보기 창 보이기
	
	tempTabArr = null;
	tempTabTypeArr = null;
	tempTabNumArr = null;
	tempOldNameArr = null;
	$('#view_OpenApi').attr('checked', false);
	$('#view_latestUpload').attr('checked', false);
	
	for(var i=0;i<menuArr.length;i++){
		if(menuArr[i].indexOf("OpenApi") > -1){
			if(setObj.openAPI == 0){
				menuArr[i] = 'OpenApi_off';
				$('#OpenApi').css('display', 'none');
			}else{
				menuArr[i] = 'OpenApi';
				$('#OpenApi').css('display', 'block');
			}
		}else if(menuArr[i].indexOf("latestUpload") > -1){
			if(setObj.latestView == 0){
				menuArr[i] = 'latestUpload_off';
			}else{
				menuArr[i] = 'latestUpload';
			}
		}
	}
}

//tab menu add
function tabEditBtn(kind){
	if(nowRightTabName == 'board'){				//오른쪽 탭이 board 일때 리스트 타입 을 none
		$('#addTabTr').css('visibility', 'hidden');
	}else{
		$('#addTabTr').css('visibility', 'visible');
	}
	
	if(kind  == "ADD"){
		$('#addTabName').val("");
		$("input[name=addTabRaido][value=list]").attr("checked", true);
		$('#saveBtn').css('display', 'block');
		$('#modifyBtn').css('display', 'none');
		$('#tabAddDig').dialog('open');
	}else if(kind  == "EDIT"){
		var thisId = $('input[name=tabRadio]:checked').attr('id').split("_")[1];
		var thisIndex = $.inArray(thisId , tempTabArr );
		var thisType = tempTabTypeArr[thisIndex];
		if(thisId != null && thisId != ""){
			$('#addTabName').val(thisId);
			$("input[name=addTabRaido][value="+ thisType +"]").attr("checked", true);
			$('#saveBtn').css('display', 'none');
			$('#modifyBtn').css('display', 'block');
			$('#tabAddDig').dialog('open');
		}
	}else if(kind  == "DELETE"){
		var thisId = $('input[name=tabRadio]:checked').attr('id').split("_")[1];
		var thisIndex = $.inArray(thisId , tempTabArr );
// 		jConfirm("'" + thisId + "'  탭을 삭제 하시겠습니까?", '', function(text){
		jConfirm("'" + thisId + "'  Are you sure you want to delete the tab?", '', function(text){
			if(text == true){
				if(tempTabArr.length <= 1){
// 					jAlert("삭제 할 수 없습니다.", '정보');
					jAlert("Unable to delete.", 'Info');
					return;
				}
				tempTabArr.splice(thisIndex, 1);
				tempTabTypeArr.splice(thisIndex, 1);
				tempTabNumArr.splice(thisIndex, 1);
				tempOldNameArr.splice(thisIndex, 1);
				tempTabName = tempTabArr[0];
				reloadModify();
			}
		});
	}
}

//tab 항목 추가
function addTabData(btn){
	var tName = $('#addTabName').val();
	var tType = $(':radio[name="addTabRaido"]:checked').val();
	
	if(btn == "save"){
		if($.inArray(tName, tempTabArr) > -1){
// 			jAlert("중복된 이름입니다.", '정보');
			jAlert("Duplicate name.", 'Info');
			return;
		}
		tempTabArr.push(tName);
		tempTabTypeArr.push(tType);
		tempTabNumArr.push(nowTabelHeight);
	}else if(btn == "modify"){
		var tId = $(':radio[name="tabRadio"]:checked').attr('id').split("_")[1];
		var tIdx = $.inArray(tId, tempTabArr);
		tempTabArr[tIdx] = tName;
		tempTabTypeArr[tIdx] = tType;
		tempTabNumArr[tIdx] = nowTabelHeight;
	}
	
	tempTabName = tName;
	$('#tabAddDig').dialog('close');
	reloadModify();
}

//메뉴 및 latist list 숨기기
function viewCheck(obj){
	var targetId =  obj.id.split("_")[1].trim();
	var thisIndex = 0;
	
	if(!obj.checked){
		thisIndex = $.inArray(targetId, menuArr);
		$('#'+targetId).css('display', 'none');
		menuArr[thisIndex] = targetId+"_off";
		if(targetId == "latestUpload"){
			$('#image_latest_list').css('display', 'none');
		}
	}else{
		thisIndex = $.inArray(targetId+"_off", menuArr);
		$('#'+targetId).css('display', 'block');
		menuArr[thisIndex] = targetId;
		if(targetId == "latestUpload"){
			$('#image_latest_list').css('display', 'block');
		}
	}
}

//user authority manage
function userManage(){
	if(editMode != 1){
		return;
	}
	var manageDig = jQuery.FrameDialog.create({
		url: '<c:url value="/geoCMS/userManage.do"/>',
		title: 'MANAGE',
		width: 720,
		height: 540,
		buttons: {},
		autoOpen:false
	});
	manageDig.dialog('open');
}
</script>
