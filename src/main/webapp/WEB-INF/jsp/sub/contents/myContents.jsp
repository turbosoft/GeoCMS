<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
%>
<style>
.m_l_10
{
	margin-left: 10px;
}

.m_l_15
{
	margin-left: 15px;
}

.onProjectDiv
{
	background-color: #00BCD4;
	color: white;
	font-weight: bold;
}

.offProjectDiv
{
	background-color: gray;
	color: white;
	font-weight: normal;
}

.f_s_12
{
	font-size:12px;
}

.cmsTabDiv
{
	height: 25px;
	background-color: black;
}

.cmsTabDiv :FIRST-CHILD 
{
	font-size: 15px;
	font-weight: bold;
/* 	color: #37c2c0; */
	color: #eff5fa;
}
</style>
<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var myContentsNum = 12;
// var myContentsType = '';
var removeMode = 0;
var myContentRemoveArr = new Array();
var contentNowPageNum = 1; 					//현재 페이지

function myContentsListSetup(){
// 	myContentsType = myCType;
	
	clickMyContentPage('GeoCMS', 1);
	clickMyContentPage('GeoPhoto', 1);
	clickMyContentPage('GeoVideo', 1);
	
	removeModeOnOff(false);

	myContentsMarks();
}

//페이지 선택
function clickMyContentPage(callType, pageNum){
	$('#'+ callType +'_list_table tr').remove();
	
	if(callType == 'GeoCMS'){
		myContentsNum = 5;
	}else{
		myContentsNum = 12;
	}
	
	var Url			= baseRoot() + 'cms/getMyContents/';
	var param		= callType + "/" + loginToken +"/" + loginId +"/" + pageNum + "/" + myContentsNum;
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
				addMyContentsCell(callType, response);
				
				//페이지 설정
				var dataLen = 1;
				if(data.DataLen != null && data.DataLen != "" && data.DataLen != "null"){
					dataLen = data.DataLen;
					//총 페이지 계산
					var min = 1;
					var totalPage = 1;
					if(dataLen % myContentsNum == 0){
						totalPage = parseInt(dataLen / myContentsNum);
					}else{
						totalPage = parseInt(dataLen / myContentsNum)+1;
					}
					//테이블에 페이지 추가
					addMyContentsPageCell(callType, totalPage, pageNum);
				}
			}else{
// 				jAlert(data.Message, '정보');
			}
		}
	});
}

function addMyContentsCell(callType, response){
	var target = document.getElementById(callType +'_list_table');
	var blankImg = 'images/geoImg/blank(100x70).PNG';

	var imgWidth = 70;		//image width
	var imgHeight = 50;		//image height
	var max_cell = 4;
	if(callType == 'GeoCMS'){
		max_cell = 3;
	}
	
	var nowCnt = 0;
	for(var i=0; i<myContentsNum; i++) {
		
		//타입 별 file 주소 설정
		var localAddress = '';
		if(response[i] != null && response[i] != '' && response[i] != undefined){
			localAddress = 'upload/'+response[i].DATAKIND;
			if(response[i].DATAKIND == "GeoPhoto"){
				localAddress += '/'+response[i].FILENAME;
			}else if(response[i].DATAKIND == "GeoVideo"){
				localAddress += '/'+response[i].THUMBNAIL;
			}
		}
		
		//image add
		var img_row;
		if(nowCnt % max_cell == 0){
			img_row = target.insertRow(-1);
		}
		nowCnt++;
		var img_cell = img_row.insertCell(-1);
		var innerHTMLStr = '';
		var tempArr = new Array; //mapCenterChange에 넘길 객체 생성

		if(response[i] == null || response[i] == '' || response[i] == undefined) {
			if(callType == 'GeoCMS'){
				img_row.setAttribute('style', 'height:20px');
				img_cell.setAttribute('colspan', '3');
				nowCnt = nowCnt + 2;
				
				img_row = target.insertRow(-1);
				img_cell = img_row.insertCell(-1);
				img_row.setAttribute('style', 'height:1px;');
				img_row.setAttribute('bgcolor', '#FFFFFF');
				img_cell.setAttribute('colspan', '3');
			}else{
				innerHTMLStr += "<div style='width:93px; height:72px;'></div>";
				img_cell.innerHTML = innerHTMLStr;
			}
		}else{
			if(response[i].DATAKIND == 'GeoCMS'){
				if(nowCnt == 1){
					img_row.setAttribute('style', 'height:20px');
					img_cell.setAttribute('width', '230');
					img_cell.innerHTML = '제목';
					
					img_cell = img_row.insertCell(-1);
					img_cell.setAttribute('width', '100');
					img_cell.innerHTML = '작성자';
					
					img_cell = img_row.insertCell(-1);
					img_cell.setAttribute('width', '80');
					img_cell.innerHTML = '작성일';
					
					img_row = target.insertRow(-1);
					img_cell = img_row.insertCell(-1);
					img_row.setAttribute('style', 'height:1px;');
					img_row.setAttribute('bgcolor', '#D2D2D2');
					img_cell.setAttribute('colspan', '3');
					
					img_row = target.insertRow(-1);
					img_cell = img_row.insertCell(-1);
					img_row.setAttribute('style', 'height:1px;');
					img_row.setAttribute('bgcolor', '#82B5DF');
					img_cell.setAttribute('colspan', '3');
					
					img_row = target.insertRow(-1);
					img_cell = img_row.insertCell(-1);
				}
				img_row.setAttribute('id', 'GeoCMS_' + response[i].IDX);
				img_row.setAttribute('onclick', 'boardViewDetail(this);');
				img_row.setAttribute('style', 'height:20px');
				var titleStr = response[i].TITLE;
				if(titleStr != null && titleStr.length > 15){
					titleStr = titleStr.substring(0,15) + "...";
				}
				
				img_cell.innerHTML = titleStr;
				nowCnt++;
				
				img_cell = img_row.insertCell(-1);
				img_cell.innerHTML = response[i].ID;
				nowCnt++;
				
				img_cell = img_row.insertCell(-1);
				img_cell.innerHTML = response[i].U_DATE;
				
				img_row = target.insertRow(-1);
				img_cell = img_row.insertCell(-1);
				img_row.setAttribute('style', 'height:1px;');
				img_row.setAttribute('bgcolor', '#D2D2D2');
				img_cell.setAttribute('colspan', '3');
				
// 				innerHTMLStr += "<a class='searchTag' href='javascript:;' onclick="+'"'+"boardViewDetail(this);"+'"'+" title='제목 : "+ response[i].TITLE+"\n내용 : "+ response[i].CONTENT+"' border='0' id='GeoCMS_"+ response[i].IDX +"'>";
// 				innerHTMLStr += "<img src='images/blank(100x70).PNG' width='70' height='50' hspace='10' vspace='10' border='3' style='border-color:#888888'/>";
			}else{
				innerHTMLStr += "<a class='imageTag' id='"+ response[i].DATAKIND +"_"+ response[i].IDX +"' href='javascript:;' onclick="+'"';
				tempArr.push(response[i].LATITUDE);
				tempArr.push(response[i].LONGITUDE);
				tempArr.push(response[i].FILENAME);
				tempArr.push(response[i].IDX);
				tempArr.push(response[i].DATAKIND);
				tempArr.push(response[i].ORGINNAME);
				tempArr.push(response[i].THUMNAIL);
				tempArr.push(response[i].ID);
				innerHTMLStr += "myContentCenterChange('"+ tempArr +"','"+ response[i].DATAKIND + "', 'load');";
				innerHTMLStr += '"'+" title='제목 : "+ response[i].TITLE +"\n내용 : "+ response[i].CONTENT + "\n작성일 : "+ response[i].U_DATE +"' border='0'>";

				//image or video icon add
				innerHTMLStr += "<div style='position:absolute; width:30px; height:30px; margin:15px 0 0 15px;  background-image:url(<c:url value='images/geoImg/"+ response[i].DATAKIND +"_marker.png'/>); zoom:0.7;'></div>";
				//xml file check icon add
				if(loadXML(response[i].FILENAME, response[i].DATAKIND) == 1){
//	 				var tempTop = 54;
//	 				var tempLeft = 84;
					var tempTop = 24;
					var tempLeft = 54;
					innerHTMLStr += "<div style='position:absolute; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:30px; height:30px; background-image:url(images/geoImg/thumbnail.png);'></div>";
				}
				innerHTMLStr += "<img class='round' src='<c:url value='"+ localAddress +"'/>' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' style='border:2px solid #888888'/>";
				innerHTMLStr += "</a>";
				img_cell.innerHTML = innerHTMLStr;
			}

			$('#'+response[i].DATAKIND +"_"+ response[i].IDX).contextMenu('context1', {
				bindings: {
//					'context_modify': function(t) { inputCaption(t.id, text); },
					'context_delete': function(t) {
						jConfirm('정말 삭제하시겠습니까?', '정보', function(type){
							if(type) {
//								contentDelete(t.id.split("_")[1]);
								contentDelete(t.id.split("_")[0], t.id.split("_")[1]);
							}
						});
					}
				}
			});
		}
		
		//remove arr draw
		if(removeMode == 1){
			var thisIndex = $.inArray(response[i].DATAKIND +"_"+ response[i].IDX, myContentRemoveArr);
			if(thisIndex > -1){
				myContentCenterChange("'"+ tempArr +"'", response[i].DATAKIND, 'draw');
			}
		}
	}
}

function addMyContentsCellBoard(callType, response){
	
	var innerHTMLStr = "";
	for(var i=0; i<myContentsNum; i++) {
		if(i == 0){
			innerHTMLStr += "<tr style='height:20px;'>";
			innerHTMLStr += "<td width='200'>제목</td>";
			innerHTMLStr += "<td width='70'>작성자</td>";
			innerHTMLStr += "<td width='100'>작성일</td>";
			innerHTMLStr += "<tr height='1' bgcolor='#D2D2D2'><td colspan='3'></td></tr>";
			innerHTMLStr += "<tr height='1' bgcolor='#82B5DF'><td colspan='3'></td></tr>";
		}
		if(response[i] == null || response[i] == '' || response[i] == undefined) {
			innerHTMLStr += "<tr style='height:20px;'><td colspan='3'></td></tr>";
			innerHTMLStr += "<tr height='1' bgcolor='white'><td colspan='3'></td></tr>";
		}else{
			var titleStr = response[i].TITLE;
			if(titleStr != null && titleStr.length > 15){
				titleStr = titleStr.substring(0,15) + "...";
			}

			innerHTMLStr += "<tr style='text-align:center;height:20px;' onclick='boardViewDetail(this);' id='GeoCMS_" + response[i].IDX + "'>";
			innerHTMLStr += "<td style='text-align:left;'>" + titleStr +"</td><td>" + response[i].ID + " </td><td>" + response[i].U_DATE + "</td>";
			innerHTMLStr += "</tr><tr height='1' bgcolor='#D2D2D2'><td colspan='3'></td></tr>";
		}
	}

	$('#'+callType +'_list_table').append(innerHTMLStr);
	$('#'+callType +'_list_table').attr('border', '0');
	
}

//테이블에 페이지 추가
function addMyContentsPageCell(callType, totalPage, pageNum) {
// 	var target = document.getElementById('myContent_list_table');
	var target = document.getElementById(callType +'_list_table');
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '4';
// 	cell.height = '18px';
	contentNowPageNum = pageNum;
	
	var innerHTMLStr = "<div id='pagingDiv_"+ callType +"'>";
	var pageGroup = 0;

	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}

	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:10px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickMyContentPage('"+ callType +"', "+(pageGroup-10)+");'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:35px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageMC(\"prev\","+ totalPage +","+ callType +");'></div>";
	}
	
	innerHTMLStr += "<div style='position:absolute;left:45px;text-align:center;width:320px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'><a href="+'"'+ "javascript:clickMyContentPage('"+ callType +"', "+(i).toString()+");"+'"';
		innerHTMLStr += " style='padding:2px 4px 0 3px; text-decoration:none;'> ";
		
		if(pageNum == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:370px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageMC(\"next\","+ totalPage +","+ callType +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:385px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMyContentPage('"+ callType +"', "+(pageGroup+10)+");'></div>";
	}

	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

function clickMovePageMC(cType, totalPage, callType){
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
		clickMyContentPage(callType, movePage);
	}
}

//move pageGroup : prev, next
// function moveNextAdd(callType, pageNum){
// // 	$('#myContent_list_table tr').remove();
// 	clickMyContentPage(callType, pageNum);
// }

//mycontent get marker
function myContentsMarks(contentsType){
	if(contentsType == 'Board'){
		return;
	}
	
	var tmpPageNum = '&nbsp';
	var tmpContentNum = '&nbsp';
	
	var Url			= baseRoot() + 'cms/getMyContents/';
	var param		= 'marker/' + loginToken +"/" + loginId +"/" + tmpPageNum + "/" + tmpContentNum;
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
				contentMarker(response);
			}else{
// 				jAlert(data.Message+'marker', '정보');
			}
		}
	});
}

function myContentCenterChange(tmpArr, type, contentType){
	var tpAr = tmpArr.split(",");

	if(removeMode == 0){
		mapCenterChange(tmpArr);
	}else{
		var left = Math.floor($('#'+ contentType +"_"+ tpAr[3]).find('img').offset().left);
		var top = Math.floor($('#'+ contentType +"_"+ tpAr[3]).find('img').offset().top);
		top = top-100;
		
		var innerHTML = '';
		innerHTML += '<div style="width:72px;height:54px;background-color:red; opacity:0.5; position:absolute; left:'+ left +'px; top:'+ top +'px;" class="removeOn" id="removeOn_'+ contentType +"_"+ tpAr[3] +'"';
		innerHTML += ' onclick="myContentChkRm(this)" /></div>';
		$('#'+ contentType +"_"+ tpAr[3]).parent().append(innerHTML);
		if(type == 'load'){
			myContentRemoveArr.push(contentType +"_"+ tpAr[3]);
		}
	}
}

function myContentChkRm(obj){
	var thisIndex = $.inArray(obj.id.replace("removeOn_",""), myContentRemoveArr);
	alert('thisIndex : ' + thisIndex + 'obj.id.replace) : ' + obj.id.replace("removeOn_","") + " myContentRemoveArr : " + JSON.stringify(myContentRemoveArr));
	if(thisIndex > -1){
		myContentRemoveArr.splice(thisIndex, 1);
	}
	alert('thisIndex : ' + thisIndex + 'obj.id.replace) : ' + obj.id.replace("removeOn_","") + " myContentRemoveArr : " + JSON.stringify(myContentRemoveArr));
	$(obj).remove();
}

//content remove
function contentDelete(type, tmpIdArr){
	var Url			= baseRoot() + 'cms/deleteContent/';
	var param		= loginToken +"/" + loginId +"/" + type + "/" + tmpIdArr;
	var callBack	= "?callback=?";
	
// 	alert(loginToken +"/" + loginId +"/" + type + "/" + tmpIdArr);
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			if(data.Code == '100'){
				jAlert(data.Message, '정보');
				removeModeOnOff(false);
				clickMyContentPage(type, 1)
// 				myContentsListSetup(myContentsType);
			}else{
				jAlert(data.Message, '정보');
			}
		}
	});
}

function removeMyContent(removeType){
	var tmpRemoveArr = new Array();
	if(myContentRemoveArr != null && myContentRemoveArr.length > 0){
		$.each(myContentRemoveArr, function(idx, val){
			if(val.split("_")[0] == removeType){
				tmpRemoveArr.push(val);
			}
		});
		if(tmpRemoveArr != null && tmpRemoveArr.length > 0){
			contentDelete(removeType, tmpRemoveArr);
		}else{
			jAlert('선택된 content가 없습니다', '정보');
		}
	}else{
		jAlert('선택된 content가 없습니다', '정보');
	}
}

//make content
function myContentsMake(){
// 	var tmpType = myContentsType == 'Both'?'Image':myContentsType;
	ContentsMakes(null,'Image','','');
}

//remove mode on/off
function removeModeOnOff(obj){
	if(obj){
		removeMode = 1;
		$('.removeMyContentBtn').css('display','block');
		$('#makeContents').css('display','none');
	}else{
		removeMode = 0;
		myContentRemoveArr = new Array();
		$('.removeOn').remove();
		$('#removeModeOnOffChk').attr('checked',false);
		$('.removeMyContentBtn').css('display','none');
		$('#makeContents').css('display','block');
	}
}

</script>
<div style="margin-left:10px;display:none;">
	<label>EDIT MODE</label>
	<input type="checkbox" id="removeModeOnOffChk" onclick="removeModeOnOff(this.checked);"/>
<!-- 	<button id="removeMyContentBtn" onclick="removeMyContent();" style="display:none; float:right; margin-right:30px;">remove</button> -->
</div>

<div style="height:800px;">
		<div id="GeoCMS_DIV" class="cmsTabDiv">
			<label style="margin-left:10px;">BOARD</label>
			<button class="removeMyContentBtn" onclick="removeMyContent('GeoCMS');" style="display:none; float:right; margin-right:30px;">remove</button>
		</div>
		<table id="GeoCMS_list_table" style="height: 200px; margin:0 10px;" ></table>
	
		<div id="GeoPhoto_DIV" class="cmsTabDiv">
			<label style="margin-left:10px;">IMAGE</label>
			<button class="removeMyContentBtn" onclick="removeMyContent('GeoPhoto');" style="display:none; float:right; margin-right:30px;">remove</button>
		</div>
		<table id="GeoPhoto_list_table" style="height: 255px;"></table>
	
		<div id="GeoVideo_DIV" class="cmsTabDiv">
			<label style="margin-left:10px;">VIDEO</label>
			<button class="removeMyContentBtn" onclick="removeMyContent('GeoVideo');" style="display:none; float:right; margin-right:30px;">remove</button>
		</div>
		<table id="GeoVideo_list_table" style="height: 255px;"></table>
<!-- 	<table id="myContent_list_table"></table> -->
</div>

<button id="makeContents" onclick="myContentsMake();" style="position:absolute; left:300px; top:780px;">make Contents</button>

<div id="context1" class="contextMenu">
	<ul>
		<li id="context_delete">Delete</li>
	</ul>
</div>
