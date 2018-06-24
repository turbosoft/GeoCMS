<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>
<script type="text/javascript">

//회원가입 dialog 닫기
function joinClose(){
	jQuery.FrameDialog.closeDialog();
}

//회원가입
function joinUser(){
	if($.trim($('#id_input').val())=='') {
// 		jAlert('아이디를 입력해 주세요.', '정보');
		jAlert('Please enter your ID.', 'Info');
		$('#id_input').focus();
		return;
	}
	if($.trim($('#pass_input1').val())=='') {
// 		jAlert('비밀번호를 입력해 주세요.', '정보');
		jAlert('Please enter a password.', 'Info');
		$('#pass_input1').focus();
		return;
	}
	
	if($.trim($('#pass_input2').val())=='') {
// 		jAlert('비밀번호를 확인을 해 주세요.', '정보');
		jAlert('Please check your password.', 'Info');
		$('#pass_input2').focus();
		return;
	}
	
	if($.trim($('#email_input').val())=='') {
// 		jAlert('이메일을 입력해 주세요.', '정보');
		jAlert('Please enter your e-mail.', 'Info');
		$('#email_input').focus();
		return;
	}
	
	if(checkId == 0){
// 		jAlert('아이디 중복체크를 해주세요.', '정보');
		jAlert('Please check ID duplication.', 'Info');
		return;
	}
	
	if($.trim($('#pass_input1').val()) != $.trim($('#pass_input2').val())){
// 		jAlert('비밀번호가 일치하지 않습니다.', '정보');
		jAlert('Passwords do not match.', 'Info');
		return;
	}
	
	if(checkEmail != 2){
// 		jAlert('이메일 인증을 받으세요.', '정보');
		jAlert('Get email verification.', 'Info');
		return;
	}
	
	var id 			= $.trim($('#id_input').val());
	var pass 		= $.trim($('#pass_input1').val());
	var email		= $.trim($('#email_input').val());
	
	var Url			= baseRoot() + "cms/join/";
	var param		= id + "/"+ pass + "/" + email + "/I";
	var callBack	= "?callback=?";
	
	$('body').append('<div class="lodingOn"></div>');
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		,success: function(data) {
			$('.lodingOn').remove();
			if(data.Code == 100){
				jAlert(data.Message,'Info',function(){
					joinClose();
					location.reload();
				});
			}else{
				jAlert(data.Message, 'Info');
			}
		}
		,error: function(){
			$('.lodingOn').remove();
		}
	});
}

var checkId = 0;	//id 중복체크 1:중복체크 ok
//id 중복체크
function idCheck(){
	var textType 	= 'ID';
	var textVal 	= $.trim($('#id_input').val());
	var pattern = /^[A-Za-z0-9]{5,20}$/;
	
	$('#idErrorMsg').css('display','none');
	
	if(textVal == '') {
// 		jAlert('아이디를 입력해 주세요.', '정보');
		jAlert('Please enter your ID.', 'Info');
		return;
	}else if(!pattern.test(textVal)){
		$('#idErrorMsg').css('display','block');
		return;
	}
	
	var Url			= baseRoot() + "cms/userChk/";
	var param		= textVal +"/"+ textType;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		,success: function(data) {
			if(data.Code == "101"){
				checkId = 1;
			}else{
				checkId = 0;
			}
			jAlert(data.Message, 'Info');
		}
	});
}

//아이디 입력란 변경 시 아이디 중복 체크 0
function chkReSet(type){
	if(type == 'ID'){
		checkId = 0;
	}else if(type == 'Email'){
		checkEmail = 0;
	}
}

var randomStr = "";	//random string
var checkEmail = 0;	//email 인증
//이메일 확인
function emailCheck(){
	if($.trim($('#email_input').val())=='') {
// 		jAlert('이메일을 입력해 주세요.', '정보');
		jAlert('Please enter your e-mail.', 'Info');
		$('#email_input').focus();
		return;
	}
	
	var textType 	= 'EMAIL';
	var textVal 	= $.trim($('#email_input').val());
	
	var Url			= baseRoot() + "cms/userChk/";
	var param		= textVal +"/"+ textType;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == "103"){
// 				jConfirm(textVal + ' \n해당 주소로  인증 메일이 발송됩니다.', '정보', function(res){
				jConfirm(textVal + ' \nYou will receive a verification email at this address.', 'Info', function(res){
					if(res){
						$('body').append('<div class="lodingOn"></div>');
						$('#confirmDiv').css('display', 'block');
						randomStr = Math.random().toString(36).substr(2);
						//send e-mail check
						$.ajax({
							type: 'POST',
							url: "<c:url value='/geoUserSendMail.do'/>",
							data: 'thisType=checkEmail&searchEmail='+textVal+'&text='+randomStr,
							success: function(data) {
// 								jAlert('인증메일이 발송 되었습니다.', '정보');
								jAlert('Verification email sent.', 'Info');
								checkEmail = 1;
								$('.lodingOn').remove();
							},
							error:function(){
								$('.lodingOn').remove();
							}
						});
					}
				});
			}else{
				checkEmail = 0;
				jAlert(data.Message, 'Info');
			}
		}
	});
}

function confirmNumChk(){
	if(checkEmail != 1){
// 		jAlert('인증 메일을 받으세요.', '정보');
		jAlert('Get a verification email.', 'Info');
		return;
	}
	var text = $.trim($('#email_chkNum').val());
	if(randomStr != text){
// 		jAlert('인증 번호가 일치하지 않습니다.', '정보');
		jAlert('Authentication number mismatch.', 'Info');
		return;
	}
	
// 	jAlert('이메일 인증이 완료되었습니다.', '정보');
	jAlert('Email verification is complete.', 'Info');
	checkEmail = 2;
}

</script>

</head>

<body bgcolor="#FFF">
<table id='join_table' border=1 class="joinCls" style="width:100%;">
	<tbody>
		<tr>
			<th>ID</th>
			<td>
				<input type="text" id="id_input" onkeypress="chkReSet('ID');">
				<button onclick='idCheck();' class="radiusBtn5">ID CHECK</button>
<!-- 				<label id="idErrorMsg" style="color: red; display:none;">5~20자의 영문자, 숫자만 사용 가능합니다.</label> -->
				<label id="idErrorMsg" style="color: red; display:none;">Only 5 ~ 20 alphanumeric characters can be used.</label>
			</td>
		</tr>
		<tr>
			<th>PASS</th>
			<td>
				<input type='password' id='pass_input1'>
			</td>
		</tr>
		<tr>
			<th>PASS CHECK</th>
			<td>
				<input type='password' id='pass_input2'>
				<font color="red" id="pass2Message"></font>
			</td>
		</tr>
		<tr>
			<th>E-Mail</th>
			<td>
				<input type="text" id="email_input" onkeypress="chkReSet('Email');">
				<button onclick='emailCheck();' class="radiusBtn5">CHECK</button>
				<div id="confirmDiv" style="display: none;">
					<input type="text" id="email_chkNum">
					<button onclick='confirmNumChk();' class="radiusBtn5">CONFIRM</button>
				</div>
			</td>
		</tr>
		<tr>
			<td colspan='2'align='center'>
				<button onclick='joinUser();' class="radiusBtn5">SAVE</button>
				<button onclick='joinClose();' class="radiusBtn5">CANCEL</button>
			</td>
		</tr>
	</tbody>
</table>

</body>
