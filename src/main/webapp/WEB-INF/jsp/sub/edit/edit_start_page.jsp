<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript">
var select_edit_num = 0;	//편집 객체의 배열에서의 위치

//편집 모드
function contentMove(){
	if(editMode == 0){
		$('#myProject_list').css('display','none');
		$('#copyReqStart').css('display','none');
		//지도 초기 설정
		editMapSetting();
		
		$('#moreViewImg').css('display', 'none');
		
		editMode = 1;										//편집모드로 변경(편집모드 : 1 , 편집불가: 0)
		iconSetting();										//아이콘 변경
		
		editModeEvent();
	}else{
		editExit();	//편집모드 빠져나가기
	}
}

//Edit Mode Event 초기화 및 이벤트 막기
function editModeEvent(){
	//편집 객체 초기화
	$('.over_edit').remove();
	$('.select_edit').remove();
	
	$("a").attr("href", "#");	//a 객체 이벤트 초기화
	$(".menu_images").attr("onclick", null);	//메뉴 이미지 객체 이벤트 초기화
	
	$(".editing").css("display","block");	//객체 편집모드에 만  버튼이미지 보이기
}

//편집 모드 버튼 이벤트
function editBtnEvent(kind){
	if(editMode != 1){
		return;
	}

	if(kind == "SAVE"){	//save 버튼 클릭 이벤트
		isFirstChk = false;
		var isFirstType = "";
		
		if((setObj.latitude == null || setObj.latitude == undefined || setObj.latitude == '') && (setObj.longitude == null || setObj.longitude == undefined || setObj.longitude == '')){
			isFirstChk = true;
		}
		
		setObj.latitude = homeMarker.getPosition().lat();
		setObj.longitude = homeMarker.getPosition().lng();
		setObj.mapZoom = map.getZoom();
		
		serverDigOpen();
	}else if(kind == "CANCEL"){ //cancel 버튼 클릭
		cancelEditExit();
		setTimeout(function(){
			contentMove();
		},200);
		
	}
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
	
	$('#image_map').css('z-index',10);	//구글 맵 이벤트 복구
	menuSetting();		//메뉴 설정
	
	$('#moreViewImg').css('display', 'block'); //더보기 창 보이기
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
	typeShape = "editMap";
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
				$('#serverName_1').val('Base Server');
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
		var param		= loginToken + "/"+ loginId + "/"+ setObj.latitude +"/"+ setObj.longitude +"/" + setObj.mapZoom;
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
		var param		= loginToken + "/"+ loginId + "/"+ setObj.latitude +"/"+ setObj.longitude +"/" + setObj.mapZoom ;
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
