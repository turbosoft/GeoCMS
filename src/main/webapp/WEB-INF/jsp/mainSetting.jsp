<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<style type="text/css">
ul {
    list-style-type: none;
    padding: 0px;
    margin: 0px;
}

ul li {
    background-repeat: no-repeat;
    background-position: 0px center; 
    padding-left: 15px; 
}
</style>

<script type="text/javascript">
var editDialog = null;			//편집 Dialog
var contentViewDialog = null;	//게시판 리스트 Dialog
var tableMap;					//table list info
var menuMap;					//menu list info
var setObj = null;
var mainImageWidth = 100;
var mainImageHeight = 70;

//초기 설정 데이터 불러오기
function getBase() {
	var Url			= baseRoot() + "cms/getbase";
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				result = data.Data;
				setObj = new Object();										//setting data를 변수에 저장한다.
				if(result != null && result.length > 0){
					setObj.mapZoom = result[0].mapzoom;
					setObj.latitude =  result[0].latitude;
					setObj.longitude =  result[0].longitude;
				}
				
				dMarkerLat = setObj.latitude;
				dMarkerLng = setObj.longitude;
				b_url = 'cms/getContent/';
				getServer("","", "");
				mainSetting();	
			}else{
				jAlert(data.Message, 'Info');
				setObj = new Object();
				setObj.openAPI = '0';
				setObj.latestView = '1';
				setObj.mapZoom = 8;
				b_url = 'cms/getContent/';
				getServer("","", "");
				mainSetting();	
			}
		}
	});
}

function getAes(type){
	var txtVal = $('#aesText').val();
	var encrypt = "encrypt";
	if(type != 'A'){
		encrypt = "Y";
	}
	
	txtVal = txtVal.replace(/\//g,'&sbsp');
	
	var Url			= baseRoot() + "cms/encrypt/";
	var param		= txtVal + "/" + encrypt;
	var callBack	= "?callback=?";
	
	$.ajax({
		type : "get",
		url  : Url + param + callBack,
		dataType : "jsonp",
		async	: false,
		cache	: false,
		success: function(data) {
			alert("success");
		}
	});
}

//get server
function getServer(tmpFileName, tmpFileType, rObj){
	var Url			= baseRoot() + "cms/selectServerList/";
	var param		= loginToken + "/" + loginId +"/" +"Y";
	var callBack	= "?callback=?";
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			var tmpServerId = '';
			var tmpServerPass = '';
			var tmpServerPort = '';
			if(data.Code == '100'){
				b_serverUrl = response[0].serverurl;
				b_serverViewPort = response[0].serverviewport;
				b_serverPath = response[0].serverpath;
				if(b_serverUrl != null && b_serverUrl != "" && b_serverUrl != undefined){
					b_serverType = "URL";
				}else{
					b_serverType = "LOCAL";
				}
				tmpServerId = response[0].serverid;
				tmpServerPass = response[0].serverpass;
				tmpServerPort = response[0].serverport;
			}else if(data.Code != '200'){
				b_serverPath = "upload";
			}else{
				b_serverPath = "upload";
			}
			
			if(tmpFileName != null && tmpFileName != ""){
				if(tmpFileType != null && tmpFileType == "EXIF"){
					$.ajax({
						type: 'POST',
						url: '<c:url value="/geoExif.do"/>',
						data: 'file_name='+tmpFileName+'&type=load&serverType='+b_serverType+'&serverUrl='+b_serverUrl+
						'&serverPath='+b_serverPath+'&serverViewPort='+ b_serverViewPort +'&serverId='+tmpServerId+'&serverPass='+tmpServerPass,
// 						data: 'file_name='+tmpFileName+'&type=load',
						
						success: function(data) {
							var response = data.trim();
							if(rObj != null ){
								exifSetting(response, rObj[0], rObj[1], rObj[10]);
							}
						}
					});	
				}else if(tmpFileType != null && tmpFileType == "XML_CHECK"){
					var file_check = 0;
					$.ajax({
						type: "POST",
						url: 'Http://'+ location.host + '/GeoCMS/geoXml.do',
						data: 'file_name='+tmpFileName+'&type=load&serverType='+b_serverType+'&serverUrl='+b_serverUrl+
						'&serverPath='+b_serverPath+ '&serverPort='+tmpServerPort+'&serverViewPort='+ b_serverViewPort +'&serverId='+tmpServerId+'&serverPass='+tmpServerPass,
// 						data: 'file_name='+tmpFileName+'&type=load',
						success:function(xml) {
							if(xml != null && xml != "" && xml != 'null'){
								file_check = 1;
							}
						},
						error: function(xhr, status, error) {
//				 			alert('XML 호출 오류! 관리자에게 문의하여 주세요.');
						}
					});
					return file_check;
				}else if(tmpFileType != null && tmpFileType == "GPX"){
				 	var lat_arr = new Array(); 
				 	var lng_arr = new Array();

					$.ajax({
						type: "POST",
						url: 'Http://'+ location.host + '/GeoCMS/geoXml.do',
						data: 'file_name='+tmpFileName+'&type=load&serverType='+b_serverType+'&serverUrl='+b_serverUrl+
						'&serverPath='+b_serverPath+ '&serverPort='+tmpServerPort+'&serverViewPort='+ b_serverViewPort +'&serverId='+tmpServerId+'&serverPass='+tmpServerPass,
// 						data: 'file_name='+tmpFileName+'&type=load',
						success:function(data) {
							if(data != null){
								var response = JSON.parse(data);
								if(response != null){
									response = response.gpsData;
									$.each(response, function(idx, val){
										if(val != null && val.lat != null && val.lon != null){
											var lat_str = val.lat;
			 								var lng_str = val.lon;
			 								lat_arr.push(parseFloat(lat_str));
			 								lng_arr.push(parseFloat(lng_str));
										}
									});
								}
							}
// 							$(xml).find('trkpt').each(function(index) {
// 								var lat_str = $(this).attr('lat');
// 								var lng_str = $(this).attr('lon');
// 								lat_arr.push(parseFloat(lat_str));
// 								lng_arr.push(parseFloat(lng_str));
// 							});
							gps_size = lat_arr.length;
							setGPSData(lat_arr, lng_arr);
						},
						error: function(xhr, status, error) {
							map.setCenter(0, 0);
						}
					});
				}
			}
		}
	});
}

//메뉴 설정
function mainSetting() {
	tableMap = newMap();	//table list info
	mainProjectGroup("1", "list", "main");
	
	menuSetting();			//메뉴 설정
}


//메뉴 설정
function menuSetting(){
	$('#menus').empty();
	//임의 메뉴 설정
	menuMap = newMap();
	menuMap.put("logo",{"src": "<c:url value='/images/geoImg/english_images/logo.jpg'/>", "top": 20, "width": 152, "etc": ""});	//이미지 주소, top, width, function 및 id
	menuMap.put("MyProjects",{"src": "<c:url value='/images/geoImg/english_images/myProjects.png'/>", "top": 13, "width": 70, "etc": "onclick='viewMyProjects(null);'"});
	menuMap.put("OpenApi",{"src": "<c:url value='/images/geoImg/english_images/menu04.gif'/>", "top": 55, "width": 77, "etc": "onclick='diagOpen()'" /*"id='opener'"*/});
	menuMap.put("searchBox",{"src": "<c:url value='/images/geoImg/btn_image/search.png'/>", "top": 32, "width": 28, "etc": "alt='search Button' onclick='searchAction();'"});
	
	var leftNum = 20;
	var innerHTMLStr = "";
	
	if(loginType =='ADMIN') {
		innerHTMLStr +=  "<img src='<c:url value='/images/geoImg/btn_image/exit_off.png'/>' style='top:15px; right:50px; position:relative; float:right; cursor:pointer; width:20px; height:20px;' id='editExitlBtn' class='editing'/>";
		innerHTMLStr +=  "<img src='<c:url value='/images/geoImg/btn_image/save_off.png'/>' style='top:15px; right:80px; position:relative; float:right; cursor:pointer; width:20px; height:20px;' id='editSaveBtn' class='editing' onclick='editBtnEvent(\"SAVE\");'/>";
		innerHTMLStr +=  "<img src='<c:url value='/images/geoImg/btn_image/cancel_off.png'/>' style='top:15px; right:110px; position:relative; float:right; cursor:pointer; width:20px; height:20px;' id='editCancelBtn' class='editing' onclick='editBtnEvent(\"CANCEL\");'/>";
		innerHTMLStr +=  "<img src='<c:url value='/images/geoImg/btn_image/user_off.png'/>' style='top:15px; right:140px; position:relative; float:right; cursor:pointer; width:20px; height:20px;' id='manageBtn' class='editing' onclick='userManage();'/>";
		innerHTMLStr +=  "<img src='<c:url value='/images/geoImg/btn_image/setting_on.png'/>' style='top:15px; right:170px; position:relative; float:right; cursor:pointer; width:20px; height:20px;' id='editBtn'/>";
	}
	
	for(var i=0;i<menuArr.length;i++){
		var menuId = menuArr[i].split("_")[0];
		
		if(menuId == "latestUpload"){
			continue;
		}
		
		if(menuId == "MyProjects" && (loginId == null || loginId == '' || loginId == 'null')) {	//로그인 하지 않으면 저작 불가능하도록 메뉴 제외	
			continue;
		}

		if(menuId == "logo" ||  menuId == "Home"){	// 메뉴가 logo, home 인 경우 메인 페이지로 되돌아가는 기능 추가
			innerHTMLStr += "<a href='<c:url value='/'/>'>";
		}else if(menuId == "searchBox"){	//검색 박스인 경우 input box 추가
			innerHTMLStr += "<img src='" + menuMap.get(menuId).src + "' id='" + menuId + "' class='menu_images' style='width:" + menuMap.get(menuId).width + "px; top:109px; left:380px; position:relative; cursor: pointer; clear:both;' ";
			innerHTMLStr +=  menuMap.get(menuId).etc + " /> ";
			innerHTMLStr += "<input type='text' id='srchBox' size='45' style='position:relative; top:100px; left:-10px; height: 23px; ' onKeyPress='submit1(event);'/>";
		}
		
		if(menuId != "searchBox" && menuId != "MyProjects"){
			innerHTMLStr += "<img src='" + menuMap.get(menuId).src + "' id='" + menuId + "' class='menu_images' style='width:" + menuMap.get(menuId).width + "px; margin-top:" + menuMap.get(menuId).top + "px; left:" + leftNum + "px; position:absolute; cursor: pointer; ";
			if(menuArr[i].split("_")[1] == "off"){
				innerHTMLStr += "display:none;'";
			}else{
				innerHTMLStr += "'";
			}
			innerHTMLStr +=  menuMap.get(menuId).etc + " /> ";
		}
		
		if(menuId == "logo" ||  menuId == "Home"){
			innerHTMLStr += "</a>";
		}
		
		if(menuId == "MyProjects"){
			var tmpLeft = $('#userId').css('left');
			tmpLeft = Number(tmpLeft.replace('px',''));
// 			tmpLeft += 70;
			tmpLeft -= 120;
			
			innerHTMLStr += "<img src='" + menuMap.get(menuId).src + "' id='" + menuId + "' class='menu_images' style='width:" + menuMap.get(menuId).width + "px; margin-top:" + menuMap.get(menuId).top + "px; left:"+ tmpLeft + "px; position:absolute; cursor: pointer; ";
			innerHTMLStr += "'";
			innerHTMLStr +=  menuMap.get(menuId).etc + " /> ";
		}
		
		leftNum += 110 + menuMap.get(menuId).width;
		
		if(i == 0){
			leftNum += 400;
		}
	}
	
	$('#menus').append(innerHTMLStr);
	iconSetting();
}

//admin icon change
function iconSetting(){
		var tmpSettinglImg = '<c:url value="/images/geoImg/btn_image/setting_on.png"/>';
		var tmpUserImg = '<c:url value="/images/geoImg/btn_image/user_off.png"/>';
		var tmpCancelImg = '<c:url value="/images/geoImg/btn_image/cancel_off.png"/>';
		var tmpSaveImg = '<c:url value="/images/geoImg/btn_image/save_off.png"/>';
		var tmpExitImg = '<c:url value="/images/geoImg/btn_image/exit_off.png"/>';
		
		$('#editBtn').attr('onClick', 'contentMove();');
		$('#editExitlBtn').attr('onclick', null);
		if(editMode == 1){
			tmpSettinglImg = '<c:url value="/images/geoImg/btn_image/setting_off.png"/>';
			tmpUserImg = '<c:url value="/images/geoImg/btn_image/user_on.png"/>';
			tmpCancelImg = '<c:url value="/images/geoImg/btn_image/cancel_on.png"/>';
			tmpSaveImg = '<c:url value="/images/geoImg/btn_image/save_on.png"/>';
			tmpExitImg = '<c:url value="/images/geoImg/btn_image/exit_on.png"/>';
			
			$('#editBtn').attr('onClick', null);
			$('#editExitlBtn').attr('onClick', 'editExit()');
		}
		$('#editBtn').attr('src', tmpSettinglImg);
		$('#manageBtn').attr('src', tmpUserImg);
		$('#editCancelBtn').attr('src', tmpCancelImg);
		$('#editSaveBtn').attr('src', tmpSaveImg);
		$('#editExitlBtn').attr('src', tmpExitImg);
}

function mainProjectGroup(pageNum, type, nCallType){
	if(editMode == 1){
		return;
	}
	b_nowProjectIdx = 0;
	$('#polygonView').attr('checked', false); //지도 polygon view off
	$('.viewModeCls').css('display','none');
	
	if(nCallType == 'main'){
		typeShape = 'mainMarker';
		initialize();
	}
	
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpContentNum = '&nbsp';
	var tmpIndex = '&nbsp';
	
	if(tmpLoginId == null || tmpLoginId == "" || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == "" || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	
	var Url			= baseRoot() + 'cms/getMainProjectList/';
	var param		= type + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + pageNum + "/" + tmpContentNum + "/" + tmpIndex +"/"+ b_orderType;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			addMainProjectGroupCell(response);
		}
	});
}

//project group list
function addMainProjectGroupCell(response){
	var innerHTML = '';
	
	$('#imageMoveArea').empty();
	$('#mainProjectListView').empty();
	
	var setTbHeight = $(window).height() - 180 - $('#footer').height();//화면 크기에 따라 이미지 크기 조정
	$('#mainProjectListView').css('height', setTbHeight);
	$('#mainProjectListView').css('overflow-y', 'scroll');
	$('#imageMoveArea').css('height', '0px');
	
// 	$('#imageMoveArea').append("<table border=1 class='ui-widget' id='left_list_table_1' style='border-collapse: collapse; height: 563px;width:100%; border-left:0px;border-color:#999;'><tbody></tbody></table>");	
// 	$('#imageMoveArea').preppend("<div id='mainProjectListView'></div>");
	
	if(response != null){
		for(var i=0;i<response.length;i++){
			var proShare = '';
			if(response[i].projectsharetype == '1'){
// 				proShare = '전체공개';
				proShare = 'FULL';
			}else if(response[i].projectsharetype == '0'){
// 				proShare = '비공개';
				proShare = 'NON';
			}else{
// 				proShare = '선택공개';
				proShare = 'SELECTIVE';
			}

			var projectNameTxt = response[i].projectname.length>40? response[i].projectname.substring(0,40)+'...' : response[i].projectname;
			innerHTML += '<div id="mainPName_'+ response[i].projectidx +'" onclick="moveMainDetailView('+response[i].projectidx+');"';

			innerHTML += 'class="offProjectDiv" style="cursor:pointer;">';
			
			innerHTML += "<input type='hidden' id='mainhiddenProName_"+ response[i].projectidx +"' value='"+ response[i].projectname +"'/>";
			innerHTML += '<input type="hidden" id="mainhiddenShareType_'+ response[i].projectidx +'" value="'+ response[i].projectsharetype +'"/>';
			
			innerHTML += "<label class='titleLabel' title='"+ response[i].projectname +"' style='width:390px !important;font-size: 16px;display: inline-block;margin-top:3px;cursor:pointer;'>"+ projectNameTxt +"</label>";
			
			var tmpUserId = response[i].projectid.length>7? response[i].projectid.substring(0,7)+'...' : response[i].projectid;
			innerHTML += '<div class="subDivCls" style="float:right;font-size:12px;margin-top:5px;color:#ddd;margin-right:5px; cursor:pointer;"><label class="m_l_10" style="font-size: 11px; cursor:pointer;">WRITER: </label><label style="display:inline-block; width:45px;font-size: 11px; cursor:pointer;" title="'+ response[i].projectid +'">'+ tmpUserId + '</label><label class="margin-left:5px;" style="font-size: 11px;cursor:pointer;">DATE: </label><label style="font-size: 11px;cursor:pointer;">' + response[i].projectudate + '</label><label style="margin-left:5px;font-size: 11px;cursor:pointer;">'+ proShare + '</label>';
			innerHTML += '</div>';

// 			innerHTML += '<button onclick="openProjectViewer('+ response[i].projectidx +');" class="editFileBtn" style="border-radius:5px; float:left; margin:3px 5px 0 0px;font-size:12px;width:75px;background-color: #efefef;"> Viewer </button>';

			innerHTML += '</div>';

			innerHTML += '</div>';
		}

		$('#mainProjectListView').append(innerHTML);
	}
}

function moveMainDetailView(cProjectIdx){
	if(editMode == 1){
		return;
	}
	if(cProjectIdx != null && cProjectIdx != '' && cProjectIdx != undefined){
		$('.viewModeCls').css('display','block');
		$('#mainBody').append('<div class="lodingOn"></div>');
		$('.orderTypeClass').css('display','none');
		b_nowProjectIdx = cProjectIdx;
		
		$('#mainProjectListView').empty();
		$('#imageMoveArea').append("<table border=1 class='ui-widget' id='left_list_table_1' style='border-collapse: collapse; width:100%; border-left:0px;border-color:#999;'><tbody></tbody></table>");
		clickImagePage("1", null, "list", cProjectIdx);
		
		typeShape = 'marker';
		initialize();
	}else{
		$('.orderTypeClass').css('display','block');
// 		if(b_orderType == "DESC"){
// 			$('#orderTypeDesc').css('display','block');
// 		}else{
// 			$('#orderTypeAsc').css('display','block');
// 		}
		mainProjectGroup("1", "list","main");
	}
}


//페이지 선택
function clickImagePage(pageNum, content_num, type, cProjectIdx){
	var dataIdx = '&nbsp';
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpIndex = '&nbsp';
	
	
	if(tmpLoginId == null || tmpLoginId == "" || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == "" || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	
	if(content_num == null || content_num == "" || content_num == 'null'){
		content_num = '&nbsp';
	}
	
	if(cProjectIdx == null || cProjectIdx == "" || cProjectIdx == 'null'){
		cProjectIdx = '&nbsp';
	}
	
	var Url			= baseRoot() + b_url;
	var param		= type + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + pageNum + "/" + content_num + "/" + cProjectIdx + "/"+ tmpIndex;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			
			leftListSetup(response);
			//페이지 설정
// 			var dataLen = 1;
// 			if(data.DataLen != null && data.DataLen != "" && data.DataLen != "null" && data.DataLen != undefined){
// 				dataLen = data.DataLen;
// 			}
// 			if(obj.table_num == "1"){leftPageSetup(dataLen, obj);}
		}
		, error:function(request,status,error){
			$('.lodingOn').remove();
		}
	});
}


//이미지 리스트 설정
function leftListSetup(pure_data) {
	//전달할 각 속성을 배열에 저장
	var id_arr = new Array();
	var title_arr = new Array();
	var content_arr = new Array();
	var file_url_arr = new Array();
	var udate_arr = new Array();
	var idx_arr = new Array();
	var lat_arr = new Array();
	var lon_arr = new Array();
	var thumbnail_url_arr = new Array();
	var origin_url_arr = new Array();
	var dataKind_arr = new Array();
	var projectUserId_arr = new Array();
	var status_arr = new Array();
	
	if(pure_data != null && pure_data.length > 0){
		for(var i=0; i<pure_data.length; i++) {
			id_arr.push(pure_data[i].id);		//id 저장
			title_arr.push(pure_data[i].title);	//title 저장
			content_arr.push(pure_data[i].content);	//content 저장
			file_url_arr.push(pure_data[i].filename); //fileName 저장
			udate_arr.push(pure_data[i].u_date);	//udate 저장
			idx_arr.push(pure_data[i].idx); //idx 저장

			lat_arr.push(pure_data[i].latitude);
			lon_arr.push(pure_data[i].longitude);
			thumbnail_url_arr.push(pure_data[i].thumbnail);
			origin_url_arr.push(pure_data[i].originname);
			dataKind_arr.push(pure_data[i].datakind);	// GeoPhoto, GeoVideo
			projectUserId_arr.push(pure_data[i].projectUserId);	// project user id
			status_arr.push(pure_data[i].status);	// file upload status
			
			if(i == 0){
				var proShare = '';
				if(pure_data[i].projectsharetype == '1'){
//					proShare = '전체공개';
					proShare = 'FULL';
				}else if(pure_data[i].projectsharetype == '0'){
//					proShare = '비공개';
					proShare = 'NON';
				}else{
//					proShare = '선택공개';
					proShare = 'SELECTIVE';
				}
				
				var innerHTML= '';
				var projectNameTxt = pure_data[i].projectname.length>40? pure_data[i].projectname.substring(0,40)+'...' : pure_data[i].projectname;
				innerHTML += '<div id="mainPName_'+ pure_data[i].projectidx +'" onclick="moveMainDetailView(null);"';
	
				innerHTML += 'class="onProjectDiv" style="cursor:pointer;">';

				innerHTML += "<input type='hidden' id='mainhiddenProName_"+ pure_data[i].projectidx +"' value='"+ pure_data[i].projectname +"'/>";
				innerHTML += '<input type="hidden" id="mainhiddenShareType_'+ pure_data[i].projectidx +'" value="'+ pure_data[i].projectsharetype +'"/>';
				
				innerHTML += "<label class='titleLabel' title='"+ pure_data[i].projectname +"' style='width:390px !important;font-size: 16px;display: inline-block;margin-top:3px; cursor:pointer;'>"+ projectNameTxt +"</label>";
				var tmpUserId = pure_data[i].projectuserid.length>7? pure_data[i].projectuserid.substring(0,7)+'...' : pure_data[i].projectuserid;
				innerHTML += '<div class="subDivCls" style="float:right;font-size:12px;margin-top:5px;color:#ddd;margin-right:5px; cursor:pointer;"><label class="m_l_10" style="font-size: 11px;cursor:pointer;">WRITER: </label><label style="display:inline-block; width:45px;font-size: 11px;cursor:pointer;" title="'+ pure_data[i].projectuserid +'">'+ tmpUserId + '</label><label class="margin-left:5px;" style="font-size: 11px;cursor:pointer;">DATE: </label><label style="font-size: 11px;cursor:pointer;">' + pure_data[i].projectudate + '</label><label style="margin-left:5px;font-size: 11px;cursor:pointer;">'+ proShare + '</label>';
				innerHTML += '</div>';
				
	// 			innerHTML += '<button onclick="openProjectViewer('+ pure_data[i].projectidx +');" class="editFileBtn" style="border-radius:5px; float:left; margin:3px 5px 0 0px;font-size:12px;width:75px;background-color: #efefef;"> Viewer </button>';
				innerHTML += '</div>';
	
				innerHTML += '</div>';
				
				$('#mainProjectListView').append(innerHTML);
				$('#mainProjectListView').css('height','55px');
				$('#mainProjectListView').css('overflow-y','hidden');
				
				var setTbHeight = $(window).height() - 130 - $('#footer').height() - $('#mainProjectListView').height();//화면 크기에 따라 이미지 크기 조정
				$('#imageMoveArea').css('height', setTbHeight);
				$('#imageMoveArea').css('overflow-y', 'scroll');
			}
		}
	}
	
	//테이블에 데이터 추가
	addLeftImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr);
}

//left content list data add
function addLeftImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr){
	var target = document.getElementById('left_list_table_1');
	var max_cell = '3';
	var blankImg = '<c:url value="/images/geoImg/blank(100x70).PNG"/>';

	var thumbnail_arr = new Array();
	//xml file check
	for(var i=0;i<file_url_arr.length;i++){
		var thumbnail_arr_data = loadXMLMain(file_url_arr[i], dataKind_arr[i]);
		thumbnail_arr.push(thumbnail_arr_data);
	}
	var imgWidth = mainImageWidth;		//image width
	var imgHeight = mainImageHeight;		//image height
	
	$('#left_list_table_1').attr("border","0");
	
	var tmpMakerImg = 'images';
	for(var i=0; i<id_arr.length; i++) {

		var localAddress = ftpBaseUrl() + "/" + dataKind_arr[i];
		if(dataKind_arr[i] == "GeoPhoto"){
			var tmpThumbFileName = file_url_arr[i].split('.');
			localAddress += "/"+tmpThumbFileName[0] +'_thumbnail.png';
			
		}else if(dataKind_arr[i] == "GeoVideo"){
			localAddress += "/"+thumbnail_url_arr[i];
		}
		
 		//image add
		var img_row;
		if(i % max_cell == 0){
			img_row = target.insertRow(-1);
		}
		
		var img_cell = img_row.insertCell(-1);
		var innerHTMLStr = "";
		if(id_arr[i]=="" && title_arr[i]=="" && content_arr[i]=="" && file_url_arr[i]=="") {	//등록한 이미지가 없을때
			innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:3px solid gray'/>";
			img_cell.innerHTML = innerHTMLStr;
		}else{
			innerHTMLStr += "<a class='imageTag' href='javascript:;' onclick="+'"';
			var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
			tempArr.push(lat_arr[i]);
			tempArr.push(lon_arr[i]);
			tempArr.push(file_url_arr[i]);
			tempArr.push(idx_arr[i]);
			tempArr.push(dataKind_arr[i]);
			tempArr.push(origin_url_arr[i]);
			tempArr.push(thumbnail_url_arr[i]);
			tempArr.push(id_arr[i]);
			tempArr.push(projectUserId_arr[i]);
			innerHTMLStr += "mapCenterChange('"+ tempArr +"');";

			innerHTMLStr += '"'+" title='TITLE : "+ title_arr[i] +"\nCONTENT : "+ content_arr[i] + "\nWriter :" +id_arr[i] + "\nDate : "+udate_arr[i] +"' border='0'>";
			
			//xml file check icon add
			if(thumbnail_arr[i] == 1){
				var tempTop = 63;
				var tempLeft = 116;
				var tempXmlImg = 'xmlFile_w.png';
				innerHTMLStr += "<div></div>"
				innerHTMLStr += "<div style='position:absolute; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px; background-image:url(<c:url value='"+tmpMakerImg+"/geoImg/btn_image/"+tempXmlImg+"'/>);background-repeat: no-repeat;background-size: 15px 20px;'></div>";
			}
			
// 			innerHTMLStr += "<img class='round' src='"+localAddress+"' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' style='border:3px solid gray'/>";
			
			innerHTMLStr += "<div style='border:2px solid #888888;";
			innerHTMLStr += " background: url(\""+ localAddress +"\") no-repeat center; display: inline-block; width: 100px; height:70px; background-size: 100px 70px;margin:10px;'></div>";
			
			//image or video icon add
			innerHTMLStr += "<img class='round' src='./images/geoImg/"+ dataKind_arr[i] +"_marker.png' style='margin:0px 0 16px -162px; width:30px; height:30px; zoom:0.7;' />";
			
			innerHTMLStr += "</a>";
			
// 			var tempWriter = "style='position: absolute; left: 150px; margin-top:-50px; font-size:12px;'";	//list type인 경우 작성자명 위치 설정
// 			var tempDate = "style='position: absolute; left: 150px; margin-top:-30px; font-size:12px;'";	//list type인 경우 날짜 위치 설정
// 			innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-70px; font-size:12px;'>&nbsp;Writer : "+id_arr[i]+"</div>";
// 			innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-50px; font-size:12px;'>&nbsp;Date : "+udate_arr[i]+"</div>";
// 			var tmpTtText = title_arr[i];
// 			if(tmpTtText != null && tmpTtText != ''){
// 				tmpTtText = tmpTtText.length>30?tmpTtText.substring(0,28)+'...':tmpTtText;
// 			}
// 			innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-30px; font-size:12px;'  title='"+ title_arr[i] +"'>&nbsp;Title : "+tmpTtText+"</div>";
			
			img_cell.innerHTML = innerHTMLStr;
		}
	}
	$('.lodingOn').remove();
}

function loadXMLMain(file_url, data_kind) {
	var url_buf = file_url.split(".");
	var xml_file_name = url_buf[0] + '.xml';
	var file_check = 0;
	xml_file_name = data_kind +'/'+xml_file_name;
	getServer(xml_file_name, 'XML_CHECK', "");
}


//map object
function newMap() {
  var map = {};
  map.value = {};
  map.getKey = function(id) {
    return "k_"+id;
  };
  map.put = function(id, value) {
    var key = map.getKey(id);
    map.value[key] = value;
  };
  map.contains = function(id) {
    var key = map.getKey(id);
    if(map.value[key]) {
      return true;
    } else {
      return false;
    }
  };
  map.get = function(id) {
    var key = map.getKey(id);
    if(map.value[key]) {
      return map.value[key];
    }
    return null;
  };
  map.remove = function(id) {
    var key = map.getKey(id);
    if(map.contains(id)){
      map.value[key] = undefined;
    }
  };
 
  return map;
}

//list 더보기
function moreListView(viewPageNum, b_nowProIdx, selBoardNum){
	if(viewPageNum == null || viewPageNum == '' || viewPageNum == 'null'){
		viewPageNum = 1;
	}
	var movePage = '<c:url value="/geoCMS/content_list.do"/>';
	
	contentViewDialog = jQuery.FrameDialog.create({
		url: movePage+'?viewPageNum='+viewPageNum+'&nowProIdx='+b_nowProIdx+'&urlText='+b_url+'&selBoardNum='+selBoardNum,
		width: 960,
		height: 650,
		buttons: {},
		autoOpen:false
	});
	$('.ui-dialog-titlebar').attr('class', 'ui-dialog-titlebar');
	$('.ui-dialog-title').remove();
	$('.ui-dialog').attr('id', 'board_dig');
	contentViewDialog.dialog('open');
}

//my project list page
function viewMyProjects(orderIdx){

	$('#myProject_list').css('display','block');
// 	$('#image_latest_list').css('display','none');
	$('#copyReqStart').css('display','block');
	
	if(orderIdx == null || orderIdx == '' || orderIdx == 'null'){
		orderIdx = '&nbsp';
	}
	var tmeShareEdit = '&nbsp';
	
	var Url			= baseRoot() + "cms/getProjectList/";
	var param		= loginToken + "/" + loginId +"/" +orderIdx + "/" +tmeShareEdit;
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
				projectGroupListSetup(response);
			}else{
				projectGroupListSetup(response);
				jAlert(data.Message, 'Info');
			}
		}
	});
}


</script>
<style>
 .ui-tabs .ui-tabs-nav li.ui-tabs-selected a, .ui-tabs .ui-tabs-nav li.ui-state-disabled a, .ui-tabs .ui-tabs-nav li.ui-state-processing a
 {
 	background-color:rgb(15, 118, 207);
 	color:#fff;
 }
</style>
