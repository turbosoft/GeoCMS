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
var nowTabName = '';			//현재 선택한 Tab name
var nowRightTabName = '';		//현재 선택한 Right Tab name
var setObj = null;

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
				setObj.openAPI = '0';
				setObj.latestView = '0';
				var tmpContentIdx = 0;
				var tmpBoardIdx = 0;
				if(result != null && result.length > 0){
					for(var i=0;i<result.length; i++){
						if(i == 0){
// 							setObj.openAPI = result[i].openapi;
							setObj.latestView = result[i].latestview;
							setObj.mapZoom = result[i].mapzoom;
							setObj.latitude =  result[i].latitude;
							setObj.longitude =  result[i].longitude;
						}else{
							if(result[i].tabgroup == 'content'){
								b_contentTabArr[tmpContentIdx] = result[i].tabname;	//content tab list
								b_contentTabTypeArr[tmpContentIdx] = result[i].tabtype; //content tab type list
								b_contentNum[tmpContentIdx] = result[i].tabheight;	//content num
								b_contentTabIdxArr[tmpContentIdx] = result[i].tabidx;
								tmpContentIdx ++;
							}else if(result[i].tabgroup == 'board'){
								b_boardTabArr[tmpBoardIdx] = result[i].tabname;	//board tab list
								b_boardNum[tmpBoardIdx] = result[i].tabheight;	//board num
								b_boardTabIdxArr[tmpBoardIdx] = result[i].tabidx;
								tmpBoardIdx++;
							}
						}
					}
					setObj.contentTab = b_contentTabArr;
					setObj.contentTabType = b_contentTabTypeArr;
					setObj.contentNum = b_contentNum;
					setObj.contentTabIdx = b_contentTabIdxArr;
					setObj.boardTab = b_boardTabArr;
					setObj.boardNum = b_boardNum;
					setObj.boardTabIdx = b_boardTabIdxArr;
				}
				
				dMarkerLat = setObj.latitude;
				dMarkerLng = setObj.longitude;
				
				if(setObj.openAPI == '0') {									//openAPI 보여주기 여부  {0:안보이기, 1:보이기}
					var idx = $.inArray('OpenApi', menuArr);	
					menuArr[idx] = 'OpenApi_off';
				}
				if(setObj.latestView == '0'){								//latest Upload 보여주기 여부  {0:안보이기, 1:보이기}
					var idx = $.inArray('latestUpload', menuArr);
					menuArr[idx] = 'latestUpload_off';
				}
				getServer("","", "");
				rightTabAdd();								//content TAB 추가
				rightTabChang('content_tab');				//left list content type setting
			}else{
				jAlert(data.Message, 'Info');
				setObj = new Object();
				setObj.openAPI = '0';
				setObj.latestView = '1';
				setObj.mapZoom = 8;
				rightTabAdd();								//content TAB 추가
				rightTabChang('content_tab');				//left list content type setting
			}
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
				jAlert(data.Message, 'Info');
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

//right tab add
function rightTabAdd() {
	var innerHTMLStr = "";
	innerHTMLStr += '<div id="content_tab" style="height:22px; width:190px; margin-left:6px; float:left; text-align:center; font-size:13px; top:100px; font-weight:bold; cursor:pointer;" ';
	innerHTMLStr += ' onclick="rightTabChang(this.id)">';
	innerHTMLStr += 'CONTENT';
	innerHTMLStr += '</div>';
	$('#board_tab').before(innerHTMLStr);	
}

//right tab click event
function rightTabChang(objId){
	if(editMode == 1){
		return;
	}
	nowTabName = '';	//현재 선택한 탭 이름 초기화
	if(objId == 'content_tab'){						//content_tab 선택시
		$('#content_tab').removeClass('col_gray1');
		$('#content_tab').addClass('col_blue');
		$('#content_tab').css('color', '#ffffff');
		$('#board_tab').removeClass('col_blue');
		$('#board_tab').addClass('col_gray1');
		$('#board_tab').css('color', 'gray');
		
		b_url = 'cms/getContent/';
		
		tabArr = b_contentTabArr;
		tabTypeArr = b_contentTabTypeArr;
		tabNumArr = b_contentNum;
		tabIdxArr = b_contentTabIdxArr;
		nowRightTabName = 'content';				//현재 선택한 right tab
		mainSetting();								//left type 설정
	}else{											//board_tab 선택시
		$('#board_tab').removeClass('col_gray1');
		$('#board_tab').addClass('col_blue');
		$('#board_tab').css('color', '#ffffff');
		$('#content_tab').removeClass('col_blue');
		$('#content_tab').addClass('col_gray1');
		$('#content_tab').css('color', 'gray');
		
		b_url = "cms/getBoard/";
		
		tabArr = b_boardTabArr;
		tabTypeArr = null;
		tabNumArr = b_boardNum;
		tabIdxArr = b_boardTabIdxArr;
		nowRightTabName = 'board';					//현재 선택한 right tab
		mainSetting();								//left type 설정
	}
}

//메뉴 설정
function mainSetting() {
	tableMap = newMap();	//table list info
	tabSetting();			//상단 리스트 TAB 설정
	menuSetting();			//메뉴 설정
}

var totalHeaderWidth = 0;	//전체 tab 너비
//상단 리스트 TAB 설정
function tabSetting(){
	var tabList = null;
	if(editMode == 1 &&  tempTabArr != null){		//만약 VIEW 모드이면 	임시저장 된 메뉴리스트를 그려준다.
		tabList = tempTabArr;
	}else{
		tabList = tabArr;
	}
	
	$('#tabs').empty();
	
	totalHeaderWidth = 0;
	tabMoveNum = 0;
	tabMaxMoveNum = 0;

	$("#tabs").append("<div id='tabHeader' style='height:25px; width:420px; overflow:hidden; position:absolute; background-color:#000000;'></div>");
	$("#tabHeader").append("<div id='tabHeader_long' style='height:25px; border-radius:5px 5px 0 0; position:absolute; width:6000px; margin-left:27px;'></div>");
	
	$("#tabs").append("<div style='width: 30px;height: 25px;background-color: black;position: absolute;left: 390px;display:none;' class='moveIcon'></div>");
	$("#tabs").append("<div style='width: 30px; height: 25px; background-color: black; position: absolute; display: none;' class='moveIcon'></div>");
	$("#tabs").append("<img src='<c:url value='/images/geoImg/btn_image/tab_move_l.png'/>' style='width: 10px;height: 18px;top: 3px;position: absolute;display: none;left: 9px;' class='moveIcon' onclick='tabMove(\"right\")'>");
	$("#tabs").append("<img src='<c:url value='/images/geoImg/btn_image/tab_move_r.png'/>' style='width: 10px;height: 18px;top: 2px;left: 401px;position: absolute;display: none;background-color: black;' class='moveIcon' onclick='tabMove(\"left\")'>");
	
	for(var i=0;i<tabList.length;i++){
		var header = "<div style='float:left; height:86%; margin-left:3px; border:1px solid #999; border-bottom:0px; border-radius:5px 5px 0 0; text-align:center; padding-top:2px;cursor:pointer;'";
		header += "id='header_" + i + "' class='tabDiv'>";
		
		header += "<input type='radio' id='tabRadio_" + i + "' name='tabRadio' class='editing' style='float:left; display:none;' onclick='callList(this.id)'>";
		header += "<a id='tabA_"+ i + "' class='tabsClass' style='text-decoration:none; color:black;' onclick='selectTab(this.id)'>" + tabList[i] + "</a>";
		
		header += "</div>";
		$("#tabHeader_long").append(header);
		
		$('#header_' + i).css("width", $('#header_' + i).width() + 30);
	}
	$("#tabs").append("<div id='tabs-1' style='width:420px;'></div>");
	
	$('#tabs-1').append("<table border=1 class='ui-widget' id='left_list_table_1' style='margin: 30px 20px 16px 20px; border-collapse: collapse; height: 563px;width:383px;border-left:0px;border-color:#999;'><tbody></tbody></table>");	//처음 페이지 로딩시 첫번째 tab만 데이터 로딩

	tabMaxMoveNum = $('#tabHeader').width();
	
	if(editMode == 1 &&  tempTabArr != null){
		$.each($('.tabDiv'), function(idx, val){
			totalHeaderWidth += $(val).width()+ 17;
		});
	}else{
		$.each($('.tabDiv'), function(idx, val){
			totalHeaderWidth += $(val).width()+3;
		});
	}
	
	if((totalHeaderWidth > 380 && editMode == 0) || (totalHeaderWidth > 370 && editMode != 0)){
		$('.moveIcon').css("display", "block");
		totalHeaderWidth += 60;
	}
	
	if(editMode == 1){
		$('.tabDiv').animate({width : "+=15"});
		totalHeaderWidth += (15 * (tabArr.length-1));
		$('.editing').css('display', 'block');

		var editNowIndex = $.inArray(tempTabName, tempTabArr);
		callList('tabRadio_'+editNowIndex);
	}

	//초기 설정시 탭 데이터 설정
	if(nowTabName == ""){
		selectTab('tabA_'+ 0);	//탭 클릭시 해당 탭의 데이터를 불러온다
	}
}

//탭 선택 시 적용되는 함수
function selectTab(objId){
	$('.tabDiv').removeClass('col_blue');
	$('.tabDiv').addClass('col_gray1');
	$('.tabsClass').css('color', 'gray');
	$('#'+objId).parent().removeClass('col_gray1');
	$('#'+objId).parent().addClass('col_blue');
	$('#'+objId).css('color', '#ffffff');
	$('#polygonView').attr('checked', false); //지도 polygon view off
	
	var tIdx = -1;
	var tType = "";
	var tConNum = 0;
	var tTabHeight = 0;
	
	tIdx = objId.replace('tabA_','');
	tTabHeight = tabNumArr[tIdx];
	if(tabNumArr[tIdx] == null || tabNumArr[tIdx] == '' || tabNumArr[tIdx] == undefined){
		tConNum = cntOfHeight(550, "");
	}else{
		tConNum = cntOfHeight(tabNumArr[tIdx], "");
	}
	nowTabName = tabArr[tIdx];
	
	if(nowRightTabName == "content"){
		tType = tabTypeArr[tIdx];
// 		tConNum =cntOfHeight(tabNumArr[tIdx], tType);
		if(tabNumArr[tIdx] == null || tabNumArr[tIdx] == '' || tabNumArr[tIdx] == undefined){
			tConNum = cntOfHeight(550, tType);
		}else{
			tConNum = cntOfHeight(tabNumArr[tIdx], tType);
		}
	}

	$('#left_list_table_1').css("height", tTabHeight);
	//list setting
	leftMenuSetting("1", tType, "1", tConNum);
}

var tabMoveNum = 0;
var tabMaxMoveNum = 0;
//탭 좌 우의 이미지 버튼 클릭시 탭 무빙
function tabMove(text){
	if(text == "left" && tabMaxMoveNum <= totalHeaderWidth){
		$('#tabHeader_long').animate({marginLeft : "-=30"});
		tabMoveNum -= 30;
		tabMaxMoveNum += 20;
	}else if(text == "right" && tabMoveNum < 0){
		$('#tabHeader_long').animate({marginLeft : "+=30"});
		tabMoveNum += 30;
		tabMaxMoveNum -= 20;
	}
}

//메뉴 설정
function menuSetting(){
	$('#menus').empty();
	//임의 메뉴 설정
	menuMap = newMap();
	menuMap.put("logo",{"src": "<c:url value='/images/geoImg/english_images/logo.jpg'/>", "top": 20, "width": 152, "etc": ""});	//이미지 주소, top, width, function 및 id
	menuMap.put("MyProjects",{"src": "<c:url value='/images/geoImg/english_images/myProjects.png'/>", "top": 55, "width": 77, "etc": "onclick='viewMyProjects(null);'"});
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
			var searchTop = 52;
			if(loginType =='ADMIN') {
				searchTop = 32;
			}
			innerHTMLStr += "<img src='" + menuMap.get(menuId).src + "' id='" + menuId + "' class='menu_images' style='width:" + menuMap.get(menuId).width + "px; top:" + searchTop + "px; right:50px; position:relative; cursor: pointer; float:right; clear:both;' ";
			innerHTMLStr +=  menuMap.get(menuId).etc + " /> ";
			innerHTMLStr += "<input type='text' id='srchBox' size='50' style='position:relative; top:"+ searchTop +"px; right:50px; height: 23px; float:right;' onKeyPress='submit1(event);'/>";
		}
		
		if(menuId != "searchBox"){
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

//list setting
function leftMenuSetting(tableNum, type, pageNum, contentNum){	//tableNum, type, pageNum, contentNum
	objSetting(tableNum, type, pageNum, contentNum);	//tab페이지에 데이터 설정 (table_num, type, page_num, content_num)
	
	$('#left_list_table_2').empty();
	
	setTimeout(function(){
		var tableRow = 0;
		var obj1 = tableMap.get("1");
		var table_two_count = 0;
		var t_tabHeight = $('#tabs').height();
		if(t_tabHeight == 0){
			t_tabHeight = 400;
		}
		
		if(nowRightTabName == 'content'){
			table_two_count = Math.floor(($('#image_map').height()-40-$('#imageMoveArea').children().first().outerHeight() - t_tabHeight)/102);
			if(type == 'gellery'){
				table_two_count = Math.floor(($('#image_map').height()-40-$('#imageMoveArea').children().first().outerHeight() - t_tabHeight)/150)*3;
			}
		}else{
			table_two_count = Math.floor(($('#image_map').height()-$('#imageMoveArea').children().first().outerHeight() - t_tabHeight - 40)/26)-1;
		}


		if(tableNum == "1"){
			var tempTop = 400;
			if($('#left_list_table_1').offset() != null && $('#left_list_table_1').height() != null){
				tempTop = $('#left_list_table_1').offset().top + $('#left_list_table_1').height();
			}
			if(table_two_count > 0){
				tableRow = table_two_count;
				if($.inArray("latestUpload", menuArr) > -1){
					$('#latestUpload').css("display", "block");
					$('#image_latest_list').css("display", "block");
				}
				
				$('#latestUpload').css("top", tempTop + 40);
				$('#image_latest_list').css("top", tempTop + 60);
			}else{
				$('#latestUpload').css("display", "none");
				$('#image_latest_list').css("display", "none");
			}

			$('#moreViewImg').css("top", tempTop-20);
		}

		var thisIndex = $.inArray("latestUpload", menuArr);
		if(thisIndex > -1){
			$('#latestUpload').css('display', 'block');
			$('#image_latest_list').css('display', 'block');
		}else{
			$('#latestUpload').css('display', 'none');
			$('#image_latest_list').css('display', 'none');
		}
		$('.hrLine').remove();
		if(tableRow > 0) {
			$('#tabs-1').append("<hr class='hrLine'>");
			if(nowRightTabName == 'board')	tableRow =  tableRow -1;
			objSetting("2", type, "1", tableRow);	//latest 페이지에 데이터 설정(table_num, type, page_num, content_num)
		}else{
			$('#latestUpload').css('display', 'none');
		}
		
	}, 200);
}

//image table 정보 설정
function objSetting(table_num, image_type, page_num, content_num){
	var nowObj = new Object();
	nowObj.table_num = table_num;							//image table num
	nowObj.table_name = 'left_list_table_' + table_num;		//image table name
	nowObj.type = (table_num == "1")?"list":"latest";		//image table data type
	nowObj.image_type = image_type;							//image table image type
	nowObj.content_num = content_num;						//image table content count
	nowObj.max_cell = (image_type == "gellery")?3:1;		//image table cell count
	nowObj.max_row = content_num/nowObj.max_cell;			//image table row count
	nowObj.imgWidth = (image_type == "gellery")?100:120;	//image table image width
	nowObj.imgHeight = (image_type == "gellery")?110:73;	//image table image height
	
	if(tableMap.get(table_num) == null){
		tableMap.put(table_num, nowObj);
	}else{
		tableMap.put(table_num, nowObj);
	}
	
	clickImagePage(page_num, table_num);	//image table setting
}

//설정 파일 읽어오는 부분 필요

//페이지 선택
function clickImagePage(pageNum, tableNum){
	var obj = tableMap.get(tableNum);
	var tName = nowTabName;
	if(editMode == 1){
		var tIdx = $.inArray(tempTabName, tempTabArr);
		tName = tempOldNameArr[tIdx];
	}
	obj.pageNum = pageNum;
	
	var dataIdx = '&nbsp';
	var tmpTabIndex = 1;
	
	if(tName == null || tName == ""){
		tName = '&nbsp';
	}else{
		tmpTabIndex = $.inArray(tName, b_boardTabArr)+1;
	}
	
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpIndex = '&nbsp';
	
	if(tmpLoginId == null || tmpLoginId == "" || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == "" || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	
	var Url			= baseRoot() + "cms/getBoard/";
	var param		= obj.type + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + pageNum + "/" + obj.content_num + "/" + tmpTabIndex + "/" + dataIdx;
	var callBack	= "?callback=?";

	//현재 left tab가 board일때
	if(nowRightTabName == "board"){
		$.ajax({
			type	: "get"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				var response = data.Data;
				
				//이미지 리스트 설정
				leftListSetup(response, obj);
				//페이지 설정
				var dataLen = 1;
				if(data.DataLen != null && data.DataLen != "" && data.DataLen != "null"){
					dataLen = data.DataLen;
				}
				if(tableNum == "1"){leftPageSetup(dataLen, obj);}
				//디자인 적용
				setImageDesign(obj);
			}
		});
	}else{
		if(tName != null && tName != '' && tName != '&nbsp'){
			tmpTabIndex = $.inArray(tName, b_contentTabArr)+1;
		}

		Url			= baseRoot() + b_url;
		param		= obj.type + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + pageNum + "/" + obj.content_num + "/" + tmpTabIndex + "/" + tmpIndex;
		
		$.ajax({
			type	: "get"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				var response = data.Data;
				
				leftListSetup(response, obj);
				//페이지 설정
				var dataLen = 1;
				if(data.DataLen != null && data.DataLen != "" && data.DataLen != "null" && data.DataLen != undefined){
					dataLen = data.DataLen;
				}
				if(obj.table_num == "1"){leftPageSetup(dataLen, obj);}
				
				//디자인 적용
				setImageDesign(obj);
			}
		});
	}
}

//image table css
function setImageDesign(obj) {
	if(obj.image_type == "list" && nowRightTabName == 'content'){
		$('#'+obj.table_name+'  tbody tr td').css('width', '400px');
		$('#'+obj.table_name+'  tbody tr td').css('border-bottom', '1px solid gray');
		$('#'+obj.table_name+'  tbody tr:last-child td').css('border-bottom', 'none');
	}
}

//이미지 리스트 설정
function leftListSetup(pure_data, obj) {
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

			if(nowRightTabName != 'board') {
				lat_arr.push(pure_data[i].latitude);
				lon_arr.push(pure_data[i].longitude);
				thumbnail_url_arr.push(pure_data[i].thumbnail);
				origin_url_arr.push(pure_data[i].originname);
				dataKind_arr.push(pure_data[i].datakind);	// GeoPhoto, GeoVideo
				projectUserId_arr.push(pure_data[i].projectUserId);	// project user id
				status_arr.push(pure_data[i].status);	// file upload status
			}
		}
	}
	
	//부족한 데이터는 "" 로 채운다
	var max_row = obj.max_row;
	var max_cell = obj.max_cell;
	if((max_row * max_cell) > id_arr.length) {
		for(var i = id_arr.length; i < (max_row*max_cell); i++) {
			id_arr.push("");
			title_arr.push("");
			content_arr.push("");
			file_url_arr.push("");
			udate_arr.push("");
			idx_arr.push("");
		}
	}
	//테이블 초기화
	$('#'+obj.table_name+" tr").remove();
	
	//테이블에 데이터 추가
	if(nowRightTabName == 'content') {		//현재 right tab이 content일 경우
		//content list view (gellery or list type)
		addLeftImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr, obj);
	}else{
		//board list view
		addBoardDataCell(id_arr, title_arr, content_arr, file_url_arr, idx_arr, udate_arr, obj);
	}
}

//left content list data add
function addLeftImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr, obj){
	var target = document.getElementById(obj.table_name);
	var max_row = obj.max_row;
	var max_cell = obj.max_cell;
	var blankImg = '<c:url value="/images/geoImg/blank(100x70).PNG"/>';

	var thumbnail_arr = new Array();
	//xml file check
	for(var i=0;i<file_url_arr.length;i++){
		var thumbnail_arr_data = loadXMLMain(file_url_arr[i], dataKind_arr[i]);
		thumbnail_arr.push(thumbnail_arr_data);
	}
	
	var imgWidth = obj.imgWidth;		//image width
	var imgHeight = obj.imgHeight;		//image height
	var img_type = obj.image_type;		//image type
	
	$('#'+obj.table_name).attr("border","0");
	
	var tmpMakerImg = 'images';
	if(obj.isPop != null && obj.isPop != '' && obj.isPop != 'null'){
		target = window.frames[1].document.getElementById(obj.table_name);
		tmpMakerImg = '../images';
	}
	
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
			 if(img_type == "gellery"){innerHTMLStr += "<div style='margin-left: 10px;font-size:12px;border: 3px solid gray;width: 100px;line-height: 20px;margin-top: -13px;'>&nbsp&nbsp&nbsp</div>";}
			img_cell.innerHTML = innerHTMLStr;
		}else{
			innerHTMLStr += "<a class='imageTag' href='javascript:;' onclick="+'"';
			if(obj.isPop == null || obj.isPop == '' || obj.isPop == 'null'){	//메인리스트면 mapCenterchange event , 아니면 view event
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
			}else if(dataKind_arr[i] == "GeoPhoto"){
				innerHTMLStr += "parent.imageViewer('"+file_url_arr[i]+"','"+ id_arr[i] +"','"+ idx_arr[i] +"','"+projectUserId_arr[i]+"');";
			}else if(dataKind_arr[i] == "GeoVideo"){
				innerHTMLStr += "parent.videoViewer('"+file_url_arr[i]+"', '"+ origin_url_arr[i]+"','"+ id_arr[i] +"','"+ idx_arr[i] +"','"+projectUserId_arr[i]+"');";
			}

			innerHTMLStr += '"'+" title='TITLE : "+ title_arr[i] +"\nCONTENT : "+ content_arr[i] +"' border='0'>";
			//image or video icon add
			innerHTMLStr += "<div style='position:absolute; width:30px; height:30px; margin:15px 0 0 15px;  background-image:url(<c:url value='"+tmpMakerImg+"/geoImg/"+ dataKind_arr[i] +"_marker.png' />); zoom:0.7;'></div>";
			//xml file check icon add
			if(thumbnail_arr[i] == 1){
				var tempTop = 63;
				var tempLeft = 116;
				var tempXmlImg = 'xmlFile_w.png';
				if(img_type == 'gellery'){
					tempTop = 129;
					tempLeft = 94; 
					tempXmlImg = 'xmlFile_b.png';
				}
				innerHTMLStr += "<div></div>"
				innerHTMLStr += "<div style='position:absolute; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px; background-image:url(<c:url value='"+tmpMakerImg+"/geoImg/btn_image/"+tempXmlImg+"'/>);background-repeat: no-repeat;background-size: 15px 20px;'></div>";
			}
			
			innerHTMLStr += "<img class='round' src='"+localAddress+"' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' style='border:3px solid gray'/>";
			
			innerHTMLStr += "</a>";
			
			var tempWriter = (img_type == "list")?"style='position: absolute; left: 150px; margin-top:-50px; font-size:12px;'":"";	//list type인 경우 작성자명 위치 설정
			var tempDate = (img_type == "list")?"style='position: absolute; left: 150px; margin-top:-30px; font-size:12px;'":"style='margin-left: 10px; font-size:12px;'";	//list type인 경우 날짜 위치 설정
			if(img_type == "list"){
				innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-50px; font-size:12px;'>&nbsp;Writer : "+id_arr[i]+"</div>";
				innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-30px; font-size:12px;'>&nbsp;Date : "+udate_arr[i]+"</div>";
			}else{
				innerHTMLStr += "<div style='margin-left: 10px;font-size:12px;border: 3px solid gray;width: 100px;line-height: 25px;margin-top: -13px;'>&nbsp;"+udate_arr[i]+"</div>";
			}
			
			img_cell.innerHTML = innerHTMLStr;
		}
	}
}

//left board list data add
function addBoardDataCell(id_arr, title_arr, content_arr, file_url_arr, idx_arr, udate_arr, obj){
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

	for(var i=0;i<id_arr.length;i++){
		var titleStr = title_arr[i];
		if(titleStr != null && titleStr.length > 15){
			titleStr = titleStr.substring(0,15) + "...";
		}
		if(id_arr[i] == null || id_arr[i] == ''){
			innerHTMLStr += "<tr style='text-align:center;height:25px;'>";
		}else{
			innerHTMLStr += "<tr style='text-align:center;height:25px;' onclick='boardViewDetail(this);' id='GeoCMS_" + idx_arr[i] + "'>";
		}
		innerHTMLStr += "<td style='text-align:left;'>" + titleStr +"</td><td>" + id_arr[i] + " </td><td>" + udate_arr[i] + "</td>";
		innerHTMLStr += "</tr><tr class='tr_line' bgcolor='#D2D2D2'><td colspan='3'></td></tr>";
	}
	$('#'+obj.table_name).append(innerHTMLStr);
	$('#'+obj.table_name).attr('border', '0');
	
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
function moreListView(viewPageNum, b_nowTabIdx, selBoardNum){
	if(viewPageNum == null || viewPageNum == '' || viewPageNum == 'null'){
		viewPageNum = 1;
	}
	var tempTabName = nowTabName;
	var movePage = '';
	var tmpTabIndex = 1;
	
	if(nowRightTabName == 'content' && (b_nowTabIdx == null || b_nowTabIdx == '')){
		movePage = '<c:url value="/geoCMS/content_list.do"/>';
		if(tempTabName != null && tempTabName != ''){
			tmpTabIndex = $.inArray(tempTabName, b_contentTabArr)+1;
		}
	}else{
		movePage = '<c:url value="/geoCMS/board_list.do"/>';
		if(b_nowTabIdx != null && b_nowTabIdx != '' && b_nowTabIdx != undefined){
			tmpTabIndex = b_nowTabIdx;
		}else if(tempTabName != null && tempTabName != ''){
			tmpTabIndex = $.inArray(tempTabName, b_boardTabArr)+1;
		}
	}
	
	contentViewDialog = jQuery.FrameDialog.create({
		url: movePage+'?viewPageNum='+viewPageNum+'&nowTabIdx='+tmpTabIndex+'&urlText='+b_url+'&selBoardNum='+selBoardNum,
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

//수정모드 일때 탭 라디오 버튼 클릭 시 해당 리스트를 불러온다.
function callList(objId){
	//이전 데이터 저장
	var oldTabIdx = $.inArray(tempTabName, tempTabArr);
	tempTabNumArr[oldTabIdx] = nowTabelHeight;
	
	tempTabName = $('#'+ objId).next().text();
	
	$('.tabDiv').css('background-color', '#F0F0F0');
	$('.tabsClass').css('color', '#000000');
	
	$('#'+objId).parent().css('background-color', '#0066FF');
	$('#'+objId).next().css('color', '#ffffff');
	
	var tIdx = $.inArray(tempTabName, tempTabArr);
	var tNum = cntOfHeight(tempTabNumArr[tIdx], "");
	var tType = "";
	$('#left_list_table_1').css('height', tempTabNumArr[tIdx]);
	
	nowContnetNum = tNum;
	nowTabelHeight = tempTabNumArr[tIdx];
	$('#'+objId).attr('checked', true);
	
	if(nowRightTabName == "content"){
		tType = tempTabTypeArr[tIdx];
		imgType1 = tType;
		tNum = cntOfHeight(tempTabNumArr[tIdx], tType);
		if(tType == "gellery"){
			nowContnetNum =  Math.floor(tempTabNumArr[tIdx]/150);
			tNum = tNum/3;
		}
		editLeftSetting(tType, tNum, tempTabNumArr[tIdx], 1);
		$('#left_list_table_1_view').remove();
		$('#left_list_table_1_resize').remove();
		moveObjView();
	}else{
		tNum = cntOfHeight(tempTabNumArr[tIdx], tType);
		editLeftBoardSetting(tNum, tempTabNumArr[tIdx], 1);
		$('#left_list_table_1_view').remove();
		$('#left_list_table_1_resize').remove();
		moveObjView();
	}
	return;
}

//컨텐츠 갯수 반환
function cntOfHeight(num, type){
	var tNum = 0;
	if(nowRightTabName == "content"){
		tNum = Math.floor(num/102);
		if(type == "gellery"){
			tNum = Math.floor(num/150)*3;
		}
	}else{
		tNum = Math.floor(num/26)-2;
	}
	return tNum;
}

//my content list page
function viewMyContents(){
	$('#myContent_list').css('display','block');
	myContentsListSetup();
}

//my project list page
function viewMyProjects(orderIdx){

	$('#myProject_list').css('display','block');
	$('#image_latest_list').css('display','none');
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
