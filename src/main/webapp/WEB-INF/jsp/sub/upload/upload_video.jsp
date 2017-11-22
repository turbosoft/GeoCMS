<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");				//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");			//로그인 token

String projectBoard = request.getParameter("projectBoard");
String projectImage = request.getParameter("projectImage");
String b_contentTabArr = request.getParameter("b_contentTabArr");
String projectNameArr = request.getParameter("projectNameArr");			//project name array
String projectIdxArr = request.getParameter("projectIdxArr");			//project idx array
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';					//로그인 아이디
var loginToken = '<%= loginToken %>';			//로그인 token

var projectBoard = "<%=projectBoard%>";		//GeoCMS 연동여부				0:연동안됨, 1:연동됨
var projectImage = "<%=projectImage%>";		//GeoCMS_Image 연동여부		0:연동안됨, 1:연동됨
var b_contentTabArr = "<%=b_contentTabArr%>";	//content tab array
b_contentTabArr = b_contentTabArr.split(",");
var projectNameArr = '<%=projectNameArr%>';		//project name array
projectNameArr = JSON.parse(projectNameArr);
var projectIdxArr = "<%=projectIdxArr%>";		//project idx array
projectIdxArr = projectIdxArr.split(",");

var videoUploadCnt = 0;
var uploadFileName = '';

$(document).ready(
	function(){
// 		$('.create_button').button();
		$('.create_button').width(80);
		$('.create_button').height(22);
		$('.create_button').css('fontSize', 11);
		$('.create_button').css('margin-left', 5);
		$('.create_button').css('margin-right', 5);
		
// 		$('.cancle_button').button();
		$('.cancle_button').width(80);
		$('.cancle_button').height(22);
		$('.cancle_button').css('fontSize', 11);
		$('.cancle_button').css('margin-left', 5);
		$('.cancle_button').css('margin-right', 5);
		
		$('#upload_table tr td').css('fontSize', 12);
		
		//tab select
		var innerHTML = '';
		for(var i=0;i<b_contentTabArr.length;i++){
			innerHTML += '<option>'+ b_contentTabArr[i] +'</option>';
		}
		$('#showKind').append(innerHTML);
		$('#showVideo').attr("checked", true);
		
		//project name setting
		innerHTML = '';
		for(var i=0;i<projectNameArr.length;i++){
			innerHTML += '<option value="'+ projectIdxArr[i] +'">'+ projectNameArr[i] +'</option>';
		}
		$('#projectKind').append(innerHTML);
		
		$('#file_upload').uploadify({
			'uploader' : '<c:url value="/lib/uploadify/uploadify.swf"/>',
			'onComplete' : function(event,queueID, fileObj, response, data) {
				videoUploadCnt++;
				
				if(response != null && response != ''){
					var saveFileName = response.split('GeoVideo\\')[1].split('.')[0];
					var enCodingFile = response.split(',files:')[1];
					uploadFileName = enCodingFile;

					//response 로 전달받은 저장 파일명으로 ajax 인코딩 수행 (인코딩이 동작되어도 웹페이지는 동작..)
					$.ajax({
						type: 'POST',
						url: '<c:url value="/geoEncoding.do"/>',
						data: 'filename='+enCodingFile,
						success: function(data) {
						}
					});
					
					$('#file_upload_gpx').uploadifySettings('script', '<c:url value="/geoUpload.do"/>?uploadType=GeoVideo&saveFileName='+saveFileName);
					$('#file_upload_gpx').uploadifyUpload();
				}
			},
			'cancelImg' : '<c:url value="/lib/uploadify/cancel.png"/>',
			'folder' : '/upload/GeoVideo',
			'fileExt' : '*.avi;*.mpg;*.mp4;*.mov;*.ogg;*.flv;*.webm;*.m4v;',
			'fileDesc' : 'Video Files',
			'auto' : false,
// 			'queueSizeLimit': 2,
			'hideButton' : false,
			'buttonText' : 'video File',
		});
		
		$('#file_upload_gpx').uploadify({
			'buttonText' : 'gpx File',
			'uploader' : '<c:url value="/lib/uploadify/uploadify.swf"/>',
			'onComplete' : function(event,queueID, fileObj, response, data) {
				if(response != null && response != ''){
					saveVideoFn(response);
				}
			},
			'cancelImg' : '<c:url value="/lib/uploadify/cancel.png"/>',
			'folder' : '/upload/GeoVideo',
			'fileExt' : '*.gpx;',
			'fileDesc' : 'Video Files',
			'auto' : false,
			'hideButton' : false
		});
	}
);
//cms/saveVideo/{token}/{loginId}/{title}/{content}/{filesStr}/{filePath}/{latitude}/{longitude}/{tabName}/{shareType}/{shareUser}
function saveVideoFn(data){
	var tmpArr = data.split(",");
	var lat = 0;
	var lon = 0;
	var filePath = "";
	var fileName = "";

	$.each(tmpArr, function(idx, val){
		if(val.indexOf("lat") > -1){
			lat = val.split(":")[1];
		}else if(val.indexOf("lon") > -1){
			lon = val.split(":")[1];
		}
// 		else if(val.indexOf("files") > -1){
// 			filePath = val.split("files:")[1].split('GeoVideo\\')[0];
// 			fileName = val.split("files:")[1].split('GeoVideo\\')[1];
// 		}
	});
	
	if(uploadFileName != null && uploadFileName != ''){
		filePath = uploadFileName.split('GeoVideo\\')[0];
		fileName = uploadFileName.split('GeoVideo\\')[1];
	}
	
	var title = $('#title_area').val();
	var content = document.getElementById('content_area').value;
	var tabName = $('#showKind').val();
	var projectIdxNum = $('#projectKind').val();
// 	var shareType = $('input[name=shareRadio]:checked').val();
// 	var addShareUser = $('#shareAdd').val();

	title = title.replace(/\//g,'&sbsp');
	content = content.replace(/\//g,'&sbsp');
	filePath = filePath.replace(/\\/g,'&sbsp');
	
	if(lat == null || lat == ''){
		lat = '0.0';
	}
	
	if(lon == null || lon == ''){
		lon = '0.0';
	}
// 	if(addShareUser == null || addShareUser.length <= 0){
// 		addShareUser = '&nbsp';
// 	}
	
	var Url			= baseRoot() + "cms/saveVideo/";
	var param		= loginToken + "/" + loginId + "/" + title + "/" + content + "/" + fileName + "/" + filePath + "/" + lat + "/" + lon + "/" + tabName + "/" + projectIdxNum;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				//계속 업로드 할 것인지 물음 기능 추가
				jConfirm('게시물을 계속 업로드 하시겠습니까?', '정보', function(type){
					if(!type){
						window.parent.closeUpload();
						window.parent.viewMyProjects(projectIdxNum);
						jAlert(data.Message, '정보');
					}
				});
			}else{
				jAlert(data.Message, '정보');
			}
		}
	});
}

//게시물 생성
function createContent() {
	if($.trim($('#title_area').val())=='') {
		jAlert('제목을 입력해 주세요.', '정보');
		$('#title_area').focus();
		return;
	}
	
	var gpxUpChk = $('#file_upload_gpxQueue').children().length == 0?false:true;
	if(!gpxUpChk){
		jAlert('gpx 파일을 업로드 해 주세요.', '정보');
		return;
	}
	
	contentSave();
}

function contentSave() {
	//게시물 정보 전송 설정
// 	var title = encodeURIComponent($('#title_area').val());
// 	var content = encodeURIComponent(document.getElementById('content_area').value);
//		$('#file_upload').uploadifySettings('script', 'UploadServlet?id='+id+'&title='+title+'&content='+content+'&tabKind='+$('#showKind').val());
	$('#file_upload').uploadifySettings('script', '<c:url value="/geoUpload.do"/>?uploadType=GeoVideo');
	//파일 업로드
	$('#file_upload').uploadifyUpload();
}

//게시물 생성 취소
function cancelContent() {
	jConfirm('게시물 생성을 취소하시겠습니까?', '정보', function(type){
		window.parent.closeUpload();
	});
}

//upload kind 선택 시 
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(null, type, '', '');
}

//all checked
function allCheck(obj){
	if(obj.checked){
		$('.shareChk').attr('checked',true);
	}else{
		$('.shareChk').attr('checked',false);
	}
}

//open shareUser list
function getShareUser(){
	contentViewDialog = jQuery.FrameDialog.create({
		url:'<c:url value="/geoCMS/share.do" />?shareKind=GeoVideo',
		width: 370,
		height: 535,
		buttons: {},
		autoOpen:false
	});
	contentViewDialog.dialog('widget').find('.ui-dialog-titlebar').remove();
	contentViewDialog.dialog('open');
}

</script>

</head>

<body bgcolor='#e5e5e5'>

<table id='upload_table' border=1>
	<tr id="showDivTR">
		<td height="25" colspan="2" style="font-size: 12px;">
			<div style="width:250px;float:left;">
				<div style="float:left;"><input type="radio" id="showBoard" name="showRadio" onclick="changeShow('Board')">Board</div>
				<div style="float:left;"><input type="radio" id="showImage" name="showRadio" onclick="changeShow('Image')">Image</div>
				<div style="float:left;"><input type="radio" id="showVideo" name="showRadio">Video</div>
			</div>
			<div>
				<select style="float:right;margin-right:10px;" id="showKind"></select>
			</div>
		</td>
	</tr>
	<tr>
		<td width="80" height="25" align="center">Project Name</td>
		<td width="" height="25" align="center">
			<select style="width:318px;" id="projectKind"></select>
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' style="width:80px;">TITLE</td>
		<td width='' height='25' align='center'>
			<input id='title_area' type='text' style='width:316px;'>
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' colspan='2'>CONTENT</td>
	</tr>
	<tr>
		<td width='' height='300' align='center' colspan='2'>
			<textarea id='content_area' style='width:400px; height:370px;'></textarea>
		</td>
	</tr>
<!-- 	<tr class="showDivTR"> -->
<!-- 		<td colspan="2"> -->
<!-- 			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">비공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="1" name="shareRadio">전체공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div> -->
<!-- 		</td> -->
<!-- 	</tr> -->
	<tr>
		<td id='file_upload_td' width='' height='25' colspan='2'>
			<input id='file_upload' name='file_upload' type='file'/>
			<input id='file_upload_gpx' name='file_upload_gpx' type='file'/>
<!-- 			<div style="background-image:images/upload/selectGpx.png;"> -->
<!-- 				<input id='file_upload_gpx' name='file_upload_gpx' type='file'/> -->
<!-- 			</div> -->
<!-- 			<img src="images/upload/selectGpx.png" id='file_upload_gpxx' name='file_upload_gpx'> -->
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' colspan='2'>
			<button class='create_button' onclick='createContent();'>SAVE</button>
			<button class='cancle_button' onclick='cancelContent();'>CANCLE</button>
		</td>
	</tr>
</table>

<!-- <input type="hidden" id="shareAdd"/> -->
<!-- <input type="hidden" id="shareRemove"/> -->
<!-- <div id="clonSharUser" style="display:none;"></div> -->
</body>
