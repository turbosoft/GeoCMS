<%@ page language="java" contentType="text/html; charset=UTF-8" import="java.net.*" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
String loginType = (String)session.getAttribute("loginType");				//로그인 권한
%>

<script type='text/javascript'>
var loginId = '<%=loginId%>';
var loginToken = '<%=loginToken%>';
var loginType = '<%=loginType%>';
var uploadDig= null;

$(function() {
	$('.image_upload_button').button();
	$('.image_upload_button').width(130);
	$('.image_upload_button').height(30);
	$('.image_upload_button').css('fontSize', 12);
});

//make contents button click function
function ContentsMakes(obj, type, boardNowTab, selBoardNum) {
	if(loginId == null || loginId =='' || loginId == 'null') {
		jAlert("로그인 정보가 만료되었습니다.\n\n다시 로그인을 수행하여 주세요.", '정보');
	}
	else {	//base board upload setting	
		var tempBoardTab = nowTabName;
		if(boardNowTab != null && boardNowTab != '' && boardNowTab != 'null'){
			tempBoardTab = boardNowTab;
		}
		var tempUrl = '<c:url value="/geoCMS/upload_board.do"/>?'+obj+'&projectImage='+ projectImage+ '&projectVideo='+projectVideo+'&b_boardTabArr='+b_boardTabArr+'&nowTabName='+tempBoardTab+'&selBoardNum='+selBoardNum;
		var tempTitle = 'Board Upload';
		var tempWidth = 960;
		var tempHeight = 660;
		
		if((nowRightTabName == "content" && projectImage == 1 && type == "") || type == "Image"){	//image upload
			tempUrl = '<c:url value="/geoCMS/upload_image.do"/>?projectBoard=1&projectVideo='+projectVideo+'&b_contentTabArr='+b_contentTabArr;
			tempTitle = 'Image Upload';
			tempWidth = 435;
			tempHeight = 640;
		}else if((nowRightTabName == "content" && projectVideo == 1 && type == "") || type == "Video"){	//video upload
			tempUrl = '<c:url value="/geoCMS/upload_video.do"/>?projectBoard=1&projectImage='+projectImage+'&b_contentTabArr='+b_contentTabArr;
			tempTitle = 'Video Upload';
			tempWidth = 435;
			tempHeight = 675;
		}
		
		//image, video 생성시 프로젝트가 없으면 생성 할 수 없음
		if(tempTitle != 'Board Upload'){
			var orderIdx  = '&nbsp';
			var tmeShareEdit = 'Y';
			var Url			= baseRoot() + "cms/getProjectGroup/";
			var param		= loginToken + "/" + loginId + "/" + orderIdx + "/" + tmeShareEdit;
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
						var projectNameArr = new Array();
						var projectIdxArr = new Array();
						if(response != null && response.length > 0){
							$.each(response, function(idx, val){
								projectNameArr.push(val.PROJECTNAME);
								projectIdxArr.push(val.IDX);
							});
						}
						tempUrl += '&projectNameArr='+JSON.stringify(projectNameArr)+'&projectIdxArr='+projectIdxArr;
						uploadDig = jQuery.FrameDialog.create({
							url: tempUrl,
							title: tempTitle,
							width: tempWidth,
							height: tempHeight,
							buttons: {},
							autoOpen:false
						});
						uploadDig.dialog('open');
					}else{
						jAlert('프로젝트 생성 후 컨텐츠를 업로드 할수 있습니다.', '정보');
					}
				}
			});
		}else{
			uploadDig = jQuery.FrameDialog.create({
				url: tempUrl,
				title: tempTitle,
				width: tempWidth,
				height: tempHeight,
				buttons: {},
				autoOpen:false
			});
			uploadDig.dialog('open');
		}
	}
}

//close dialog
function closeUpload() {
	$('.ui-dialog :button').blur();
	uploadDig.dialog('close');
}
</script>
