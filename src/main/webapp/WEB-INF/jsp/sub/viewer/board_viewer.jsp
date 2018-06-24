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
String boardNowTabIdx = request.getParameter("boardNowTabIdx");	// 선택 객체 tab idx
String selBoardNum = request.getParameter("selBoardNum");	// 페이지당 컨텐츠 개수
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';				// 로그인 아이디
var loginToken = '<%= loginToken %>';		// 로그인 token
var loginType = '<%= loginType %>';			// 로그인 타입

var idxNum = <%= idxNum %>;			// 선택 객체 인덱스 번호
var viewPageNum = <%=viewPageNum%>; // 선택 시 페이지 번호
var boardNowTabIdx = <%=boardNowTabIdx%>; // 선택 객체 tab idx
var boardNowTab = "";
var selBoardNum = <%=selBoardNum%>; // 페이지당 컨텐츠 개수
var nowObj = new Object();			// 현재 객체 정보

$(document).ready(
	function(){
		getTabNameList();
		getServerBoard();
		
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
		var tmpToken = '&nbsp';
		var tmpLoginId = '&nbsp';
		
		if(loginToken != null && loginToken != '' && loginToken != 'null'){
			tmpToken = loginToken;
		}
		if(loginId != null && loginId != '' && loginId != 'null'){
			tmpLoginId = loginId;
		}

		var tmpTabIndex = '&nbsp';
		var Url			= baseRoot() + "cms/getBoard/";
		var param		= dataType + "/" + tmpToken + "/" + tmpLoginId + "/" + dataPageNum + "/" + dataContentNum + "/" + tmpTabIndex + "/" + idxNum ;
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
					
					$('#title_area').text(result[0].title);
					textEditor.document.body.innerHTML = result[0].content;
					
					var localAddress = ftpBaseUrl() + "/GeoCMS";
					var strClass = textEditor.document.getElementsByTagName('img');
					$.each(strClass , function(idx, val){
						var tempId = $(this).attr('id');
						var tempSrc = $(this).attr('src');
						$(this).attr('src', localAddress + "/"+ tempSrc );
					});
					
					$('#writer_area').text(result[0].id);
					$('#date_area').text(result[0].u_date);
					nowObj.idx = idxNum;
					nowObj.title = result[0].title;
					nowObj.content = result[0].content;
					nowObj.viewPageNum = viewPageNum;
					nowObj.shareType = result[0].sharetype;
					if(tmpShareList != null && tmpShareList.length > 0){
						nowObj.oldShareUserLen = tmpShareList.length;	//저장된 공유 유저 len
					}
					
					if(loginId != null && loginId != '' && loginId != 'null' && (loginId == result[0].id && loginType != 'WRITE' || loginType == 'ADMIN')) {
						$('#modifyBtn').css('display', 'inline-block');
					}else if(editUserCheck() == 1){
						$('#modifyBtn').css('display', 'inline-block');
					}
				}else{
					jAlert(data.Message, 'Info');
				}
			}
		});
	}
);

function getTabNameList() {
	var Url			= baseRoot() + "cms/getbase";
	var callBack	= "?callback=?";
	pop_tabArr = new Array();
	
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
						if(i > 0 && result[i].tabgroup == 'board' && result[i].tabidx == boardNowTabIdx){
							boardNowTab = result[i].tabname;
						}
					}
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

//편집 가능 유저 확인
function editUserCheck(){
	var Url			= baseRoot() + "cms/getShareUser/";
	var param		= loginToken + "/" + loginId + "/" + idxNum + "/GeoCMS";
	var callBack	= "?callback=?";
	var editUserYN  = 0;

	$.ajax({
		  type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(response) {
			if(response.Code == 100 && response.Data[0].shareedit == 'Y'){
				editUserYN = 1;
			}
		}
	});
	return editUserYN;
}

//리스트로 되돌아가기
function backPage(){
	jQuery.FrameDialog.closeDialog();
	if(viewPageNum == null || viewPageNum == "" || viewPageNum == "null"){
		viewPageNum = 1;
	}
	parent.moreListView(viewPageNum, boardNowTabIdx, selBoardNum);
}

//수정 하기
function modifyContent(){
	jQuery.FrameDialog.closeDialog();
	parent.BoardModeifyFun(idxNum, boardNowTabIdx, selBoardNum);
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
