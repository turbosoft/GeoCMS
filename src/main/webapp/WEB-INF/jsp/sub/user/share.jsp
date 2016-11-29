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

String shareIdx = (String)request.getParameter("shareIdx");					//객체 idx
String shareKind = (String)request.getParameter("shareKind");				//객체 kind
// String showProject = (String)request.getParameter("showProject");			//my project call 여부
%>
<style type="text/css">
.shareTD, .editTD
{
	border:1px solid rgba(128, 128, 128, 0.51);
	padding: 5px;
}

.rmBtn
{
	float: right;
	margin-right: 10px;
}

.txt_center
{
	text-align: center;
}

#searchText
{
	height: 20px;
}

#shareUser_table
{
	margin-top: 12px;
}

#shareUser_table th
{
	background-color: #d6e3ef;
}
</style>

<script type="text/javascript">
var loginId = '<%=loginId%>';
var loginToken = '<%=loginToken%>';

var shareIdx = '<%=shareIdx%>';
var shareKind = '<%=shareKind%>';
<%-- var showProject = '<%=showProject%>'; --%>

var nowpage = 1;
var nowSelUserNum = 10;
// var nowTopNum = 460;				//paging div top

var addShareUser = new Array();		// 공유 유저
var removeShareUser = new Array();	// 삭제 유저

var checkArr = new Array();			//선택 유저
var editYesArr = new Array();		//편집 가능 유저 Y
var editNoArr = new Array();		//편집 가능 유저 N

$(function() {
// 	if(showProject == 'Y'){
// 		$('.shareBtnCls').css('display','none');
// 		nowTopNum = 505;
// 	}

	if(window.parent.$('#clonSharUser').children().length > 0){
		var tmpShareAddVal = window.parent.$('#shareAdd').val();
		if(tmpShareAddVal.length > 0){
			addShareUser = tmpShareAddVal.split(',').map(Number);
		}
		
		var tmpShareRemoveVal = window.parent.$('#shareRemove').val();
		if(tmpShareRemoveVal.length > 0){
			removeShareUser = tmpShareRemoveVal.split(',').map(Number);
		}
		
		var tmpEditYesVal = window.parent.$('#editYes').val();
		if(tmpEditYesVal.length > 0){
			editYesArr = tmpEditYesVal.split(',').map(Number);
		}
		
		var tmpEditNoVal = window.parent.$('#editNo').val();
		if(tmpEditNoVal.length > 0){
			editNoArr = tmpEditNoVal.split(',').map(Number);
		}
		
		
		$('#shareUser_table').remove();
		$('#shareDiv').append(window.parent.$('#shareUser_table').clone());
	}else{
		clickUserPage('first', 1);
	}
});

//search user
function clickUserPage(type, page){
	nowpage = page;
// 	nowSelUserNum = $('#selUserNum').val();
	var searchText	= $('#searchText').val();
	var orderText = 'ASC';
	var tmpIdx = '&nbsp';
	var tmpAddShare = '&nbsp';
	var tmpRemoveShare = '&nbsp';
	
	if(type == 'search' && (searchText == null || searchText == '' || searchText == 'null')){
		jAlert('검색 하실 ID를 입력해 주세요.', '정보');
		return;
	}
	
	if(searchText == loginId){
		return;
	}
	
	if(shareIdx != null && shareIdx != '' && shareIdx != 'null'){
		tmpIdx = shareIdx;
	}
	
	if(shareKind == null || shareKind == '' || shareKind == 'null'){
		shareKind = '&nbsp';
	}
	
	if(type != 'search'){
		searchText = '&nbsp';
	}
	
	if(addShareUser != null && addShareUser.length > 0){
		tmpAddShare = addShareUser;
	}
	
	if(removeShareUser != null && removeShareUser.length > 0){
		tmpRemoveShare = removeShareUser;
	}
	
// 	alert('shareIdx : ' + shareIdx + "  : " +loginToken + "/" + loginId + "/" + searchText + "/"+ nowpage + "/"+ nowSelUserNum + "/" + tmpIdx + "/" + shareKind + "/" + orderText +  "/" + tmpAddShare + "/" +tmpRemoveShare);
	
	var Url			= baseRoot() + "cms/searchShareUser/";
	var param		= loginToken + "/" + loginId + "/" + type + "/" + searchText + "/"+ nowpage + "/"+ nowSelUserNum + "/" + tmpIdx + "/" + shareKind + "/" + orderText +  "/" + tmpAddShare + "/" +tmpRemoveShare;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			
			if(data.Code == '100'){
				var data_line_arr = data.Data;
// 				alert(JSON.stringify(data_line_arr));
				if(data_line_arr != null && data_line_arr != ''){
					if(page != null && type == 'search'){
						if(data.SearchYN == 'Y'){
							jAlert('이미 공유한 사용자 입니다.', '정보');
						}else{
							jConfirm("'"+ searchText +" 를 공개 유저에 추가 하시겠습니까?", '', function(text){
								if(text == true){
									
									makeShareArray('add', data_line_arr[0].UID);
								}
							});
						}
					}else{
						var innerHTMLStr = '';
						var totalCnt = 0;
						$('.shareTR').remove();
						$('.allCheckBox').attr('checked',false);
						$('.allCheckBoxEdit').attr('checked',false);
						
						for(var i=0; i<data_line_arr.length; i++) {
							innerHTMLStr += '<tr class="shareTR" id="shareTR_'+ data_line_arr[i].UID +'">';
							innerHTMLStr += '<td class="shareTD txt_center"><input type="checkbox" ';
							if($.inArray(data_line_arr[i].UID, checkArr) > -1){
								innerHTMLStr += ' checked=true ';
							}
							innerHTMLStr += ' class="shareChk" id="chk_'+ data_line_arr[i].UID +'" onclick="shareChkFn(this);"/></td>';
							
							innerHTMLStr += '<td class="shareTD"><label>'+ data_line_arr[i].ID +'</label></td>';
							
							innerHTMLStr += '<td class="editTD txt_center"><input type="checkbox" ';

							if(data_line_arr[i].SHAREEDIT == 'Y' || $.inArray(data_line_arr[i].UID, editYesArr) > -1){
								innerHTMLStr += ' checked=true ';
							}
							
							innerHTMLStr += ' class="editChk" id="edit_'+ data_line_arr[i].UID +'" onclick="editChkFn(this);"/></td>';
							innerHTMLStr += '</tr">';
						}
						
						$('#shareUser_table tr:last').after(innerHTMLStr);
						
// 						if($('.allCheckBox').attr('checked')){
// 							allCheck(true);
// 						}
						
// 						if($('.allCheckBoxEdit').attr('checked')){
// 							allCheckEdit(true);
// 						}
						
						if(data.DataLen != null){
							totalCnt = data.DataLen;
						}
						var totalPage = totalCnt%nowSelUserNum == 0?totalCnt/nowSelUserNum : (totalCnt/nowSelUserNum)+1
						addUserPageCell(totalPage);
					}
				}
			}else{
				if(page != null && type == 'search'){
					jAlert('해당 사용자가 존재하지 않습니다.', '정보');
				}else if(page != null && type != 'first'){
					jAlert(data.Message, '정보');
				}
			}
		}
	});
}

//checked remove
function shareUserRemove(){
	$.each($('.shareChk'),function(idx, val){
		if(val.checked){
			var vId = val.id.split('_')[1];
			if(vId != null && vId != ''){
				makeShareArray('remove', parseInt(vId));
			}
		}
	});
	
	$.each(checkArr, function(idx, val){
		var tmpIdx = $.inArray(val, addShareUser);
		if(tmpIdx > -1){
			addShareUser.splice(tmpIdx, 1);
		}else{
			removeShareUser.push(val);
		}
	});
	clickUserPage('list', 1);
}

function makeShareArray(makeType, searchUid){
	if(makeType == 'remove'){
		var tmpIdx = $.inArray(searchUid, addShareUser);
		if(tmpIdx > -1){
			addShareUser.splice(tmpIdx, 1);
		}else{
			removeShareUser.push(searchUid);
		}
		
		$('#shareTR_'+searchUid).remove();
		
		//checkArr remove
		tmpIdx = $.inArray(searchUid, checkArr);
		if(tmpIdx > -1){
			checkArr.splice(tmpIdx, 1);
		}
		
		//editYesArr remove
		tmpIdx = $.inArray(searchUid, editYesArr);
		if(tmpIdx > -1){
			editYesArr.splice(tmpIdx, 1);
		}
	}else if(makeType == 'add'){
		var tmpUid = searchUid.UID;
		var tmpIdx = $.inArray(tmpUid, removeShareUser);
		if(tmpIdx > -1){
			removeShareUser.splice(tmpIdx,1);
		}else{
			addShareUser.push(searchUid);
		}
// 		alert(tmpUid + " : "  +tmpIdx + " : removeShareUser : " + JSON.stringify(removeShareUser) + " : addShareUser : " + JSON.stringify(addShareUser));
		clickUserPage('list', 1);
	}
}

function findInUser(findTxt){
	var res = true;
	$.each($('.shareTR'),function(idx, val){
		var nowTxt = $(val).find('label').text();
		if(findTxt == nowTxt){
			res = false;
		}
	});
	return res;
}

//테이블에 페이징 숫자 추가
function addUserPageCell(totalPage) {
	var target;
	target = document.getElementById("shareUser_table");
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '5';
// 	cell.height = '18px';
	row.className ='shareTR';
	
	var innerHTMLStr = "<div id='pagingDiv' style='margin:5px;position:absolute;top:460px;'>";
	var pageGroup = 0;
	if(nowpage%10 == 0){
		pageGroup = (nowpage/10-1)*10+1;
	}else{
		pageGroup = Math.floor(nowpage/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:-10px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickUserPage(\"list\", "+ (pageGroup-10)+");'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:15px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePage(\"prev\","+ totalPage +");'></div>";
	}
	
	innerHTMLStr += "<div style='position:absolute;left:23px;text-align:center;width:280px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'><a href="+'"'+ "javascript:clickUserPage(\'list\', '"+(i).toString()+"');"+'"';
		innerHTMLStr += " style='padding:2px 0 0 2px; text-decoration:none;'> ";
		if(nowpage == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:300px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePage(\"next\","+ totalPage +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:315px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickUserPage(\"list\","+ (pageGroup+10)+");'></div>";
	}
	
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
	
}

function clickMovePage(cType, totalPage){
	var movePage = 0;
	if(cType == 'next'){
		if(nowpage+1 <= totalPage){
			movePage = nowpage+1;
		}
	}else{
		if(contentNowPageNum > 1){
			movePage = nowpage-1;
		}
	}
	if(movePage > 0){
		clickUserPage('list', movePage);
	}
}

//close popup
function shareClose(){
	jQuery.FrameDialog.closeDialog();
}

//checked share
function shareChkFn(obj){
	if(obj.checked){
		checkArr.push(parseInt(obj.id.split("_")[1]));
	}else{
		var tmpIdx = $.inArray(parseInt(obj.id.split("_")[1]), checkArr);
		if(tmpIdx > -1){
			checkArr.splice(tmpIdx, 1);
		}
	}
}

//all checked
function allCheck(objChk){
	if(objChk){
		$('.shareChk').attr('checked',true);
		$.each($('.shareChk'),function(idx, val){
			if(val.id != null && val.id != ''){
				var tmpId = parseInt(val.id.split("_")[1]);
				var tmpIdx = $.inArray(tmpId, checkArr);
				if(tmpIdx < 0){
					checkArr.push(tmpId);
				}
			}
		});
	}else{
		$('.shareChk').attr('checked',false);
		$.each($('.shareChk'),function(idx, val){
			if(val.id != null && val.id != ''){
				var tmpId = parseInt(val.id.split("_")[1]);
				var tmpIdx = $.inArray(tmpId, checkArr);
				if(tmpIdx > -1){
					checkArr.splice(tmpIdx, 1);
				}
			}
		});
	}
}

//checked edit
function editChkFn(obj){
	if(obj.checked){
		var tmpIdx = $.inArray(parseInt(obj.id.split("_")[1]), editNoArr);
		if(tmpIdx > -1){
			editNoArr.splice(tmpIdx, 1);
		}else{
			editYesArr.push(parseInt(obj.id.split("_")[1]));
		}
	}else{
		var tmpIdx = $.inArray(parseInt(obj.id.split("_")[1]), editYesArr);
		if(tmpIdx > -1){
			editYesArr.splice(tmpIdx, 1);
		}else{
			editNoArr.push(parseInt(obj.id.split("_")[1]));
		}
	}
}

//all checked edit
function allCheckEdit(objChk){
	if(objChk){
		$.each($('.editChk'),function(idx, val){
			if(val.id != null && val.id != ''){
				if($(this).attr('checked') != true){
					var tmpId = parseInt(val.id.split("_")[1]);
					var tmpIdx = $.inArray(tmpId, editNoArr);
					if(tmpIdx > -1){
						editNoArr.splice(tmpIdx, 1);
					}else{
						editYesArr.push(tmpId);
					}
				}
			}
		});
		$('.editChk').attr('checked',true);
	}else{
		$.each($('.editChk'),function(idx, val){
			if(val.id != null && val.id != ''){
				if($(this).attr('checked') == true){
					var tmpId = parseInt(val.id.split("_")[1]);
					var tmpIdx = $.inArray(tmpId, editYesArr);
					if(tmpIdx > -1){
						editYesArr.splice(tmpIdx, 1);
					}else{
						editNoArr.push(tmpId);
					}
				}
			}
		});
		$('.editChk').attr('checked',false);
	}
}

function shareUserSave(){
	if($('#shareUser_table tr').length<= 2){
		jAlert('공유 유저를 선택해 주세요', '정보');
		return;
	}
	
	window.parent.$('#shareAdd').val(addShareUser);
	window.parent.$('#shareRemove').val(removeShareUser);
	
	window.parent.$('#editYes').val(editYesArr);
	window.parent.$('#editNo').val(editNoArr);
	
	window.parent.$('#clonSharUser').empty();
	
	window.parent.$('#clonSharUser').append($('#shareUser_table'));
	
	shareClose();
	window.parent.$('input[name=shareRadio]:radio[value="2"]').attr("checked",true);
}

</script>

</head>

<body bgcolor="#FFF">
	<table id='searchUser_table' style="width:100%;">
		<tbody>
			<tr>
				<td colspan="2">
					ID : <input type='text' id='searchText'>
					<button onclick='clickUserPage("search", 1);'>search</button>
					<button onclick='shareUserRemove();' style="float: right; margin-top: 2px;">remove</button>
				</td>
			</tr>
		</tbody>
	</table>
	
	<div id="shareDiv" style="height:395px;">
	<table id='shareUser_table' style="width:100%;">
		<tbody>
			<tr>
				<th width="30" class="shareTD"><input type="checkbox" onclick="allCheck(this.checked);" class="shareChk allCheckBox"></th>
				<th class="shareTD">ID</th>
				<th width="80" class="editTD"><input type="checkbox" onclick="allCheckEdit(this.checked);" class="editChk allCheckBoxEdit">
					<label>편집권한</label>
				</th>
			</tr>
		</tbody>
	</table>
	</div>
	
<!-- 	<select id="selUserNum" onchange="clickUserPage('list', 1);" style="position:absolute; margin-top:48px;"> -->
<!-- 		<option value="5">5개씩</option> -->
<!-- 		<option value="10" selected="selected">10개씩</option> -->
<!-- 		<option value="15">15개씩</option> -->
<!-- 		<option value="20">20개씩</option> -->
<!-- 		<option value="30">30개씩</option> -->
<!-- 		<option value="40">40개씩</option> -->
<!-- 		<option value="50">50개씩</option> -->
<!-- 	</select> -->
		
	<div style="text-align:center; margin-top: 50px;" class="shareBtnCls">
		<button onclick='shareUserSave();'>ok</button>
		<button onclick='shareClose();'>cancel</button>
	</div>
</body>
