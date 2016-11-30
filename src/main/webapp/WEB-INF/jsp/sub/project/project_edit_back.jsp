<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");				//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");			//로그인 token

String viewPageNum = request.getParameter("viewPageNum");	//now view page number
String nowTabName = request.getParameter("nowTabName");		//now tab name
String pop_tabArr = request.getParameter("tabArr");			//tab array
String urlText = request.getParameter("urlText");			//url
%>

<script type="text/javascript">
var loginId = '<%= loginId %>';					//로그인 아이디
var loginToken = '<%= loginToken %>';			//로그인 token

var contentNowPageNum = "<%=viewPageNum%>";		//현재 페이지 번호
var contentNowType = "";						//현재 리스트 타입 [gellery, list]
var contentnowTabName = "<%=nowTabName%>";		//현재 탭 이름
var contentCountNum = 0;						//현재 view count
var contentViewKind = "";						//현재 view kind [image_video, image, video]
var urlText = "<%=urlText%>";					//현재 base url
var pop_tabArr = "<%=pop_tabArr%>";	//content tab array
pop_tabArr = pop_tabArr.split(",");

$(function(){
	$("input[name=popRadio][value=list]").attr("checked", true);	//초기 설정은 list
	if(urlText == 'cms/getContent/'){
		$('#pop_both').attr("checked", true);
	}else{
		$('#viewKind').css('display', 'none');
		if(urlText == 'cms/getImage/'){
			$('#pop_image').attr("checked", true);
		}else if(urlText == 'cms/getVideo/'){
			$('#pop_video').attr("checked", true);
		}
	}
	var innerHTMLStr ='<option>All</option>';
	for(var i=0;i<pop_tabArr.length;i++){
		innerHTMLStr += '<option>'+ pop_tabArr[i] +'</option>';
	}
	$('#selTabType').append(innerHTMLStr);
	$('#selTabType').val(contentnowTabName);
	clickContentPage(contentNowPageNum);
});

//게시판 리스트 가져오기
function clickContentPage(pageNum){
	if(pageNum == null || pageNum == '' || pageNum == 'null') return;
	contentNowPageNum = pageNum;
	contentNowType = $('input[name=popRadio]:checked').attr('id').split("_")[1];
	contentCountNum = $('#selContentNum').val();
	contentnowTabName = $('#selTabType').val();
	contentViewKind = $('input[name=popKindRadio]:checked').attr('id').split("_")[1];
	
	var moveUrl = '';
	if(contentViewKind == 'both'){
		moveUrl = 'cms/getContent/';
	}else if(contentViewKind == 'image'){
		moveUrl = 'cms/getImage/';
	}else if(contentViewKind == 'video'){
		moveUrl = 'cms/getVideo/';
	}
	
	var tempObj = new Object();
	tempObj.contentCountNum = contentCountNum;
	tempObj.type = contentNowType;
	tempObj.TabName = contentnowTabName;
	tempObj.pageNum = pageNum;
	tempObj.moveUrl = moveUrl;
	
	if(loginId == null || loginId == '' || loginId == 'null'){
		loginId = '&nbsp';
	}
	
	var Url			= baseRoot() + moveUrl;
	var param		= "list/" + loginId + "/" + pageNum + "/" + contentCountNum + "/" + contentnowTabName;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			
			var response = data.Data;
			clearContentTable();
			var makeTmpObj = makeTempObj('content_list_table_pop', tempObj.type, tempObj.contentCountNum);
			makeTmpObj.tabName = tempObj.TabName;
			makeTmpObj.pageNum = tempObj.pageNum;
			makeTmpObj.moveUrl = tempObj.moveUrl;
			parent.leftListSetup(response, makeTmpObj);
			
			//페이지 설정
			contentPageSetup(response, makeTmpObj);
			//content view table css
			setContentDesign(makeTmpObj.type);
		}
	});
}

function contentPageSetup(totalRes, obj){
	var totalPage = 1;
	if(totalRes != null && totalRes.length > 0){
		if(totalRes[0].TOTAL_CNT % obj.contentNum == 0){
			totalPage = parseInt(totalRes[0].TOTAL_CNT / obj.contentNum);
		}else{
			totalPage = parseInt(totalRes[0].TOTAL_CNT / obj.contentNum)+1;
		}
	}
	
	//테이블에 페이지 추가
	addContentPageCell(totalPage,obj.pageNum,'pop');
}

//content view table css
function setContentDesign(contentNowType) {
	var target = window.frames[0].document.getElementById("content_list_table_pop");
	if(contentNowType == 'list'){
		for(var i=0;i<target.getElementsByTagName("tr").length;i++){
			var tmp = target.getElementsByTagName("tr")[i].getElementsByTagName('td')[0];
			tmp.style.borderBottom = '1px solid gray';
		}
	}
}

//테이블에 페이징 숫자 추가
function addContentPageCell(totalPage, pageNum, type) {
	var target;
	if(type == 'pop'){
		target = window.frames[0].document.getElementById("content_list_table_pop");
	}else{
		target = document.getElementById("content_list_table_pop");
	}
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '3';
	cell.height = '18px';
	
	var innerHTMLStr = "<div id='pagingDiv' style='height:18px;'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;font-size:14px;left:270px;' onclick='moveNext("+ totalPage+","+ (pageGroup-10)+");'> prev </div>";
	}
	innerHTMLStr += "<div style='position:absolute;font-size:14px;left:320px;text-align:center;width:301px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'>[<a href="+'"'+"javascript:clickContentPage('"+(i).toString()+"');"+'"'+" style='text-decoration:none;'><font color='#000' ";
		if(pageNum == i){
			innerHTMLStr += "style='font-weight:900'";
		}
		innerHTMLStr += ">"+(i).toString()+"</font></a>]</font>";
	}
	innerHTMLStr += "</div>";
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;font-size:14px;width:40px;left:641px;' onclick='moveNext("+ totalPage+","+ (pageGroup+10)+");'> next </div>";
	}
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

//move pageGroup : prev, next
function moveNext(totalPage, pageNum){
	clickContentPage(pageNum);
	$('#content_list_table_pop tr:last').remove();
	addContentPageCell(totalPage, pageNum, '');
}

//테이블 초기화
function clearContentTable() {
	var target = document.getElementById("content_list_table_pop");
	target.innerHTML = "";
}

//popup 창에 띄울 임시 object 만들기
function makeTempObj(table_name, image_type, max_row){
	var nowObj = new Object();
	nowObj.table_name = table_name;							//image table name
	nowObj.image_type = image_type;							//image table image type
	nowObj.max_row = (image_type == "gellery")?max_row/5:max_row;	//image table row count
	nowObj.max_cell = (image_type == "gellery")?5:1;		//image table cell count
	nowObj.left = (image_type == "gellery")?30:25;			//image table left		
	nowObj.top = 65;										//image table top
	nowObj.imgWidth = (image_type == "gellery")?100:120;	//image table image width
	nowObj.imgHeight = (image_type == "gellery")?70:75;		//image table image height
	nowObj.writer_top = (image_type == "gellery")?0:55;		//image table writer top 
	nowObj.date_top = (image_type == "gellery")?0:75;		//image table date to
	nowObj.isPop = 'Y';
	nowObj.contentNum = max_row;
	return nowObj;
}

</script>
</head>
<body>
	<!-- tab type -->
	<table class='ui-widget' width="100%" style="font-size: 13px;">
		<tr>
			<td>
				Tab Type :
				<select id="selTabType" style="margin-left:5px;" onchange="clickContentPage(1)"></select>
			</td>
			<td width="400px;">
				<div id='viewKind'>
					View Kind :
					<input type="radio" id="pop_both"  name="popKindRadio" value="both"  onchange="clickContentPage(1)">Image+Video
					<input type="radio" id="pop_image" name="popKindRadio" value="image" onchange="clickContentPage(1)">Image
					<input type="radio" id="pop_video" name="popKindRadio" value="video" onchange="clickContentPage(1)">Video
				</div>
			</td>
			<td>
				View Type :
				<input type="radio"id="pop_list" name="popRadio" value="list" onchange="clickContentPage(1)">List
				<input type="radio" id="pop_gellery" name="popRadio" value="gellery" onchange="clickContentPage(1)">Gellery
			</td>
			<td>
				<select id="selContentNum" style="margin:7px 10px 5px 10px;" onchange="clickContentPage(1);">
					<option value="5" selected="selected">5개씩</option>
					<option value="10">10개씩</option>
					<option value="15">15개씩</option>
					<option value="20">20개씩</option>
					<option value="30">30개씩</option>
					<option value="40">40개씩</option>
					<option value="50">50개씩</option>
				</select>
			</td>
		<tr>
		<tr>
			<td colspan="4">
				<table class='ui-widget' id="content_list_table_pop" width="100%" style="margin-top:10px;"></table>
			</td>
		</tr>
	</table>
</body>
</html>