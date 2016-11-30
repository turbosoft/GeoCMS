<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");
String loginToken = (String)session.getAttribute("loginToken");
String loginType = (String)session.getAttribute("loginType");

String idxNum = request.getParameter("idxNum");				// 선택 객체 인덱스 번호
String viewPageNum = request.getParameter("viewPageNum");	// 선택 시 페이지 번호
String boardNowTab = request.getParameter("boardNowTab");	// 선택 객체 tab name
String selBoardNum = request.getParameter("selBoardNum");	// 페이지당 컨텐츠 개수
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';				// 로그인 아이디
var loginToken = '<%= loginToken %>';		// 로그인 token
var loginType = '<%= loginType %>';			// 로그인 타입

var idxNum = <%= idxNum %>;			// 선택 객체 인덱스 번호
var viewPageNum = <%=viewPageNum%>; // 선택 시 페이지 번호
var boardNowTab = <%=boardNowTab%>; // 선택 객체 tab name
var selBoardNum = <%=selBoardNum%>; // 페이지당 컨텐츠 개수
var nowObj = new Object();			// 현재 객체 정보

$(document).ready(
	function(){
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
		
		var dataType = 'one';
		var dataPageNum = '&nbsp';
		var dataContentNum = '&nbsp';
		var dataTabName = '&nbsp';

		var Url			= baseRoot() + "cms/getBorder/";
		var param		= dataType + "/" + loginToken + "/" + loginId + "/" + dataPageNum + "/" + dataContentNum + "/" + dataTabName + "/" + idxNum ;
		var callBack	= "?callback=?";
		
		$.ajax({
			type	: "get"
			, url	: Url + param + callBack
			, dataType	: "jsonp"
			, async	: false
			, cache	: false
			, success: function(data) {
				if(data.Code == '100' && data.Data.length > 0){
					var result = data.Data;
					var tmpShareList = data.shareList;
					
					$('#title_area').text(result[0].TITLE);
					textEditor.document.body.innerHTML = result[0].CONTENT;
					
					var strClass = textEditor.document.getElementsByTagName('img');
					$.each(strClass , function(idx, val){
						var tempId = $(this).attr('id');
						var tempSrc = $(this).attr('src');
						 $(this).attr('src', "<c:url value='/upload/GeoCMS/"+ tempSrc +"'/>" );
					});
					
					$('#writer_area').text(result[0].ID);
					$('#date_area').text(result[0].U_DATE);
					nowObj.idx = idxNum;
					nowObj.title = result[0].TITLE;
					nowObj.content = result[0].CONTENT;
					nowObj.viewPageNum = viewPageNum;
					nowObj.shareType = result[0].SHARETYPE;
					if(tmpShareList != null && tmpShareList.length > 0){
						nowObj.oldShareUserLen = tmpShareList.length;	//저장된 공유 유저 len
					}
					
					if(loginId != null && loginId != '' && loginId != 'null' && (loginId == result[0].ID && loginType != 'WRITE' || loginType == 'ADMIN')) {
						$('#modifyBtn').css('display', 'inline-block');
					}
				}else{
					jAlert(data.Message, '정보');
				}
			}
		});
	}
);

//리스트로 되돌아가기
function backPage(){
	jQuery.FrameDialog.closeDialog();
	if(viewPageNum == null || viewPageNum == "" || viewPageNum == "null"){
		viewPageNum = 1;
	}
	parent.moreListView(viewPageNum, boardNowTab, selBoardNum);
}

//수정 하기
function modifyContent(){
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes($.param(nowObj),"Board", boardNowTab, selBoardNum);
}

</script>

</head>

<body bgcolor='#e5e5e5'>
<table id='board_viewer_table' border=1>
	<tr>
		<td width='100' height='25' align='center'>TITLE</td>
		<td width='860' height='25' align='center' colspan="3">
			<label id='title_area'></label>
		</td>
	</tr>
	<tr>
		<td width='100' height='25' align='center'>
			WRITER
		</td>
		<td width='380' height='25' align='center'>
			<label id='writer_area' style='width:400px;'></label>
		</td>
		<td width='100' height='25' align='center'>
			DATE
		</td>
		<td width='380' height='25' align='center'>
			<label id='date_area' style='width:400px;'></label>
		</td>	
	</tr>
	<tr>
		<td width='960' height='25' align='center' colspan='4'>CONTENT</td>
	</tr>
	<tr>
		<td width='960' height='300' align='center' colspan='4'>
			<iframe src="about:blank" width="930" height="392" id="textEditor" name="textEditor"  style="background-color:#ffffff"></iframe>
			<textarea id='comment' style='display:none;'></textarea>
		</td>
	</tr>
	<tr>
		<td width='960' height='25' align="center" colspan='4'>
			<button class='create_button' onclick='backPage();'>LIST</button>
			<button class='cancle_button' id="modifyBtn" onclick='modifyContent();' style="display:none;">MODIFY</button>
		</td>
	</tr>
</table>
</body>
