<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>
<script type="text/javascript">

//search dialog 닫기
function findClose(){
	jQuery.FrameDialog.closeDialog();
}

//search id or pass
function searchUserInfo(type){
	if(type == 'pass' && $.trim($('#pass_id').val())==''){
// 		jAlert('아이디를 입력해 주세요.', '정보');
		jAlert('Please enter your ID.', 'Info');
		$('#pass_id').focus();
		return;
	}
	if($.trim($('#'+type+'_email').val())=='') {
// 		jAlert('이메일을 입력해 주세요.', '정보');
		jAlert('Please enter your e-mail.', 'Info');
		$('#'+type+'_email').focus();
		return;
	}
	
	var textType 	= 'find'+ type;
	var email 		= $.trim($('#'+type+'_email').val());
	var id			= '&nbsp';
	
	if(type == 'pass'){
		id = $.trim($('#pass_id').val());
	}
	
	var Url			= baseRoot() + "cms/findUser/";
	var param		= textType + "/" + email +"/"+ id;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				str = data.Data;
// 				jConfirm($('#'+type+'_email').val() + '해당 주소로 등록하신  '+ type + '가 발송됩니다.', '정보', function(res){
				jConfirm($('#'+type+'_email').val() + 'We will send you the '+ type +' that you registered with that address.', 'Info', function(res){
					if(res){
						sendMail(str,type);
					}
				});
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//send e-mail id or pass
function sendMail(text,type){
	$('body').append('<div class="lodingOn"></div>');
	
	$.ajax({
		type: 'POST',
		url: "<c:url value='/geoUserSendMail.do'/>",
		data: 'type=search&searchEmail='+$('#'+type+'_email').val()+'&text='+text+'&textType='+type+'&searchType=findPass',
		success: function(data) {
			$('.lodingOn').remove();
			$('#'+type+'_email').val('');
// 			jAlert('요청 하신 '+ type +'가 등록하신 이메일로 발송되었습니다.','정보');
			jAlert('The requested '+ type +' has been sent to your email.','Info');
		},
		error: function(){
			$('.lodingOn').remove();
		}
	});
}
</script>

</head>

<body bgcolor="#FFF">
<table id='find_table' style="border-collapse: collapse;border: 1px solid black;">
	<tbody>
		<tr>
			<th colspan="2" height="50" style="border: 1px solid black;">ID SEARCH</th>
			<th colspan="2" style="border: 1px solid black;">PASSWORD SEARCH</th>
		</tr>
		<tr>
			<td width="65" height="70">
				&nbsp;E-Mail
			</td>
			<td width="235" style="border-right: 1px solid black;">
				<input type="text" id="id_email">
			</td>
			<td width="65">
				&nbsp;<label>ID</label>
			</td>
			<td width="235">
				<input type="text" id="pass_id">
			</td>
		</tr>
		<tr>
			<td colspan="2" style="border-right: 1px solid black;">
			</td>
			<td>
				&nbsp;<label>E-Mail</label>
			</td>
			<td>
				<input type="text" id="pass_email">
			</td>
		</tr>
		<tr align="center"  height="50">
			<td colspan="2" style="border-right: 1px solid black;">
				<button onclick="searchUserInfo('id');" class="radiusBtn5">search ID</button>
			</td>
			<td colspan="2">
				<button onclick="searchUserInfo('pass');" class="radiusBtn5">search PASS</button>
			</td>
		</tr>
		<tr>
			<td colspan='4'align='center' height="30" style="border: 1px solid black;">
				<button onclick='findClose();' class="radiusBtn5">CANCEL</button>
			</td>
		</tr>
	</tbody>
</table>

</body>
