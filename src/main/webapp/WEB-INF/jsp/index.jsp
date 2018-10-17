<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%-- <%@ page autoFlush="true" buffer="1094kb"%> --%>
<%@ page import="javax.servlet.http.HttpServletResponse,java.io.PrintWriter;" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="page_common.jsp"></jsp:include>
<jsp:include page="mainSetting.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
String loginType = (String)session.getAttribute("loginType");				//로그인 권한
%>
<title>GeoCMS</title>

<!-- login -->
<script type="text/javascript">
var loginId = '<%=loginId%>';
var loginToken = '<%=loginToken%>';
var loginType = '<%=loginType%>';

var typeShape ="marker";
var LocationData = new Array();	//마커용
var editMode = 0;	//편집 모드 (0:일반 모드 , 1:편집모드)
var b_contentNum = [];
var menuArr = ['logo', /*'MakeContents',*/ 'MyProjects', /*'OpenApi',  'latestUpload',*/ 'searchBox']; 		//menu List
var projectImage = 0;	//GeoPhoto 다운여부
var projectVideo = 0;	//GeoVideo 다운여부
var b_url = '';			//url
var request = null;		//request;
var dMarkerLat = 0;		//default marker latitude
var dMarkerLng = 0;		//default marker longitude
var b_nowProjectIdx = 0;
var b_nowProjectContentNum = 18;
var b_orderType = 'DESC';

$(function(){
	session_check();	//login check
	
	var mapWidth = $(window).width()- $('#image_list').width();	//화면 크기에 따라 이미지 크기 조정
	$('#image_map').css('width', mapWidth);
	
	var setMapHeight = $(window).height() - 100 - $('#footer').height();//화면 크기에 따라 이미지 크기 조정
	if(setMapHeight > 500){
		$('#image_map').css('height', setMapHeight);
	}
	
    $('#dialog').dialog({	//openApi dialog
      autoOpen: false,
      width:845,
      height:660,
      minHeight:660,
      top:100,
      modal:true,
      hide: {
        effect: 'explode',
        duration: 1000
      }
    });
    
    $('#LoginDig').dialog({	//projectName 추가, 수정 dialog
        autoOpen: false,
        width:400,
        height:160,
        title:'LOGIN',
        modal:true,
        background:"#99CCFF"
      });
    
    $('#projectNameAddDig').dialog({	//projectName 추가, 수정 dialog
        autoOpen: false,
        width:320,
        height:191,
        title:'Add Layer',
        modal:true,
        background:"#99CCFF"
      });
    
    $('#uploadWorldFileDig').dialog({	//좌표 파일 추가
        autoOpen: false,
        width:360,
        height:210,
        title:'File Upload',
        modal:true,
        background:"#e5e5e5"
      });
    
    $('#copyPojectAddDig').dialog({	//projectName 추가, 수정 dialog
        autoOpen: false,
        width:320,
        height:130,
        title:'Add Layer',
        modal:true,
        background:"#99CCFF"
      });
    
    $('#serverDig').dialog({	//serverDig
        autoOpen: false,
        width:500,
        height:200,
        modal:true,
        background:"#99CCFF"
      });
    
    callRequest("BI", "/GeoPhoto/geoSetChkImage.do", null);
    
    $(window).resize(function(){
    	var mapWidth = 0;
    	if($(window).width() < $('#menus').css('min-width').replace('px','')){
    		mapWidth = $('#menus').css('min-width').replace('px','') - $('#image_list').width();
    	}else{
    		mapWidth = $(window).width()- $('#image_list').width();	//화면 크기에 따라 이미지 크기 조정
    	}
    	$('#image_map').css('width', mapWidth);
    	$('#map_canvas').css('min-width',mapWidth);
    }).resize();

});

//GeoPhoto, GeoVideo 연결
function httpRequest(type, obj){
	if(window.XMLHttpRequest){
		try{
			request = new XMLHttpRequest();
		}catch(e){
			request = null;
		}

	}else if(window.ActiveXObject){
		//* IE
		try{
			request = new ActiveXObject("Msxml2.XMLHTTP");
		}catch(e){
			//* Old Version IE
			try{
				request = new ActiveXObject("Microsoft.XMLHTTP");
			}catch(e){
				request = null;
			}
		}
	}

	request.onreadystatechange = function(){
		if(request.readyState == 4 && request.status == 200){
			if(type == "BI"){
				projectImage = 1;
				callRequest("BV", "/GeoVideo/geoSetChkVideo.do", null);
			}
			else if(type == "BV"){
				projectVideo = 1;
				getBase();
			}
		}else if(request.readyState == 4 && type == "BI"){
			callRequest("BV", "/GeoVideo/geoSetChkVideo.do", null);
		}else if(request.readyState == 4 && type == "BV"){
			getBase();
		}
	}
}

//GeoPhoto, GeoVideo 연결 function
function callRequest(type, textUrl, obj){
	httpRequest(type, obj);
	request.open("POST", "http://"+location.host + textUrl, true);
	request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
	request.send(null);
}

//login 여부
function session_check(){
	if(loginId != null && loginId != '' && loginId != 'null') {
		$('#login_page').css('display', 'none');
		$('#status_login').css('display', 'block');
		$('#userId').text(loginId);
		
		var tmpWidth = $('#userId').width();
		if(loginType !='ADMIN'){
			tmpWidth += 100;
			$('#userId').css('right', tmpWidth+'px');
			$('#status_login').find('img').css('right', '45px');
		}else{
			tmpWidth += 340;
			$('#userId').css('right', tmpWidth+'px');
		}
	}else{
		$('#login_page').css('display', 'block');
		$('#status_login').css('display', 'none');
	}
}

//search word
function searchAction(){
	if(proEdit == 1){
		moveProContent();
	}
	$('#myProject_list').css('display','none');
	$('#copyReqStart').css('display','none');
	if(editMode == 1){	//편집 모드 시 검색 불가
		return;
	}
	var Skeyword = $('#srchBox').val();
	$('#search_bar').val(Skeyword);
	
	search();
	
	$('#image_list').css('display', 'none');
// 	$('#latestUpload').css('display', 'none');
// 	$('#moreViewImg').css('display', 'none');
// 	$('#image_latest_list').css('display', 'none');
	$('#image_list').next().css('display', 'none');
	
	$('#srch_page').css('display', 'block');
}

//검색어 입력
function submit1(e){
	var keycode;
	if(window.event) keycode = window.event.keyCode;
	else if(e) keycode = e.which;
	else return true;
	if(keycode == 13) {
		searchAction();
	}
}

//openAPI 팝업
function diagOpen(){
	 $('#dialog').dialog( 'open' );
}

//logout
function fnLogout(){
	if(editMode != 0){
		return;	
	}
	
	$.ajax({
		type: 'POST',
		url: "<c:url value='geoSetUserInfo.do'/>",
		data: 'typeVal=logout',
		success: function(data) {
			window.location.href='/GeoCMS';
		}
	});
}


//googleMap
function cmsLoadExif(){
	
	var markerCnt = 5;
	var tmpPageNum = '&nbsp';
	var tmpTabName = editMode == 1?tempTabName:nowTabName;
	
	var Url			= baseRoot() + b_url;
	var param		= typeShape + "/" + tmpPageNum + "/" + markerCnt + "/" + tmpTabName;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			markDataMake(response);
		}
	});
}

</script>

</head>
<body bgcolor="#FFF" id="mainBody">
<!-- 	<input type="text" id="aesText" style="width:100px;height: 30px;"> -->
<!-- 	<button id="aesBtn" onclick="getAes('A');">AES BTN</button> -->
<!-- 	<button id="aesBtn" onclick="getAes('D');">DES BTN</button> -->
	<!-- 상단 메뉴 -->
	<div id="menus" style="width:100%;height:90px; min-width: 1500px;">
	</div>
	
	<div id="status_login" style="display:none;">
		<!-- user -->
		<div id="userId" style="height:30px; position:absolute; top:17px;color: blue;"></div>
		<!-- logout -->
		<img src="<c:url value='/images/geoImg/main_images/logout.png'/>" style="position:absolute; right:300px; top: 15px; width:50px; height:24px; cursor:pointer;" onclick="fnLogout();">
	</div>
	
	<!-- login -->
	<div id="login_page" style="position:relative; right:0px; top:-100px; display:none; width: 100%; min-width:1500px;">
		<jsp:include page="sub/user/login.jsp"/>
	</div>
	
	<!-- map -->
	<div id="image_map" style="height:769px; position:absolute; left:420px; top:100px; background-color: #EAEAEA; z-index: 10;">
		<jsp:include page="sub/map/image_googlemap.jsp"/>
	</div>
	
	<!-- left list table -->
	<div id="image_list" style="width:420px; position:absolute; top:150px; display:block; z-index: 1">
		<jsp:include page="image_content_list.jsp"/>
	</div>
	
	<!-- my contents table -->
	<div id="myContent_list" style="width: 420px; height:800px; position: absolute; top: 100px; display: none; z-index: 490; background-color:white;">
		<jsp:include page="sub/contents/myContents.jsp"/>
	</div>
	
	<!-- my projects table -->
	<div id="myProject_list" style="width: 420px; height:800px; position: absolute; top: 100px; display: none; z-index: 490; background-color:white;">
		<jsp:include page="sub/project/myProjects.jsp"/>
	</div>
	
	<!-- more view -->
<%-- 	<img src="<c:url value='/images/geoImg/btn_image/more_list.png'/>" id="moreViewImg" style="position:absolute; left:390px; top: 143px; width:20px; height:20px;z-index:1" onclick="moreListView(1,'','');"> --%>
	
	<!-- latest upload -->
<%-- 	<img src="<c:url value='/images/geoImg/english_images/title_01.gif'/>" style="position:absolute; left:20px; top: 465px;" id="latestUpload"/> --%>
<!-- 	<div id="image_latest_list" style="position:absolute; top:480px; left:12px; display:block; z-index: 0"> -->
<!-- 		<table border=0 id="left_list_table_2" style="margin-left: 10px;"> -->
<!-- 			<tbody> -->
<!-- 			</tbody> -->
<!-- 		</table> -->
<!-- 	</div> -->
	
	<div id="srch_page" style="display: none;">
		<jsp:include page="search_page.jsp"/>
	</div>
	<div id="make_contents" style="position:absolute; left:250px; top:430px; z-index:1;">
		<jsp:include page="sub/contents/make_contents.jsp"/>
	</div>
	<div id="edit_start_page" style="display: none;">
		<jsp:include page="sub/edit/edit_start_page.jsp"/>
	</div>
	<div id="footer" style="position:absolute; width:100%; height:40px; top:869px; z-index:2; min-width: 1500px; /* background-color:#EAEAEA; */ ">
		<jsp:include page="footer.jsp"/>
	</div>
	
	<div id="dialog" title="Open API" style="display:none;">
  		<img src="<c:url value='/images/geoImg/APIcontent2.jpg'/>">
	</div>
	
	<div style="display: none;">
		<jsp:include page="sub/moreList/board_list.jsp"></jsp:include>
	</div>
	
	<div style="display: none;">
		<jsp:include page="sub/moreList/content_list.jsp"></jsp:include>
	</div>
	
	<!-- server dialog -->
	<div id="serverDig">
		<div>
			<label style="display: block; height: 30px; font-size: 16px; float: left; width: 200px; font-weight: bold;">FILE SAVE URL</label>
			<button id="serverAddBtn" onclick="serverAdd();" style="width: 50px; height: 20px; float: right; margin-right:6px;">ADD</button>
		</div>
		<div style="font-size: 15px;" id="serverDiv">
		</div>
		<div style="text-align: center; margin-top: 15px;" id="serverBtnArea">
			<button onclick="serverSettingSave();">Save</button>
			<button onclick="serverCencle();">Cencle</button>
		</div>
	</div>
</body>

</html>