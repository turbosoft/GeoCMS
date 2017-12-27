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
var LocationData = [];	//마커용
var editMode = 0;	//편집 모드 (0:일반 모드 , 1:편집모드)
// var tabArr = ['CivilComplaint', 'Traffic', 'Environment', 'Construction', 'board']; 	//tab menu list
var tabArr = [];		//tab list
var tabTypeArr = [];	//tab type list
var tabNumArr = [];		//tab count list
var b_contentTabArr = []; //content tab list
var b_contentTabTypeArr = [];	//content tab type list
var b_contentNum = [];
var b_boardTabArr = [];	//board tab list
var b_boardNum = [];
var menuArr = ['logo', /*'MakeContents',*/ 'MyProjects', 'OpenApi',  'latestUpload', 'searchBox']; 		//menu List
var projectImage = 0;	//GeoPhoto 다운여부
var projectVideo = 0;	//GeoVideo 다운여부
var b_url = '';			//url
var request = null;		//request;

$(function(){
	session_check();	//login check
	
	var mapWidth = $(window).width()- $('#image_list').width()	//화면 크기에 따라 이미지 크기 조정
	$('#image_map').css('width', mapWidth);
	
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
    
    $('#tabAddDig').dialog({	//tab 추가, 수정 dialog
        autoOpen: false,
        width:300,
        height:150,
        title:'TAB Manage',
        modal:true,
        background:"#99CCFF"
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
        width:400,
        height:150,
        title:'Make Project',
        modal:true,
        background:"#99CCFF"
//         position:[420,300]
      });
    
    $('#markerDig').dialog({	//marker change dialog
        autoOpen: false,
        width:400,
        height:150,
        title:'Maker Icon',
        modal:true,
        background:"#99CCFF"
//         position:[420,300]
      });
    
    callRequest("BI", "/GeoPhoto/geoSetChkImage.do", null);
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
// function callRequest(type, textUrl, params, obj){
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
			tmpWidth += 360;
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
	if(editMode == 1){	//편집 모드 시 검색 불가
		return;
	}
	var Skeyword = $('#srchBox').val();
	$('#search_bar').val(Skeyword);
	
	search();
	
	$('#image_list').css('display', 'none');
	$('#latestUpload').css('display', 'none');
	$('#moreViewImg').css('display', 'none');
	$('#image_latest_list').css('display', 'none');
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
<body bgcolor="#FFF">
	<!-- 상단 메뉴 -->
	<div id="menus" style="width:100%;height:100px;">
	</div>
	
	<div id="status_login" style="display:none;">
		<!-- user -->
		<div id="userId" style="height:30px; position:absolute; top:15px;color: blue;"></div>
		<!-- logout -->
		<img src="<c:url value='/images/geoImg/main_images/logout.png'/>" style="position:absolute; right:300px; top: 15px; width:50px; height:20px; cursor:pointer;" onclick="fnLogout();">
	</div>
	
	<!-- login -->
	<div id="login_page" style="position:absolute; right:0px; top:0px; display:none;">
		<jsp:include page="sub/user/login.jsp"/>
	</div>
	
	<!-- map -->
	<div id="image_map" style="height:800px; position:absolute; left:420px; top:100px; background-color: #EAEAEA; z-index: 10;">
		<jsp:include page="sub/map/image_googlemap.jsp"/>
	</div>
	
	<!-- left list table -->
	<div id="image_list" style="width:420px; position:absolute; top:100px; display:block; z-index: 1">
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
	<img src="<c:url value='/images/geoImg/btn_image/more_list.png'/>" id="moreViewImg" style="position:absolute; left:390px; top: 143px; width:20px; height:20px;z-index:1" onclick="moreListView(1,'','');">
	
	<!-- latest upload -->
	<img src="<c:url value='/images/geoImg/english_images/title_01.gif'/>" style="position:fixed; left:20px; top: 465px;" id="latestUpload"/>
	<div id="image_latest_list" style="position:absolute; top:480px; left:12px; display:block; z-index: 0">
		<table border=0 id="left_list_table_2" style="margin-left: 10px;">
			<tbody>
			</tbody>
		</table>
	</div>
	
	<!-- edit btn -->
	<div style="position:absolute;background-color: #ffffff;width:130px;height: 200px;left: 430px;top: 160px;border: 1px solid gray;z-index: 500;display:none;" id="editPopBtn">
		<img src="<c:url value='/images/geoImg/btn_image/edit_add.png'/>" style='width:30px; height:30px; margin:15px 0 0 5px;' onclick="tabEditBtn('ADD');"/>
		<label style="display: inline-block; float: right; margin: 25px 20px 0 0;">Add Tab</label><br>
		
		<img src="<c:url value='/images/geoImg/btn_image/edit_delete.png'/>" style='width:30px; height:30px; margin:15px 0 0 5px;' onclick="tabEditBtn('DELETE');"/>
		<label style="display: inline-block; float: right; margin: 25px 20px 0 0;">Delete Tab</label><br>
		
		<img src="<c:url value='/images/geoImg/btn_image/edit_update.png'/>" style='width:30px; height:30px; margin:15px 0 0 5px;' onclick="tabEditBtn('EDIT');"/>
		<label style="display: inline-block; float: right; margin: 25px 20px 0 0;">Modify Tab</label>
		
		<hr>
		<p class="fnt_12" style="display: none;"><input type="checkbox" id="view_OpenApi" name="view_OpenApi" onclick="viewCheck(this);" /> Open API </p>
		<p class="fnt_12"><input type="checkbox" id="view_latestUpload" name="view_latestUpload" onclick="viewCheck(this);" /> Latest Uploads </p>
		
	</div>
	<!-- edit btn -->
	
	<div id="srch_page" style="display: none;">
		<jsp:include page="search_page.jsp"/>
	</div>
	<div id="make_contents" style="position:absolute; left:250px; top:430px; z-index:1;">
		<jsp:include page="sub/contents/make_contents.jsp"/>
	</div>
	<div id="edit_start_page" style="display: none;">
		<jsp:include page="sub/edit/edit_start_page.jsp"/>
	</div>
	<div id="footer" style="position:absolute; width:100%; height:50px; top:900px; z-index:2; /* background-color:#EAEAEA; */ ">
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
	
	<!-- add tab dialog -->
	<div id="tabAddDig">
		<table style="font-size: 15px;">
			<tr>
				<td style="width:90px;">Tab Name</td>
				<td><input type="text" id="addTabName"/></td>
			</tr>
			<tr id="addTabTr">
				<td>Tab Type</td>
				<td>
					<input type="radio" name="addTabRaido" value="list" checked="checked"/> List
					<input type="radio" name="addTabRaido" value="gellery"/> Gellery
				</td>
			</tr>
			<tr>
				<td colspan="2" style="text-align:center;">
					<input type="button" style="margin-top:10px;margin-left:110px;" id="saveBtn" value="Save" onclick="addTabData('save');"/>
					<input type="button" style="margin-top:10px;margin-left:110px;display:none;" id="modifyBtn" value="Modify" onclick="addTabData('modify');"/>
				</td>
			</tr>
		</table>
	</div>
	
</body>

</html>