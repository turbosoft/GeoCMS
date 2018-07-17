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
var tempTabIdxArr = null;	//tab idx arr 임시저장
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
		//지도 초기 설정
		editMapSetting();
		
		$('#editPopBtn').css('display', 'block');
		$('#moreViewImg').css('display', 'none');
		
		editMode = 1;										//편집모드로 변경(편집모드 : 1 , 편집불가: 0)
		iconSetting();										//아이콘 변경
		tempTabArr = jQuery.extend([], tabArr);
		tempTabTypeArr = jQuery.extend([], tabTypeArr);		//탭 타입 메뉴 임시저장 하기
		tempTabNumArr = jQuery.extend([], tabNumArr);
		tempOldNameArr = jQuery.extend([], tabArr);			//tabArr oldName 임시저장
		tempTabName = nowTabName;
		tempTabIdxArr = jQuery.extend([], tabIdxArr);
		
		var tmpIdx = $.inArray(tempTabName, tempTabArr);	//현재 선택 탭 배열번호
		$('#tabRadio_'+tmpIdx).attr('checked',true);	//첫 번째 탭 선택
		imgType1 = tempTabTypeArr[tmpIdx];					//현재 선택 탭 list type
		
		if(nowRightTabName == 'content'){
			if(imgType1 == "gellery"){
				if(tempTabNumArr[tmpIdx] == null || tempTabNumArr[tmpIdx] == '' || tempTabNumArr[tmpIdx] == undefined){
					nowContnetNum = Math.floor(550/150);	//현재 컨텐츠 갯수
				}else{
					nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/150);	//현재 컨텐츠 갯수
				}
			}else{
				if(tempTabNumArr[tmpIdx] == null || tempTabNumArr[tmpIdx] == '' || tempTabNumArr[tmpIdx] == undefined){
					nowContnetNum = Math.floor(550/102);	//현재 컨텐츠 갯수
				}else{
					nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/102);	//현재 컨텐츠 갯수
				}
			}
		}else{
			nowContnetNum = Math.floor(tempTabNumArr[tmpIdx]/26)-2;	//현재 컨텐츠 갯수
		}
		
		tempTabelHeight = tempTabNumArr[tmpIdx];
		nowTabelHeight = tempTabelHeight;			//탭 테이블의 높이를 현재 테이블 높이로 저장
		
		$('.tabDiv').animate({width : "+=15"});				//라디오 버튼 추가로 인한 탭 너비 조절
		totalHeaderWidth += (15 * (tabArr.length-1));		//라디오 버튼 추가로 인한 탭 너비 조절
		
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
	innerHTMLStr += "style='position:absolute; width:" + editWidth + "px;height:20px; left:" + editLeft + "px; top:" + (editTop +editHeight) + "px;background-color:red;cursor:" + editCursor + ";z-index:999; background-image:url(/GeoCMS/images/geoImg/sizeBar.PNG);background-size:cover;'></div>";
	
	$('#menus').append(innerHTMLStr);
	$(".over_edit").mousedown(function(){ edit_move(this.id);});
	$(".tabsClass").mousedown(function(){ edit_move(this.id);});
}

//메뉴아이템을 클릭했을때 이벤트
function edit_move(objId){
	if(objId != null && objId != ""){
		var tmpNowSelectTabAIdx = objId.replace('tabA_','');
		var tmpNowSelectTabAName = $('#'+objId).text();
		if(tmpNowSelectTabAIdx > -1){
			select_mode = 1;
			select_edit_id = objId;
			
			var editWidth = $('#'+objId).parent().width();
			var editHeight = $('#'+objId).parent().height();
			var editLeft = $('#'+objId).parent().offset().left;
			var editTop = $('#'+objId).parent().offset().top;
			
			var innerHTMLStr = "";
			innerHTMLStr = "<div class='select_edit' style='position:absolute; width:" + editWidth + "px;height:" + editHeight + "px; left:" + editLeft + "px; top:" + editTop+ "px; ";
			innerHTMLStr += "background-color:#00BCD4;z-index:999;opacity:0.5;'> " + tmpNowSelectTabAName + " </div>";
		
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
	var tpNowSelectTabName = $('#'+ select_edit_id).text();
	
	for(var i=0;i<tempTabArr.length;i++){
		var x_half = 0;
		
		if(tempTabArr[i] == tpNowSelectTabName){
			select_edit_num = i;
		}
		
		if(i < tempTabArr.length-1){
			x_half = ($('#tabA_'+(i+1)).offset().left) + ($('#tabA_'+(i+1)).width()/2);
		}
		
		if(i == 0 && x < $('#tabA_'+ i).offset().left + ($('#tabA_'+i).width()/2)){
			tpNum = 0;
		}else if(x > $('#tabA_'+i).offset().left && x <  x_half){
			tpNum = i+1;
		}
	}
	
	var tempArray = new Array();
	var tempTypeArray = new Array();
	var tempNumArray = new Array();
	var tempOldNameArray = new Array();
	var tempIdxArray = new Array();
	var cnt = 0;
	if(select_edit_num < tpNum){
		for(var i=0;i<tempTabArr.length;i++){
			if(i>= select_edit_num+1 && i < tpNum){
				tempArray[cnt] = tempTabArr[cnt+1];
				tempTypeArray[cnt] = tempTabTypeArr[cnt+1];//
				tempNumArray[cnt] = tempTabNumArr[cnt+1];//
				tempIdxArray[cnt] = tempTabIdxArr[cnt+1];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[cnt+1];//
			}else if(i == tpNum){
				tempArray[cnt] = tempTabArr[select_edit_num];
				tempTypeArray[cnt] = tempTabTypeArr[select_edit_num];//
				tempNumArray[cnt] = tempTabNumArr[select_edit_num];//
				tempIdxArray[cnt] = tempTabIdxArr[select_edit_num];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[select_edit_num];//
				tempArray[++cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempIdxArray[cnt] = tempTabIdxArr[i];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else if( i != select_edit_num){
				tempArray[cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempIdxArray[cnt] = tempTabIdxArr[i];/////////////////////////
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
				tempIdxArray[cnt] = tempTabIdxArr[i];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else if(i == tpNum){
				tempArray[cnt] = tempTabArr[select_edit_num];
				tempTypeArray[cnt] = tempTabTypeArr[select_edit_num];//
				tempNumArray[cnt] = tempTabNumArr[select_edit_num];//
				tempIdxArray[cnt] = tempTabIdxArr[select_edit_num];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[select_edit_num];//
				tempArray[++cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempIdxArray[cnt] = tempTabIdxArr[i];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}else{
				tempArray[cnt] = tempTabArr[i];
				tempTypeArray[cnt] = tempTabTypeArr[i];//
				tempNumArray[cnt] = tempTabNumArr[i];//
				tempIdxArray[cnt] = tempTabIdxArr[i];/////////////////////////
				tempOldNameArray[cnt] = tempOldNameArr[i];//
			}
			cnt++;
		}
	}else{
		tempArray = tempTabArr;
		tempTypeArray = tempTabTypeArr;//
		tempNumArray = tempTabNumArr;//
		tempIdxArray = tempTabIdxArr;/////////////////////////
		tempOldNameArray = tempOldNameArr;//
	}
	
	tempTabArr = tempArray;
	tempTabTypeArr = tempTypeArray;//
	tempTabNumArr = tempNumArray;//
	tempTabIdxArr = tempIdxArray;/////////////////////////
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
			tempSNum = 150;
		}else{
			tempSNum = 102;
		}
		tempNum = Math.floor((y-25)/tempSNum);
	}else{
		tempSNum = 26;
		tempNum = Math.floor((y-25)/tempSNum)-1;
	}
	
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
	var blankImg = 'images/geoImg/sharkzone.jpg';
	
	if(eTableNum == 1){
		$('#left_list_table_1').empty();
	}
	
	var max_row = eContnetNum;							//image table image width
	var max_cell = (eimgType1 == "gellery")?3:1;		//image table image width
	var imgWidth = (eimgType1 == "gellery")?100:120;	//image table image width
	var imgHeight = (eimgType1 == "gellery")?110:73;	//image table image height
	var totalArrCnt = (eimgType1 == "gellery")?eContnetNum*3:eContnetNum;

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
		isFirstChk = false;
		var isFirstType = "";
		var oldTabIdx = $.inArray(tempTabName, tempTabArr);
		tempTabNumArr[oldTabIdx] = nowTabelHeight;
		
		tabArr = tempTabArr;
		tabTypeArr = tempTabTypeArr;
		tabNumArr = tempTabNumArr;
		tabIdxArr = tempTabIdxArr;
		
		var apiCheck = 0;
		var latestCheck = $('#view_latestUpload').attr('checked')==true?1:0;
		var chkBool = true;
		
		if(nowRightTabName == 'content'){
			setObj.contentTab = tabArr;
			setObj.contentTabType = tabTypeArr;
			setObj.contentNum = tabNumArr;
			setObj.contentTabIdx = tabIdxArr;
			if(tabArr == null || (tabArr!= null && tabArr.length<1) || tabTypeArr == null || (tabTypeArr!= null && tabTypeArr.length<1) || 
					tabNumArr == null || (tabNumArr!= null && tabNumArr.length<1)  || tabIdxArr == null || (tabIdxArr!= null && tabIdxArr.length<1) ){
				chkBool = false;
			}
			
		}else if(nowRightTabName == 'board'){
			setObj.boardTab = tabArr;
			setObj.boardNum = tabNumArr;
			setObj.boardTabIdx = tabIdxArr;
			if(tabArr == null || (tabArr!= null && tabArr.length<1)  || tabNumArr == null || (tabNumArr!= null && tabNumArr.length<1)  || 
					tabIdxArr == null || (tabIdxArr!= null && tabIdxArr.length<1) ){
				chkBool = false;
			}
		}
		
		if(!chkBool){
// 			jAlert('탭을 생성해 주세요.','정보');
			jAlert('Please create a tab.','Info');
			return;
		}
		
		if((setObj.latitude == null || setObj.latitude == undefined || setObj.latitude == '') && (setObj.longitude == null || setObj.longitude == undefined || setObj.longitude == '')){
			isFirstChk = true;
		}
		
		setObj.openAPI = apiCheck;
		setObj.latestView = latestCheck;
		setObj.latitude = homeMarker.getPosition().lat();
		setObj.longitude = homeMarker.getPosition().lng();
		setObj.mapZoom = map.getZoom();
		
		if(setObj.contentTab == null || setObj.contentTab == ''){
			setObj.contentTab = '&nbsp';
		}else{
			$.each(setObj.contentTab, function(idx , val){
				val = dataReplaceFun(val);
				if(val != null && val != undefined){
					val = val.replace(/,/g,'&xbsp');
				}
				setObj.contentTab[idx] = val;
			});
		}
		
		if(setObj.contentTabType == null || setObj.contentTabType == ''){setObj.contentTabType = '&nbsp';}
		if(setObj.contentNum == null || setObj.contentNum == ''){setObj.contentNum = '&nbsp';}
		if(setObj.contentTabIdx == null || setObj.contentTabIdx == ''){setObj.contentTabIdx = '&nbsp';}
		if(setObj.boardTab == null || setObj.boardTab == ''){
			setObj.boardTab = '&nbsp';
		}else{
			$.each(setObj.boardTab, function(idx , val){
				val = dataReplaceFun(val);
				if(val != null && val != undefined){
					val = val.replace(/,/g,'&xbsp');
				}
				setObj.boardTab[idx] = val;
			});
		}
		if(setObj.boardNum == null || setObj.boardNum == ''){setObj.boardNum = '&nbsp';}
		if(setObj.boardTabIdx == null || setObj.boardTabIdx == ''){setObj.boardTabIdx = '&nbsp';}
		
		serverDigOpen();
	}else if(kind == "CANCEL"){ //cancel 버튼 클릭
		cancelEditExit();
		setTimeout(function(){
			contentMove();
		},200);
		
	}
}

//ui reload
function reloadModify(){
	menuSetting();		//메뉴 설정
	tabSetting();		//상단 리스트 TAB 설정
}

//exit 버튼 클릭 이벤트 , 편집 모드 빠져나가기
function editExit(){
	window.location.href='/GeoCMS';
}

//exit 버튼 클릭 이벤트 , 편집 모드 빠져나가기
function cancelEditExit(){
	$('.viewModeCls').css('display','block');
	$('.morkerModeCls1').css('display','none');
	$('.morkerModeCls2').css('display','none');
	
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
	tempTabIdxArr = null;
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
		var thisIndex = $('input[name=tabRadio]:checked').attr('id').split("_")[1];
		var thisId = tempTabArr[thisIndex];
		
		var thisType = tempTabTypeArr[thisIndex];
		if(thisId != null && thisId != ""){
			$('#addTabName').val(thisId);
			$("input[name=addTabRaido][value="+ thisType +"]").attr("checked", true);
			$('#saveBtn').css('display', 'none');
			$('#modifyBtn').css('display', 'block');
			$('#tabAddDig').dialog('open');
		}
	}else if(kind  == "DELETE"){
		var thisIndex = $('input[name=tabRadio]:checked').attr('id').split("_")[1];
		var thisId = tempTabArr[thisIndex];
		
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
				tempTabIdxArr.splice(thisIndex, 1);/////////////////
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
		
		if(tName != null && tName.indexOf('\'') > -1){
// 			jAlert('특수문자 \' 는 사용할 수 없습니다.', '정보');
			jAlert('Special character \' can not be.', 'Info');
			return;
		}
		
		tempTabArr.push(tName);
		tempTabTypeArr.push(tType);
		if(nowTabelHeight == null || nowTabelHeight == '' || nowTabelHeight == 'null'){
			nowTabelHeight = 500;
		}
		tempTabNumArr.push(nowTabelHeight);
		tempTabIdxArr.push("&nbsp");
	}else if(btn == "modify"){
		var tParentId = $(':radio[name="tabRadio"]:checked').parent().attr('id');
		if(tParentId != null && tParentId != undefined){
			var tParentIdIdx = tParentId.split('_')[1];
			if($.inArray(tName, tempTabArr) > -1 && $.inArray(tName, tempTabArr) != tParentIdIdx){
// 				jAlert("중복된 이름입니다.", '정보');
				jAlert("Duplicate name.", 'Info');
				return;
			}
			
			if(tName != null && tName.indexOf('\'') > -1){
// 				jAlert('특수문자 \' 는 사용할 수 없습니다.', '정보');
				jAlert('Special character \' can not be.', 'Info');
				return;
			}
		}
		
		var tId = $(':radio[name="tabRadio"]:checked').next().text();
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

//edit marker init
function editMapSetting(){
	typeShape = "forSearch";
	LocationData = null;
	initialize();
	$('#searchDefaultPlace').val("");
	$('.viewModeCls').css('display','none');
	$('.morkerModeCls1').css('display','block');
	$('.morkerModeCls2').css('display','none');
	var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
	var marker_latlng = new google.maps.LatLng(dMarkerLat, dMarkerLng);
	homeMarker = new google.maps.Marker({
        position: marker_latlng,
        map: map,
        title: "default",			
        id: "default",
        label: {
        	text: "default",
        	fontSize: '0px'
        },
        icon: tmpMarkerIcon
    });
}

//place text click
function onPlaceChanged() {
	var place = mapAutocomplete.getPlace();
    if (place.geometry) {
      map.panTo(place.geometry.location);
      map.setZoom(15);
      homeMarker.setPosition(place.geometry.location);
    }else {
      document.getElementById('searchDefaultPlace').placeholder = 'Enter a city';
    }
}

var homeMarker = null;
var mapAutocomplete = null;
function defaultMarkerSet(setType){
	if(setType == 'open'){
		google.maps.event.addListener(map, 'click', function(event) {
			var latitude = event.latLng.lat();
		    var longitude = event.latLng.lng();
		    homeMarker.setPosition(event.latLng);
	    });
		
		$('.morkerModeCls1').css('display','none');
		$('.morkerModeCls2').css('display','block');
		
		mapAutocomplete = new google.maps.places.Autocomplete(
	            /** @type {!HTMLInputElement} */ (
	                document.getElementById('searchDefaultPlace')), {
// 	              types: ['(cities)'],
// 	              componentRestrictions: countryRestrict
	            });
	        places = new google.maps.places.PlacesService(map);

	        mapAutocomplete.addListener('place_changed', onPlaceChanged);
		
	}
	else if(setType == 'cencle'){
		editMapSetting();
	}
	
}

var serverTblCnt = 0;	//tatal server cnt
var serverNewCnt = 0;	//add server cnt
var isFirstChk = false; //first tab save
var isServerFirst = false;	//first server save
var serverHeight = 200;
var serverYIndex = 0;

//server dialog open
function serverDigOpen(){
	$('.ui-dialog-title').remove();
	$('.ui-dialog-titlebar').remove();
	getServerList();
}

function getServerList(){
	$('.serverTblClass').remove();
	serverTblCnt = 0;
	serverNewCnt = 0;
	isServerFirst = false;
	serverHeight= 200;
	
	var Url			= baseRoot() + "cms/selectServerList/";
	var param		= loginToken + "/" + loginId +"/" +"&nbsp";
	var callBack	= "?callback=?";
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			if(data.Code == '100'){
				serverDataSet(response);
				if(!$('#serverDig').dialog("isOpen")){
					$('#serverDig').dialog('open');
				}
			}else if(data.Code == '200'){
				serverDataSetDef_1();
				$('#serverPath_1').val(b_serverPath);
				$('#serverName_1').val('기본 서버');
				$('#serverRadio_1').attr('checked',true);
				$('.serverInputClass_1').attr('readonly',true);
				isServerFirst = true;
				serverYIndex = 1;
				$('#serverDig').dialog('open');
			}else{
				jAlert(data.Message, 'Info');
			}
			serverReSet();
		}
	});
}

function serverDataSet(response){
	if(response != null){
		for(var i=0;i<response.length;i++){
			if(response[i].serverurl != null && response != ''){
				serverDataSetDef_2();
				$('#serverName_'+serverTblCnt).val(response[i].servername);
				$('#serverUrl_'+serverTblCnt).val(response[i].serverurl);
				$('#serverPort_'+serverTblCnt).val(response[i].serverport);
				$('#serverId_'+serverTblCnt).val(response[i].serverid);
				$('#serverPass_'+serverTblCnt).val(response[i].serverpass);
				$('#serverPath_'+serverTblCnt).val(response[i].serverpath);
				$('#serverViewPort_'+serverTblCnt).val(response[i].serverviewport);
				$('#serverIdx_'+serverTblCnt).val(response[i].idx);
				if(response[i].selectyn == 'Y'){
					$('#serverRadio_'+serverTblCnt).attr('checked',true);
					serverYIndex = serverTblCnt;
				}
				$('.serverInputClass_'+serverTblCnt).attr('readonly',true);
				serverHeight = serverHeight + 215;
				if(serverHeight > 500){
					serverHeight = serverHeight - 215;
				}
			}else{
				serverDataSetDef_1();
				$('#serverPath_'+serverTblCnt).val(response[i].serverpath);
				$('#serverName_'+serverTblCnt).val(response[i].servername);
				$('#serverIdx_'+serverTblCnt).val(response[i].idx);
				if(response[i].selectyn == 'Y'){
					$('#serverRadio_'+serverTblCnt).attr('checked',true);
					serverYIndex = serverTblCnt;
				}
				$('.serverInputClass_'+serverTblCnt).attr('readonly',true);
			}
		}
		$('#serverDig').dialog('option','height',serverHeight);
	}
}

function serverDataSetDef_1(){
	serverTblCnt++;
	var htmlStr = '';
	htmlStr += '<table id="serverTbl_'+ serverTblCnt +'" class="serverTblClass" style="width:100%; margin-top:10px; background-color:lavender;">';
	htmlStr += 	'<tr>';
	htmlStr += 		'<td rowspan="2"  style="vertical-align:top; padding-top:10px;">';
	htmlStr += 			'<input type="radio" id="serverRadio_'+ serverTblCnt +'" value="'+ serverTblCnt +'" name="serverRadio"/>';
	htmlStr += 			'<input type="hidden" id="serverIdx_'+ serverTblCnt +'">';
	htmlStr += 		'</td>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>Server Name</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverName_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 		'<td rowspan="2" style="width:67px; vertical-align:top; padding-top:7px;">';
	htmlStr += 			'<button onclick="serverModify('+ serverTblCnt +',true);" id="serverMoBtn_'+ serverTblCnt +'" class="serverMoClass" style="width:65px;">Modify</button>';
	htmlStr += 			'<button onclick="serverUpdate('+ serverTblCnt +',\'U\');" id="serverUpBtn_'+ serverTblCnt +'" style="display:none; width:65px;" class="serverUpClass">Update</button>';
	htmlStr += 			'<button onclick="serverAddCenCle('+ serverTblCnt +');" id="serverCnBtn_'+ serverTblCnt +'" style="display:none; width:65px; margin-top:11px;" class="serverCnClass">Cencle</button>';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr +=			'<label>File Path</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverPath_'+ serverTblCnt + '" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += '</table>';
	
	$('#serverDiv').append(htmlStr);
}

function serverDataSetDef_2(){
	serverTblCnt ++;
	var htmlStr = '';
	htmlStr += '<table id="serverTbl_'+ serverTblCnt+ '" class="serverTblClass" style="width:100%; margin-top:10px; background-color:lavender;">';
	htmlStr += 	'<tr>';
	htmlStr += 		'<td rowspan="7" style="vertical-align:top; padding-top:10px;">';
	htmlStr += 			'<input type="radio" id="serverRadio_'+ serverTblCnt + '" value="'+ serverTblCnt +'" name="serverRadio"/>';
	htmlStr += 			'<input type="hidden" id="serverIdx_'+ serverTblCnt +'">';
	htmlStr += 		'</td>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>Server Name</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverName_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 		'<td rowspan="6" style="vertical-align:top; padding-top:7px;width:67px;">';
	htmlStr += 			'<button onclick="severRemove('+ serverTblCnt +');" id="serverRmBtn_'+ serverTblCnt +'" class="serverRmClass" style="width:65px;">Remove</button>';
	htmlStr += 			'<button onclick="serverModify('+ serverTblCnt +',true);" id="serverMoBtn_'+ serverTblCnt +'" class="serverMoClass" style="width:65px; margin-top:11px;">Modify</button>';
	htmlStr += 			'<button onclick="serverUpdate('+ serverTblCnt +',\'U\');" id="serverUpBtn_'+ serverTblCnt +'" style="display:none; width:65px;" class="serverUpClass">Update</button>';
	htmlStr += 			'<button onclick="serverSave(\'U\');" id="serverSaBtn_'+ serverTblCnt +'" style="display:none; width:65px;" class="serverSaClass">Save</button>';
	htmlStr += 			'<button onclick="serverAddCenCle('+ serverTblCnt +');" id="serverCnBtn_'+ serverTblCnt +'" style="display:none; width:65px; margin-top:11px;" class="serverCnClass">Cencle</button>';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>Server URL</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverUrl_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>Port Number</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverPort_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>View Port Number</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverViewPort_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>User ID</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="password" id="serverId_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>Password</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="password" id="serverPass_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += 	'<tr>';
	htmlStr += 		'<th style="width:120px; text-align:left;">';
	htmlStr += 			'<label>File Path</label>';
	htmlStr += 		'</th>';
	htmlStr += 		'<td>';
	htmlStr += 			'<input type="text" id="serverPath_'+ serverTblCnt +'" class="serverInputClass_'+ serverTblCnt +' serverInputClassW">';
	htmlStr += 		'</td>';
	htmlStr += 	'</tr>';
	htmlStr += '</table>';
	
	$('#serverDiv').append(htmlStr);
}

//add server
function serverAdd(){
	serverHeight = serverHeight + 215;
	$('#serverDig').dialog('option','height',serverHeight);
	serverNewCnt = serverTblCnt+1;
	$('#serverAddBtn').css('display','none');
	$('#serverBtnArea').css('display','none');
	serverDataSetDef_2();
	$('.serverMoClass').css('display','none');
	$('.serverUpClass').css('display','none');
	$('.serverRmClass').css('display','none');
	$('.serverCnClass').css('display','none');
	$('#serverSaBtn_'+serverNewCnt).css('display','block');
	$('#serverCnBtn_'+serverNewCnt).css('display','block');
	$(':radio[name="serverRadio"]').attr('disabled',true);
}

//add cencle server
function serverAddCenCle(tmpIdx){
	if(tmpIdx == serverNewCnt){
		$('#serverTbl_'+ serverNewCnt).remove();
		serverTblCnt = serverTblCnt-1;
		serverNewCnt = 0;
		serverHeight = serverHeight - 215;
		$('#serverDig').dialog('option','height',serverHeight);
	}else{
		$('.serverInputClass_'+tmpIdx).attr('readonly',true);
	}
	$(':radio[name="serverRadio"]').attr('disabled',false);
	serverReSet();
}

function serverReSet(){
	$('.serverMoClass').css('display','block');
	$('.serverRmClass').css('display','block');
	$('.serverUpClass').css('display','none');
	$('.serverSaClass').css('display','none');
	$('.serverCnClass').css('display','none');
	$('#serverAddBtn').css('display','block');
	$('#serverBtnArea').css('display','block');
	$('.serverInputClassW').attr('readonly',true);
}

//modify mode set
function serverModify(tmpTblIdx, tmpYN){
	if(tmpYN){
		$('.serverRmClass').css('display','none');
		$('.serverUpClass').css('display','none');
		$('.serverSaClass').css('display','none');
		$('.serverMoClass').css('display','none');
		$('.serverInputClass_'+tmpTblIdx).attr('readonly',false);
		$(':radio[name="serverRadio"]').attr('disabled',true);
		$('#serverUpBtn_'+tmpTblIdx).css('display','block');
		$('#serverCnBtn_'+tmpTblIdx).css('display','block');
		$('#serverBtnArea').css('display','none');
		$('#serverAddBtn').css('display','none');
	}else{
		serverReSet();
		$('.serverInputClass_'+tmpTblIdx).attr('readonly',true);
		$(':radio[name="serverRadio"]').attr('disabled',false);
	}
}

function serverSettingSave(){
	if(isServerFirst){
		serverSave("S");
	}else{
		var tmpNowRadioIdx = $(':radio[name="serverRadio"]:checked').val();
		if(serverYIndex == tmpNowRadioIdx){
			saveSetting();
		}else{
			serverUpdate(tmpNowRadioIdx,"S");
		}
	}
}


//server Save
function serverSave(sType){
	var serverName = $('#serverName_'+ serverNewCnt).val();
	var serverUrl = $('#serverUrl_'+ serverNewCnt).val();
	var serverPort = $('#serverPort_'+ serverNewCnt).val();
	var serverId = $('#serverId_'+ serverNewCnt).val();
	var serverPass = $('#serverPass_'+ serverNewCnt).val();
	var serverPath = $('#serverPath_'+ serverNewCnt).val();
	var serverViewPort = $('#serverViewPort_'+ serverNewCnt).val();
	var selectYn = $('#serverRadio_'+ serverNewCnt).attr('checked');
	var serverDefaultName = '&nbsp';
	var serverDefaultPath = '&nbsp';
	
	if(isServerFirst){
		serverDefaultName = $('#serverName_1').val();
		serverDefaultPath = $('#serverPath_1').val();
		
		if(serverDefaultName == null || serverDefaultName == ''){
// 			jAlert('서버명을 입력해 주세요.','Info');
			jAlert('Please enter server name.','Info');
			return;
		}
		if(serverDefaultPath == null || serverDefaultPath == ''){
// 			jAlert('저장할 파일 경로를 입력해 주세요.','Info');
			jAlert('Please enter the file path to save.','Info');
			return;
		}
	}
	
	if(serverNewCnt != 0 || (jQuery.type(serverUrl) !== undefined && jQuery.type(serverUrl) !== 'undefined')){
		if(serverName == null || serverName == ''){
// 			jAlert('서버명을 입력해 주세요.','Info');
			jAlert('Please enter server name.','Info');
			return;
		}
		if(serverUrl == null || serverUrl == ''){
// 			jAlert('서버 주소를 입력해 주세요.','Info');
			jAlert('Please enter a server address.','Info');
			return;
		}
		if(serverPort == null || serverPort == ''){
// 			jAlert('서버 포트를 입력해 주세요.','Info');
			jAlert('Please enter the server port.','Info');
			return;
		}
		if(serverId == null || serverId == ''){
// 			jAlert('서버 아이디를 입력해 주세요.','Info');
			jAlert('Please enter the server ID.','Info');
			return;
		}
		if(serverPass == null || serverPass == ''){
// 			jAlert('서버 비밀번호를 입력해 주세요.','Info');
			jAlert('Please enter your server password.','Info');
			return;
		}
		if(serverPath == null || serverPath == ''){
// 			jAlert('저장할 파일 경로를 입력해 주세요.','Info');
			jAlert('Please enter a file path to save.','Info');
			return;
		}
		if(serverViewPort == null || serverViewPort == ''){
// 			jAlert('파일을 불러올 포트를 입력해 주세요.','Info');
			jAlert('Please enter the port from which to load the file.','Info');
			return;
		}
// 		var prot_pattern = /^[0-9]$/g;
// 		alert(prot_pattern.test(serverPort.trim()));
// 		if(!prot_pattern.test(serverPort)){
// 			jAlert('서버 포트는 숫자만 입력이 가능합니다.','Info');
// 			return;
// 		}
// 		var server_pattern = /([0-9a-zA-Z\-]+\.)+([a-zA-Z]{2,6}+\.)+([a-zA-Z])/;
// 		if(!server_pattern.test(serverUrl)){
// 			jAlert('서버 주소가 형식에 맞지 않습니다.','Info');
// 			return;
// 		}
		
		if(selectYn){
			selectYn = 'Y';
		}else{
			selectYn = 'N';
		}
	}else{
		serverName = '&nbsp';
		serverUrl = '&nbsp';
		serverPort = '&nbsp';
		serverId = '&nbsp';
		serverPass = '&nbsp';
		serverPath = '&nbsp';
		serverViewPort = '&nbsp';
		selectYn = '&nbsp';
	}
	serverName = dataReplaceFun(serverName);
	serverId = dataReplaceFun(serverId);
	serverPass = dataReplaceFun(serverPass);
	serverPath = dataReplaceFun(serverPath);
	serverDefaultName = dataReplaceFun(serverDefaultName);
	serverDefaultPath = dataReplaceFun(serverDefaultPath);
	
	if(serverNewCnt != 0 || isServerFirst){
		var Url			= baseRoot() + "cms/saveServer/";
		var param		= loginToken + "/"+ loginId + "/" + serverName + "/" + serverUrl + "/" + serverPort +"/" + serverId + "/"+
							serverPass + "/ "+  serverPath + "/" + serverViewPort + "/"+ selectYn +"/"+ serverDefaultName +"/"+ serverDefaultPath;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data != null){
					if(data.Code == '100'){
						jAlert(data.Message, 'Info', function(res){
							if(sType == 'S'){
								saveSetting();
							}else if(sType == 'U'){
								getServerList();
							}
						});
						isServerFirst = false;
					}else{
						jAlert(data.Message,'Info');
					}
				}
			}
		});
	}
}

function saveSetting(){
	if(isFirstChk){
		var Url			= baseRoot() + "cms/insertBase/";
		var param		= loginToken + "/"+ loginId + "/" + setObj.contentTab + "/" + setObj.contentTabType + "/" + setObj.contentNum +"/" + setObj.contentTabIdx + "/"+
							setObj.boardTab + "/" + setObj.boardNum + "/"+ setObj.boardTabIdx +"/"+ setObj.openAPI + "/" + setObj.latestView +"/"+ setObj.latitude +"/"+
							setObj.longitude +"/" + setObj.mapZoom;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data != null){
					if(data.Code == '100'){
						jAlert(data.Message, 'Info', function(res){
							editExit();
						});
					}else{
						jAlert(data.Message,'Info');
					}
				}
			}
		});
	}else{
		var Url			= baseRoot() + "cms/updateBase/";
		var param		= loginToken + "/"+ loginId + "/" + setObj.contentTab + "/" + setObj.contentTabType + "/" + setObj.contentNum +"/" + setObj.contentTabIdx + "/"+
							setObj.boardTab + "/" + setObj.boardNum + "/"+ setObj.boardTabIdx +"/"+ setObj.openAPI + "/" + setObj.latestView +"/"+ setObj.latitude +"/"+
							setObj.longitude +"/" + setObj.mapZoom ;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data != null){
					if(data.Code == '100'){
						jAlert(data.Message, 'Info', function(res){
							editExit();
						});
					}else{
						jAlert(data.Message,'Info');
					}
				}
			}
		});
	}
}

//sever update
function serverUpdate(tmpTblIdx, uType){
	if(isServerFirst){
		serverSave('U');
		serverModify(tmpTblIdx, false);
		return;
	}
	var serverName = '&nbsp';
	var serverUrl = '&nbsp';
	var serverPort = '&nbsp';
	var serverId = '&nbsp';
	var serverPass = '&nbsp';
	var serverPath = '&nbsp';
	var selectYn = '&nbsp';
	var serverIdx = '&nbsp';
	var serverDefault = '&nbsp';
	var serverViewPort ='&nbsp';
	
	serverName = $('#serverName_'+ tmpTblIdx).val();
	serverUrl = $('#serverUrl_'+ tmpTblIdx).val();
	serverPort = $('#serverPort_'+ tmpTblIdx).val();
	serverId = $('#serverId_'+ tmpTblIdx).val();
	serverPass = $('#serverPass_'+ tmpTblIdx).val();
	serverPath = $('#serverPath_'+ tmpTblIdx).val();
	serverViewPort = $('#serverViewPort_'+ tmpTblIdx).val();
	selectYn = $('#serverRadio_'+ tmpTblIdx).attr('checked');
	serverIdx = $('#serverIdx_'+ tmpTblIdx).val();
	
	if(serverName == null || serverName == ''){
// 		jAlert('서버명을 입력해 주세요.','Info');
		jAlert('Please enter server name.','Info');
		return;
	}
	if(serverPath == null || serverPath == ''){
// 		jAlert('저장할 파일 경로를 입력해 주세요.','Info');
		jAlert('Please enter the file path to save.','Info');
		return;
	}
	
	if(jQuery.type(serverUrl) !== undefined && jQuery.type(serverUrl) !== 'undefined'){
		if(serverUrl == null || serverUrl == ''){
// 			jAlert('서버 주소를 입력해 주세요.','Info');
			jAlert('Please enter a server address.','Info');
			return;
		}
		if(serverPort == null || serverPort == ''){
// 			jAlert('서버 포트를 입력해 주세요.','Info');
			jAlert('Please enter the server port.','Info');
			return;
		}
		if(serverId == null || serverId == ''){
// 			jAlert('서버 아이디를 입력해 주세요.','Info');
			jAlert('Please enter the server ID.','Info');
			return;
		}
		if(serverPass == null || serverPass == ''){
// 			jAlert('서버 비밀번호를 입력해 주세요.','Info');
			jAlert('Please enter your server password.','Info');
			return;
		}
		if(serverViewPort == null || serverViewPort == ''){
// 			jAlert('파일을 불러올 포트를 입력해 주세요.','Info');
			jAlert('Please enter the port from which to load the file.','Info');
			return;
		}
		
		if(serverName == null || serverName == ''){
// 			jAlert('서버명을 입력해 주세요.','Info');
			jAlert('Please enter server name.','Info');
			return;
		}
	}else{
		serverUrl = '&nbsp';
		serverPort = '&nbsp';
		serverId = '&nbsp';
		serverPass = '&nbsp';
		serverViewPort = '&nbsp';
		serverDefault = 'Y';
	}
	
	if(selectYn){
		selectYn = 'Y';
	}else{
		selectYn = 'N';
	}
	
	serverName = dataReplaceFun(serverName);
	serverId = dataReplaceFun(serverId);
	serverPass = dataReplaceFun(serverPass);
	serverPath = dataReplaceFun(serverPath);
	serverDefault = dataReplaceFun(serverDefault);
	
	var Url			= baseRoot() + "cms/updateServer/";
	var param		= loginToken + "/"+ loginId + "/" + serverName + "/" + serverUrl + "/" + serverPort +"/" + serverId + "/"+
						serverPass + "/" + serverPath + "/"+ serverViewPort + "/"+ selectYn +"/"+ serverIdx +"/"+ serverDefault;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data != null){
				if(data.Code == '100'){
					if(uType == 'U'){
						getServerList();
					}else{
						saveSetting();
					}
					
				}else{
					jAlert(data.Message,'Info');
				}
			}
		}
	});
}

//remove server
function severRemove(tmpTblIdx){
	if(tmpTblIdx == serverNewCnt){
		$('#serverTbl_'+ tmpTblIdx).remove();
		$('#serverRadio_1').attr('checked',true);
		serverNewCnt = 0;
		serverHeight = serverHeight - 215;
		$('#serverDig').dialog('option','height',serverHeight);
	}else{
		var tmpIdx = $('#serverIdx_'+tmpTblIdx).val();
		var Url			= baseRoot() + "cms/deleteServer/";
		var param		= loginToken + "/"+ loginId + "/" + tmpIdx;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data != null){
					if(data.Code == '100'){
						getServerList();
					}else{
						jAlert(data.Message,'Info');
					}
				}
			}
		});
	}
}

//server dialog close
function serverCencle(){
	$('#serverDig').dialog('close');
}
</script>
