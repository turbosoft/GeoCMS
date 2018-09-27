<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">

<script type="text/javascript">
var contentNowPageNum = 1;		//현재 페이지 번호

//게시물 페이지 설정
function leftPageSetup(totalRes, obj) {
	var contentNum = obj.content_num;
	var tName = nowTabName;
	if(editMode == 1){
		tName = tempTabName;
	}
	var totalPage = 1;
	
	if(totalRes % contentNum == 0){
		totalPage = parseInt(totalRes / contentNum);
	}else{
		totalPage = parseInt(totalRes / contentNum)+1;
	}
	
	//테이블에 페이지 추가
	addImagePageCell(totalPage,obj.pageNum);
	
	if(obj.pageNum == '1'){
		initialize();
	}
}

//테이블에 페이지 추가
function addImagePageCell(totalPage, pageNum) {
	var target = document.getElementById("left_list_table_1");
	contentNowPageNum = pageNum;
	
	var row = target.insertRow(-1);
	var cell = row.insertCell(-1);
	cell.colSpan = '3';

	var innerHTMLStr = "<div id='pagingDiv'>";
	var pageGroup = 0;
	if(pageNum%10 == 0){
		pageGroup = (pageNum/10-1)*10+1;
	}else{
		pageGroup = Math.floor(pageNum/10)*10+1;
	}

	if(pageGroup > 1){
		innerHTMLStr += "<div style='position:absolute;left:25px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DL.png'/>); width: 18px;height: 14px; background-repeat:no-repeat;cursor:pointer;' onclick='clickImagePage("+(pageGroup-10)+",1);'></div>";
	}
	
	if(totalPage > 1){ 
		innerHTMLStr += "<div style='position:absolute;left:50px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_L.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageICL(\"prev\","+ totalPage +");'></div>";
	}

	innerHTMLStr += "<div style='position:absolute;left:55px;text-align:center;width:290px;'>";
	
	if(!isNaN(totalPage)){
		for(var i=pageGroup; i<(pageGroup+10); i++) {
			if(i>totalPage){
				continue;
			}
			innerHTMLStr += "<font color='#000'><a href="+'"'+ "javascript:clickImagePage('"+(i).toString()+"', '1');"+'"';
			innerHTMLStr += " style='padding:2px 2px 0 2px; text-decoration:none;'> ";
			if(pageNum == i){
				innerHTMLStr += " <font color='#066ab0' style='font-weight:900; font-size:12px;'>";
			}else{
				innerHTMLStr += " <font color='#6d808f' style='font-size:12px;'> ";
			}
			innerHTMLStr += (i).toString()+"</font></a></font>";
		}
	}
	
	innerHTMLStr += "</div>";
	
	if(totalPage > 1){
		innerHTMLStr += "<div style='position:absolute;left:345px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_R.png'/>); width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickMovePageICL(\"next\","+ totalPage +");'></div>";
	}
	
	if(totalPage >= (pageGroup+10)){
		innerHTMLStr += "<div style='position:absolute;width:40px;left:360px; margin-top:4px; background-image: url(<c:url value='/images/geoImg/btn_image/paging_DR.png'/>);width: 18px;height: 14px; background-repeat:no-repeat; cursor:pointer;' onclick='clickImagePage("+ (pageGroup+10)+",1);'></div>";
	}
	
	innerHTMLStr += "</div>";
	cell.innerHTML = innerHTMLStr;
	if(editMode == 1 && select_mode != 2){
		editModeEvent();
	}
}

function clickMovePageICL(cType, totalPage){
	var movePage = 0;
	contentNowPageNum = Number(contentNowPageNum);
	if(cType == 'next'){
		if(contentNowPageNum+1 <= totalPage){
			movePage = contentNowPageNum+1;
		}
	}else{
		if(contentNowPageNum > 1){
			movePage = contentNowPageNum-1;
		}
	}
	
	if(movePage > 0){
		clickImagePage(movePage,1);
	}
}

function fuOrderTypeChange(oType){
	if(editMode == 1){
		return;
	}
	b_orderType = oType;
	if(oType == 'DESC'){
		$('#orderTypeDesc').css('display','block');
		$('#orderTypeAsc').css('display','none');
	}else{
		$('#orderTypeDesc').css('display','none');
		$('#orderTypeAsc').css('display','block');
	}
	mainProjectGroup("1", "list", "change");
}

</script>
<div style="height: 30px;" class="orderTypeClass">
	<div style="width: 50px;float: left;margin-left: 260px;margin-top: 2px;font-size: 15px;	">Date : </div>
	<div id="orderTypeDesc" onclick="fuOrderTypeChange('ASC');" style="display: block;width: 100px;background-color: #e4e4e4;border-radius: 5px;margin-bottom: 10px;text-align: center;height: 25px;line-height: 25px;cursor: pointer;float: left;">DESC ▼</div>
	<div id="orderTypeAsc" onclick="fuOrderTypeChange('DESC');" style="display: none;width: 100px;background-color: #e4e4e4;border-radius: 5px;margin-bottom: 10px;text-align: center;height: 25px;line-height: 25px;cursor: pointer;float: left;">ASC ▲</div>
</div>
<div id='mainProjectListView' style="width:100%;"></div>
<div id="imageMoveArea" style="width:420px; height:100%;">
</div>

<input type="hidden" id="shareAdd"/>
<input type="hidden" id="shareRemove"/>
<input type="hidden" id="editYes"/>
<input type="hidden" id="editNo"/>
<div id="clonSharUser" style="display:none;"></div>