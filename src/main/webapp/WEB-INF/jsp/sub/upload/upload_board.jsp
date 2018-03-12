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

String ObjIdx = request.getParameter("idx");					//now idx
String ObjTitle = request.getParameter("title");				//now title
if(ObjTitle != null && ObjTitle != ""){
	ObjTitle = ObjTitle.replaceAll("'", "\\\\'");
}
String ObjContent = request.getParameter("content");			//now content
if(ObjContent != null && ObjContent != ""){
	ObjContent = ObjContent.replaceAll("'", "\\\\'");
}

String viewPageNum = request.getParameter("viewPageNum");		//now view page number
String projectImage = request.getParameter("projectImage");		//GeoPhoto conn check
String projectVideo = request.getParameter("projectVideo");		//GeoVideo conn check
String b_boardTabArr = request.getParameter("b_boardTabArr");	//board tab array
String b_nowTabName = request.getParameter("nowTabName");		//now tab name
String selBoardNum = request.getParameter("selBoardNum");		//페이지당 컨텐츠 개수

String shareType = request.getParameter("shareType");				//공유 타입
String oldShareUserLen = request.getParameter("oldShareUserLen");	//저장된 공유 유저
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var ObjIdx = '<%= ObjIdx %>';				//현재 객체 idx
var ObjTitle = '<%= ObjTitle %>';			//현재 객체 title
var ObjContent = '<%= ObjContent %>';		//현재 객체 content
var viewPageNum = '<%=viewPageNum%>';		// 선택 시 페이지 번호
var selBoardNum = '<%=selBoardNum%>';		// 선택 시 페이지 번호
var projectImage = "<%=projectImage%>";		//GeoCMS 연동여부				0:연동안됨, 1:연동됨
var projectVideo = "<%=projectVideo%>";		//GeoCMS_video 연동여부		0:연동안됨, 1:연동됨
var b_boardTabArr = "<%=b_boardTabArr%>";	//board tab array
b_boardTabArr = b_boardTabArr.split(",");
var b_nowTabName = "<%=b_nowTabName%>";		//board nowTab

var shareType = "<%=shareType%>";				//공유 타입
var oldShareUserLen = "<%=oldShareUserLen%>";	//저장된 공유 유저

var fileCnt = 1;
var fontList = ["굴림", "굴림체", "돋움", "돋움체", "바탕", "바탕체", "궁서", "궁서체", "Arial", "Courier New", "Tahoma", "Times New Roman", "Verdana", "Sans Serif", "MS Gothic", "MS PGothic", "MS UI Gothic", "Meiryo", "SimSun"];
$(function() {
		//text Size list
		for(var i=1;i<7;i++){
			var strHtml = "<option value='" + i + "px' >" + i  + " </option>"; 
			$('#fontSizeList').append(strHtml);
		}
		
		//text Style list
		$.each(fontList, function(idx, val){
			var strHtml = "<option value='" + val + "' >" + val  + " </option>"; 
			$('#fontKindList').append(strHtml);
		});
		
		//text color list
		$('#iColorPicker').click(function(){
			textEditor.focus();
			var fontColor = $('#caption_font_color').val();
			$('#icp_caption_font_color').children().children().attr('color', fontColor);
			textEditor.document.execCommand("ForeColor", false, fontColor);
		});

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
		for(var i=0;i<b_boardTabArr.length;i++){
			innerHTML += '<option>'+ b_boardTabArr[i] +'</option>';
		}
		$('#showKind').append(innerHTML);
		$('#showKind').val(b_nowTabName);
		
		$('#showBoard').attr("checked", true);
		
		if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
			$('#title_area').val(ObjTitle);
			textEditor.document.body.innerHTML = ObjContent;
			
			var strClass = textEditor.document.getElementsByTagName('img');
			$.each(strClass , function(idx, val){
				var tempId = $(this).attr('id');
				var tempSrc = $(this).attr('src');

				 $(this).attr('src', "<c:url value='/upload/GeoCMS/"+ tempSrc +"'/>");
			});
			$('#showDiv').css('display', 'none');
			$("input[name=shareRadio][value=" + shareType + "]").attr("checked", true);
		}
	}
);


function fileSaveInfo(){
	var form = $('form')[0];
    var formData = new FormData(form);
    var fileLen = $('#fileinfo').children().length;
    if(fileLen > 0){
    	$.ajax({
    		url: "<c:url value='/geoUpload.do'/>?uploadType=GeoCMS",
	    	type: 'POST',
	        data:  formData,
	    	mimeType:"multipart/form-data",
	    	contentType: false,
	        cache: false,
	        processData:false,
	   		success: function(data, textStatus, jqXHR)
	    	{
	 			boardDataSave(data);
	    	},
	     	error: function(jqXHR, textStatus, errorThrown) 
	     	{
	     		jAlert(jqXHR + " : " + textStatus + " : " +errorThrown,'Info' );
	     	}          
	    });
    }else{
    	boardDataSave('');
    }
}

//make change object(board, image, video)
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(null, type, b_nowTabName);
}

//게시물 생성
function createContent() {
// 	var id = $.cookie('id');
	
	if(loginId != null && loginId != '' && loginId != 'null') {
		var title = $('#title_area').val();
		var innerStr = textEditor.document.body.innerHTML;
		var shareType = $('input[name=shareRadio]:checked').val();
		var addShareUser = $('#shareAdd').val();

		 if(title == null || title == "" || title == 'null'){
// 			 jAlert('제목을 입력해 주세요.', '정보');
			 jAlert('Please enter the title.', 'Info');
			 $('#title_area').focus();
			 return;
		 }
		 
		 if(innerStr == null || innerStr == "" || innerStr == 'null'){
// 			 jAlert('내용을 입력해 주세요.', '정보');
			 jAlert('Please enter your details.', 'Info');
			 return;
		 }
		 
		 if(shareType != null && shareType == 2 && (addShareUser == null || addShareUser == '') && oldShareUserLen == 0){
// 			 jAlert('공유 유저가 지정되지 않았습니다.', '정보');
			 jAlert('No sharing user specified.', 'Info');
			 return;
		 }
		 datasubmit();
		 fileSaveInfo();
// 	 	$('#fileinfo').submit();
	}
	else {
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', '정보');
		jAlert('I lost my login information.', 'Info');
	}
}

function boardDataSave(data){
	var filePathStr = '';
	var fileNameStr = '';
	var fileStr = new Array();
	if(data != null && data != ''){
		var tmpfile = data.split(",");
		$.each(tmpfile, function(idx, val){
			if(val.indexOf("path:")>-1){
				filePathStr = val.replace('path:','');
			}else{
				fileStr.push(val);
			}
		});
		fileNameStr = fileStr.join(',');
		filePathStr = filePathStr.replace(/\\/g,'&sbsp');
	}else{
		filePathStr = '&nbsp';
		fileNameStr = '&nbsp';
	}
	
	var strClass = textEditor.document.getElementsByTagName('img');
	$.each(strClass , function(idx, val){
		var tmpIdx = $(this).attr('id').lastIndexOf("_");
		var tempId = $(this).attr('id').substring(0, tmpIdx);
		
		$.each(fileStr, function(dataIdx, dataVal){
			var tmpFN = dataVal;
			if(dataVal.indexOf("(") > 0){
				tmpFN = dataVal.substring(0,dataVal.indexOf("(")) + dataVal.substring(dataVal.indexOf("."),dataVal.length);
			}
			
			if(tmpFN.indexOf(tempId)>-1){
				tempId = dataVal;
				fileStr[dataIdx] = "";
				return false;
			}
		});

		$(this).attr('src', tempId);
	});
	
	var title = $('#title_area').val();
	var innerStr = textEditor.document.body.innerHTML;
	var tmpTabName = $('#showKind').val();
	var shareType = $('input[name=shareRadio]:checked').val();
	var tmpAddShareUser = $('#shareAdd').val();
	var tmpRemoveShareUser = $('#shareRemove').val();
	var tmpEditYes = $('#editYes').val();
	var tmpEditNo = $('#editNo').val();
	
	if(tmpAddShareUser == null || tmpAddShareUser.length <= 0){
		 tmpAddShareUser = '&nbsp';
	 }
	 
	 if(tmpRemoveShareUser == null || tmpRemoveShareUser.length <= 0){
		 tmpRemoveShareUser = '&nbsp';
	 }
	 
	 if(tmpEditYes == null || tmpEditYes.length <= 0){
		 tmpEditYes = '&nbsp';
	 }
	 
	 if(tmpEditNo == null || tmpEditNo.length <= 0){
		 tmpEditNo = '&nbsp';
	 }
	
	title = title.replace(/\//g,'&sbsp');
	innerStr = innerStr.replace(/\//g,'&sbsp');
	
	var bareUrl			= baseRoot();
	if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
		bareUrl = bareUrl + "cms/updateBorder/";
	}else{
		bareUrl = bareUrl + "cms/saveBorder/";
	}
	
	title = encodeURIComponent(title);
	innerStr = encodeURIComponent(innerStr);
	
	var Url			= baseRoot();
	var param		= loginToken + "/" + loginId + "/" + title + "/" + innerStr + "/" + fileNameStr + "/" + filePathStr + "/" + tmpTabName + "/" + ObjIdx + "/" + shareType + "/" + tmpAddShareUser + "/" + tmpRemoveShareUser +"/"+ tmpEditYes +"/"+ tmpEditNo;
	var callBack	= "?callback=?";
	if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
		Url = Url + "cms/updateBorder/";
	}else{
		Url = Url + "cms/saveBorder/";
	}
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				jAlert(data.Message, 'Info');
				window.parent.closeUpload();
				if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
// 					window.parent.viewMyContents();
					backPage();
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});

}

//게시물 생성 취소
function cancelContent() {
	if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
// 		jConfirm('게시물 수정을 취소하시겠습니까?', '정보', function(type){
		jConfirm('Are you sure you want to unpost this post?', 'Info', function(type){
			backPage();
		});
	}else{
// 		jConfirm('게시물 생성을 취소하시겠습니까?', '정보', function(type){
		jConfirm('Are you sure you want to cancel creating posts?', 'Info', function(type){
			if(type) window.parent.closeUpload();
		});
	}
}

//에디터 동작 함수
function textEditFn(type, typeEtc){
	textEditor.focus();
	if(typeEtc != null){	//typeEtc : 글자체 or 글자 크기 
		textEditor.document.execCommand(type, "", typeEtc);
	}else{
		textEditor.document.execCommand(type);
	}
}

//file button reset
//만약 file button에 저장된 이미지가 내용에서 삭제 되었으면 해당 file button 삭제
function datasubmit()
{
	var tempInputFile = new Array();
	var removeFile = new Array();
	var innerStr = textEditor.document.body.innerHTML;
	$('#comment').val(innerStr);
	var strClass = textEditor.document.getElementsByTagName('img');
	$.each(strClass , function(idx, val){
		var tmpIdx = $(this).attr('id').lastIndexOf("_");
		var tempId = $(this).attr('id').substring(0,tmpIdx);
		tempInputFile.push(tempId);
	});
	
	var filess = document.getElementsByClassName('imgFiles');
	$.each(filess , function(idx, val){
		if(this.value != null && this.value != '' && this.value != undefined){
			var tmpIdx = this.value.lastIndexOf("\\") + 1;
			var tmpId = this.value.substring(tmpIdx, this.value.length);
			var idx = $.inArray(tmpId , tempInputFile);
			if(idx == -1){
				removeFile.push($(this).attr('id'));
			}
		}
	});

	$.each(removeFile, function(idx, val){
		$('#' + removeFile[idx]).remove();
	});
}

//파일 선택시 실행되는 함수
function fileChange(obj){
	var igmPath = URL.createObjectURL(obj.files[0]);
    var strHtml = "<img src='" + igmPath + "' id='" + obj.files[0].name + "_" + fileCnt +"'/>";
    $('#textEditor').focus();

    textEditor.document.execCommand("insertHTML", false, strHtml);	//에디터에 이미지 파일 추가
    
	$('#fileinfo').append($('#'+obj.id));	//선택 파일 버튼 폼객체에 추가
	var appendFileBtn = "<input id='imgFile_" + (++fileCnt) + "' name='imgFileName' type='file' accept='.jpg,.gif,.png,.bmp' class='imgFiles' onchange='fileChange(this);'/>";
	$('#editBtnArea').prepend(appendFileBtn); //새로운 파일 버튼 만들어 추가
}

//리스트로 되돌아가기
function backPage(){
	jQuery.FrameDialog.closeDialog();
	parent.moreListView(viewPageNum, b_nowTabName, selBoardNum);
}

//open shareUser list
function getShareUser(){
	contentViewDialog = jQuery.FrameDialog.create({
		url:'<c:url value="/geoCMS/share.do" />?shareIdx='+ ObjIdx +'&shareKind=GeoCMS',
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
	<tr>
		<td width="400" height="25" colspan="2" style="font-size: 12px;">
			<div style="width:250px;float:left;" id="showDiv">
				<div style="float:left;"><input type="radio" id="showBoard" name="showRadio">Board</div>
				<div style="float:left;"><input type="radio" id="showImage" name="showRadio" onclick="changeShow('Image')">Image</div>
				<div style="float:left;"><input type="radio" id="showVideo" name="showRadio" onclick="changeShow('Video')">Video</div>
			</div>
			<div>
				<select style="float:right;margin-right:10px;" id="showKind"></select>
			</div>
		</td>
	</tr>
	<tr>
		<td width='100' height='25' align='center'>TITLE</td>
		<td width='860' height='25' align='center'>
			<input id='title_area' type='text' style='width:830px;'>
		</td>
	</tr>
	<tr>
		<td width='960' height='25' align='center' colspan='2'>CONTENT</td>
	</tr>
	<tr>
		<td width='960' height='300' align='left' colspan='2'>
			<div style="width:100%;height:30px;" id="editBtnArea">
				<div style="float:left;"><select id="fontKindList" onchange="textEditFn('fontname', this.value);" style="height:21px;"></select>
				<select id="fontSizeList" onchange="textEditFn('fontSize', this.value);" style="height:21px;"></select>
				</div>
				
				<div style="float:left;margin-left:10px;">
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_bold.gif'/>" onclick="textEditFn('Bold');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_underline.gif'/>" onclick="textEditFn('underline');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_Italic.gif'/>" onclick="textEditFn('Italic');"/>
					<input id="caption_font_color" type="hidden" class="iColorPicker"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_alignleft.gif'/>" onclick="textEditFn('justifyleft');" style="margin-left:27px;"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_aligncenter.gif'/>" onclick="textEditFn('justifycenter');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_alignright.gif'/>" onclick="textEditFn('justifyright');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_numberset.gif'/>" onclick="textEditFn('insertorderedlist');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_markset.gif'/>" onclick="textEditFn('insertunorderedlist');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_indent.gif'/>" onclick="textEditFn('indent');"/>
					<img src="<c:url value='/images/geoImg/board/textEdit/btn_n_outdent.gif'/>" onclick="textEditFn('outdent');"/>
				</div>
				
				<input id='imgFile_1' name='imgFileName' type='file' accept='.jpg,.gif,.png,.bmp' class='imgFiles' onchange='fileChange(this);' style="margin-left:20px;"/>
				
			</div>
			<iframe src="about:blank" width="930" height="392" onload="this.contentDocument.designMode='on'" id="textEditor" name="textEditor"  style="background-color:#ffffff"></iframe>
			<textarea id='comment' style='display:none;'></textarea>
		</td>
	</tr>
	<tr class="showDivTR">
		<td colspan="2">
<!-- 			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">비공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="1" name="shareRadio">전체공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div> -->
			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">Nondisclosure</div>
			<div style="float:left;"><input type="radio" value="1" name="shareRadio">Full disclosure</div>
			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">Selective disclosure</div>
		</td>
	</tr>
	<tr>
		<td width='960' height='25' align='center' colspan='2'>
			<button class='create_button' onclick='createContent();'>SAVE</button>
			<button class='cancle_button' onclick='cancelContent();'>CANCLE</button>
		</td>
	</tr>
</table>

<input type="hidden" id="shareAdd"/>
<input type="hidden" id="shareRemove"/>
<input type="hidden" id="editYes"/>
<input type="hidden" id="editNo"/>
<div id="clonSharUser" style="display:none;"></div>

<form enctype="multipart/form-data" method="post" name="fileinfo" id="fileinfo" style="display:none;">
<!-- 	<iframe id="uploadIFrame" name="uploadIFrame" style="display:none;"></iframe> -->
</form>
</body>
