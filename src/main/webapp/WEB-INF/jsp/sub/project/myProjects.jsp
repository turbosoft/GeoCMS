<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<%
String loginId = (String)session.getAttribute("loginId");					//로그인 아이디
String loginToken = (String)session.getAttribute("loginToken");				//로그인 token
%>
<script type="text/javascript">
var loginId = '<%= loginId %>';				//로그인 아이디
var loginToken = '<%= loginToken %>';		//로그인 token

var proContentNum = 12;
// var proType = '';
var proIdx = 0;
var proEdit = 0;
var oldShareUser = 0;
var nowProTabIdx = null;

function projectGroupListSetup(response){
	$('#project_list_table').empty();
	proIdx = response[0].idx;
	shareInit();
	if(proEdit == 1){
		moveProContent();
	}
	
	markerProArr = new Array();
	console.log('mess');
	addProjectGroupCell(response);
}

//project group list
function addProjectGroupCell(response){
	var innerHTML = '';
	
	if(response != null){
		for(var i=0;i<response.length;i++){
			var proShare = '';
			if(response[i].sharetype == '1'){
// 				proShare = '전체공개';
				proShare = 'FULL';
			}else if(response[i].sharetype == '0'){
// 				proShare = '비공개';
				proShare = 'NON';
			}else{
// 				proShare = '선택공개';
				proShare = 'SELECTIVE';
			}

			var projectNameTxt = response[i].projectname.length>28? response[i].projectname.substring(0,28)+'...' : response[i].projectname;
			innerHTML += '<div id="pName_'+ response[i].idx +'" onclick="fnProjectDiv(this,'+response[i].idx+');"';

			innerHTML += 'class="offProjectDiv">';
			
			innerHTML += "<input type='hidden' id='hiddenProName_"+ response[i].idx +"' value='"+ response[i].projectname +"'/>";
			innerHTML += '<input type="hidden" id="hiddenProUserIn_'+ response[i].idx +'" value="'+ response[i].editUserIn +'"/>';
			innerHTML += '<input type="hidden" id="hiddenShareType_'+ response[i].idx +'" value="'+ response[i].sharetype +'"/>';
			innerHTML += '<input type="hidden" id="hiddenTabIdx_'+ response[i].idx +'" value="'+ response[i].tabidx +'"/>';
			
			innerHTML += "<label class='titleLabel' title='"+ response[i].projectname +"'>"+ projectNameTxt +"</label>";

			//edit btn
// 			if(loginId == response[i].id){
// 				innerHTML += '<button onclick="editProject('+ response[i].idx +');" class="editProBtn" style="border-radius:5px;"> EDIT </button>';
				innerHTML += '<button onclick="openProjectWriter();" class="editProBtn" style="border-radius:5px; margin:3px 5px 0 5px;"> Edit Annotation </button>';
// 			}
			
			//upload btn
			innerHTML += '<button onclick="openProjectViewer('+ response[i].idx +');" class="editFileBtn" style="border-radius:5px; float:right; margin-top:3px;"> Viewer </button>';

			var tmpUserId = response[i].id.length>7? response[i].id.substring(0,7)+'...' : response[i].id;

// 			innerHTML += '<div class="subDivCls"><label class="m_l_10">작성자: </label><label style="display:inline-block; width:45px;" title="'+ response[i].id +'">'+ tmpUserId + '</label><label style="margin-left:5px;">등록일: </label><label>' + response[i].u_date + '</label><label style="margin-left:5px;">'+ proShare + '</label></div>';
			innerHTML += '<div class="subDivCls"><label class="m_l_10">WRITER: </label><label style="display:inline-block; width:45px;" title="'+ response[i].id +'">'+ tmpUserId + '</label><label class="margin-left:5px;">DATE: </label><label>' + response[i].u_date + '</label><label style="margin-left:5px;">'+ proShare + '</label></div>';
			innerHTML += '</div>';

			innerHTML += '<table id="pChild_'+ response[i].idx + '" style="border:1px solid gray; width:100%;"/>';
			innerHTML += '</div>';

		}

		$('#project_list_table').append(innerHTML);
		
		if(response[0].idx != null && response[0].idx != '' && response[0].idx != undefined){
			fnProjectDiv($('#pName_'+response[0].idx), response[0].idx);
		}
		
		clickProjectPage(1,proIdx, null);
	}
}

//project group open close
var editBtnClk = 0;
function fnProjectDiv(obj, projectIdx){
	if(editBtnClk != 0){
		editBtnClk = 0;
		return;
	}
	
	if($(obj).hasClass('onProjectDiv')){
		$(obj).removeClass('onProjectDiv');
		$(obj).addClass('offProjectDiv');
		$('#pChild_'+ projectIdx).empty();
		projectMarkerData(projectIdx);
	}else{
		$(obj).removeClass('offProjectDiv');
		$(obj).addClass('onProjectDiv');
		proIdx = projectIdx;
		clickProjectPage(1,proIdx,null);
		projectMarkerData(projectIdx);
	}
}

//페이지 선택
function clickProjectPage(pageNum, tmpProIdx, dataType){
	var Url			= baseRoot() + "cms/getProjectContent/";
	var param		= loginToken + "/" + loginId + "/list/" + tmpProIdx + "/" + pageNum + "/" + proContentNum;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			if(response != null && response != '' && data.Code == '100'){
				if(dataType != 'editView'){
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
					editDiagOpen(data.DataLen);
				}
			}else{
				if(dataType != 'editView'){
					jAlert(data.Message, 'Info');
				}else{
					editDiagOpen(0);
				}
			}
		}
	});
}

function addProjectChildCell(response, pageNum){
	var nowPChild = 'pChild_'+ proIdx;
	$('#'+nowPChild).empty();
	var target = document.getElementById(nowPChild);
	
	var blankImg = '<c:url value="/images/geoImg/blank(100x70).PNG"/>';

	var imgWidth = 70;		//image width
	var imgHeight = 50;		//image height
	var max_cell = 4;
	
	var totalLan = response.length%4 == 0?response.length:response.length + (4-response.length%4);

	for(var i=0; i<totalLan; i++) {
			//image add
			var img_row;
			if(i % max_cell == 0){
				img_row = target.insertRow(-1);
			}
			
			var img_cell = img_row.insertCell(-1);
			var innerHTMLStr = '';
			img_cell.setAttribute('height', '74px');
			
			if(response[i] == null || response[i] == '' || response[i] == undefined ) {	//등록한 이미지가 없을때 나 
				innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:2px solid white;'/>";
				img_cell.innerHTML = innerHTMLStr;
			}else{
				//타입 별 file 주소 설정
				var localAddress = ftpBaseUrl() + "/" + response[i].datakind;
				
				if(response[i].datakind == "GeoPhoto"){
					var tmpThumbFileName = response[i].filename.split('.');
					localAddress += "/"+tmpThumbFileName[0] +'_thumbnail.png';
				}else if(response[i].datakind == "GeoVideo"){
					localAddress += "/"+response[i].thumbnail;
				}
				
				innerHTMLStr += "<a class='imageTag' id='Pro_"+ response[i].datakind +"_"+response[i].idx +"' href='javascript:;' onclick="+'"';
				var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
				tempArr.push(response[i].latitude);
				tempArr.push(response[i].longitude);
				tempArr.push(response[i].filename);
				tempArr.push(response[i].idx);
				tempArr.push(response[i].datakind);
				tempArr.push(response[i].originname);
				tempArr.push(response[i].thumbnail);
				tempArr.push(response[i].id);
				tempArr.push(response[i].projectUserId);
				tempArr.push("");
				tempArr.push("");
				tempArr.push(response[i].u_date);
				tempArr.push(response[i].seqnum);
				tempArr.push(response[i].dronetype);
				innerHTMLStr += "mapCenterChange('"+ tempArr +"');";
// 				innerHTMLStr += '"'+" title='제목 : "+ response[i].title +"\n내용 : "+ response[i].content +"\n작성자 : "+ response[i].id +"\n작성일 : "+ response[i].u_date +"' border='0'>";
				innerHTMLStr += '"'+" title='TITLE : "+ response[i].title +"\nCONTENT : "+ response[i].content +"\nWRITER : "+ response[i].id +"\nDATE : "+ response[i].u_date +"' border='0'>";
				
				var tmpMarginTop = '0';
				if(totalLan/4 > 1){
					tmpMarginTop = '15px';
				}
				//image or video icon add
				innerHTMLStr += "<div style='position:relative;width:30px; height:30px; margin:"+tmpMarginTop+" 0 0 20px;  background-image:url(<c:url value='images/geoImg/"+ response[i].datakind +"_marker.png'/>); zoom:0.7;'></div>";
				
				//xml file check icon add
				if(loadXML(response[i].filename, response[i].datakind) == 1){
					var tempTop = 8;
					var tempLeft = 66;
					innerHTMLStr += "<div style='position:relative; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px; background-image:url(<c:url value='images/geoImg/btn_image/xmlFile_w.png'/>);'></div>";
				}else{
					var tempTop = 8;
					var tempLeft = 66;
					innerHTMLStr += "<div style='position:relative; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px;'></div>";
				}
				
				innerHTMLStr += "<img class='round' src='<c:url value='"+ localAddress +"'/>' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' ";
				var tmpViewId = "MOVE_"+ response[i].datakind + "_" + response[i].idx;
				if($.inArray(tmpViewId, moveContentArr) > -1){
					innerHTMLStr += " style='border:3px solid red; margin: -51px 0 0 15px;/>";
				}else{
					innerHTMLStr += " style='border:2px solid #888888; margin: -51px 0 0 15px;'/>";
				}
				
				innerHTMLStr += "</a>";
				img_cell.innerHTML = innerHTMLStr;
				
				if(response[i].id == loginId || response[i].projectUserId == loginId){
					$('#Pro_'+response[i].datakind +"_"+response[i].idx).contextMenu('context2', {
						bindings: {
							'context_delete': function(t) {
// 								jConfirm('해당 컨텐츠를 삭제 하시겠습니까?', '정보', function(type){ 
								jConfirm('Are you sure you want to delete this content?', 'Info', function(type){ 
									if(type){
										var tbId = $(t).closest( 'table').attr( 'id' );
										removeContents(t.id.split("_")[1], t.id.split("_")[2], tbId.split('_')[1]);
									}
								});
							}
						}
					});
				}
			}
	}//for end
}

//XML 유무에 따라 썸네일 아이콘 추가
function loadXML(file_url, data_kind){
	
	var url_buf = file_url.split(".");
	var xml_file_name = url_buf[0] + '.xml';
	var file_check =0;
	
	$.ajax({
		type: "GET",
		url: 'Http://'+ location.host +'/'+ data_kind +'/upload/'+xml_file_name,
		dataType: "xml",
		cache: false,
		async: false,
		success: function(xml) {
			file_check = 1; //저작 됨
		},
		error: function(xhr, status, error) {
			file_check = 0; //저작 안됨
		}
	});
	
	return file_check;
}

//테이블에 페이지 추가
function addProjectPageCell(totalPage, pageNum) {
	var target = document.getElementById('pChild_'+ proIdx);
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '4';
	var leftMargin = 5;
	
	var innerHTMLStr = "<div id='pagingDiv_" + proIdx + "' style='margin-top:-8px;'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='float:left; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickProjectPage("+(pageGroup-10)+ ","+proIdx+",null);'></div>";
	}else{
		leftMargin += 18;
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='float:left; margin:4px 0 0 "+ leftMargin + "px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageMP(\"prev\","+ totalPage +","+pageNum+","+proIdx+");'></div>";
	}
	
	innerHTMLStr += "<div style='float:left; text-align:center;width:320px;'>";
	for(var i=pageGroup; i<(pageGroup+10); i++) {
		if(i>totalPage){
			continue;
		}
		innerHTMLStr += "<font color='#000'><a href="+'"'+"javascript:clickProjectPage('"+(i).toString()+"',"+proIdx+",null);"+'"';
		innerHTMLStr += " style='padding:2px 0 0 2px; text-decoration:none;'> ";
		if(pageNum == i){
			innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
		}else{
			innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
		}
		innerHTMLStr += (i).toString()+"</font></a></font>";
	}
	innerHTMLStr += "</div>";

	if(totalPage > 1){
		innerHTMLStr += "<div style='float:left; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageMP(\"next\","+ totalPage +","+pageNum+","+proIdx+");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='float:left; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickProjectPage("+(pageGroup+10)+","+proIdx+", null);'></div>";
	}
	
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
}

//move pageGroup : prev, next
function clickMovePageMP(cType, totalPage, pageNum, projectIdx){
	var movePage = 0;
	proIdx = projectIdx;
	$('#pChild_'+ proIdx).empty();
	if(cType == 'next'){
		if(pageNum+1 <= totalPage){
			movePage = pageNum+1;
		}
	}else{
		if(pageNum > 1){
			movePage = pageNum-1;
		}
	}
	if(movePage > 0){
		addProjectPageCell(totalPage, movePage);
		clickProjectPage(movePage, projectIdx ,null);
	}
}

//프로젝트 명 추가 dialog Open
function openAddProjectName(){
	proIdx = 0;
	nowProTabIdx = null;
	$('#projectNameAddDig #saveBtn').css('display','inline-block');
	$('#projectNameAddDig #modifyBtn').css('display','none');
	$('#projectNameAddDig #removeBtn').css('display','none');
	$('#projectNameTxt').val('');
	getTabList();
}

//프로젝트 명 추가 dialog close
function closeAddProjectName(){
	shareInit();
	$('#projectNameAddDig').dialog('close');
}

//project modify
function editProject(projectIdx){
	editBtnClk = 1;
	var tmpProName = $('#hiddenProName_'+ projectIdx).val();
	var tmpProShare = $('#hiddenShareType_'+projectIdx).val();
	var tmpImgIcon = $('#markerIcon_'+projectIdx).attr('src');
	
	nowProTabIdx = $('#hiddenTabIdx_'+ projectIdx).val();

	$('#projectNameTxt').val(tmpProName);
	oldShareUser = tmpProShare;
	proIdx = projectIdx;
	$('input[name=shareRadio]:radio[value='+ tmpProShare +']').attr('checked',true);
	
	clickProjectPage(1, projectIdx, 'editView');
}

function editDiagOpen(totalLen){
	if(totalLen == 0){
		$('#projectNameAddDig #removeBtn').css('display','inline-block');
	}else{
		$('#projectNameAddDig #removeBtn').css('display','none');
	}
	$('#projectNameAddDig #saveBtn').css('display','none');
	$('#projectNameAddDig #modifyBtn').css('display','inline-block');
	getTabList();
}

//open shareUser list
function getShareUser(){
	contentViewDialog = jQuery.FrameDialog.create({
		url:'<c:url value="/geoCMS/share.do" />?shareIdx='+ proIdx +'&shareKind=GeoProject',
		width: 370,
		height: 535,
		buttons: {},
		autoOpen:false
	});
	contentViewDialog.dialog('widget').find('.ui-dialog-titlebar').remove();
	contentViewDialog.dialog('open');
}

//add project name
function addProjectName(){
	var projectNameTxt = $('#projectNameTxt').val();
	var projectShareUser = $('#shareAdd').val();
	var projectEditYes = $('#editYes').val();
	var projectShareType = $('input[name=shareRadio]:checked').val();
	
	if(projectNameTxt == null || projectNameTxt == ''){
// 		jAlert('프로젝트 명을 입력해 주세요.', '정보');
		jAlert('Please enter project name.', 'Info');
		return;
	}
	
	if(projectShareType != null && projectShareType == 2 && (projectShareUser == null || projectShareUser == '')){
// 	 	jAlert('공유 유저가 지정되지 않았습니다.', '정보');
	 	jAlert('No sharing user specified.', 'Info');
	 	return;
	}
	
	if(projectNameTxt != null && projectNameTxt.indexOf('\'') > -1){
// 		jAlert('프로젝트 명에 특수문자 \' 는 사용할 수 없습니다.', '정보');
		jAlert('You can not use the special character \' in the project name.', 'Info');
		return;
	}
	
	projectNameTxt = dataReplaceFun(projectNameTxt);

	if(projectShareUser == null || projectShareUser == ''){
		projectShareUser = '&nbsp';
	}
	
	if(projectEditYes == null || projectEditYes == ''){
		projectEditYes = '&nbsp';
	}
	
	var Url			= baseRoot() + "cms/saveProject/";
	var param		= loginToken + "/"+ loginId + "/" + projectNameTxt + "/" + projectShareType + "/" + projectShareUser + "/"+ projectEditYes;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == "100" && data.Data != null){
				var projectTabIdx = $('#tabSelect').val();
				if(projectTabIdx != null && projectTabIdx != ''){
					
					var Url			= baseRoot() + "cms/updateContentTab/";
	     			var param		= loginToken + "/" + loginId + "/"+ projectTabIdx +"/" + data.Data + "/GeoProject";
	     			var callBack	= "?callback=?";
	     			$.ajax({
	     				type	: "POST"
	     				, url	: Url + param + callBack
	     				, dataType	: "jsonp"
	     				, async	: false
	     				, cache	: false
	     				, success: function(data) {
	     					if(data.Code == '100'){
	     						viewMyProjects(data.Data);
								jAlert(data.Message, 'Info', function(res){
	     							closeAddProjectName();
	     						});
	     					}else{
	     						closeAddProjectName();
	     						jAlert(data.Message, 'Info');
	     						viewMyProjects(null);
	     					}
	     				}
	     			});
				}else{
					closeAddProjectName();
					jAlert(data.Message, 'Info');
					viewMyProjects(null);
				}
			}else{
				closeAddProjectName();
				jAlert(data.Message, 'Info');
				viewMyProjects(null);
			}
		}
	});
}

//modify project name
function modifyProjectName(){
	var projectNameTxt = $('#projectNameTxt').val();
	var projectShareType = $('input[name=shareRadio]:checked').val();
	
	var projectAddShareUser = $('#shareAdd').val();
	var projectRemoveShareUser = $('#shareRemove').val();
	var projectEditYes = $('#editYes').val();
	var projectEditNo = $('#editNo').val();
	
	if(projectNameTxt == null || projectNameTxt == ''){
// 		jAlert('프로젝트 명을 입력해 주세요.', '정보');
		jAlert('Please enter project name.', 'Info');
		return;
	}
	
	if(projectShareType != null && projectShareType == 2 && (projectAddShareUser == null || projectAddShareUser == '') && oldShareUser != 2){
// 	 	jAlert('공유 유저가 지정되지 않았습니다.', '정보');
	 	jAlert('No sharing user specified.', 'Info');
	 	return;
	}
	
	if(projectNameTxt != null && projectNameTxt.indexOf('\'') > -1){
// 		jAlert('프로젝트 명에 특수문자 \' 는 사용할 수 없습니다.', '정보');
		jAlert('You can not use the special character \' in the project name.', 'Info');
		return;
	}

	projectNameTxt = dataReplaceFun(projectNameTxt);
	
	if(projectAddShareUser == null || projectAddShareUser == ''){ projectAddShareUser = '&nbsp'; }
	if(projectRemoveShareUser == null || projectRemoveShareUser == ''){ projectRemoveShareUser = '&nbsp'; }
	if(projectEditYes == null || projectEditYes == ''){ projectEditYes = '&nbsp'; }
	if(projectEditNo == null || projectEditNo == ''){ projectEditNo = '&nbsp'; }
	
	var Url			= baseRoot() + "cms/updateProject/";
	var param		= loginToken + "/"+ loginId + "/" + proIdx + "/" + projectNameTxt + "/" + projectShareType + "/" + projectAddShareUser + "/"+ projectRemoveShareUser + "/" + projectEditYes+ "/" + projectEditNo;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var projectTabIdx = $('#tabSelect').val();
			if(data.Code == "100" && projectTabIdx != null && projectTabIdx != '' && projectTabIdx != nowProTabIdx){
 				var Url			= baseRoot() + "cms/updateContentTab/";
     			var param		= loginToken + "/" + loginId + "/"+ projectTabIdx +"/" + proIdx + "/GeoProject";
     			var callBack	= "?callback=?";
     			$.ajax({
     				type	: "POST"
     				, url	: Url + param + callBack
     				, dataType	: "jsonp"
     				, async	: false
     				, cache	: false
     				, success: function(data) {
     					if(data.Code == '100'){
     						viewMyProjects(proIdx);
     						closeAddProjectName();
     						jAlert(data.Message, 'Info');
     					}else{
     						closeAddProjectName();
     						jAlert(data.Message, 'Info');
     						viewMyProjects(null);
     					}
     				}
     			});
			}else{
				viewMyProjects(proIdx);
				closeAddProjectName();
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//make content
function myContentsMake(){
	ContentsMakes('Image','','');
}

function removeContents(type, tmpIdArr, parentId){
	var Url			= baseRoot() + "cms/deleteContent/";
	var param		= loginToken + "/"+ loginId + "/" + type + "/" + tmpIdArr;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			viewMyProjects(parentId);
			jAlert(data.Message, 'Info');
		}
	});
}

function shareInit(){
	$('#shareAdd').val('');
	$('#shareRemove').val('');
	$('#editYes').val('');
	$('#editNo').val('');
	$('#clonSharUser').empty();
	oldShareUser = 0;
}

//move btn click
function moveProContent(){
	if(proEdit == 0){
		proEdit = 1;
		//project name setting
		var innerHTML = '';
		$.each($('.titleLabel'), function(idx, val){
			var tmpIdx = $(this).parent().attr('id').split('_');
			var tmpProUserIn = $('#hiddenProUserIn_'+tmpIdx[1]).val();
			if(tmpProUserIn == 'Y' || $(this).parent().children().hasClass('editProBtn')){
				var tmpShare = $('#hiddenShareType_'+tmpIdx[1]).val();
				var tmpText = $('#hiddenProName_'+tmpIdx[1]).val();
				innerHTML += '<option value="'+ tmpIdx[1] +'_'+ tmpShare+'">'+ tmpText +'</option>';
			}
		});
		$('#moveContentSel').append(innerHTML);
		$('#moveContentBtn').removeClass('offMoveCon');
		$('#moveContentBtn').addClass('onMoveCon');
		$('#moveContentView').css('display','block');
		$('.editProBtn').css('display','none');
		$('.editFileBtn').css('display','none');
		$('#myProject_list #makeContents').css('display','none');
		$('#proAddBtn').css('visibility','hidden');
		$('#image_map').append('<div id="mapNo" style="width:'+ $('#image_map').width() +'px; height:'+ $('#image_map').height() +'px;top: 0;background-color: gray;position: absolute;z-index: 100;opacity: 0.2;"></div>');
	}else{
		proEdit = 0;
		moveContentArr = new Array();
		$('#moveContentBtn').addClass('offMoveCon');
		$('#moveContentBtn').removeClass('onMoveCon');
		$('.imageTag').find('img').css('border', '2px solid #888888');
		$('#moveContentSel').empty();
		$('#moveContentViewSub').empty();
		$('#moveContentView').css('display','none');
		$('.editProBtn').css('display','block');
		$('.editFileBtn').css('display','block');
		$('#myProject_list #makeContents').css('display','block');
		$('#proAddBtn').css('visibility','visible');
		$('#mapNo').remove();
	}
	
}

var moveContentArr = new Array();
//move content add
function moveContentAdd(objArr){
	objArr = objArr.split(",");
	
	if(objArr[7] != loginId){
// 		jAlert('다른 사용자의 컨텐츠는 이동 할 수 없습니다.', '정보');
		jAlert('Other users content can not be moved.', 'Info');
		return;
	}
	
	var tbId = $('#Pro_'+ objArr[4] + '_'+ objArr[3]).closest('table').attr('id');
	if(tbId != null && tbId != '' && tbId != undefined){
		var tmpProIdx = tbId.split('_')[1];
		var isEditCru = $('#pName_'+tmpProIdx).children().hasClass('editProBtn');
		if(isEditCru){
			var tmpDivID = 'MOVE_'+ objArr[4] + '_'+ objArr[3];
			if($.inArray(tmpDivID, moveContentArr) > -1){
				moveContentRemove(tmpDivID);
				return;
			}
			
			moveContentArr.push(tmpDivID);

			$('#Pro_'+ objArr[4] + '_'+ objArr[3]).find('img').css('border', '3px solid red');
			
			var localAddress = ftpBaseUrl() + "/" + objArr[4];
			
			if(objArr[4] == "GeoPhoto"){
				var tmpThumbFileName = objArr[2].split('.');
				localAddress += "/"+tmpThumbFileName[0] +'_thumbnail.png';
			}else if(objArr[4] == "GeoVideo"){
				localAddress += "/"+objArr[6];
			}
			
			var innerHTMLStr = '';
			innerHTMLStr += "<a class='imageTag' id='MOVE_"+ objArr[4] + "_"+ objArr[3] +"' href='javascript:;' ";
			var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
			innerHTMLStr += '"'+" border='0'>";

			innerHTMLStr += "<img class='round' src='<c:url value='"+ localAddress +"'/>' width='90' height='70' hspace='10' vspace='10' style='border:2px solid #888888'/>";
			innerHTMLStr += "</a>";
			$('#moveContentViewSub').append(innerHTMLStr);
			
			$('#'+tmpDivID).contextMenu('context2', {
				bindings: {
					'context_delete': function(t) {
// 						jConfirm('현재 목록에서 제거 하시겠습니까?', '정보', function(type){
						jConfirm('Remove from current list?', 'Info', function(type){ 
							if(type){
								moveContentRemove(t.id);
							}
						});
					}
				}
			});
		}else{
// 			jAlert('공유받은 컨텐츠는 이동 할 수 없습니다.', '정보');
			jAlert('Shared content can not be moved.', 'Info');
		}
	}
}

function moveContentRemove(pId){
	var tmpArr = pId.split("_");
	if($.inArray(pId, moveContentArr) > -1){
		moveContentArr.splice($.inArray(pId, moveContentArr),1);
	}
	
	$('#'+pId).remove();
	$('#Pro_'+ tmpArr[1] + '_'+ tmpArr[2]).find('img').css('border', '2px solid #888888');
}

function moveProjectSave(){
	var moveProIS = $('#moveContentSel').val();
	if(moveContentArr == null || moveContentArr.length < 1){
// 		jAlert('컨텐츠를 선택해 주세요.', '정보');
		jAlert('Please select content.', 'Info');
		return;
	}
	
	var moveContentArrTmp = new Array();
	$.each(moveContentArr,function(idx,val){
		val = val.replace('MOVE_','');
		moveContentArrTmp.push(val);
	});
	
	var moveProISIdx = "";
	var moveProISShare = "";
	if(moveProIS != null && moveProIS != ""){
		moveProISIdx = moveProIS.split("_")[0];
		moveProISShare = moveProIS.split("_")[1];
	}
	
	if(moveProISIdx == null || moveProISIdx == "" || moveProISShare == null || moveProISShare == ""){
// 		jAlert('이동할 프로젝트를 선택해 주세요.', '정보');
		jAlert('Please select a project to move.', 'Info');
		return;
	}
	
	var Url			= baseRoot() + "cms/moveProject/";
	var param		= loginToken + "/" + loginId + "/"+ moveProISIdx + "/" + moveContentArrTmp;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				viewMyProjects(null);
			}
			jAlert(data.Message, 'Info');
		}
	});
}

function removeProjectName(){
// 	jConfirm('정말 삭제하시겠습니까?', '정보', function(type){
	jConfirm('Are you sure you want to delete?', 'Info', function(type){
		if(type){ 
			var Url			= baseRoot() + "cms/removeProject/";
			var param		= loginToken + "/" + loginId + "/"+ proIdx;
			var callBack	= "?callback=?";
			
			$.ajax({
				type	: "POST"
				, url	: Url + param + callBack
				, dataType	: "jsonp"
				, async	: false
				, cache	: false
				, success: function(data) {
					viewMyProjects(null);
					closeAddProjectName();
					jAlert(data.Message, 'Info');
				}
			});
		} 
	});
}

//project marker 
var markerProArr = new Array();
function projectMarkerData(tmpProIdx){
	$('#polygonView').attr('checked',false);
	//지도 데이터 초기화
	markerArr = new Array();
	markerFileList = null;
	//set map option
	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
	//create map
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	var tmpIdx = $.inArray(tmpProIdx, markerProArr);
	if(tmpIdx < 0){
		markerProArr.push(tmpProIdx);
	}else{
		markerProArr.splice(tmpIdx,1);
	}

	if(markerProArr == null || markerProArr.length <= 0){
		var marker_latlng = new google.maps.LatLng(dMarkerLat, dMarkerLng);
    	map.setCenter(marker_latlng);
    	map.setZoom(setObj.mapZoom);
    	return;
	}
	
	var Url			= baseRoot() + "cms/getProjectContent/";
	var param		= loginToken + "/" + loginId + "/marker/" + markerProArr + "/&nbsp;/&nbsp;";
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			if(response != null && response != '' && data.Code == '100'){
				markDataMake(response);
			}else{
// 				jAlert("위치정보가 존재하지 않습니다.", '정보');
				jAlert("Location information does not exist.", 'Info');
				var marker_latlng = new google.maps.LatLng(dMarkerLat, dMarkerLng);
		    	map.setCenter(marker_latlng);
		    	map.setZoom(setObj.mapZoom);
		    	return;
			}
		}
	});
}

//file upload dialog open
function openProjectViewer(projectIdx){
	editBtnClk = 1;
	
	var Url			= baseRoot() + "cms/getProjectContent/";
	var param		= loginToken + "/" + loginId + "/list/" + projectIdx + "/1/1";
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			if(response != null && response != '' && data.Code == '100' && response.length > 0){
				if(response[0].datakind == 'GeoPhoto'){
					imageViewer(response[0].filename, response[0].id, response[0].idx, response[0].projectuserid);
				}else if(response[0].datakind == 'GeoVideo'){
					videoViewer(response[0].filename, response[0].orignname, response[0].id, response[0].idx, response[0].projectuserid);
				}
			}else{
				jAlert("There is no content.","Info");
			}
		}
	});
}

//새창 띄우기 (저작)
function openProjectWriter() {
	editBtnClk = 1;
	
	var objTIdx = 0; 
	var objTDataKind = "";
	var objTArr = [];
	$('.editAnno').each(function(idx,val){
		objTIdx =$(val).parent().attr('id');
	});
	
	if(objTIdx != null && objTIdx != '' ){
		objTArr = objTIdx.split('_');
		objTIdx = objTArr[2];
		objTDataKind = objTArr[1];
		
		if(objTIdx != null && objTIdx != '' && objTDataKind != null && objTDataKind != ''){
			var Url			= baseRoot() + "cms/getShareUser/";
			var param		= loginToken + "/" + loginId + "/" + objTIdx + "/"+objTDataKind;
			var callBack	= "?callback=?";
			var tmpEditUserYN  = 0;
			
			$.ajax({
				  type	: "get"
				, url	: Url + param + callBack
				, dataType	: "jsonp"
				, async	: false
				, cache	: false
				, success: function(response) {
					if(response.Code == 100 && response.Data[0].shareedit == 'Y'){
						tmpEditUserYN = 1;
					}
					if(objTDataKind == 'GeoPhoto'){
						getOneImageData(objTIdx, tmpEditUserYN);
					}else if(objTDataKind = 'GeoVideo'){
						getOneVideoData(objTIdx, tmpEditUserYN);
					}
				}
			});
			
		}else{
			jAlert("Please select content.","Info");
		}
	}else{
		jAlert("Please select content.","Info");
	}
	
}

//get on image
function getOneImageData(tmpTIdx, tmpEditUserYN){
	var Url			= baseRoot() + "cms/getImage/";
	var param		= "one/" + loginToken + "/" + loginId + "/&nbsp/&nbsp/&nbsp/" +tmpTIdx;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				var response = data.Data;
				if(response != null && response != ''){
					response = response[0];
					
					if(tmpEditUserYN == 0 && (response.projectuserid == loginId && response.projectuserid != response.id)){
						tmpEditUserYN = 1;
					}
					var base_url = 'http://'+location.host;
					window.open('', 'image_write_page', 'width=1150, height=830');
					var form = document.createElement('form');
					form.setAttribute('method','post');
					form.setAttribute('action',base_url + "/GeoPhoto/geoPhoto/image_write_page.do?loginToken="+loginToken+"&loginId="+loginId+'&projectBoard=1&editUserYN='+tmpEditUserYN+'&projectUserId='+response.projectuserid);
					form.setAttribute('target','image_write_page');
					document.body.appendChild(form);
					
					var insert = document.createElement('input');
					insert.setAttribute('type','hidden');
					insert.setAttribute('name','file_url');
					insert.setAttribute('value',response.filename);
					form.appendChild(insert);
					
					var insertIdx = document.createElement('input');
					insertIdx.setAttribute('type','hidden');
					insertIdx.setAttribute('name','idx');
					insertIdx.setAttribute('value',tmpTIdx);
					form.appendChild(insertIdx);
					
					form.submit();
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

//get one video
function getOneVideoData(tmpTIdx, tmpEditUserYN){
	var Url			= baseRoot() + "cms/getVideo/";
	var param		= "one/" + loginToken + "/" + loginId + "/&nbsp/&nbsp/&nbsp/" +tmpTIdx;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == 100){
				var response = data.Data;
				
				if(response != null && response != ''){
					response = response[0];
					
					if(tmpEditUserYN == 0 && (response.projectuserid == loginId && response.projectuserid != response.id)){
						tmpEditUserYN = 1;
					}
					var base_url = 'http://'+location.host;
					window.open('', 'video_write_page', 'width=1145, height=926');
					var form = document.createElement('form');
					form.setAttribute('method','post');
					form.setAttribute('action',base_url + "/GeoPhoto/geoVideo/video_write_page.do?loginToken="+loginToken+"&loginId="+loginId+'&projectBoard=1&editUserYN='+tmpEditUserYN+'&projectUserId='+response.projectuserid);
					form.setAttribute('target','video_write_page');
					document.body.appendChild(form);
					
					var insert = document.createElement('input');
					insert.setAttribute('type','hidden');
					insert.setAttribute('name','file_url');
					insert.setAttribute('value',response.filename);
					form.appendChild(insert);
					
					var insertIdx = document.createElement('input');
					insertIdx.setAttribute('type','hidden');
					insertIdx.setAttribute('name','idx');
					insertIdx.setAttribute('value',tmpTIdx);
					form.appendChild(insertIdx);
					
					form.submit();
				}
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}


//file change
function fileChangeInfo(obj){
	$('#floorMap_pop_file_1').empty();
	
	var tmpHtml = '';
	for(var i=0; i<obj.files.length;i++){
		tmpHtml += "<div style='margin:5px 0 5px 10px; text-decoration:underline; color:gray;'>"+ obj.files[i].name +"</div>";
	}
	$('#floorMap_pop_file_1').append(tmpHtml);
}

//file upload save
function createUploadFile() {
	if(loginId != '' && loginId != null) {
		$('#fileinfo').append($('#file_1'));	//선택 파일 버튼 폼객체에 추가
		
		var uploadFileLen = $('#fileinfo').children().length;
		if(uploadFileLen <= 0){
// 			 jAlert('컨텐츠를 선택해 주세요.', '정보');
			 jAlert('Please select content.', 'Info');
			 return;
		}
		var uploadProIdx = $('#uploadFileProIdx').val();
		
		$('#uploadWorldFileDig').append('<div class="lodingOn"></div>');
		var iframe = $('<iframe name="postiframe" id="postiframe" style="display: none"></iframe>');
        $("body").append(iframe);

        var form = $('#fileinfo');
        var resAddress = baseRoot() + "cms/saveWorldFile/";
		resAddress += loginToken + "/" + loginId + "/" + uploadProIdx;
        resAddress += "?callback=?";
         
        form.attr("action", resAddress);
        form.attr("method", "POST");

        form.attr("encoding", "multipart/form-data");
        form.attr("enctype", "multipart/form-data");

        form.attr("target", "postiframe");
        form.attr("file", $('#file_1').val());
        form.submit();
         
        $("#postiframe").load(function (e) {
         	var doc = this.contentWindow ? this.contentWindow.document : (this.contentDocument ? this.contentDocument : this.document);
         	var root = doc.documentElement ? doc.documentElement : doc.body;
         	var data = root.textContent; ////////// ? root.textContent : root.innerText;
            data = data.replace("?","").replace("(","");
            data = data.substring(0, data.length -1);
         	var resData = JSON.parse(data);
            
         	if(resData != null && resData != ''){
         		if(resData.Code == 100){
         			viewMyProjects(uploadProIdx);
					jAlert(resData.Message, 'Info', function(res){
						$('.lodingOn').remove();
						cancelUploadFile();
					});
				}else{
					jAlert(resData.Message, 'Info');
					$('.lodingOn').remove();
				}
			}else{
				$('.lodingOn').remove();
			}
         });
	}
	else {
		window.parent.closeUpload();
// 		jAlert('로그인 정보를 잃었습니다.', 'Info');
		jAlert('I lost my login information.', 'Info');
	}
}

//file upload dialog close
function cancelUploadFile(){
	$('#uploadFileProIdx').val('');
	$('#uploadWorldFileDig').dialog('close');
}

//tab select
function getTabList() {
	$('#tabSelect').empty();
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
				result = data.Data;
				if(result != null && result.length > 0){
					var innerHTML = '';
					for(var i=1;i<result.length; i++){
						if(result[i].tabgroup == 'content'){
							innerHTML += '<option value="'+ result[i].tabidx +'" ';
							if(nowProTabIdx != null && nowProTabIdx != '' && nowProTabIdx != undefined){
								if(result[i].tabidx == nowProTabIdx){
									innerHTML += ' selected="selected" ';
								}
							}
							innerHTML += '>'+ result[i].tabname +'</option>';
						}
					}
					$('#tabSelect').append(innerHTML);
				}
				$('#projectNameAddDig').dialog('open');
			}else{
				jAlert(data.Message, 'Info');
			}
		}
	});
}

</script>
	<div>
		<label style="margin-left: 15px;">Layer</label>
		<button id='proAddBtn' onclick='openAddProjectName();'>ADD</button>
<!-- 		<button onclick='moveProContent();' style="float:right; margin-right:10px; color:white; border-radius: 5px;" class='offMoveCon' id='moveContentBtn'>Move Content</button> -->
	</div>
	<div id="project_list_table" style="height: 750px; overflow-y:scroll;"></div>
	<button id="makeContents" onclick="myContentsMake();">make Contents</button>
	
	<!-- projectName dialog -->
	<div id="projectNameAddDig">
		<table style="width: 100%;">
			<tr>
				<td style="width:100px;">Tab Name</td>
				<td><select id="tabSelect" style="width:100%;"></select>
			</tr>
			<tr>
				<td style="width:100px;">Layer Name</td>
				<td><input type="text" id="projectNameTxt" style="width:100%;" /></td>
			</tr>
			<tr class="showDivTR">
				<td colspan="2">
<!-- 					<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked" onclick="shareInit();">비공개</div> -->
<!-- 					<div style="float:left;"><input type="radio" value="1" name="shareRadio" onclick="shareInit();">전체공개</div> -->
<!-- 					<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div> -->
					<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked" onclick="shareInit();">private</div>
					<div style="float:left;"><input type="radio" value="1" name="shareRadio" onclick="shareInit();">public</div>
					<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">sharing with friends</div>
				</td>
			</tr>
			<tr style="text-align: center;">
				<td colspan="2">
					<input type="button" id="saveBtn" value="Save" onclick="addProjectName();"/>
					<input type="button" id="modifyBtn" value="Modify" style="display:none;" onclick="modifyProjectName();"/>
					<input type="button" id="removeBtn" value="Remove" style="display:none;" onclick="removeProjectName();"/>
					<input type="button" value="Cancel" onclick="closeAddProjectName();"/>
				</td>
			</tr>
		</table>
	</div>
	
	
	<div style="display: none;" id="moveContentView">
		<div>
			<label style="color: white;">Layer Name:</label>
			<select id="moveContentSel"></select>
			<button onclick="moveProjectSave();" >Move Layer</button>
		</div>
		<div id="moveContentViewSub"></div>
	</div>
	
	<div id="context2" class="contextMenu">
		<ul>
			<li id="context_delete">Delete</li>
		</ul>
	</div>
	
	<div id="uploadWorldFileDig" style="background: #e5e5e5;">
		<table style="width: 100%;" border=1>
			<tr>
				<td style="width:50px; text-align: center;">FILE</td>
				<td id="file_upload_td">
					<div class="file_input_div" style="float: left;">
						<div class="file_input_img_btn"> Load </div>
					</div>
					
					<div id="floorMap_pop_file_1" class="text_box_dig" style="width:244px; height: 72px; overflow-y:auto; overflow-x:hidden; margin:8px 0 8px 10px; border:1px solid gray; float: left;"></div>
					<input type="hidden" id="uploadFileProIdx">
				</td>
			</tr>
			<tr>
				<td width="" height="25" align="center" colspan="2">
					<button class="create_button" onclick="createUploadFile();">SAVE</button>
					<button class="cancle_button" onclick="cancelUploadFile();">CANCLE</button>
				</td>
			</tr>
		</table>
	</div>
	
	<form enctype="multipart/form-data" method="POST" name="fileinfo" id="fileinfo" style="display:none;" >
	</form>

	<input type="hidden" id="shareAdd"/>
	<input type="hidden" id="shareRemove"/>
	<input type="hidden" id="editYes"/>
	<input type="hidden" id="editNo"/>
	<div id="clonSharUser" style="display:none;"></div>
