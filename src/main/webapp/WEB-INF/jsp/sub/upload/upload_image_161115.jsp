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

String projectBoard = request.getParameter("projectBoard");			//GeoCMS conn ckeck
String projectVideo = request.getParameter("projectVideo");			//GeoVideo conn check
String b_contentTabArr = request.getParameter("b_contentTabArr");	//contentTab array
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

var uploadFileLen = 0;
var imageUploadCnt = 0;

$(function() {
	$('.create_button').button();
	$('.create_button').width(80);
	$('.create_button').height(22);
	$('.create_button').css('fontSize', 11);
	$('.create_button').css('margin-left', 5);
	$('.create_button').css('margin-right', 5);
	
	$('.cancle_button').button();
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
	
	$('#file_upload').uploadify({
		'uploader' : '<c:url value="/lib/uploadify/uploadify.swf"/>',
// 		'script' : '<c:url value="/geoUpload.do"/>?uploadType=GeoPhoto',
// 		'script' : 'UploadServlet',
		'onComplete' : function(event, ID, fileObj, response, data) {
// 			alert(JSON.stringify(response));
// 			alert(response);
// 			var fileName = "";
			imageUploadCnt++;
			
			if(response != null && response != ''){
// 				response = response.replace('}','');
// 				var resObject = JSON.parse(response);
				var tmpArr = response.split(",");
				var fileName, filePath, lati, longi;

				$.each(tmpArr, function(idx, val){
					if(val != null && val != ''){
						if(val.indexOf('files') > -1){
							var tempFile = val.replace("files:","");
							var tmpFileIdx = tempFile.lastIndexOf("\\");
							fileName = tempFile.substring(tmpFileIdx+1, tempFile.length);
							filePath = tempFile.split('GeoPhoto\\')[0];
// 							filePath = tempFile.substring(0, tmpFileIdx);
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
		//'buttonImg' : '',
		'hideButton' : false
	});
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
			 jAlert('컨텐츠를 선택해 주세요.', '정보');
			 return;
		}
		
		//게시물 정보 전송 설정
		var title = encodeURIComponent($('#title_area').val());
		var content = encodeURIComponent(document.getElementById('content_area').value);
		var shareType = $('input[name=shareRadio]:checked').val();
		var addShareUser = $('#shareAdd').val();
		
		if(title == null || title == "" || title == 'null'){
			 jAlert('제목을 입력해 주세요.', '정보');
			 $('#title_area').focus();
			 return;
		 }
		 
		 if(content == null || content == "" || content == 'null'){
			 jAlert('내용을 입력해 주세요.', '정보');
			 $('#content_area').focus();
			 return;
		 }
		 
		 if(shareType != null && shareType == 2 && (addShareUser == null || addShareUser == '')){
			 jAlert('공유 유저가 지정되지 않았습니다.', '정보');
			 return;
		 }
		 
// 		$('#file_upload').uploadifySettings('script', 'UploadServlet?id='+id+'&title='+title+'&content='+content+'&type=I&tabKind='+$('#showKind').val());
// 		$('#file_upload').uploadifySettings('script', 'UploadServlet');
		$('#file_upload').uploadifySettings('script', '<c:url value="/geoUpload.do"/>?uploadType=GeoPhoto');

		//파일 업로드
		$('#file_upload').uploadifyUpload();
	}
	else {
		window.parent.closeUpload();
		jAlert('로그인 정보를 잃었습니다.', '정보');
	}
}

function saveImageFn(fileName, filePath, lati, longi){
	if(loginId != null && loginId != '' && loginId != 'null') {
		//게시물 정보 전송 설정
		var title = $('#title_area').val();
		var content = document.getElementById('content_area').value;
		var tabName = $('#showKind').val();
		var shareType = $('input[name=shareRadio]:checked').val();
		var addShareUser = $('#shareAdd').val();
		
		title = title.replace(/\//g,'&sbsp');
		content = content.replace(/\//g,'&sbsp');
		filePath = filePath.replace(/\\/g,'&sbsp');
// 		alert('filePath : ' +filePath);

		if(lati == null || lati == '' || lati == 'null'){
			lati = '&nbsp';
		}
		
		if(longi == null || longi == '' || longi == 'null'){
			longi = '&nbsp';
		}
		
		if(addShareUser == null || addShareUser.length <= 0){
			addShareUser = '&nbsp';
		}
		
		var Url			= baseRoot() + "cms/saveImage/";
		var param		= loginToken + "/" + loginId + "/" + title + "/" + content + "/" + fileName + "/" + filePath + "/" + lati + "/" + longi + "/" + tabName + "/" + shareType + "/" + addShareUser;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "POST"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
// 				alert('uploadFileLen : '+ uploadFileLen+ " imageUploadCnt : " +imageUploadCnt);
				if(data.Code == 100){
					if(uploadFileLen == imageUploadCnt){
						jAlert(data.Message, '정보');
						window.parent.closeUpload();
						window.parent.viewMyContents();
					}
// 	 				window.parent.closeDAndOpenV(fileName, loginToken);
				}else{
					jAlert(data.Message, '정보');
				}
			}
		});
	}
}

//게시물 생성 취소
function cancelContent() {
	jConfirm('게시물 생성을 취소하시겠습니까?', '정보', function(type){
		if(type) window.parent.closeUpload();
	});
}

//특정인 공개 시 선택 창
// function openSharePop() {
// // 	var $dialog = jQuery.FrameDialog.create({ //객체정보를 로드
// // 		url: 'sub/viewer/image_viewer.jsp?base_url='+base_url+'&file_url='+conv_file_url,
// // 		title: 'Image Viewer',
// // 		width:1127,  
// // 		height:650, 
// // 		buttons: {},
// // 		autoOpen:false
// // 	});
// // 	$dialog.dialog('open');
// 	getUser();
// // 	$('#shareUserDiv').dialog({
// // 		autoOpen: true,
// // 		height: 400,
// // 	    width: 350,
// // 	    modal: true,
// // 	});
// }

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
		width: 350,
		height: 535,
		buttons: {},
		autoOpen:false
// 		position:[820,300],
// 		modal:false
	});
	
// 	$('.ui-dialog-titlebar').attr('class', 'ui-dialog-titlebar');
// 	$('.ui-dialog-title').remove();
// 	$('.ui-icon-closethick').remove();
// 	$('.ui-dialog').attr('id', 'share_dig');
	contentViewDialog.dialog('widget').find('.ui-dialog-titlebar').remove();
	contentViewDialog.dialog('open');
}

// function getUser(){
// 	parent.callRequest('UserInfoServlet', '/GeoCMS/UserInfoServlet', 'type=search&searchType=user', null);
	
// // 	$.ajax({
// // 		type: 'POST',
// // 		url: '../../UserInfoServlet',
// // 		data: 'type=search',
// // 		success: function(data) {
// // 			$('.shareTR').remove();	//기존 검색 데이터 삭제
// // 			$('.shareChk').attr('checked', false); //체크박스 초기
// // 			var response = data.trim();
// // 			if(response != null && response != ''){
// // 				var innerHTMLStr = '';
// // 				var data_line_arr = new Array();
// // 				data_line_arr = response.split("\<line\>");
				
// // 				if(data_line_arr != null && data_line_arr != ""){
// // 					for(var i=0; i<data_line_arr.length; i++) {
// // 						var data_arr = new Array();
// // 						data_arr = data_line_arr[i].split("\<separator\>");
// // 						innerHTMLStr += '<tr class="shareTR">';
// // 						innerHTMLStr += '<td id="userId_'+ i +'" class="userIdClass">'+ data_arr[0] +'</td>';	//id
// // 						innerHTMLStr += '<td align="center"><input type="checkbox" id="chk_'+ i +'" class="shareChk"></td>';	//check
// // 						innerHTMLStr += '</tr>';	//type
// // 					}
// // 					$('#shareTable tr:last').before(innerHTMLStr);
// // 				}
// // 			}
// // 		}
// // 	});
// }

</script>

</head>

<body bgcolor="#e5e5e5">

<table id="upload_table" border=1>
	<tr class="showDivTR">
		<td width="400" height="25" colspan="2" style="font-size: 12px;">
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
		<td width="40" height="25" align="center">TITLE</td>
		<td width="360" height="25" align="center">
			<input id="title_area" type="text" style="width:360px;">
		</td>
	</tr>
	<tr>
		<td width="400" height="25" align="center" colspan="2">CONTENT</td>
	</tr>
	<tr>
		<td width="400" height="300" align="center" colspan="2">
			<textarea id="content_area" style="width:400px; height:370px;"></textarea>
		</td>
	</tr>
	<tr class="showDivTR">
		<td colspan="2">
			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">비공개</div>
			<div style="float:left;"><input type="radio" value="1" name="shareRadio">전체공개</div>
			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div>
		</td>
	</tr>
	<tr>
		<td id="file_upload_td" width="400" height="25" colspan="2">
			<input id="file_upload" name="file_upload" type="file"/>
		</td>
	</tr>
	<tr>
		<td width="400" height="25" align="center" colspan="2">
			<button class="create_button" onclick="createContent();">SAVE</button>
			<button class="cancle_button" onclick="cancelContent();">CANCLE</button>
		</td>
	</tr>
</table>

<input type="hidden" id="shareAdd"/>
<input type="hidden" id="shareRemove"/>
<div id="clonSharUser" style="display:none;"></div>
</body>
