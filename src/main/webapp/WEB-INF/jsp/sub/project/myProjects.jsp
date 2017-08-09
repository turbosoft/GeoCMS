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

function projectGroupListSetup(response){
	$('#project_list_table').empty();
	proIdx = response[0].IDX;
	shareInit();
	if(proEdit == 1){
		moveProContent();
	}
	
	markerProArr = new Array();
	addProjectGroupCell(response);
}

//project group list
function addProjectGroupCell(response){
	var innerHTML = '';
	
	if(response != null){
		for(var i=0;i<response.length;i++){
			var proShare = '';
			if(response[i].SHARETYPE == '1'){
				proShare = '전체공개';
			}else if(response[i].SHARETYPE == '0'){
				proShare = '비공개';
			}else{
				proShare = '선택공개';
			}
			
			var projectNameTxt = response[i].PROJECTNAME.length>22? response[i].PROJECTNAME.substring(0,22)+'...' : response[i].PROJECTNAME;
			
			innerHTML += '<div id="pName_'+ response[i].IDX +'" onclick="fnProjectDiv(this,'+response[i].IDX+');"';
			innerHTML += 'class="offProjectDiv">';
			innerHTML += '<input type="hidden" id="hiddenProName_'+ response[i].IDX +'" value="'+ response[i].PROJECTNAME +'"/>';
			innerHTML += '<input type="hidden" id="hiddenProUserIn_'+ response[i].IDX +'" value="'+ response[i].editUserIn +'"/>';
			innerHTML += '<input type="hidden" id="hiddenShareType_'+ response[i].IDX +'" value="'+ response[i].SHARETYPE +'"/>';
			innerHTML += '<label class="titleLabel">'+ projectNameTxt +'</label>';
			
			if(response[i].MARKERICON != null && response[i].MARKERICON != ''){
				innerHTML += '<img src="<c:url value="images/geoImg/map/markerIcon/'+ response[i].MARKERICON +'"/>" id="markerIcon_'+ response[i].IDX +'"  style="width:20px; height:20px; margin:5px 0 0 5px;"/>';
			}
			
			//edit btn
			if(loginId == response[i].ID){
				innerHTML += '<button onclick="editProject('+ response[i].IDX +');" class="editProBtn" style="border-radius:5px;"> EDIT </button>';
			}
			
			var tmpUserId = response[i].ID.length>7? response[i].ID.substring(0,7)+'...' : response[i].ID;
			
			innerHTML += '<div class="subDivCls"><label class="m_l_10">작성자: </label><label style="display:inline-block; width:65px;">'+ tmpUserId + '</label><label class="m_l_10">등록일: </label><label>' + response[i].U_DATE + '</label><label class="m_l_15">'+ proShare + '</label></div>';
			innerHTML += '</div>';
			
			innerHTML += '<table id="pChild_'+ response[i].IDX + '" style="border:1px solid gray; width:100%;"/>';
			innerHTML += '</div>';
		}
		
		$('#project_list_table').append(innerHTML);
		
		if(response[0].IDX != null && response[0].IDX != '' && response[0].IDX != undefined){
			fnProjectDiv($('#pName_'+response[0].IDX), response[0].IDX);
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
	var Url			= baseRoot() + "cms/getProject/";
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
					jAlert(data.Message, '정보');
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
		
		if(response[i] == null || response[i] == '' || response[i] == undefined ) {	//등록한 이미지가 없을때 나 
			innerHTMLStr += "<img class='round' src='"+ blankImg + "' width='" + imgWidth + "' height='" + imgHeight + "'hspace='10' vspace='10' style='border:2px solid white;'/>";
			img_cell.innerHTML = innerHTMLStr;
		}else{
			//타입 별 file 주소 설정
			var localAddress = "upload/" + response[i].DATAKIND;
			
			if(response[i].DATAKIND == "GeoPhoto"){
				localAddress += "/"+response[i].FILENAME;
			}else if(response[i].DATAKIND == "GeoVideo"){
				localAddress += "/"+response[i].THUMBNAIL;
			}
			
			innerHTMLStr += "<a class='imageTag' id='Pro_"+ response[i].DATAKIND +"_"+response[i].IDX +"' href='javascript:;' onclick="+'"';
			var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
			tempArr.push(response[i].LATITUDE);
			tempArr.push(response[i].LONGITUDE);
			tempArr.push(response[i].FILENAME);
			tempArr.push(response[i].IDX);
			tempArr.push(response[i].DATAKIND);
			tempArr.push(response[i].ORGINNAME);
			tempArr.push(response[i].THUMNAIL);
			tempArr.push(response[i].ID);
			tempArr.push(response[i].projectUserId);
			if(response[i].PROJECTMARKERICON != null){
				response[i].PROJECTMARKERICON = response[i].PROJECTMARKERICON.replace('_','&ubsp');
			}
			tempArr.push(response[i].PROJECTMARKERICON);
			tempArr.push(response[i].TITLE);
			tempArr.push(response[i].CONTENT);
			tempArr.push(response[i].U_DATE);
			innerHTMLStr += "mapCenterChange('"+ tempArr +"');";
			innerHTMLStr += '"'+" title='제목 : "+ response[i].TITLE +"\n내용 : "+ response[i].CONTENT +"\n작성자 : "+ response[i].ID +"\n작성일 : "+ response[i].U_DATE +"' border='0'>";
			
// 			var tmpMarginTop = '0';
// 			if(totalLan/4 > 1){
				var tmpMarginTop = '15px';
// 			}
			//image or video icon add
			innerHTMLStr += "<div style='position:relative;width:30px; height:30px; margin:"+tmpMarginTop+" 0 0 20px;  background-image:url(<c:url value='images/geoImg/"+ response[i].DATAKIND +"_marker.png'/>); zoom:0.7;'></div>";
			
			//xml file check icon add
			if(loadXML(response[i].FILENAME, response[i].DATAKIND) == 1){
				var tempTop = 8;
				var tempLeft = 66;
				innerHTMLStr += "<div style='position:relative; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px; background-image:url(<c:url value='images/geoImg/btn_image/xmlFile_w.png'/>);'></div>";
			}else{
				var tempTop = 8;
				var tempLeft = 66;
				innerHTMLStr += "<div style='position:relative; margin:"+ tempTop +"px 0 0 "+ tempLeft +"px; width:15px; height:20px;'></div>";
			}
			
			innerHTMLStr += "<img class='round' src='<c:url value='/"+ localAddress +"'/>' width='" + imgWidth + "' height='" + imgHeight + "' hspace='10' vspace='10' ";
			var tmpViewId = "MOVE_"+ response[i].DATAKIND + "_" + response[i].IDX;
			if($.inArray(tmpViewId, moveContentArr) > -1){
				innerHTMLStr += " style='border:3px solid red; margin: -51px 0 0 15px;/>";
			}else{
				innerHTMLStr += " style='border:2px solid #888888; margin: -51px 0 0 15px;'/>";
			}
			
			innerHTMLStr += "</a>";
			img_cell.innerHTML = innerHTMLStr;
			
			if(response[i].ID == loginId || response[i].projectUserId == loginId){
				$('#Pro_'+response[i].DATAKIND +"_"+response[i].IDX).contextMenu('context2', {
					bindings: {
						'context_delete': function(t) {
							jConfirm('해당 컨텐츠를 삭제 하시겠습니까?', '정보', function(type){ 
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
	}
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
// 	cell.height = '18px';
	
	var innerHTMLStr = "<div id='pagingDiv_" + proIdx + "' style='margin-top:-8px;'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}
	
	if(pageGroup > 1){
		innerHTMLStr += "<div style='float:left; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickProjectPage("+(pageGroup-10)+ ","+proIdx+",null);'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='float:left; margin:4px 0 0 5px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageMP(\"prev\","+ totalPage +","+pageNum+","+proIdx+");'></div>";
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
	$('#projectNameAddDig #saveBtn').css('display','inline-block');
	$('#projectNameAddDig #modifyBtn').css('display','none');
	$('#projectNameAddDig #removeBtn').css('display','none');
	$('#projectNameTxt').val('');
	
	$('#projectNameAddDig').dialog('open');
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

	$('#projectNameTxt').val(tmpProName);
	oldShareUser = tmpProShare;
	proIdx = projectIdx;
	$('input[name=shareRadio]:radio[value='+ tmpProShare +']').attr('checked',true);
	$('#nowMarkerIconDiv').append($('#markerIcon_42').clone());
	
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
	$('#projectNameAddDig').dialog('open');
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
	var projectMarkerIcon = '';
	
	if(projectNameTxt == null || projectNameTxt == ''){
		jAlert('프로젝트 명을 입력해 주세요.', '정보');
		return;
	}
	
	if(projectShareType != null && projectShareType == 2 && (projectShareUser == null || projectShareUser == '')){
	 	jAlert('공유 유저가 지정되지 않았습니다.', '정보');
	 	return;
	}
	
	projectNameTxt = projectNameTxt.replace(/\//g,'&sbsp');

	if(projectShareUser == null || projectShareUser == ''){
		projectShareUser = '&nbsp';
	}
	
	if(projectEditYes == null || projectEditYes == ''){
		projectEditYes = '&nbsp';
	}
	
	if(projectMarkerIcon == null || projectMarkerIcon == ''){
		projectMarkerIcon = '&nbsp';
	}
	
	var Url			= baseRoot() + "cms/saveProject/";
	var param		= loginToken + "/"+ loginId + "/" + projectNameTxt + "/" + projectShareType + "/" + projectShareUser + "/"+ projectEditYes + "/" + projectMarkerIcon;
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
			jAlert(data.Message, '정보');
		}
	});
}

//modify project name
function modifyProjectName(){
	var projectNameTxt = $('#projectNameTxt').val();
	var projectShareType = $('input[name=shareRadio]:checked').val();
	var projectMarkerIcon = $('#nowMarkerIconDiv').children().attr('src');
	
	var projectAddShareUser = $('#shareAdd').val();
	var projectRemoveShareUser = $('#shareRemove').val();
	var projectEditYes = $('#editYes').val();
	var projectEditNo = $('#editNo').val();
	
	if(projectNameTxt == null || projectNameTxt == ''){
		jAlert('프로젝트 명을 입력해 주세요.', '정보');
		return;
	}
	
	if(projectShareType != null && projectShareType == 2 && (projectAddShareUser == null || projectAddShareUser == '') && oldShareUser != 2){
	 	jAlert('공유 유저가 지정되지 않았습니다.', '정보');
	 	return;
	}

	projectNameTxt = projectNameTxt.replace(/\//g,'&sbsp');
	if(projectMarkerIcon == null || projectMarkerIcon == '' || projectMarkerIcon == undefined){ projectMarkerIcon = '&nbsp'; }else{projectMarkerIcon = projectMarkerIcon + '.+'}
	if(projectAddShareUser == null || projectAddShareUser == ''){ projectAddShareUser = '&nbsp'; }
	if(projectRemoveShareUser == null || projectRemoveShareUser == ''){ projectRemoveShareUser = '&nbsp'; }
	if(projectEditYes == null || projectEditYes == ''){ projectEditYes = '&nbsp'; }
	if(projectEditNo == null || projectEditNo == ''){ projectEditNo = '&nbsp'; }
	
	var Url			= baseRoot() + "cms/updateProject/";
	var param		= loginToken + "/"+ loginId + "/" + proIdx + "/" + projectNameTxt + "/" + projectShareType + "/" + projectAddShareUser + "/"+ projectRemoveShareUser + "/" + projectEditYes+ "/" + projectEditNo + "/" + projectMarkerIcon+'.+';
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "POST"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			viewMyProjects(proIdx);
			closeAddProjectName();
			jAlert(data.Message, '정보');
		}
	});
// 	shareInit();
}

//make content
function myContentsMake(){
	ContentsMakes(null,'Image','','');
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
			jAlert(data.Message, '정보');
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
		jAlert('다른 사용자의 컨텐츠는 이동 할 수 없습니다.', '정보');
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
			
			var localAddress = "upload/" + objArr[4];
			if(objArr[4] == "GeoPhoto"){
				localAddress += "/"+objArr[2];
			}else if(objArr[4] == "GeoVideo"){
				localAddress += "/"+objArr[6];
			}
			
			var innerHTMLStr = '';
			innerHTMLStr += "<a class='imageTag' id='MOVE_"+ objArr[4] + "_"+ objArr[3] +"' href='javascript:;' ";
			var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
			innerHTMLStr += '"'+" title='제목 : "+ objArr[10] +"\n내용 : "+ objArr[11] +"\n작성자 : "+ objArr[7] +"\n작성일 : "+ objArr[12] +"' border='0'>";

			innerHTMLStr += "<img class='round' src='<c:url value='/"+ localAddress +"'/>' width='80' height='60' hspace='10' vspace='10' style='border:2px solid #888888'/>";
			innerHTMLStr += "</a>";
			$('#moveContentViewSub').append(innerHTMLStr);
			
			$('#'+tmpDivID).contextMenu('context2', {
				bindings: {
					'context_delete': function(t) {
						jConfirm('현재 목록에서 제거 하시겠습니까?', '정보', function(type){ 
							if(type){
								moveContentRemove(t.id);
							}
						});
					}
				}
			});
		}else{
			jAlert('공유받은 컨텐츠는 이동 할 수 없습니다.', '정보');
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
		jAlert('컨텐츠를 선택해 주세요.', '정보');
		return;
	}
	
	var Url			= baseRoot() + "cms/moveProject/";
	var param		= loginToken + "/" + loginId + "/"+ moveProIS + "/" + moveContentArr;
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
			jAlert(data.Message, '정보');
		}
	});
}

function removeProjectName(){
	jConfirm('정말 삭제하시겠습니까?', '정보', function(type){
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
					jAlert(data.Message, '정보');
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
		var marker_latlng = new google.maps.LatLng(37.5663889, 126.9997222);
    	map.setCenter(marker_latlng);
    	map.setZoom(10);
    	return;
	}
	
	var Url			= baseRoot() + "cms/getProject/";
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
				jAlert("위치정보가 존재하지 않습니다.", '정보');
				var marker_latlng = new google.maps.LatLng(37.5663889, 126.9997222);
		    	map.setCenter(marker_latlng);
		    	map.setZoom(10);
		    	return;
			}
		}
	});
}

function openMarkerIconChange(){
	var tmpIconSrc = $('#nowMarkerIconDiv').children().attr('src');
	var nowMarkerIcon = '';
	if(tmpIconSrc != null && tmpIconSrc != '' && tmpIconSrc != undefined){
		nowMarkerIcon = tmpIconSrc.split('markerIcon/');
		nowMarkerIcon = nowMarkerIcon[1];
	}
	$('#markerIconDiv').empty();

	$.ajax({
		type	: "get"
		, url	: '<c:url value="/getMarkerIcon.do"/>'
		, success: function(data) {
			if(data != null && data != ''){
				var reslutArr = data.split(',');
				var innerHTMLStr = "";
				$.each(reslutArr, function(idx, val){
					val = val.trim();
					innerHTMLStr += "<div><img src='<c:url value='images/geoImg/map/markerIcon/"+ val +"'/>' style='width:30px; height:30px; float:left; margin:5px 0 0 5px;";
					if(nowMarkerIcon == val){
						innerHTMLStr += " ' class='markerIconSel_ON' ";
					}else{
						innerHTMLStr += " ' class='markerIconSel_OFF' "
					}
					innerHTMLStr += " id='"+ val +"' onclick='iconSelect(this);' /></div>";
				});
				$('#markerIconDiv').append(innerHTMLStr);
				$('#markerDig').dialog('open');
			}
		}
	});
}

function iconSelect(obj){
	if($(obj).hasClass('markerIconSel_ON')){
		$('.markerIconSel_ON').addClass('markerIconSel_OFF');
		$('.markerIconSel_ON').removeClass('markerIconSel_ON');
	}else{
		$('.markerIconSel_ON').addClass('markerIconSel_OFF');
		$('.markerIconSel_ON').removeClass('markerIconSel_ON');

	    $(obj).removeClass('markerIconSel_OFF');
	    $(obj).addClass('markerIconSel_ON');
	}
}

function markerIconChange(){
	var selectIcon = '';
	selectIcon = $('.markerIconSel_ON').attr('id');
	$('#nowMarkerIconDiv').empty();
	
	if(selectIcon != null && selectIcon != '' && selectIcon != undefined){
		var innerHTML = '<img src="<c:url value="images/geoImg/map/markerIcon/'+ selectIcon +'"/>" style="width:20px; height:20px; margin:5px 0 0 5px;"/>';
		$('#nowMarkerIconDiv').append(innerHTML);
	}
	closeMarkerIconChange();
}

function closeMarkerIconChange(){
	$('#markerDig').dialog('close');
}

</script>
	<div>
		<label style="margin-left: 15px;">My Project</label>
		<button id='proAddBtn' onclick='openAddProjectName();'>ADD</button>
		<button onclick='moveProContent();' style="float:right; margin-right:10px; color:white; border-radius: 5px;" class='offMoveCon' id='moveContentBtn'>Move Content</button>
	</div>
	<div id="project_list_table" style="height: 750px; overflow-y:scroll;"></div>
	<button id="makeContents" onclick="myContentsMake();">make Contents</button>
	
	<!-- projectName dialog -->
	<div id="projectNameAddDig">
		<table style="width: 100%;">
			<tr>
				<td style="width:100px;">Project Name</td>
				<td><input type="text" id="projectNameTxt" style="width:100%;" /></td>
			</tr>
	<!-- 		<tr id="addProjectTr"> -->
	<!-- 			<td colspan="2"> -->
	<!-- 				<label>Share User</label> -->
	<!-- 				<div id="projectShareUser"> -->
	<!-- 				</div> -->
	<!-- 			</td> -->
	<!-- 		</tr> -->
			<tr class="showDivTR">
				<td colspan="2">
					<div style="float:left;"><input type="radio" value="0" name="shareRadio" checked="checked" onclick="shareInit();">비공개</div>
					<div style="float:left;"><input type="radio" value="1" name="shareRadio" onclick="shareInit();">전체공개</div>
					<div style="float:left;"><input type="radio" value="2" name="shareRadio" onclick="getShareUser();">특정인 공개</div>
				</td>
			</tr>
			<tr style="display:none;">
				<td colspan="2">
					<input type="button" value="Marker 아이콘" onclick="openMarkerIconChange();" style="float:left; margin-top:5px;" />
					<div id="nowMarkerIconDiv" style="float:left;"></div>
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
	
	<!-- marker dialog -->
	<div id="markerDig">
		<table style="width: 100%;">
			<tr>
				<td colspan="2" style="width:100px;">marker List</td>
			</tr>
			<tr>
				<td colspan="2">
					<div id="markerIconDiv" style='width:360px; height:155px; background-color:#999; border:1px solid #999999; overflow-y:scroll;'></div>
				</td>
			</tr>
			<tr style="text-align: center;">
				<td colspan="2">
					<input type="button" value="ok" onclick="markerIconChange();"/>
					<input type="button" value="Cancel" onclick="closeMarkerIconChange();"/>
				</td>
			</tr>
		</table>
	</div>
	
	<div style="display: none;" id="moveContentView">
		<div>
			<label style="color: white;">Project Name:</label>
			<select id="moveContentSel"></select>
			<button onclick="moveProjectSave();" >Move Project</button>
		</div>
		<div id="moveContentViewSub"></div>
	</div>
	
	<div id="context2" class="contextMenu">
		<ul>
			<li id="context_delete">Delete</li>
		</ul>
	</div>

	<input type="hidden" id="shareAdd"/>
	<input type="hidden" id="shareRemove"/>
	<input type="hidden" id="editYes"/>
	<input type="hidden" id="editNo"/>
	<div id="clonSharUser" style="display:none;"></div>
