<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
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
</style>
<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var proContentNum = 12;
var proType = '';
var proIdx = 1;
var proEdit = 0;

function projectGroupListSetup(response, projectType){
// 	alert(JSON.stringify(response));
	$('#project_list_table').empty();
	proType = projectType;
	proIdx = response[0].IDX;
	addProjectGroupCell(response);
}

//project group list
function addProjectGroupCell(response){
	var innerHTML = '';
	
	for(var i=0;i<response.length;i++){
		var proShare = '';
		if(response[i].SHARE == '1'){
			proShare = '전체공개';
		}else if(response[i].SHARE == '0'){
			proShare = '비공개';
		}else{
			proShare = '선택공개';
		}
		
		var projectNameTxt = response[i].PROJECTNAME.length>20? response[i].PROJECTNAME.substring(0,20)+'...' : response[i].PROJECTNAME;
		
		innerHTML += '<div id="pName_'+ response[i].IDX +'" >';
		innerHTML += '<div onclick="fnProjectDiv(this,'+response[i].IDX+');"';
		if(i == 0){
			innerHTML += 'class="onProjectDiv"';
		}else{
			innerHTML += 'class="offProjectDiv"';
		}
		innerHTML += '><label class="m_l_10">'+ projectNameTxt +'</label>';
		//edit btn
		innerHTML += '<button onclick="editProject('+ response[i].IDX +');"> EDIT </button>';
		innerHTML += '</div>';
		
		innerHTML += '<div class="m_l_15">';
		innerHTML += '<table><tr><td>작성자</td><td><label>'+ response[i].ID + '</label></td><td>등록일</td><td><label class="m_l_10">' + response[i].UDATE + '</label></td>';
		innerHTML += '<td><label>'+ proShare + '</label></td></tr>';
		innerHTML += '</table></div>';
		
		innerHTML += '<table id="pChild_'+ response[i].IDX + '" style="border:1px solid gray; width:100%;"/>';
		innerHTML += '</div>';
	}
	$('#project_list_table').append(innerHTML);
	clickProjectPage(1,proIdx);
}

//project group open close
function fnProjectDiv(obj, projectIdx){
	if(proEdit == 1){
		return;
	}
	
	if($(obj).hasClass('onProjectDiv')){
		$(obj).removeClass('onProjectDiv');
		$(obj).addClass('offProjectDiv');
		$('#pChild_'+ projectIdx).empty();
	}else{
		$(obj).removeClass('offProjectDiv');
		$(obj).addClass('onProjectDiv');
		proIdx = projectIdx;
		clickProjectPage(1,proIdx);
	}
}

//페이지 선택
function clickProjectPage(pageNum, tmpProIdx){
// 	alert(loginToken + "/" + loginId + "/" + proType + "/" + tmpProIdx + "/" + pageNum + "/" + proContentNum);
	var Url			= baseRoot() + "cms/getProject/";
	var param		= loginToken + "/" + loginId + "/" + proType + "/" + tmpProIdx + "/" + pageNum + "/" + proContentNum;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
// 			alert(JSON.stringify(data));
			if(response != null && response != '' && data.Code == '100'){
				proIdx = tmpProIdx;
				addProjectChildCell(response, pageNum);
				
				//페이지 설정
				var dataLen = 1;
				if(data.DataLen != null && data.DataLen != "" && data.DataLen != "null"){
					dataLen = data.DataLen;
					//총 페이지 계산
					var min = 1;
					var max = 12;
					var totalPage = 1;
					if(dataLen % max == 0){
						totalPage = parseInt(dataLen / max);
					}else{
						totalPage = parseInt(dataLen / max)+1;
					}
					//테이블에 페이지 추가
					addProjectPageCell(totalPage, pageNum);
				}
			}else{
				jAlert(data.Message, '정보');
			}
		}
	});
}

function addProjectChildCell(response, pageNum){
	var nowPChild = 'pChild_'+ proIdx;
	$('#'+nowPChild).empty();
	var target = document.getElementById(nowPChild);
	
	var blankImg = 'images/blank(100x70).PNG';

	var imgWidth = 70;		//image width
	var imgHeight = 50;		//image height
	var max_cell = 4;
	
// 	$('#'+ nowPChild).attr("border","1");
	var totalLan = response.length%4 == 0?response.length:response.length + (4-response.length%4);
	
	for(var i=0; i<totalLan; i++) {
// 		alert(JSON.stringify(response[i]));
		//타입 별 file 주소 설정
		
		var localAddress = '';
		if(response[i] != null && response[i] != '' && response[i] != undefined){
			localAddress = "http://"+location.host + '/'+ response[i].DATAKIND + '/upload/'; //이미지 주소
			if(response[i].DATAKIND == "GeoPhoto"){
				localAddress += response[i].FILENAME;
			}else if(response[i].DATAKIND == "GeoVideo"){
				localAddress += response[i].THUMNAIL;
			}
		}
		
		//image add
		var img_row;
		if(i % max_cell == 0){
			img_row = target.insertRow(-1);
		}
		
		var img_cell = img_row.insertCell(-1);
		var innerHTMLStr = '';
		
		if(response[i] == null || response[i] == '' || response[i] == undefined) {	//등록한 이미지가 없을때
// 			innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:2px solid #888888'/>";
			innerHTMLStr += "<div style='width:" + imgWidth + "px; height:" + imgHeight + "px;'></div>";
			innerHTMLStr += "<div>&nbsp&nbsp&nbsp</div><div>&nbsp&nbsp&nbsp</div>";
			img_cell.innerHTML = innerHTMLStr;
		}else{
			innerHTMLStr += "<a class='imageTag' href='javascript:;' onclick="+'"';
			var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
			tempArr.push(response[i].LATITUDE);
			tempArr.push(response[i].LONGITUDE);
			tempArr.push(response[i].FILENAME);
			tempArr.push(response[i].IDX);
			tempArr.push(response[i].DATAKIND);
			tempArr.push(response[i].ORGINNAME);
			tempArr.push(response[i].THUMNAIL);
			tempArr.push(response[i].ID);
			innerHTMLStr += "mapCenterChange('"+ tempArr +"');";
			innerHTMLStr += '"'+" title='제목 : "+ response[i].TITLE +"\n내용 : "+ response[i].CONTENT +"\n작성자 : "+ response[i].ID +"\n작성일 : "+ response[i].UDATE +"' border='0'>";
			//image or video icon add
			innerHTMLStr += "<div style='position:absolute; width:30px; height:30px; margin:15px 0 0 15px;  background-image:url(images/"+ response[i].DATAKIND +"_marker.png); zoom:0.7;'></div>";
			//xml file check icon add
			if(loadXML(response[i].FILENAME, response[i].DATAKIND) == 1){
// 				var tempTop = 54;
// 				var tempLeft = 84;
				var tempTop = 24;
				var tempLeft = 54;
				innerHTMLStr += "<div style='position:absolute; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:30px; height:30px; background-image:url(images/thumbnail.png);'></div>";
			}
			innerHTMLStr += "<img class='round' src='"+ localAddress +"' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' style='border:2px solid #888888'/>";
			
			innerHTMLStr += "</a>";
			
// 			innerHTMLStr += "<div class='f_s_12'>&nbsp;Writer : "+ response[i].ID +"</div>";
// 			innerHTMLStr += "<div class='f_s_12'>&nbsp;Date : "+ response[i].UDATE +"</div>";
		}
		img_cell.innerHTML = innerHTMLStr;
	}
}

//테이블에 페이지 추가
function addProjectPageCell(totalPage, pageNum) {
	var target = document.getElementById('pChild_'+ proIdx);
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '4';
	cell.height = '18px';
	
	var innerHTMLStr = "<div id='pagingDiv_" + proIdx + "' style='height:18px;'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;font-size:14px;left:20px;' onclick='moveNextAdd("+ totalPage+","+ (pageGroup-10)+","+proIdx+");'> prev </div>";
	}
	innerHTMLStr += "<div style='position:absolute;font-size:14px;left:40px;text-align:center;width:301px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'>[<a href="+'"'+"javascript:clickProjectPage('"+(i).toString()+"',"+proIdx+");"+'"';
		innerHTMLStr += " style='text-decoration:none;'><font color='#000' "
		if(pageNum == i){
			innerHTMLStr += "style='font-weight:900'";
		}
		innerHTMLStr += ">";
		innerHTMLStr += (i).toString()+"</font></a>]</font>";
	}
	innerHTMLStr += "</div>";
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;font-size:14px;width:40px;left:341px;' onclick='moveNextAdd("+ totalPage+","+ (pageGroup+10)+","+proIdx+");'> next </div>";
	}
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

//move pageGroup : prev, next
function moveNextAdd(totalPage, pageNum, projectIdx){
	proIdx = projectIdx;
	$('#pChild_'+ proIdx).empty();
	addProjectPageCell(totalPage, pageNum);
}

function openAddProjectName(){
	$('#projectNameAddDig').dialog('open');
}

function editProject(projectIdx){
	proEdit = 1;
	contentViewDialog = jQuery.FrameDialog.create({
		url: 'project_deit.jsp?projectIdx='+projectIdx+'&nowTabName='+tempTabName+'&tabArr='+tabArr +'&urlText='+b_url+'&selBoardNum='+selBoardNum,
		width: 960,
		height: 650,
		buttons: {},
		autoOpen:false
	});
	$('.ui-dialog-titlebar').attr('class', 'ui-dialog-titlebar');
	$('.ui-dialog-title').remove();
	$('.ui-dialog').attr('id', 'board_dig');
	contentViewDialog.dialog('open');
}

</script>
<div>
	<label>My Project</label>
	<button class='create_button' onclick='openAddProjectName();'>ADD</button>
</div>
<div id="project_list_table">

</div>
