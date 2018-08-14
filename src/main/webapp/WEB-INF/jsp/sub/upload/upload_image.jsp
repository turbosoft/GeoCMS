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

String boardHiding = request.getParameter("boardHiding");				//border content hiding
%>

<style type="text/css">
select {
	height: 24px;
}
</style>
<script type="text/javascript">
var loginId = '<%= loginId %>';					//로그인 아이디
var loginToken = '<%= loginToken %>';			//로그인 token
var boardHiding = '<%= boardHiding %>';			//border content hiding
var projectNameArr = new Array();		//project name array
var projectIdxArr = new Array();		//project idx array

var uploadFileLen = 0;
var imageUploadCnt = 0;
var fileObjCnt = 1;

$(function() {
	if(boardHiding){
		$('#showBoard').parent().remove();
	}
	getImgUpProjectList();
	
	$('.create_button').width(80);
	$('.create_button').height(22);
	$('.create_button').css('fontSize', 11);
	$('.create_button').css('margin-left', 5);
	$('.create_button').css('margin-right', 5);
	
	$('.cancle_button').width(80);
	$('.cancle_button').height(22);
	$('.cancle_button').css('fontSize', 11);
	$('.cancle_button').css('margin-left', 5);
	$('.cancle_button').css('margin-right', 5);
	
	$('#upload_table tr td').css('fontSize', 12);
	
	$('#showImage').attr("checked", true);
	
	//project name setting
	innerHTML = '';
	for(var i=0;i<projectNameArr.length;i++){
		innerHTML += '<option value="'+ projectIdxArr[i] +'">'+ projectNameArr[i] +'</option>';
	}
	$('#projectKind').append(innerHTML);
	
});

//get proejct List
function getImgUpProjectList(){
	var orderIdx  = '&nbsp';
	var tmeShareEdit = 'Y';
	var Url			= baseRoot() + "cms/getProjectList/";
	var param		= loginToken + "/" + loginId + "/" + orderIdx + "/" + tmeShareEdit;
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
					projectNameArr = new Array();
					projectIdxArr = new Array();
					if(response != null && response.length > 0){
						$.each(response, function(idx, val){
							projectNameArr.push(val.projectname);
							projectIdxArr.push(val.idx);
						});
					}
			}else{
// 				jAlert('프로젝트 생성 후 컨텐츠를 업로드 할수 있습니다.', '정보');
				jAlert('You can upload content after creating a project.', 'Info');
				jQuery.FrameDialog.closeDialog();
			}
		}
	});
}

//upload kind 선택 시 
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(type, '', '','');
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

function iconSelect(obj, type){
	if($(obj).hasClass(type + '_OFF')){
		
		$.each($('.'+type+'_ON'), function(idx, val){
			$(this).removeClass(type+'_ON');
			$(this).addClass(type+'_OFF');
			var tmpSrc1 = $(this).attr('src').replace('_on','_off');
			$(this).attr('src', tmpSrc1);
		});
		$(obj).removeClass(type+'_OFF');
		$(obj).addClass(type+'_ON');
		var tmpSrc2 = $(obj).attr('src').replace('_off','_on');
		$(obj).attr('src', tmpSrc2);
	}
}

var viewTimeArr = new Array();
function fileChangeInfo(obj){
	$('#floorMap_pop_file_1').empty();
	
	viewTimeArr = new Array();
	var viewFileArr = [];
	var viewIdx = 0;
	var tmpViewArr = new Array();
	var chkTime = false;
	
	var i = document.getElementById('file_1');
	for(var i=0; i<obj.files.length;i++){
		
		var date = new Date(obj.files[i].lastModifiedDate);
		viewTimeArr.push(obj.files[i].lastModifiedDate);	//마지막 수정 날짜
		
		viewIdx = 0;
		chkTime = false;
		for(var j=0; j<obj.files.length;j++){
			var date2 = new Date(obj.files[j].lastModifiedDate);
			if(date.getTime() > date2.getTime()){
				viewIdx++;
			}else if(date.getTime() == date2.getTime() && i != j && !chkTime){
				for(var m=0;m<tmpViewArr.length;m++){
					if(tmpViewArr[m].date == date.getTime()){
						chkTime = true;
						var tmpObjTime = tmpViewArr[m];
						viewIdx += tmpObjTime.cnt;
						tmpViewArr[m].cnt = tmpObjTime.cnt += 1;
					}
				}
				
				if(!chkTime){
					var tmpObjTime = new Object();
					tmpObjTime.date = date.getTime();
					tmpObjTime.cnt = 1;
					tmpViewArr.push(tmpObjTime);
					chkTime = true;
				}
			}
		}
		obj.files[i].seq = viewIdx;
		viewFileArr[viewIdx] = obj.files[i];
		
	}
	var tmpHtml = '';
	for(var i=0; i<viewFileArr.length;i++){
		tmpHtml += "<div style='margin:5px 0 5px 10px; text-decoration:underline; color:gray;'>"+ viewFileArr[i].name +"</div>";
	}
		
	$('#floorMap_pop_file_1').append(tmpHtml);
	
}

function reString(numStr){
	if(numStr < 10){
		numStr = '0'+numStr;
	}else{
		numStr = ''+numStr;
	}
	return numStr;
}


//게시물 생성
function createContent() {
	if(loginId != '' && loginId != null) {
		$('#fileinfo').append($('#file_1'));	//선택 파일 버튼 폼객체에 추가
		
		var uploadFileLen = $('#fileinfo').children().length;
		if(uploadFileLen <= 0){
// 			 jAlert('컨텐츠를 선택해 주세요.', '정보');
			 jAlert('Please select content.', 'Info');
			 return;
		}
		
		//게시물 정보 전송 설정
		var title = $('#title_area').val();
		var content = document.getElementById('content_area').value;
		var projectIdxNum = $('#projectKind').val();
		var droneType = '&nbsp';
		if( $(':checkbox[id="droneDataChk"]').is(":checked")){
			droneType = 'Y';
		}
		
		if(title == null || title == "" || title == 'null'){
// 			 jAlert('제목을 입력해 주세요.', '정보');
			 jAlert('Please enter the title.', 'Info');
			 $('#title_area').focus();
			 return;
		 }
		 
		 if(content == null || content == "" || content == 'null'){
// 			 jAlert('내용을 입력해 주세요.', '정보');
			 jAlert('Please enter your details.', 'Info');
			 $('#content_area').focus();
			 return;
		 }
		 
		 if(title != null && title.indexOf('\'') > -1){
// 			 jAlert('제목에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			 jAlert('Can not use special character \' in title.', 'Info');
			 return;
		 }
		 
		 if(content != null && content.indexOf('\'') > -1){
// 			 jAlert('내용에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			 jAlert('Can not use special character \' in content.', 'Info');
			 return;
		 }
		 
		 title = dataReplaceFun(title);
		 content = dataReplaceFun(content);
		 
		 $('input[name=uploadDateArr]').val(JSON.stringify(viewTimeArr));
		 
		 $('body').append('<div class="lodingOn"></div>');
		 var iframe = $('<iframe name="postiframe" id="postiframe" style="display: none"></iframe>');
         $("body").append(iframe);

         var form = $('#fileinfo');
         
         var resAddress = baseRoot() + "cms/saveImageAll/";
		 resAddress += loginToken + "/" + loginId + "/" + title + "/" + content + "/" + projectIdxNum + "/"+ droneType;
         resAddress += "?callback=?";
         
         form.attr("action", resAddress);
         form.attr("method", "POST");

         form.attr("encoding", "multipart/form-data");
         form.attr("enctype", "multipart/form-data");

         form.attr("target", "postiframe");
         form.submit();
         
         $("#postiframe").load(function (e) {
         	var doc = this.contentWindow ? this.contentWindow.document : (this.contentDocument ? this.contentDocument : this.document);
         	var root = doc.documentElement ? doc.documentElement : doc.body;
         	var data = root.textContent; ////////// ? root.textContent : root.innerText;
            data = data.replace("?","").replace("(","");
            data = data.substring(0, data.length -1);
         	var resData = JSON.parse(data);
         	if(resData != null && resData != ''){
         		if(resData.Code == 100){
         			window.parent.viewMyProjects(projectIdxNum);
					jAlert(resData.Message, 'Info', function(res){
						window.parent.closeUpload();
					});
					$('.lodingOn').remove();
				}else{
					jAlert(resData.Message, 'Info', function(res){
						$('.lodingOn').remove();
					});
				}
			}else{
				$('.lodingOn').remove();
			}
         });
	}
	else {
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', '정보');
		jAlert('I lost my login information.', 'Info');
	}
}

</script>

</head>

<body bgcolor="#e5e5e5">

	<table id="upload_table" border=1>
		<tr class="showDivTR">
			<td width="" height="25" colspan="2" style="font-size: 12px;">
				<div style="width:260px; float:left; padding:3px;">
					<div style="float:left;"><input type="radio" id="showBoard" name="showRadio" onclick="changeShow('Board')">Board</div>
					<div style="float:left;"><input type="radio" id="showImage" name="showRadio">Image</div>
					<div style="float:left;"><input type="radio" id="showVideo" name="showRadio" onclick="changeShow('Video')">Video</div>
				</div>
				<div style="float:left; padding:3px;">
					<label>Drone Data </label><input type="checkbox" id="droneDataChk">
				</div>
			</td>
		</tr>
		<tr>
			<td width="80" height="25" align="center">Layer Name</td>
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
			<td width="" height="25" align="center">CONTENT</td>
			<td width="" height="75" align="center">
				<textarea id="content_area" style="width:320px; height:345px;"></textarea>
			</td>
		</tr>
		<tr>
			<td width="" height="25" align="center">IMAGE</td>
			<td id="file_upload_td">
				<div class="file_input_div" style="float: left;">
					<div class="file_input_img_btn"> LOAD </div>
		    		<input type="file" multiple name="file_a[]" id="file_1" class="file_input_hidden" onchange="fileChangeInfo(this);" accept='.jpg,.gif,.png,.bmp'  />
				</div>
<!-- 				webkitdirectory -->
				<div id="floorMap_pop_file_1" class="text_box_dig" style="width:240px; height: 72px; overflow-y:auto; margin:8px 0 8px 10px; border:1px solid gray; float: left;"></div>
			</td>
		</tr>
		<tr>
			<td width="" height="25" align="center" colspan="2">
				<button class="create_button" onclick="createContent();">SAVE</button>
				<button class="cancle_button" onclick="cancelContent();">CANCLE</button>
			</td>
		</tr>
	</table>

	<form enctype="multipart/form-data" method="POST" name="fileinfo" id="fileinfo" style="display:none;" >
		<input type="hidden" name="uploadDateArr"/>
	</form>

</body>
