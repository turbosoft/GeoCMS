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
String viewPageNum = request.getParameter("viewPageNum");		//now view page number
String selBoardNum = request.getParameter("selBoardNum");		//페이지당 컨텐츠 개수
String b_nowTabIdx = request.getParameter("nowTabIdx");			//now tab idx
String makeContentIdx = request.getParameter("makeContentIdx");		//선택한 프로젝트 인덱스

// String shareType = request.getParameter("shareType");				//공유 타입
String oldShareUserLen = request.getParameter("oldShareUserLen");	//저장된 공유 유저
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var ObjIdx = '<%= ObjIdx %>';				//현재 객체 idx
var ObjTitle = '';							//현재 객체 title
var ObjContent = '';						//현재 객체 content
var viewPageNum = '<%=viewPageNum%>';		// 선택 시 페이지 번호
var selBoardNum = '<%=selBoardNum%>';		// 선택 시 페이지 번호
var b_boardTabArr = new Array();			//board tab array
var b_nowTabName = "";						//board now Tab name
var b_nowTabIdx = "<%=b_nowTabIdx%>";		//board now Tab idx
var shareType = 1;							//공유 타입
<%-- var shareType = "<%=shareType%>";				//공유 타입 --%>
var oldShareUserLen = "<%=oldShareUserLen%>";	//저장된 공유 유저
var makeContentIdx = "<%=makeContentIdx%>";		//선택한 프로젝트 인덱스

var fileCnt = 1;
// var fontList = ["굴림", "굴림체", "돋움", "돋움체", "바탕", "바탕체", "궁서", "궁서체", "Arial", "Courier New", "Tahoma", "Times New Roman", "Verdana", "Sans Serif", "MS Gothic", "MS PGothic", "MS UI Gothic", "Meiryo", "SimSun"];
var fontList = ["gullim", "gullimche", "dod-um", "dod-umche", "batang", "batangche", "gungseo", "gungseoche", "Arial", "Courier New", "Tahoma", "Times New Roman", "Verdana", "Sans Serif", "MS Gothic", "MS PGothic", "MS UI Gothic", "Meiryo", "SimSun"];
$(function() {
		getTabNameList();
		getServerBoard();
		
		if(b_nowTabIdx != null && b_nowTabIdx != "" && b_nowTabIdx != 'null' &&  b_nowTabIdx != undefined && ObjIdx != null && ObjIdx != "" && ObjIdx != 'null' && ObjIdx != undefined){
			getOneBoardData();
		}
		
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
		
		//tab select
		var innerHTML = '';
		for(var i=0;i<b_boardTabArr.length;i++){
			innerHTML += '<option value="'+ (i+1) +'">'+ b_boardTabArr[i] +'</option>';
		}
		$('#showKind').append(innerHTML);
		$('#showKind').val(b_nowTabIdx);
		
		$('#showBoard').attr("checked", true);
		
		if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
			$('#title_area').val(ObjTitle);
			textEditor.document.body.innerHTML = ObjContent;
			
			var strClass = textEditor.document.getElementsByTagName('img');
			$.each(strClass , function(idx, val){
				var tempId = $(this).attr('id');
				var tempSrc = $(this).attr('src');

				var localAddress = ftpBaseUrl() + "/GeoCMS";
				$(this).attr('src', localAddress+"/"+ tempSrc);
			});
			$('#showDiv').css('display', 'none');
			$("input[name=shareRadio][value=" + shareType + "]").attr("checked", true);
		}
		
	}
);

function getTabNameList() {
	var Url			= baseRoot() + "cms/getbase";
	var callBack	= "?callback=?";
	b_boardTabArr = new Array();
	
	$.ajax({
		type	: "get"
		, url	: Url + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				result = data.Data;
				if(result != null && result.length > 0){
					for(var i=0;i<result.length; i++){
						if(i > 0 && result[i].tabgroup == 'board'){
							b_boardTabArr.push(result[i].tabname);
							if(b_nowTabIdx != null && b_nowTabIdx != '' && b_nowTabIdx != undefined){
								if(result[i].tabidx == b_nowTabIdx){
									b_nowTabName = result[i].tabname;
								}
							}else if(b_nowTabName == null || b_nowTabName == "" || b_nowTabName == undefined){
								b_nowTabName = result[i].tabname;
							}
						}
					}
				}
				if(b_boardTabArr == null || b_boardTabArr == ''){
// 					jAlert("게시글의 카테고리가 존재하지 않아 게시글을 작성 할 수 없습니다.", 'Info', function(res){
					jAlert("You can not create a post because the category of the post does not exist.", 'Info', function(res){	
						changeShow("Image");
					});
				}
			}else{
				jAlert(data.Message, 'Info');
				return;
			}
		}
	});
}
	
//get server
function getServerBoard(){
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
			if(data.Code == '100'){
				b_serverUrl = response[0].serverurl;
				b_serverViewPort = response[0].serverviewport;
				b_serverPath = response[0].serverpath;
				if(b_serverUrl != null && b_serverUrl != "" && b_serverUrl != undefined){
					b_serverType = "URL";
				}else{
					b_serverType = "LOCAL";
				}
			}else if(data.Code != '200'){
				b_serverPath = "upload";
				jAlert(data.Message, 'Info');
			}else{
				b_serverPath = "upload";
			}
		}
	});
}

function getOneBoardData(){
	var Url			= baseRoot() + "cms/getBoard/";
	var param		= "one/" + loginToken + "/" + loginId + "/&nbsp/&nbsp/"+ b_nowTabIdx + "/" + ObjIdx;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				var response = data.Data;
				if(response != null && response != ''){
					response = response[0];
					ObjTitle = response.title;
					ObjContent = response.content;
					shareType = response.sharetype;
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//make change object(board, image, video)
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(type,'','', makeContentIdx);
}

//게시물 생성
function createContent() {
	if(loginId != null && loginId != '' && loginId != 'null') {
		var title = $('#title_area').val();
		var innerStr = textEditor.document.body.innerHTML;
		var shareType = $('input[name=shareRadio]:checked').val();
		var tmpAddShareUser = $('#shareAdd').val();
		var tmpRemoveShareUser = $('#shareRemove').val();
		var tmpEditYes = $('#editYes').val();
		var tmpEditNo = $('#editNo').val();
		var tmpTabIndex = $('#showKind').val();
		
		if(title == null || title == "" || title == 'null'){
//			 jAlert('제목을 입력해 주세요.', '정보');
			 jAlert('Please enter the title.', 'Info');
			 $('#title_area').focus();
			 return;
		}
		if(innerStr == null || innerStr == "" || innerStr == 'null'){
//			 jAlert('내용을 입력해 주세요.', '정보');
			 jAlert('Please enter your details.', 'Info');
			 $('#content_area').focus();
			 return;
		}
		
		if(tmpTabIndex == null || tmpTabIndex == "" || tmpTabIndex == 'null'){
// 			jAlert("게시글의 카테고리가 존재하지 않아 게시글을 작성 할 수 없습니다.",'정보');
			jAlert("You can not create a post because the category of the post does not exist.", 'Info');
			return;
		}
		
		if(tmpAddShareUser == null || tmpAddShareUser.length <= 0){ tmpAddShareUser = '&nbsp';}
		if(tmpRemoveShareUser == null || tmpRemoveShareUser.length <= 0){ tmpRemoveShareUser = '&nbsp';}
		if(tmpEditYes == null || tmpEditYes.length <= 0){ tmpEditYes = '&nbsp'; }
		if(tmpEditNo == null || tmpEditNo.length <= 0){ tmpEditNo = '&nbsp'; }
		
		datasubmit();
		
		if(title != null && title.indexOf('\'') > -1){
// 			jAlert('제목에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			jAlert('Can not use special character \' in title.', 'Info');
			return;
		}
		 
		if(innerStr != null && innerStr.indexOf('\'') > -1){
// 			jAlert('내용에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			jAlert('Can not use special character \' in content.', 'Info');
			 return;
		}
		title = dataReplaceFun(title);
		innerStr = dataReplaceFun(innerStr);
		 
		$('body').append('<div class="lodingOn"></div>');
		var iframe = $('<iframe name="postiframe" id="postiframe" style="display: none"></iframe>');
        $("body").append(iframe);
        var form = $('#fileinfo');
        
        var resAddress = baseRoot();
        if(ObjIdx != null && ObjIdx != "" && ObjIdx != "null"){
        	resAddress += "cms/updateBorderAll/";
        	resAddress += loginToken + "/" + loginId + "/" + title + "/" + innerStr + "/" + ObjIdx + "/" + shareType + "/" + tmpAddShareUser + "/" + tmpRemoveShareUser +"/" + tmpEditYes + "/" + tmpEditNo +"/"+ tmpTabIndex ;
		}else{
			resAddress += "cms/saveBoardAll/";
			resAddress += loginToken + "/" + loginId + "/" + title + "/" + innerStr + "/" + shareType + "/" + tmpAddShareUser + "/" + tmpRemoveShareUser +"/" + tmpEditYes + "/" + tmpEditNo +"/"+ tmpTabIndex;
		}
        resAddress += "?callback=?";
        
        form.attr("action", resAddress);
        form.attr("method", "POST");

        form.attr("encoding", "multipart/form-data");
        form.attr("enctype", "multipart/form-data");

        form.attr("target", "postiframe");
        form.attr("file", $('#file_1').val());
        form.submit();
        
        $("#postiframe").load(function (e) {
        	var doc = this.contentWindow ? this.contentWindow.document : (this.contentDocument ? this.contentDocument : this.document);
        	var root = doc.documentElement ? doc.documentElement : doc.body;
        	var data = root.textContent; ////////// ? root.textContent : root.innerText;
            data = data.replace("?","").replace("(","").replace(")","");
        	var resData = JSON.parse(data);

        	if(resData != null && resData != ''){
        		if(resData.Code == 100){
        			jAlert(data.Message, 'Info', function(res){
						window.parent.closeUpload();
						if(ObjIdx == null || ObjIdx == "" || ObjIdx == "null"){
							backPage();
						}
					});
        			
//         			var tmpTabIndex = $('#showKind').val();
//         			if(ObjIdx == null || ObjIdx == "" || ObjIdx == "null" || ObjIdx == undefined){
//         				ObjIdx = resData.Data;
//         			}
        			
//        		 		var Url			= baseRoot() +"cms/updateContentTab/";
//        		 		var param		= loginToken +"/"+ loginId +"/"+ tmpTabIndex +"/"+ ObjIdx +"/" + "GeoCMS";
//        		 		var callBack	= "?callback=?";
// 	       		 	$.ajax({
// 		       	 		type	: "POST"
// 		       	 		, url	: Url + param + callBack
// 		       	 		, dataType	: "jsonp"
// 		       	 		, async	: false
// 		       	 		, cache	: false
// 		       	 		, success: function(data) {
// 		       	 			if(data.Code == 100){
// 		       	 			alert('1 : ');
// 		       	 				jAlert(data.Message, 'Info', function(res){
// 									window.parent.closeUpload();
// 									if(ObjIdx == null || ObjIdx == "" || ObjIdx == "null"){
// 										backPage();
// 									}
// 								});
// 		       	 			}else{
// 		       	 			alert('2 : ');
// 		       	 				jAlert(data.Message, 'Info');
// 		       	 				$('.lodingOn').remove();
// 		       	 			}
// 		       	 		}
// 		       	 	});
					
				}else{
					jAlert(resData.Message, 'Info');
					$('.lodingOn').remove();
				}
			}else{
				$('.lodingOn').remove();
			}
        });
	}
	else
	{
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', '정보');
		jAlert('I lost my login information.', 'Info');
	}
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
	parent.moreListView(viewPageNum, b_nowTabIdx, selBoardNum);
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
	<tr class="showDivTR shareDiv">
		<td colspan="2">
<!-- 			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">비공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="1" name="shareRadio">전체공개</div> -->
<!-- 			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div> -->
			<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked">private</div>
			<div style="float:left;"><input type="radio" value="1" name="shareRadio">public</div>
			<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">sharing with friends</div>
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
</form>
</body>
