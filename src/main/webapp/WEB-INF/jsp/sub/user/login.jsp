<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<script type="text/javascript">

function openLoginPage(){
	$('#LoginDig').dialog('open');
}

//로그인
function loginUser(){
	if($.trim($('#id_input').val())=='') {
// 		jAlert('아이디를 입력해 주세요.', '정보');
		jAlert('Please enter your ID.', 'Info');
		$('#id_input').focus();
		return;
	}
	if($.trim($('#pass_input').val())=='') {
// 		jAlert('비밀번호를 입력해 주세요.', '정보');
		jAlert('Please enter a password.', 'Info');
		$('#pass_input1').focus();
		return;
	}
	
	var id 			= $('#id_input').val();
	var pass 		= $('#pass_input').val();
	
	var Url			= baseRoot() + "cms/login/";
	var param		= id + "/"+ pass;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var code = data.Code;
			var token_code = data.Token;
			var resType = data.Data;
			var msg = data.Message;
			
			if(code == '100') {
				loginSetting(id, token_code, resType);
			}
			else {
				jAlert(msg, 'Info');
			}
		}
	});
}

function loginSetting(id, token, type) {
	$.ajax({
		type: 'POST',
		url: "<c:url value='geoSetUserInfo.do'/>",
		data: 'typeVal=login&loginId='+id+'&loginToken='+token+'&loginType='+type,
		success: function(data) {
			if(data == "100"){
				window.location.href='/GeoCMS';
			}else{
				jAlert(data, 'Info');
			}
		}
	});
}

//join
function fnJoin(){
	var joinDig = jQuery.FrameDialog.create({
		url: "<c:url value='/geoCMS/join.do'/>",
		title: 'JOIN',
		width: 450,
		height: 240,
		buttons: {},
		autoOpen:false
	});
	joinDig.dialog('open');
}

//search id/pass
function fnFind(){
	var findDig = jQuery.FrameDialog.create({
		url: "<c:url value='/geoCMS/find.do'/>",
		title: 'FIND',
		width: 600,
		height: 280,
		buttons: {},
		autoOpen:false
	});
	findDig.dialog('open');
}

function submitLogin(e){
	var keycode;
	if(window.event) keycode = window.event.keyCode;
	else if(e) keycode = e.which;
	else return true;
	if(keycode == 13) {
		loginUser();
	}
}
</script>

</head>

<body bgcolor="#FFF">

<div onclick="openLoginPage();" style="float: right; margin: 35px 50px; cursor: pointer;width:40px; height:20px; ">
	LOGIN
</div>
<div id="LoginDig">
	<table id='login_table' border=1 style="font-size: 13px;" width="100%;" class="loginCls" onKeyPress='submitLogin(event);'>
		<tbody>
			<tr>
				<th>ID</th>
				<td>
					<input type="text" id="id_input" tabindex=1>
				</td>
				<td rowspan="2" style="text-align:center;">
					<button onclick='loginUser();' class="radiusBtn5" style="height: 50px;">LOGIN</button>
				</td>
			</tr>
			<tr>
				<th>PASS</th>
				<td>
					<input type='password' id='pass_input' tabindex=2 onKeyPress='submitLogin(event);'>
				</td>
			</tr>
			<tr>
				<td colspan='3'align='center'>
					<button onclick='fnJoin();' class="radiusBtn5">JOIN</button>
					<button onclick='fnFind();' class="radiusBtn5">ID/PASS SEARCH</button>
				</td>
			</tr>
		</tbody>
	</table>
</div>

</body>
