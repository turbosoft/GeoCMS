<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");				//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");			//로그인 token

String viewPageNum = request.getParameter("viewPageNum");	//now view page number
String urlText = request.getParameter("urlText");			//url
String nowProIdx = request.getParameter("nowProIdx");		//now project idx
%>

<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var contentNowPageNum = "<%=viewPageNum%>";		//현재 페이지 번호
var contentNowType = "";						//현재 리스트 타입 [gellery, list]
var contentCountNum = 0;						//현재 view count
var contentViewKind = "";						//현재 view kind [image_video, image, video]
var urlText = "<%=urlText%>";					//현재 base url
var contentnowProName = "";						//현재 탭 이름
var contentnowProIdx = "<%=nowProIdx%>";		//현재 탭 인덱스
var pop_proArr = new Array();					//content tab array

var cListSelContentNum = [5, 10, 15, 20, 30, 40, 50];
var cGellerySelContentNum = [7, 14, 21, 28, 35, 42, 49];

$(function(){
	getProjectNameList();
	
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
	for(var i=0;i<pop_proArr.length;i++){
		innerHTMLStr += '<option>'+ pop_proArr[i] +'</option>';
	}
	$('#selTabType').append(innerHTMLStr);
	$('#selTabType').val(contentnowProName);
	
	viewSelectSetting();
	clickContentPage(contentNowPageNum);
});

function getProjectNameList() {
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	
	if(tmpLoginId == null || tmpLoginId == '' || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	var tmpPageNum = '&nbsp';
	var tmpContentNum = '&nbsp';
	var tmpProjectIdx = '&nbsp';
	var tmpOrderType = '&nbsp';
	
	var Url			= baseRoot() + "cms/getMainProjectList/";
	var param		= "list/"+ tmpLoginToken + "/"+ tmpLoginId + "/"+ tmpPageNum + "/" + tmpContentNum + "/"+ tmpProjectIdx +"/"+ tmpOrderType;
	var callBack	= "?callback=?";
	pop_proArr = new Array();
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				result = data.Data;
				if(result != null && result.length > 0){
					for(var i=0;i<result.length; i++){
						pop_proArr.push(result[i].projectname);
						if(result[i].idx == contentnowProIdx){
							contentnowProName = result[i].projectname;
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

function viewSelectSetting(){
	$('#selContentNum').empty();
	var innerHTMLStr ='';
	var tmpArr = contentNowType == 'list'?cGellerySelContentNum:cListSelContentNum;
	for(var i=0;i<tmpArr.length;i++){
		innerHTMLStr += '<option value="'+ tmpArr[i] +'" ';
		if(i == 0){
			innerHTMLStr += 'checked=true ';
		}
		innerHTMLStr += ' >'+ tmpArr[i] +'</option>';
	}
	$('#selContentNum').append(innerHTMLStr);
}

//게시판 리스트 가져오기
function clickContentPage(pageNum){
	if(pageNum == null || pageNum == '' || pageNum == 'null') return;
	contentNowPageNum = pageNum;
	contentNowType = $('input[name=popRadio]:checked').attr('id').split("_")[1];
	contentCountNum = $('#selContentNum').val();
	contentnowProName = $('#selTabType').val();
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
	tempObj.projectName = contentnowProName;
	tempObj.pageNum = pageNum;
	tempObj.moveUrl = moveUrl;
	
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	
	if(tmpLoginId == null || tmpLoginId == '' || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	var tmpIndex = '&nbsp';
	
	var tmpProjectIndex = 0;
	if(contentnowProName != null && contentnowProName != 'All'){
		tmpProjectIndex = $.inArray(contentnowProName, pop_proArr)+1;
	}
	
	var Url			= baseRoot() + moveUrl;
	var param		= "list/" + tmpLoginToken + "/" + tmpLoginId + "/" + pageNum + "/" + contentCountNum + "/" + tmpProjectIndex + "/" + tmpIndex;
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
			makeTmpObj.projectName = tempObj.projectName;
			makeTmpObj.pageNum = tempObj.pageNum;
			makeTmpObj.moveUrl = tempObj.moveUrl;
			contentListSetup(response, makeTmpObj);

			//페이지 설정
			contentPageSetup(data.DataLen, makeTmpObj);
		}
	});
}

function contentPageSetup(totalRes, obj){

	var totalPage = 1;
	if(totalRes != null){
		if(totalRes % obj.contentNum == 0){
			totalPage = parseInt(totalRes / obj.contentNum);
		}else{
			totalPage = parseInt(totalRes / obj.contentNum)+1;
		}
	}
	//테이블에 페이지 추가
	addContentPageCell(totalPage,obj.pageNum,'pop');
}

//content view table css
function setContentDesign(contentNowType) {
	var target = window.document.getElementById("content_list_table_pop");
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
	if(type != 'pop'){
		target = window.frames[0].document.getElementById("content_list_table_pop");
	}else{
		target = document.getElementById("content_list_table_pop");
	}

	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '3';

	var innerHTMLStr = "<div id='pagingDiv'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}

	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:270px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickContentPage("+(pageGroup-10)+");'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:295px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageCL(\"prev\","+ totalPage +");'></div>";
	}
	
	innerHTMLStr += "<div style='position:absolute;left:300px;text-align:center;width:320px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'><a href="+'"'+"javascript:clickContentPage('"+(i).toString()+"');"+'"';
		innerHTMLStr += " style='padding:2px 4px 0 3px; text-decoration:none;'> ";
		if(pageNum == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900;font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:620px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageCL(\"next\","+ totalPage +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:635px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickContentPage("+ (pageGroup+10)+");'></div>";
	}

	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

function clickMovePageCL(cType, totalPage){
	var movePage = 0;	
	contentNowPageNum = Number(contentNowPageNum);
	if(cType == 'next'){
		if(contentNowPageNum+1 <= totalPage){
			movePage = contentNowPageNum+1;
		}
	}else{
		if(contentNowPageNum > 1){
			movePage = contentNowPageNum-1;
		}
	}
	if(movePage > 0){
		clickContentPage(movePage);
	}
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
	nowObj.max_row = (image_type == "gellery")?max_row/7:max_row;	//image table row count
	nowObj.max_cell = (image_type == "gellery")?7:1;		//image table cell count
	nowObj.left = (image_type == "gellery")?30:25;			//image table left		
	nowObj.top = 65;										//image table top
	nowObj.imgWidth = (image_type == "gellery")?100:120;	//image table image width
	nowObj.imgHeight = (image_type == "gellery")?110:75;	//image table image height
	nowObj.writer_top = (image_type == "gellery")?0:55;		//image table writer top 
	nowObj.date_top = (image_type == "gellery")?0:75;		//image table date to
	nowObj.contentNum = max_row;
	return nowObj;
}

//이미지 리스트 설정
function contentListSetup(pure_data, obj) {
	//전달할 각 속성을 배열에 저장
	var id_arr = new Array();
	var title_arr = new Array();
	var content_arr = new Array();
	var file_url_arr = new Array();
	var udate_arr = new Array();
	var idx_arr = new Array();
	var lat_arr = new Array();
	var lon_arr = new Array();
	var thumbnail_url_arr = new Array();
	var origin_url_arr = new Array();
	var dataKind_arr = new Array();
	var projectUserId_arr = new Array();
	var status_arr = new Array();
	
	if(pure_data != null && pure_data.length > 0){
		for(var i=0; i<pure_data.length; i++) {
			id_arr.push(pure_data[i].id);		//id 저장
			title_arr.push(pure_data[i].title);	//title 저장
			content_arr.push(pure_data[i].content);	//content 저장
			file_url_arr.push(pure_data[i].filename); //fileName 저장
			udate_arr.push(pure_data[i].u_date);	//udate 저장
			idx_arr.push(pure_data[i].idx); //idx 저장

			lat_arr.push(pure_data[i].latitude);
			lon_arr.push(pure_data[i].longitude);
			thumbnail_url_arr.push(pure_data[i].thumbnail);
			origin_url_arr.push(pure_data[i].originname);
			dataKind_arr.push(pure_data[i].datakind);	// GeoPhoto, GeoVideo
			projectUserId_arr.push(pure_data[i].projectUserId);	// project user id
			status_arr.push(pure_data[i].status);	// file upload status
		}
	}
	
	//부족한 데이터는 "" 로 채운다
	var max_row = obj.max_row;
	var max_cell = obj.max_cell;
	if((max_row * max_cell) > id_arr.length) {
		for(var i = id_arr.length; i < (max_row*max_cell); i++) {
			id_arr.push("");
			title_arr.push("");
			content_arr.push("");
			file_url_arr.push("");
			udate_arr.push("");
			idx_arr.push("");
		}
	}
	//테이블 초기화
	$('#'+obj.table_name+" tr").remove();
	
	//테이블에 데이터 추가
	addcontentPopImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr, obj);
}

//left content list data add
function addcontentPopImageDataCell(id_arr, title_arr, content_arr, file_url_arr, udate_arr, idx_arr, lat_arr, lon_arr, thumbnail_url_arr, origin_url_arr, dataKind_arr, projectUserId_arr, status_arr, obj){
	var target = document.getElementById(obj.table_name);
	var max_row = obj.max_row;
	var max_cell = obj.max_cell;
	var blankImg = '<c:url value="/images/geoImg/blank(100x70).PNG"/>';

	var thumbnail_arr = new Array();
	//xml file check
	for(var i=0;i<file_url_arr.length;i++){
		var thumbnail_arr_data = loadXMLMain(file_url_arr[i], dataKind_arr[i]);
		thumbnail_arr.push(thumbnail_arr_data);
	}
	
	var imgWidth = obj.imgWidth;		//image width
	var imgHeight = obj.imgHeight;		//image height
	var img_type = obj.image_type;		//image type
	
	$('#'+obj.table_name).attr("border","0");
	
	var tmpMakerImg = 'images';
	target = window.frames[1].document.getElementById(obj.table_name);
	tmpMakerImg = '../images';
	
	for(var i=0; i<id_arr.length; i++) {

		var localAddress = ftpBaseUrl() + "/" + dataKind_arr[i];
		if(dataKind_arr[i] == "GeoPhoto"){
			var tmpThumbFileName = file_url_arr[i].split('.');
			localAddress += "/"+tmpThumbFileName[0] +'_thumbnail.png';
			
		}else if(dataKind_arr[i] == "GeoVideo"){
			localAddress += "/"+thumbnail_url_arr[i];
		}
		
 		//image add
		var img_row;
		if(i % max_cell == 0){
			img_row = target.insertRow(-1);
		}
		
		var img_cell = img_row.insertCell(-1);
		var innerHTMLStr = "";
		if(id_arr[i]=="" && title_arr[i]=="" && content_arr[i]=="" && file_url_arr[i]=="") {	//등록한 이미지가 없을때
			innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:3px solid gray'/>";
			 if(img_type == "gellery"){innerHTMLStr += "<div style='margin-left: 10px;font-size:12px;border: 3px solid gray;width: 100px;line-height: 20px;margin-top: -13px;'>&nbsp&nbsp&nbsp</div>";}
			img_cell.innerHTML = innerHTMLStr;
		}else{
			innerHTMLStr += "<a class='imageTag' href='javascript:;' onclick="+'"';
			if(dataKind_arr[i] == "GeoPhoto"){
				innerHTMLStr += "parent.imageViewer('"+file_url_arr[i]+"','"+ id_arr[i] +"','"+ idx_arr[i] +"','"+projectUserId_arr[i]+"');";
			}else if(dataKind_arr[i] == "GeoVideo"){
				innerHTMLStr += "parent.videoViewer('"+file_url_arr[i]+"', '"+ origin_url_arr[i]+"','"+ id_arr[i] +"','"+ idx_arr[i] +"','"+projectUserId_arr[i]+"');";
			}

			innerHTMLStr += '"'+" title='TITLE : "+ title_arr[i] +"\nCONTENT : "+ content_arr[i] +"' border='0'>";
			//image or video icon add
			innerHTMLStr += "<div style='position:absolute; width:30px; height:30px; margin:15px 0 0 15px;  background-image:url(<c:url value='"+tmpMakerImg+"/geoImg/"+ dataKind_arr[i] +"_marker.png' />); zoom:0.7;'></div>";
			//xml file check icon add
			if(thumbnail_arr[i] == 1){
				var tempTop = 63;
				var tempLeft = 116;
				var tempXmlImg = 'xmlFile_w.png';
				if(img_type == 'gellery'){
					tempTop = 129;
					tempLeft = 94; 
					tempXmlImg = 'xmlFile_b.png';
				}
				innerHTMLStr += "<div></div>"
				innerHTMLStr += "<div style='position:absolute; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px; background-image:url(<c:url value='"+tmpMakerImg+"/geoImg/btn_image/"+tempXmlImg+"'/>);background-repeat: no-repeat;background-size: 15px 20px;'></div>";
			}
			
			innerHTMLStr += "<img class='round' src='"+localAddress+"' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' style='border:3px solid gray'/>";
			
			innerHTMLStr += "</a>";
			
			var tempWriter = (img_type == "list")?"style='position: absolute; left: 150px; margin-top:-50px; font-size:12px;'":"";	//list type인 경우 작성자명 위치 설정
			var tempDate = (img_type == "list")?"style='position: absolute; left: 150px; margin-top:-30px; font-size:12px;'":"style='margin-left: 10px; font-size:12px;'";	//list type인 경우 날짜 위치 설정
			if(img_type == "list"){
				innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-70px; font-size:12px;'>&nbsp;Writer : "+id_arr[i]+"</div>";
				innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-50px; font-size:12px;'>&nbsp;Date : "+udate_arr[i]+"</div>";
				var tmpTtText = title_arr[i];
				if(tmpTtText != null && tmpTtText != ''){
					tmpTtText = tmpTtText.length>30?tmpTtText.substring(0,28)+'...':tmpTtText;
				}
				innerHTMLStr += "<div style='position: absolute; left: 160px; margin-top:-30px; font-size:12px;'  title='"+ title_arr[i] +"'>&nbsp;Title : "+tmpTtText+"</div>";
			}else{
				innerHTMLStr += "<div style='margin-left: 10px;font-size:12px;border: 3px solid gray;width: 100px;line-height: 25px;margin-top: -13px;'>&nbsp;"+udate_arr[i]+"</div>";
			}
			
			img_cell.innerHTML = innerHTMLStr;
		}
	}
}

</script>
</head>
<body>
	<!-- tab type -->
	<table width="100%" style="font-size: 13px;">
		<tr style="background-color: #066ab0; color: white; border: 5px solid #066ab0;">
			<td>
				Tab Type :
				<select id="selTabType" style="margin-left:5px; width: 170px;" onchange="clickContentPage(1)"></select>
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
				<input type="radio"id="pop_list" name="popRadio" value="list" onchange="viewSelectSetting(); clickContentPage(1);">List
				<input type="radio" id="pop_gellery" name="popRadio" value="gellery" onchange="viewSelectSetting(); clickContentPage(1);">Gellery
			</td>
			<td>
				<select id="selContentNum" style="margin:7px 10px 5px 10px;" onchange="clickContentPage(1);">
				</select>
			</td>
		</tr>
		<tr>
			<td colspan="4">
				<table id="content_list_table_pop" width="100%" style="margin-top:10px;"></table>
			</td>
		</tr>
	</table>
</body>
</html>