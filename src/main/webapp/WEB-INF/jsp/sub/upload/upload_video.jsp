<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<jsp:include page="../../page_common.jsp"></jsp:include>

<%
String loginId = (String)session.getAttribute("loginId");				//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");			//로그인 token

String makeContentIdx = request.getParameter("makeContentIdx");			//선택한 프로젝트 인덱스
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';					//로그인 아이디
var loginToken = '<%= loginToken %>';			//로그인 token
var makeContentIdx = '<%= makeContentIdx %>';	//선택한 프로젝트 인덱스

var projectNameArr = new Array();		//project name array
var projectIdxArr = new Array();		//project idx array

var videoUploadCnt = 0;
var uploadFileName = '';
var nowVideoType = 's';

$(function() {
	getVideoUpProjectList();
	
	$('.create_button').width(80);
	$('.create_button').height(22);
	$('.create_button').css('fontSize', 11);
	$('.create_button').css('margin-left', 5);
	$('.create_button').css('margin-right', 5);
	
	$('.cancle_button').width(80);
	$('.cancle_button').height(22);
	$('.cancle_button').css('fontSize', 11);
	$('.cancle_button').css('margin-left', 5);
	$('.cancle_button').css('margin-right', 5);
	
	$('#upload_table tr td').css('fontSize', 12);
	
	$('#showVideo').attr("checked", true);
	
	//project name setting
	innerHTML = '';
	for(var i=0;i<projectNameArr.length;i++){
		innerHTML += '<option value="'+ projectIdxArr[i] +'">'+ projectNameArr[i] +'</option>';
	}
	$('#projectKind').append(innerHTML);
	
	if(makeContentIdx != null){
		$('#projectKind').val(makeContentIdx);
	}
});

//get proejct List
function getVideoUpProjectList(){
	var orderIdx  = '&nbsp';
	var tmeShareEdit = 'Y';
	var Url			= baseRoot() + "cms/getProjectList/";
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
					projectNameArr = new Array();
					projectIdxArr = new Array();
					if(response != null && response.length > 0){
						$.each(response, function(idx, val){
							projectNameArr.push(val.projectname);
							projectIdxArr.push(val.idx);
						});
					}
			}else{
// 				jAlert('프로젝트 생성 후 컨텐츠를 업로드 할수 있습니다.', '정보');
				jAlert('You can upload content after creating a project.', 'Info');
				jQuery.FrameDialog.closeDialog();
			}
		}
	});
}

//게시물 생성
function createContent() {
	if(loginId != '' && loginId != null) {
		var title = $('#title_area').val();
		var content = document.getElementById('content_area').value;
		var projectIdxNum = $('#projectKind').val();
		var droneType = '&nbsp';
		var chkVideoGps = '&nbsp';
		var m_s_check = nowVideoType;
		
		if( $(':checkbox[id="droneDataChk"]:checked')){
			droneType = 'Y';
		}
		 
		//게시물 정보 전송 설정
		if(title == null || title == "" || title == 'null'){
// 			jAlert('제목을 입력해 주세요.', '정보');
			jAlert('Please enter the title.', 'Info');
			$('#title_area').focus();
			return;
		}
		 
		if(content == null || content == "" || content == 'null'){
// 			jAlert('내용을 입력해 주세요.', '정보');
			jAlert('Please enter your details.', 'Info');
			$('#content_area').focus();
			return;
		}
		
		if(title != null && title.indexOf('\'') > -1){
// 			jAlert('제목에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			jAlert('Can not use special character \' in title.', 'Info');
			return;
		}
		 
		if(content != null && content.indexOf('\'') > -1){
// 			jAlert('내용에 특수문자 \' 는 사용할 수 없습니다.', '정보');
			jAlert('Can not use special character \' in content.', 'Info');
			 return;
		}
		
		
		if(m_s_check == 's'){
			var tmpFile1 = $('#file_1').val();
			if(tmpFile1 == null || tmpFile1 == undefined || tmpFile1 == ''){
//	 			jAlert('컨텐츠를 선택해 주세요.', '정보');
				jAlert('Please select content.', 'Info');
				return;
			}
		}else if(m_s_check == 'm'){
			var chkFileIn = false;
			$.each($('.file_input_hidden_video_m'),function(idx,val){
				if($(val).val() != null && $(val).val() != undefined && $(val).val() != ''){
					chkFileIn = true;
				}
			});
			if(!chkFileIn){
//	 			jAlert('컨텐츠를 선택해 주세요.', '정보');
				jAlert('Please select content.', 'Info');
				return;
			}
		}else{
			jAlert('System Error.', 'Info');
			return;
		}
		var gpsFileTypeData = $(':radio[name="fileTypeRadio"]:checked').val();
		if(gpsFileTypeData == "2" || gpsFileTypeData == "3"){
			var chkFileIn = false;
			$.each($('.file_input_hidden_gps'),function(idx,val){
				if($(val).val() != null && $(val).val() != undefined && $(val).val() != ''){
					chkFileIn = true;
				}
			});
			if(!chkFileIn){
//	 			jAlert('컨텐츠를 선택해 주세요.', '정보');
				jAlert('Please select gps file.', 'Info');
				return;
			}
		}else if(gpsFileTypeData == "4" || gpsFileTypeData == "5"){
			chkVideoGps = $(':radio[name="videoGpsRadio"]:checked').val();
			if(m_s_check == 'm' && (chkVideoGps == null || chkVideoGps == undefined)){
				jAlert('Please select a video file from which to get coordinates.', 'Info');
				return;
			}else if(m_s_check == 's'){
				chkVideoGps = 'file_1';
			}
		}
		
		$('#fileinfo').append($('.file_input_hidden_video_'+ m_s_check));
		$('#fileinfo').append($('.file_input_hidden_gps'));

		title = dataReplaceFun(title);
		content = dataReplaceFun(content);
		
		 
		$('body').append('<div class="lodingOn"></div>');
		var iframe = $('<iframe name="postiframe" id="postiframe" style="display: none"></iframe>');
        $("body").append(iframe);
         
        var form = $('#fileinfo');
        var resAddress = baseRoot() + "cms/saveVideoAll/";
		resAddress += loginToken +"/"+ loginId +"/"+ title +"/"+ content +"/"+ projectIdxNum +"/"+droneType +"/"+ gpsFileTypeData +"/"+ chkVideoGps;
        resAddress += "?callback=?";
        
        form.attr("action", resAddress);
        form.attr("method", "POST");

        form.attr("encoding", "multipart/form-data");
        form.attr("enctype", "multipart/form-data");

        form.attr("target", "postiframe");
        form.submit();
        
         
        $("#postiframe").load(function (e) {
        	var doc = this.contentWindow ? this.contentWindow.document : (this.contentDocument ? this.contentDocument : this.document);
          	var root = doc.documentElement ? doc.documentElement : doc.body;
          	var data = root.textContent; ////////// ? root.textContent : root.innerText;
            data = data.replace("?","").replace("(","").replace(")","");
          	var resData = JSON.parse(data);
            
          	if(resData != null && resData != ''){
         		if(resData.Code == 100){
         			window.parent.viewMyProjects(projectIdxNum);
					window.parent.closeUpload();
				}else{
					jAlert(resData.Message, 'Info', function(res){
						$('.lodingOn').remove();
					});
				}
			}else{
				$('.lodingOn').remove();
			}
          });
	}
	else {
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', '정보');
		jAlert('I lost my login information.', 'Info');
	}
}

//게시물 생성 취소
function cancelContent() {
// 	jConfirm('게시물 생성을 취소하시겠습니까?', '정보', function(type){
	jConfirm('Are you sure you want to cancel creating posts?', 'Info', function(type){
		window.parent.closeUpload();
	});
}

//upload kind 선택 시 
function changeShow(type) {
	jQuery.FrameDialog.closeDialog();
	parent.ContentsMakes(type, '', '', makeContentIdx);
}

//all checked
function allCheck(obj){
	if(obj.checked){
		$('.shareChk').attr('checked',true);
	}else{
		$('.shareChk').attr('checked',false);
	}
}

//open shareUser list
function getShareUser(){
	contentViewDialog = jQuery.FrameDialog.create({
		url:'<c:url value="/geoCMS/share.do" />?shareKind=GeoVideo',
		width: 370,
		height: 535,
		buttons: {},
		autoOpen:false
	});
	contentViewDialog.dialog('widget').find('.ui-dialog-titlebar').remove();
	contentViewDialog.dialog('open');
}

//file change
function fileChangeInfo(obj){
	var objId = obj.id;
	var objFileName = "";
	$('#floorMap_pop_'+ objId).empty();
	
	if(obj.files[0] != null && obj.files[0] != undefined){
		objFileName = obj.files[0].name;
		if(objFileName.length > 25){
			objFileName = objFileName.substring(0,20) + "...";
		}
		var tmpHtml = "<div title='"+ obj.files[0].name  +"' style='margin:5px 0 5px 10px; text-decoration:underline; color:gray; position:absolute;'>"+ objFileName +"</div>";  
		$('#floorMap_pop_'+objId).append(tmpHtml);
	}else{
		$('#'+objId).val(null);
	}
	if($(':radio[name="fileTypeRadio"]:checked').val() == '4' || $(':radio[name="fileTypeRadio"]:checked').val() == '5'){
		changVideoFileGps();
	}
}

var gpxFileCnt = 1; //gpx file button index
var gpsFileTextView = 'GPX'; //gps file text view
//gpx file add button
function addGpxFileBtn(){
	gpxFileCnt ++;
	var htmlStr = "";
	var acceptSrt = " accept='.GPX, .gpx' ";
	if(gpsFileTextView == "SRT"){
		acceptSrt = " accept='.SRT, .str' ";
	}
	
	htmlStr += '<div class="file_input_div_video file_input_div_gpxFile" style="float: left; width: 390px; height: 28px;">';
	htmlStr += '<div class="file_input_img_btn_video file_label_txt" style="margin:0px;"> ' + gpsFileTextView + ' </div>';
	htmlStr += '<input type="file" name="gpx_'+ gpxFileCnt +'" id="gpx_'+ gpxFileCnt +'" class="file_input_hidden_gps" onchange="fileChangeInfo(this);" style="left:0px;" '+ acceptSrt + ' />';
	htmlStr += '<div id="floorMap_pop_gpx_'+ gpxFileCnt +'" class="text_box_dig text_box_gps" style="width:200px; height: 24px; float: left; margin-left: 10px;"></div>';
	if(gpxFileCnt > 1){
		htmlStr += '<input type="button" value="Remove" onclick="removeGpxFileBtn('+ gpxFileCnt +');" style="margin: 3px 0 3px 10px;">';
	}
	htmlStr += '</div>';
	
	$('#gps_area').append(htmlStr);
}

//gpx file remove button
function removeGpxFileBtn(thisIndex){
	$('#gpx_'+thisIndex).parent().remove();
}

//video file remove button
function removeVideoFileBtn(thisIndex){
// 	$('#file_'+thisIndex).empty();
	$('#file_'+thisIndex).val(null);
	$('#floorMap_pop_file_'+thisIndex).empty();
	if($(':radio[name="fileTypeRadio"]:checked').val() == '4' || $(':radio[name="fileTypeRadio"]:checked').val() == '5'){
		changVideoFileGps();
	}
}

//single video or multi video select
function fnVideoMainChange(tType){
	$('.video_area').css('display','none');
	$('.videoSelTopDiv').css('background-color','#e5e5e5');
	if(tType != null){
		nowVideoType = tType;
		fnFileClear();
		$('#'+ nowVideoType + '_video_area').css('display','block');
		$('#videoSelTopDiv_'+tType).css('background-color','darkgray');
	}
}

//파일 초기화
function fnFileClear(){
// 	$('#file_1').empty();
// 	$('#file_2').empty();
// 	$('#file_3').empty();
// 	$('#file_4').empty();
// 	$('#file_5').empty();
	$('#file_1').val(null);
	$('#file_2').val(null);
	$('#file_3').val(null);
	$('#file_4').val(null);
	$('#file_5').val(null);
	$('.text_box_dig').empty();
	
	$('#fileTypeRadio_1').attr('checked',true);
}

function fnGpsTypeChange(obj){
	var objId = obj.id;
	objId = objId.split("_")[1];
	
	$('#gps_file_add_area').css('display','none');
	$('#gps_file_select_area').css('display','none');
	$('.file_input_div_gpxFile').remove();
	$('#gps_file_select_area').empty();
	if(objId == '1'){
		gpxFileCnt = 0;
	}else if(objId == '2' || objId == '3'){
		$('#gps_file_add_area').css('display','block');
		if(objId == '2'){
			gpsFileTextView = 'GPX';
		}else{
			gpsFileTextView = 'SRT';
		}
		gpxFileCnt = 0;
		addGpxFileBtn();
	}else if(objId == '4' || objId == '5'){
		var chkFileIn = false;
		if(nowVideoType == 's'){
			var tmpFile1 = $('#file_1').val();
			if(tmpFile1 == null || tmpFile1 == undefined || tmpFile1 == ''){
				jAlert('Please select content.', 'Info');
			}else{
				chkFileIn = true;
			}
		}else if(nowVideoType == 'm'){
			$.each($('.file_input_hidden_video_m'),function(idx,val){
				if($(val).val() != null && $(val).val() != undefined && $(val).val() != ''){
					chkFileIn = true;
				}
			});
		}
		if(!chkFileIn){
			jAlert('Please select content.', 'Info');
			$("#fileTypeRadio_1").trigger("click");
			return;
		}
		gpxFileCnt = 0;
		
		changVideoFileGps();
		$('#gps_file_select_area').css('display','block');
	}
}

//get gps select video
function changVideoFileGps(){
	$('#gps_file_select_area').empty();
	if(nowVideoType == 'm'){
		var htmlStr = '';
		var videoGpsCheck = false;
		var videoGpsName = '';
		$.each($('.file_input_hidden_video_m'),function(idx,val){
			videoGpsName = $(val).val();
			if(videoGpsName != null && videoGpsName != undefined && videoGpsName != ''){
				videoGpsName = videoGpsName.substring(videoGpsName.lastIndexOf('\\')+1);
				htmlStr += '<div style="clear:both;">';
				htmlStr += '<input type="radio" id="videoGpsRadio_'+ idx +'" name="videoGpsRadio" value="'+ this.id +'" ';
				if(!videoGpsCheck){
					htmlStr += 'checked="checked" ';
					videoGpsCheck = true;
				}
				htmlStr += 'style="margin: 3px 0 3px 10px; float:left;">';
				htmlStr += '<div style="float:left;">'+ videoGpsName +'</div><div>';
			}
		});
		if(htmlStr != null && htmlStr != ''){
			$('#gps_file_select_area').append(htmlStr);
		}else{
			jAlert('Please select content.', 'Info');
			$("#fileTypeRadio_1").trigger("click");
		}
	}else if(nowVideoType == 's'){
		var tmpFile1 = $('#file_1').val();
		if(tmpFile1 == null || tmpFile1 == undefined || tmpFile1 == ''){
			jAlert('Please select content.', 'Info');
			$("#fileTypeRadio_1").trigger("click");
		}
	}
}

</script>

</head>

<body bgcolor='#e5e5e5'>

<table id='upload_table' border=1>
	<tr id="showDivTR">
		<td height="25" colspan="2" style="font-size: 12px;">
			<div style="width:250px;float:left;">
<!-- 				<div style="float:left;"><input type="radio" id="showBoard" name="showRadio" onclick="changeShow('Board')">Board</div> -->
				<div style="float:left;"><input type="radio" id="showImage" name="showRadio" onclick="changeShow('Image')">Image</div>
<!-- 				<div style="float:left;"><input type="radio" id="showVideo" name="showRadio" onclick="changeShow('Panorama')">Panorama</div> -->
				<div style="float:left;"><input type="radio" id="showVideo" name="showRadio">Video</div>
			</div>
			<div style="float:left; padding:3px;">
					<label>Drone Data </label><input type="checkbox" id="droneDataChk">
			</div>
		</td>
	</tr>
	<tr>
		<td width="80" height="25" align="center">Layer Name</td>
		<td width="" height="25" align="center">
			<select style="width:318px;" id="projectKind"></select>
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' style="width:80px;">TITLE</td>
		<td width='' height='25' align='center'>
			<input id='title_area' type='text' style='width:316px;'>
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' colspan='2'>CONTENT</td>
	</tr>
	<tr>
		<td width='' height='150' align='center' colspan='2'>
			<textarea id='content_area' style='width:400px; height:150px;'></textarea>
		</td>
	</tr>
	<tr>
		<td height="25" colspan="2">
			<div id="videoSelTopDiv_s" class="videoSelTopDiv" style="float: left;width: 100px;height: 28px;text-align: center; background-color: darkgray;" onclick="fnVideoMainChange('s');return;">
				<label>Single video</label>
			</div>
			<div id="videoSelTopDiv_m" class="videoSelTopDiv" style="float: left;width: 100px;height: 28px;text-align: center;" onclick="fnVideoMainChange('m');return;">
				<label>Multi Video</label>
			</div>
		</td>
	</tr>
	<tr style="background-color: darkgray;">
		<td height="25" colspan="2">		
			<!-- 단일 비디오 영역 -->
			<div id="s_video_area" class="video_area">
				<div class="file_input_div_video" id="file_input_div_1" style="clear: both;">
					<div class="file_input_img_btn_video"> + </div>
					<input type="file" name="file_1" id="file_1" class="file_input_hidden_video_s"  style="left:0;" onchange="fileChangeInfo(this);"/>
					<div id="floorMap_pop_file_1" class="text_box_dig" style="width:160px; height: 24px; margin:8px 10px; position: absolute; left:100px; top:-8px;"></div>
				</div>
			</div>
			
			<!-- 멀티 비디오 영역 -->
			<div id="m_video_area" class="video_area" style="display:none;">
				<div class="file_input_div_video" id="file_input_div_2">
					<div class="file_input_img_btn_video"> + </div>
					<input type="file" name="file_2" id="file_2" class="file_input_hidden_video_m" style="left:0;" onchange="fileChangeInfo(this);"/>
					<div id="floorMap_pop_file_2" class="text_box_dig" style="width:160px; height: 24px; margin:8px 10px; position: absolute; left:100px; top:-8px;"></div>
				</div>
				<div class="file_input_div_video" id="file_input_div_3">
					<div class="file_input_img_btn_video"> + </div>
					<input type="file" name="file_3" id="file_3" class="file_input_hidden_video_m" style="left:0;" onchange="fileChangeInfo(this);"/>
					<div id="floorMap_pop_file_3" class="text_box_dig" style="width:160px; height: 24px; margin:8px 10px; position: absolute; left:100px; top:-8px;"></div>
					<input type="button" value="Remove" onclick="removeVideoFileBtn(3);" style="margin-left: 210px;">
				</div>
				<div class="file_input_div_video" id="file_input_div_4">
					<div class="file_input_img_btn_video"> + </div>
					<input type="file" name="file_4" id="file_4" class="file_input_hidden_video_m" style="left:0;" onchange="fileChangeInfo(this);"/>
					<div id="floorMap_pop_file_4" class="text_box_dig" style="width:160px; height: 24px; margin:8px 10px; position: absolute; left:100px; top:-8px;"></div>
					<input type="button" value="Remove" onclick="removeVideoFileBtn(4);" style="margin-left: 210px;">
				</div>
				<div class="file_input_div_video" id="file_input_div_5">
					<div class="file_input_img_btn_video"> + </div>
					<input type="file" name="file_5" id="file_5" class="file_input_hidden_video_m" style="left:0;" onchange="fileChangeInfo(this);"/>
					<div id="floorMap_pop_file_5" class="text_box_dig" style="width:160px; height: 24px; margin:8px 10px; position: absolute; left:100px; top:-8px;"></div>
					<input type="button" value="Remove" onclick="removeVideoFileBtn(5);" style="margin-left: 210px;">
				</div>
			</div>
		</td>
	</tr>
	<tr style="background-color: darkgray;">
		<td height="25" colspan="2">
			<div style="clear: both; padding:10px;">
				<input type="radio" id="fileTypeRadio_1" name="fileTypeRadio" value="1" onclick="fnGpsTypeChange(this);" checked="checked"/>No coordinates
				<input type="radio" id="fileTypeRadio_2" name="fileTypeRadio" value="2" onclick="fnGpsTypeChange(this);"/>GPX
				<input type="radio" id="fileTypeRadio_3" name="fileTypeRadio" value="3" onclick="fnGpsTypeChange(this);"/>SRT<br>
				<input type="radio" id="fileTypeRadio_4" name="fileTypeRadio" value="4" onclick="fnGpsTypeChange(this);"/>Video coordinates
				<input type="radio" id="fileTypeRadio_5" name="fileTypeRadio" value="5" onclick="fnGpsTypeChange(this);"/>Video coordinates (Sony Dash cam)
			</div>
			
			<!-- gps file add area -->
			<div id="gps_file_add_area" style="display: none;">
				<input type="button" value="Add" onclick="addGpxFileBtn();" style="margin-top: 5px; margin-left:350px;">
				<div id="gps_area">
					<div class="file_input_div_video file_input_div_gpxFile" style="float: left; width: 390px; height: 28px;">
						<div class="file_input_img_btn_video file_label_txt" style="margin:0px;"> GPX </div>
						<input type="file" name="gpx_1" id="gpx_1" class="file_input_hidden_gps" onchange="fileChangeInfo(this);" style="left:0px;" accept='.GPX, .gpx' />
						<div id="floorMap_pop_gpx_1" class="text_box_dig text_box_gps" style="width:200px; height: 24px; float: left; margin-left: 100px;"></div>
					</div>
				</div>
			</div>
			
			<!-- get gps file video select area -->
			<div id="gps_file_select_area" style="display: none; margin-left:30px;"></div>
		</td>
	</tr>
	<tr>
		<td width='' height='25' align='center' colspan='2'>
			<button class='create_button' onclick='createContent();'>SAVE</button>
			<button class='cancle_button' onclick='cancelContent();'>CANCLE</button>
		</td>
	</tr>
</table>

	<form enctype="multipart/form-data" method="post" name="fileinfo" id="fileinfo" style="display:none;" >
		<input type="hidden" name="uploadType" id="uploadType" value="GeoVideo"/>
	</form>

</body>
