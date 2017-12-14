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

String projectBoard = request.getParameter("projectBoard");				//GeoCMS conn ckeck
String projectVideo = request.getParameter("projectVideo");				//GeoVideo conn check
String b_contentTabArr = request.getParameter("b_contentTabArr");		//contentTab array
String projectNameArr = request.getParameter("projectNameArr");			//project name array
String projectIdxArr = request.getParameter("projectIdxArr");			//project idx array
%>

<style type="text/css">
select {
	height: 24px;
}
</style>
<script type="text/javascript">
var loginId = '<%= loginId %>';					//로그인 아이디
var loginToken = '<%= loginToken %>';			//로그인 token

var projectBoard = "<%=projectBoard%>";			//GeoCMS 연동여부				0:연동안됨, 1:연동됨
var projectVideo = "<%=projectVideo%>";			//GeoCMS_video 연동여부		0:연동안됨, 1:연동됨
var b_contentTabArr = "<%=b_contentTabArr%>";	//content tab array
b_contentTabArr = b_contentTabArr.split(",");
var projectNameArr = '<%=projectNameArr%>';		//project name array
projectNameArr = JSON.parse(projectNameArr);
var projectIdxArr = "<%=projectIdxArr%>";		//project idx array
projectIdxArr = projectIdxArr.split(",");

var uploadFileLen = 0;
var imageUploadCnt = 0;

$(function() {
// 	$('.create_button').button();
	$('.create_button').width(80);
	$('.create_button').height(22);
	$('.create_button').css('fontSize', 11);
	$('.create_button').css('margin-left', 5);
	$('.create_button').css('margin-right', 5);
	
// 	$('.cancle_button').button();
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
	$('#showImage').attr("checked", true);
	
	//project name setting
	innerHTML = '';
	for(var i=0;i<projectNameArr.length;i++){
		innerHTML += '<option value="'+ projectIdxArr[i] +'">'+ projectNameArr[i] +'</option>';
	}
	$('#projectKind').append(innerHTML);
	
	//upload
	$('#file_upload').uploadify({
		'uploader' : '<c:url value="/lib/uploadify/uploadify.swf"/>',
		'onComplete' : function(event, ID, fileObj, response, data) {
			imageUploadCnt++;
			
			if(response != null && response != ''){
				var tmpArr = response.split(",");
				var fileName, filePath, lati, longi;

				$.each(tmpArr, function(idx, val){
					if(val != null && val != ''){
						if(val.indexOf('files') > -1){
							var tempFile = val.replace("files:","");
							var tmpFileIdx = tempFile.lastIndexOf("\\");
							fileName = tempFile.substring(tmpFileIdx+1, tempFile.length);
							filePath = tempFile.split('GeoPhoto\\')[0];
						}else if(val.indexOf('lati') > -1){
							lati = val.split(':')[1];
						}else if(val.indexOf('longi') > -1){
							longi = val.split(':')[1];
						}
					}
				});
				saveImageFn(fileName, filePath, lati, longi);
			}
		},
		'cancelImg' : '<c:url value="/lib/uploadify/cancel.png"/>',
		'folder' : '/upload/GeoPhoto',	
		'fileExt' : '*.jpg;*.gif;*.png;*.bmp;',
		'fileDesc' : 'Image Files',
		'auto' : false,
		'multi' : true,
		'hideButton' : false
	});
	
	$('#file_uploadUploader').css('margin-left','9px');
});

//upload kind 선택 시 
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(null, type, '', '');
}

//게시물 생성
function createContent() {
// 	var id = $.cookie('id');

	if(loginId!='' || loginId!=null) {
		uploadFileLen = $('#file_uploadQueue').children().length;
		if(uploadFileLen <= 0){
// 			 jAlert('컨텐츠를 선택해 주세요.', '정보');
			 jAlert('Please select content.', 'Info');
			 return;
		}
		
		//게시물 정보 전송 설정
		var title = encodeURIComponent($('#title_area').val());
		var content = encodeURIComponent(document.getElementById('content_area').value);
		
		if(title == null || title == "" || title == 'null'){
// 			 jAlert('제목을 입력해 주세요.', '정보');
			 jAlert('Please enter the title.', 'Info');
			 $('#title_area').focus();
			 return;
		 }
		 
		 if(content == null || content == "" || content == 'null'){
// 			 jAlert('내용을 입력해 주세요.', '정보');
			jAlert('Please enter your content.', 'Info');
			$('#content_area').focus();
			return;
		 }
		 
		$('#file_upload').uploadifySettings('script', '<c:url value="/geoUpload.do"/>?uploadType=GeoPhoto');
		//파일 업로드
		$('#file_upload').uploadifyUpload();
	}
	else {
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', '정보');
		jAlert('I lost my login information.', 'Info');
	}
}

function saveImageFn(fileName, filePath, lati, longi){
	if(loginId != null && loginId != '' && loginId != 'null') {
		//게시물 정보 전송 설정
		var title = $('#title_area').val();
		var content = document.getElementById('content_area').value;
		var tabName = $('#showKind').val();
		var projectIdxNum = $('#projectKind').val();
		
		title = title.replace(/\//g,'&sbsp');
		content = content.replace(/\//g,'&sbsp');
		filePath = filePath.replace(/\\/g,'&sbsp');

		if(lati == null || lati == '' || lati == 'null'){
			lati = '&nbsp';
		}
		
		if(longi == null || longi == '' || longi == 'null'){
			longi = '&nbsp';
		}
		title = encodeURIComponent(title);
		innerStr = encodeURIComponent(innerStr);
		
		var Url			= baseRoot() + "cms/saveImage/";
		var param		= loginToken + "/" + loginId + "/" + title + "/" + content + "/" + fileName + "/" + filePath + "/" + lati + "/" + longi + "/" + tabName + "/" + projectIdxNum;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data.Code == 100){
					if(uploadFileLen == imageUploadCnt){
						window.parent.closeUpload();
						window.parent.viewMyProjects(projectIdxNum);
						jAlert(data.Message, 'Info');
					}
				}else{
					jAlert(data.Message, 'Info');
				}
			}
		});
	}
}

//게시물 생성 취소
function cancelContent() {
// 	jConfirm('게시물 생성을 취소하시겠습니까?', '정보', function(type){
	jConfirm('Are you sure you want to cancel creating posts?', 'Info', function(type){
		if(type) window.parent.closeUpload();
	});
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
		url:'<c:url value="/geoCMS/share.do" />?shareKind=GeoPhoto',
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

<body bgcolor="#e5e5e5">

<table id="upload_table" border=1>
	<tr class="showDivTR">
		<td width="" height="25" colspan="2" style="font-size: 12px;">
			<div style="width:250px; float:left; padding:3px;">
				<div style="float:left;"><input type="radio" id="showBoard" name="showRadio" onclick="changeShow('Board')">Board</div>
				<div style="float:left;"><input type="radio" id="showImage" name="showRadio">Image</div>
				<div style="float:left;"><input type="radio" id="showVideo" name="showRadio" onclick="changeShow('Video')">Video</div>
			</div>
			<div>
				<select style="float:right;margin-right:2px;" id="showKind"></select>
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
		<td width="" height="25" align="center">TITLE</td>
		<td width="" height="25" align="center">
			<input id="title_area" type="text" style="width:316px;">
		</td>
	</tr>
	<tr>
		<td width="" height="25" align="center" colspan="2">CONTENT</td>
	</tr>
	<tr>
		<td width="" height="300" align="center" colspan="2">
			<textarea id="content_area" style="width:400px; height:370px;"></textarea>
		</td>
	</tr>
	<tr>
		<td id="file_upload_td" width="" height="25" colspan="2">
			<input id="file_upload" name="file_upload" type="file"/>
		</td>
	</tr>
	<tr>
		<td width="" height="25" align="center" colspan="2">
			<button class="create_button" onclick="createContent();">SAVE</button>
			<button class="cancle_button" onclick="cancelContent();">CANCLE</button>
		</td>
	</tr>
</table>
</body>
