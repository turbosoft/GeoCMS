<%@ page language="java" contentType="text/html; charset=UTF-8"  pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
String loginType = (String)session.getAttribute("loginType");				//로그인 권한

String viewPageNum = request.getParameter("viewPageNum");	//now view page number
String selBoardNum = request.getParameter("selBoardNum");	//view list page board count
String nowTabIdx = request.getParameter("nowTabIdx");		//now tab idx
%>

<script type="text/javascript">
var loginId = '<%=loginId%>';
var loginToken = '<%=loginToken%>';
var loginType = '<%=loginType%>';

var boardCountNum = 0;						//한 페이지당 컨텐츠 갯수
var boardNowPageNum = "<%=viewPageNum%>";	//현재 페이지 번호
var boardType = "";							//현재 리스트 타입 [gellery, list]
var selBoardNum = "<%=selBoardNum%>";		//페이지 당 보여줄 객체 개수
var boardnowTabName = "";	//현재 탭 이름
var boardnowTabIdx = "<%=nowTabIdx%>";		//현재 탭 인덱스
var board_tabArr = new Array();		//content tab array

$(function(){
	getTabNameList();
	
	//tab select box setting
	var innerHTMLStr = '<option>All</option>';
	for(var i=0;i<board_tabArr.length;i++){
		innerHTMLStr += '<option>'+ board_tabArr[i] +'</option>';
	}
	$('#selBoardTabType').append(innerHTMLStr);
	$('#selBoardTabType').val(boardnowTabName);
	$('#selBoardNum').val(selBoardNum);
	//board page setting
	clickBoardPage(boardNowPageNum);
});

function getTabNameList() {
	var Url			= baseRoot() + "cms/getbase";
	var callBack	= "?callback=?";
	board_tabArr = new Array();
	
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
							board_tabArr.push(result[i].tabname);
							if(result[i].tabidx == boardnowTabIdx){
								boardnowTabName = result[i].tabname;
							}
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

//게시판 리스트 가져오기
function clickBoardPage(pageNum){
	if(pageNum == null || pageNum == '' || pageNum == 'null') return;
	boardNowPageNum = pageNum;
	boardCountNum = $('#selBoardNum').val();
	boardnowTabName = $('#selBoardTabType').val();
	
	var dataType = 'list';
	var dataIdx = '&nbsp';
	
	if(loginToken == null || loginToken == '' || loginToken == 'null'){
		loginToken = '&nbsp';
	}
	
	if(loginId == null || loginId == '' || loginId == 'null'){
		loginId = '&nbsp';
	}
	
	var tmpTabIndex = 0;
	if(boardnowTabName != null && boardnowTabName != 'All'){
		tmpTabIndex = $.inArray(boardnowTabName, board_tabArr)+1;
	}
	
	var Url			= baseRoot() + "cms/getBoard/";
	var param		= dataType + "/" + loginToken + "/" + loginId + "/" + pageNum + "/" + boardCountNum + "/" + tmpTabIndex + "/" + dataIdx;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				var response = data.Data;
				
				//이미지 리스트 설정
				boardListSetup(response);
				//페이지 설정
				boardPageSetup(pageNum, data.DataLen);
			}else{
				boardFirstSet();
				jAlert(data.Message, 'Info');
			}
		}
	});
}
	
//테이블 초기화
function boardFirstSet(){
	$('#board_list_table div').remove();
	$("#board_list_table tr").remove();
	$("#board_list_table").next().remove();
	
	var innerHTMLStr = "<div style='position:absolute; border:2px solid #82B5DF; width:98%; height:35px; border-radius:10px; top:52px;'></div>";
	$('#board_list_table').append(innerHTMLStr);

	innerHTMLStr = "<tr style='text-align:center;'>";
// 	innerHTMLStr += "<td width='73'>번호</td>";
// 	innerHTMLStr += "<td width='379'>제목</td>";
// 	innerHTMLStr += "<td width='73'>작성자</td>";
// 	innerHTMLStr += "<td width='164'>작성일</td>";
	innerHTMLStr += "<td width='73'>NO</td>";
	innerHTMLStr += "<td width='379'>TITLE</td>";
	innerHTMLStr += "<td width='73'>WRITER</td>";
	innerHTMLStr += "<td width='164'>DATE</td>";
	innerHTMLStr += "<tr style='height:15px;' align='center'></tr>";
	innerHTMLStr += "<tr class='tr_line' bgcolor='#D2D2D2'><td colspan='4'></td></tr>";
	innerHTMLStr += "<tr class='tr_line' bgcolor='#82B5DF'><td colspan='4'></td></tr>";
	$('#board_list_table').append(innerHTMLStr);
}
	
//이미지 리스트 설정
function boardListSetup(pure_data) {

	//전달할 각 속성을 배열에 저장
	var id_arr = new Array();
	var title_arr = new Array();
	var content_arr = new Array();
	var file_url_arr = new Array();
	var udate_arr = new Array();
	var idx_arr = new Array();
	
	for(var i=0;i<pure_data.length;i++){
		id_arr.push(pure_data[i].id); //id 저장
		title_arr.push(pure_data[i].title); //title 저장
		content_arr.push(pure_data[i].content); //content 저장
		file_url_arr.push(pure_data[i].filename); //fileName 저장
		udate_arr.push(pure_data[i].u_date); //uDate 저장
		idx_arr.push(pure_data[i].idx); //idx 저장
	}
	
	//테이블 초기화
	boardFirstSet();
	
	//테이블에 데이터 추가
	addBoardListDataCell(id_arr, title_arr, content_arr, file_url_arr, idx_arr, udate_arr);
}

//게시물 페이지 설정
function boardPageSetup(pageNum, totalPageCnt) {
			var totalPage = 1;
			if(totalPageCnt % boardCountNum == 0){
				totalPage = parseInt(totalPageCnt / boardCountNum);
			}else{
				totalPage = parseInt(totalPageCnt / boardCountNum)+1;
			}
			
			//테이블에 페이지 추가
			addBoardPageCell(totalPage,pageNum);
}

//테이블에 페이징 숫자 추가
function addBoardPageCell(totalPage,pageNum) {
	var innerHTMLStr = "<div id='pagingDiv' style='margin-top:10px;'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:270px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickBoardPage("+(pageGroup-10)+");'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:295px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageBL(\"prev\","+ totalPage +");'></div>";
	}
	
	innerHTMLStr += "<div style='position:absolute;left:300px;text-align:center;width:320px;'>"
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		
		innerHTMLStr += "<font color='#000'><a href="+'"'+ "javascript:clickBoardPage('"+(i).toString()+"');"+'"';
		innerHTMLStr += " style='padding:2px 4px 0 3px; text-decoration:none;'> ";
		if(boardNowPageNum == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:620px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageBL(\"next\","+ totalPage +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:635px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickBoardPage("+ (pageGroup+10)+");'></div>";
	}
	
	innerHTMLStr += "</div>";
	$('#board_list_table').after(innerHTMLStr);
}

function clickMovePageBL(cType, totalPage){
	var movePage = 0;	
	boardNowPageNum = Number(boardNowPageNum);
	if(cType == 'next'){
		if(boardNowPageNum+1 <= totalPage){
			movePage = boardNowPageNum+1;
		}
	}else{
		if(boardNowPageNum > 1){
			movePage = boardNowPageNum-1;
		}
	}
	if(movePage > 0){
		clickBoardPage(movePage);
	}
}

//테이블 데이터 추가
function addBoardListDataCell(id_arr, title_arr, content_arr, file_url_arr, idx_arr, udate_arr){
	var innerHTMLStr = "";
	var listNum = boardNowPageNum;
	if(listNum > 1){
		listNum = ((listNum-1) * boardCountNum) +1;
	}
	
	for(var i=0;i<id_arr.length;i++){
		innerHTMLStr += "<tr style='text-align:center;height:25px;' onclick='boardViewDetail(this);' id='GeoCMS_" + idx_arr[i] + "'>";
		innerHTMLStr += "<td style='font-size:12px;'>" + (listNum++) +"</td>";
		innerHTMLStr += "<td style='text-align:left;'>" + title_arr[i] +"</td><td>" + id_arr[i] + " </td><td>" + udate_arr[i] + "</td>";
		innerHTMLStr += "</tr><tr class='tr_line' bgcolor='#D2D2D2'><td colspan='4'></td></tr>";
	}
	$('#board_list_table').append(innerHTMLStr);
	
}

//게시물 클릭 시 board 데이터 보여주기
function boardViewDetail(obj){
	if(obj.id == null || obj.id == ""){
		return;
	}
	
	if(boardnowTabName == null || boardnowTabName == 'null'){	//만약 tab name 없으면 board tab array의 0번째 값을 넣어준다. search로 viewer를 띄웠을 경우
		boardnowTabName = parent.b_boardTabArr[0];
	}
	var bObjId = obj.id.split("_")[1];
	var tmpTabIndex = 1;
	if(boardnowTabName != null && boardnowTabName != ''){
		tmpTabIndex = $.inArray(boardnowTabName, parent.b_boardTabArr)+1;
	}
	
	jQuery.FrameDialog.closeDialog();
	var	contentDetailViewDialog = window.parent.jQuery.FrameDialog.create({
		url: '<c:url value="/geoCMS/board_viewer.do"/>?idxNum="' + bObjId + '"&viewPageNum="' + boardNowPageNum + '"&boardNowTabIdx="'+ tmpTabIndex+'"&selBoardNum='+$('#selBoardNum').val(),
		title: 'Board Viewer',
		width: 960,
		height: 650,
		buttons: {},
		autoOpen:false
	});
	
	contentDetailViewDialog.dialog('open');
}

</script>
</head>
<body>
	<select id="selBoardTabType" style="margin:7px 10px 5px 10px; width: 200px;" onchange="clickBoardPage(1);"></select>
	
	<select id="selBoardNum" style="margin:7px 10px 5px 600px; display: inline-block;" onchange="clickBoardPage(1);">
		<option value="5">5</option>
		<option value="10">10</option>
		<option value="15" selected="selected">15</option>
		<option value="20">20</option>
		<option value="30">30</option>
		<option value="40">40</option>
		<option value="50">50</option>
	</select>
	
	<table id="board_list_table" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin-top:10px;">
	</table>
</body>
</html>