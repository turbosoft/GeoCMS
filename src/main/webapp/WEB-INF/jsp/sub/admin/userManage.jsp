<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>
<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
String loginType = (String)session.getAttribute("loginType");				//로그인 권한
%>

<script type="text/javascript">
var loginId = '<%=loginId%>';
var loginToken = '<%=loginToken%>';
var loginType = '<%=loginType%>';

var userLevelArr = new Array();
var nowPageNum = 1;
var nowSelUserNum = 10;
$(function() {
	//search reg_date textbox setting
	$('.sDate').datepicker({
		dateFormat: "yymmdd"
	});
	$('.sDate').attr('maxlength', 8);
	$('.sDate').css('width', '100px');
	
	//search type option setting
	getUserLevel();
	
	//search user start
	clickUserPage(1);
});

//get user Level
function getUserLevel(){
	var Url			= baseRoot() + "cms/getbase";
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				var response = data.Data;
				if(response != null && response != ''){
					var data_level = response.userLevel;
					if(data_level != null && data_level != ""){
						var data_arr = new Array();
						data_arr = data_level.split(",");
						for(var i=0; i<data_arr.length; i++) {
							if(data_arr[i] != null && data_arr[i] != ''){
								userLevelArr.push(data_arr[i]);
							}
						}
					}
					var innerHTMLStr = '';
					innerHTMLStr += '<option value="0">--select--</option>';
					for(var j=0; j<userLevelArr.length;j++){
						innerHTMLStr += '<option>'+ userLevelArr[j] +'</option>';
					}
					$('.sTypeClass').append(innerHTMLStr);
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//search user
function clickUserPage(pageNum){
	if($('#userSearchSel').val() == 'REG_DATE'){
		if(($('#startDate').val() != '' && $('#startDate').val().length < 8) || ($('#endDate').val() != '' && $('#endDate').val().length < 8)){
			alert('날짜를 입력해 주십시오./n ex)YYYYMMDD');
			return;
		}
		if($('#startDate').val() != ''){
			var stDate = $('#startDate').val().substring(0,4)+'-'+$('#startDate').val().substring(4,6) + '-'+$('#startDate').val().substring(6,8);
			stDate = new Date(stDate);
			if(isNaN(stDate.getDate())){
				alert('날짜를 입력해 주십시오./n ex)YYYYMMDD');
				return;
			}
		}
		
		if($('#endDate').val() != ''){
			var edDate = $('#endDate').val().substring(0,4)+'-'+$('#endDate').val().substring(4,6) + '-'+$('#endDate').val().substring(6,8);
			edDate = new Date(edDate);
			if(isNaN(edDate.getDate())){
				alert('날짜를 입력해 주십시오./n ex)YYYYMMDD');;
				return;
			}
		}
	}else if($('#userSearchSel').val() == 'TYPE'){
		var sType = $('#searchType').val();
		if(sType == '0'){
			sType ='';
		}
		$('#searchText').val(sType);
	}
	
	nowPageNum = pageNum;
	nowSelUserNum = $('#selUserNum').val();
	
	var searchType	= $('#userSearchSel').val();
	var searchText	= $('#searchText').val();
	var sDate		= $('#startDate').val();
	var eDate		= $('#endDate').val();
	
	if(searchText == null || searchText == '' || searchText == 'null'){
		searchText = '&nbsp';
	}
	if(sDate == null || sDate == '' || sDate == 'null'){
		sDate = '&nbsp';
	}
	if(eDate == null || eDate == '' || eDate == 'null'){
		eDate = '&nbsp';
	}
		
	var Url			= baseRoot() + "cms/searchUser/";
	var param		= loginToken + "/"+ searchType + "/"+ searchText + "/"+ sDate + "/"+ eDate + "/"+ nowPageNum + "/"+ nowSelUserNum;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			
			if(data.Code == '100'){
				$('.searchTR').remove();	//기존 검색 데이터 삭제
				$('.searchChk').attr('checked', false); //체크박스 초기
				var data_line_arr = data.Data;
				
				if(data_line_arr != null && data_line_arr != ''){
					var innerHTMLStr = '';
					var totalCnt = 0;
					
					if(data_line_arr != null && data_line_arr != ""){
						for(var i=0; i<data_line_arr.length; i++) {
							innerHTMLStr += '<tr class="searchTR">';
							innerHTMLStr += '<td align="center"><input type="checkbox" id="chk_'+ i +'" class="searchChk"></td>';	//check
							innerHTMLStr += '<td id="userId_'+ i +'" class="userIdClass">'+ data_line_arr[i].id +'</td>';	//id
							innerHTMLStr += '<td>'+ data_line_arr[i].email +'</td>';	//email
							innerHTMLStr += '<td align="center">'+ data_line_arr[i].R_DATE +'</td>';	//reg_date
							innerHTMLStr += '<td align="center"><select id="userLvSel_'+ i +'">';
							for(var j=0; j<userLevelArr.length;j++){
								innerHTMLStr += '<option ';
								if(userLevelArr[j] == data_line_arr[i].type){
									innerHTMLStr += 'selected="selected"';
								}
								innerHTMLStr += '>'+ userLevelArr[j] +'</option>';
							}
							innerHTMLStr += '</select></td></tr>';	//type
						}
						
						$('#manage_table tr:last').after(innerHTMLStr);
						
						if(data.DataLen != null){
							totalCnt = data.DataLen;
						}
						var totalPage = totalCnt%nowSelUserNum == 0? totalCnt/nowSelUserNum : (totalCnt/nowSelUserNum)+1;
						addUSerPageCell(totalPage);
					}
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//테이블에 페이징 숫자 추가
function addUSerPageCell(totalPage) {
	var target;
	target = document.getElementById("manage_table");
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '5';
// 	cell.height = '18px';
	row.className ='searchTR';
	
	var innerHTMLStr = "<div id='pagingDiv'>";
	var pageGroup = 0;
	if(nowPageNum%10 == 0){
		pageGroup = (nowPageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(nowPageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:160px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickUserPage("+ (pageGroup-10)+");'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:185px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePage(\"prev\","+ totalPage +");'></div>";
	}
	
	innerHTMLStr += "<div style='position:absolute;left:195px;text-align:center;width:320px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'><a href="+'"'+"javascript:clickUserPage('"+(i).toString()+"');"+'"'+'"';
		innerHTMLStr += " style='padding:2px 2px 0 2px; text-decoration:none;'> ";
		if(nowPageNum == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:520px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePage(\"next\","+ totalPage +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:535px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickUserPage("+ (pageGroup+10)+");'></div>";
	}
	
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

function clickMovePage(cType, totalPage){
	var movePage = 0;	
	nowPageNum = Number(nowPageNum);
	if(cType == 'next'){
		if(nowPageNum+1 <= totalPage){
			movePage = nowPageNum+1;
		}
	}else{
		if(nowPageNum > 1){
			movePage = nowPageNum-1;
		}
	}
	if(movePage > 0){
		clickUserPage(movePage);
	}
}

//search type selectBox change
function typeChange(obj){
	var val = obj.value;
	$('#searchText').val('');
	$('#startDate').val('');
	$('#endDate').val('');
	$('#searchType').val('0');
	
	if(val == 'REG_DATE'){
		$('#sDateSpan').css('display','inline-block');
		$('#searchType').css('display','none');
		$('#searchText').css('display','none');
	}else if(val == 'TYPE'){
		$('#sDateSpan').css('display','none');
		$('#searchText').css('display','none');
		$('#searchType').css('display','inline-block');
	}else{
		$('#sDateSpan').css('display','none');
		$('#searchType').css('display','none');
		$('#searchText').css('display','inline-block');
	}
}

//close popup
function manageClose(){
	jQuery.FrameDialog.closeDialog();
}

//all checked
function allCheck(obj){
	if(obj.checked){
		$('.searchChk').attr('checked',true);
	}else{
		$('.searchChk').attr('checked',false);
	}
}

//data type chenge
function typeChangefn(obj){
	$('.searchChk').each(function(idx, val){
		if(val.checked && val.id != null && val.id != ''){
			$('#userLvSel_'+val.id.split('_')[1]).val(obj.value);
		}
	});
	obj.value = '0';
}

//user change type save
function userTypeSave(){
	var saveArr = new Array();
	$('.userIdClass').each(function(idx, val){
		if(val.id != null && val.id != ''){
			var saveObj = new Object();
			var idx = val.id.split('_')[1];
			saveObj.id = $('#'+val.id).text();
			saveObj.type = $('#userLvSel_'+idx).val();
			saveArr.push(saveObj);
		}
	});
	
	if(saveArr == null || saveArr.length == 0){
		return;
	}
	var Url			= baseRoot() + "cms/typeUpdate/";
	var param		= loginToken + "/"+ JSON.stringify(saveArr);
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Message;
			alert(response);
		}
	});
}

</script>

</head>

<body bgcolor="#FFF">
	<table id='manage_table'>
		<tbody>
			<tr>
				<td colspan="5">
				<select id="userSearchSel" onchange="typeChange(this);">
					<option>ID</option>
					<option>EMail</option>
					<option>REG_DATE</option>
					<option>TYPE</option>
				</select>
				<input type='text' id='searchText'>
				<select id="searchType" class="sTypeClass" style="display:none;"></select>
				<span id="sDateSpan" style="display:none;">
					<input type="text" id='startDate' class="sDate">~<input type="text" id='endDate' class="sDate">
				</span>
				<button onclick='clickUserPage(1);'>search</button>
				
				<select class="sTypeClass" style="float:right;margin:2px 10px 0 0;" onchange="typeChangefn(this);"></select>
				<label style="float:right; margin-right:10px;">Change Type : </label>
				</td>
			</tr>
			<tr>
				<th width="30" height="30"><input type="checkbox" onclick="allCheck(this);" class="searchChk"></th>
				<th>ID</th>
				<th>EMail</th>
				<th width="100">Reg_Date</th>
				<th width="90" >TYPE</th>
			</tr>
		</tbody>
	</table>
	
	<div style="postion:absolute; margin-top:-18px;">
		<select id="selUserNum" onchange="clickUserPage(1);">
			<option value="5">5</option>
			<option value="10" selected="selected">10</option>
			<option value="15">15</option>
			<option value="20">20</option>
			<option value="30">30</option>
			<option value="40">40</option>
			<option value="50">50</option>
		</select>
	</div>
	<div style="text-align:center;">
		<button onclick='userTypeSave();'>save</button>
		<button onclick='manageClose();'>cancel</button>
	</div>
</body>
