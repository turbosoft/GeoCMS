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

var searchSKind = '';

//검색 실행
function searchPageInit(text, boardChk, imageChk, videoChk, check, display) {
	var encode_text = encodeURIComponent(text);
	searchSKind = check;
	
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	if(tmpLoginId == null || tmpLoginId == '' || tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' || tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	
	var Url			= baseRoot() + "cms/searchList/";
	var param		= tmpLoginToken + "/" + tmpLoginId + "/" + text + "/" + boardChk + "/" + imageChk + "/" + videoChk + "/" + check + "/" + display + "/" + projectImage + "/"+projectVideo;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == '100'){
				var response = data.Data;
				
				//이미지 리스트 설정
				searchListSetup(response);
			}else{
				jAlert(data.Message, '정보');
			}
		}
	});
}

//이미지 리스트 설정
function searchListSetup(pure_data) {
	//전달할 각 속성을 배열에 저장
	var search_arr = new Array();
	var id_arr = new Array();
	var title_arr = new Array();
	var content_arr = new Array();
	var udate_arr = new Array();
	var file_url_arr = new Array();
	var idx_arr = new Array();
	var lati_arr = new Array(); //marker를 위한 latitude
	var longi_arr = new Array(); //marker를 위한 longitude
	var thumbnail_url_arr = new Array();
	var origin_url_arr = new Array();
	var dataKind_arr = new Array();
	
	for(var i=0; i<pure_data.length; i++) {
		search_arr.push(pure_data[i].SEARCHKIND);
		id_arr.push(pure_data[i].ID); //id 저장
		title_arr.push(pure_data[i].TITLE); //title 저장
		content_arr.push(pure_data[i].CONTENT); //content 저장
		udate_arr.push(pure_data[i].U_DATE);
		idx_arr.push(pure_data[i].IDX);
		lati_arr.push(pure_data[i].LATITUDE);
		longi_arr.push(pure_data[i].LONGITUDE);
		dataKind_arr.push(pure_data[i].DATAKIND);
		
		file_url_arr.push(pure_data[i].FILENAME);
		
		if(pure_data[i].ORIGINNAME != null){
			thumbnail_url_arr.push(pure_data[i].THUMBNAIL);
			origin_url_arr.push(pure_data[i].ORIGINNAME);
		}else{
			thumbnail_url_arr.push("blank");
			origin_url_arr.push("blank");
		}
	}
	SearchResultMarker(lati_arr, longi_arr, file_url_arr, thumbnail_url_arr, idx_arr, dataKind_arr, origin_url_arr, id_arr);
	
	//테이블 초기화
	clearSearchTable();
	//테이블에 데이터 추가
	for(var i=0; i<id_arr.length; i++) {
		addSearchDataCell(search_arr[i], id_arr[i], title_arr[i], content_arr[i], udate_arr[i], file_url_arr[i], thumbnail_url_arr[i], origin_url_arr[i], lati_arr[i], longi_arr[i], idx_arr[i], dataKind_arr[i]);
	}
}

//테이블에 데이터 추가
function addSearchDataCell(search, id, title, content, udate, file_url, thumbnail_url, origin_url, lat_arr, lon_arr, idx_arr, dataKind_arr) {

	var target = document.getElementById('search_content_list_table');
	var url = 'upload/'+ dataKind_arr+'/';
	
	var thumbnail_arr = "";
	//xml file check
	thumbnail_arr= loadXML(file_url, dataKind_arr);

	var row;
	row = target.insertRow(-1);
	row.setAttribute('bgcolor', '#e5e5e5');
	var img_cell = row.insertCell(-1);
	var innerHTMLStr = '';

	var tempArr = new Array; //mapCenterChange에 넘길 객체 생성
	tempArr.push(lat_arr);
	tempArr.push(lon_arr);
	tempArr.push(file_url);
	tempArr.push(idx_arr);
	tempArr.push(dataKind_arr);
	tempArr.push(origin_url);
	tempArr.push(thumbnail_url);
	tempArr.push(id);
	
	if(dataKind_arr != 'GeoCMS'){
		innerHTMLStr += "<a class='searchTag' href='javascript:;' onclick="+'"'+"mapCenterChange('"+ tempArr +"');"+'"'+" title='제목 : "+ title+"\n내용 : "+ content+"' border='0'>";
	}else{
		innerHTMLStr += "<a class='searchTag' href='javascript:;' onclick="+'"'+"boardViewDetail(this);"+'"'+" title='제목 : "+ title+"\n내용 : "+ content+"' border='0' id='GeoCMS_"+ idx_arr +"'>";
	}	

	//이미지 or 비디오 아이콘
	if(dataKind_arr != 'GeoCMS'){
		innerHTMLStr += "<div style='position:absolute; width:30px; height:30px; background-image:url(images/geoImg/"+ dataKind_arr +"_marker.png); zoom:0.7;left:22px;margin-top:18px;'></div>";
		if(thumbnail_arr == 1){
			innerHTMLStr += "<div style='position:absolute; margin:95px 0 0 125px; width:30px; height:30px; background-image:url(images/geoImg/thumbnail.png);'></div>";
		}
	}

	if(dataKind_arr=='GeoPhoto'){
		innerHTMLStr += "<img src='<c:url value='" + (url+file_url) + "'/>' width='140' height='110' hspace='10' vspace='10' border='3' style='border-color:#888888'/>";
	}else if(dataKind_arr=='GeoVideo'){
		innerHTMLStr += "<img src='<c:url value='" + (url+thumbnail_url) + "'/>' width='140' height='110' hspace='10' vspace='10' border='3' style='border-color:#888888'/>";
	}else{
		innerHTMLStr += "<img src='images/geoImg/blank(100x70).PNG' width='140' height='65' hspace='10' vspace='10' border='3' style='border-color:#888888'/>";
	}

	innerHTMLStr += "</a>";
	img_cell.innerHTML = innerHTMLStr;
	var txt_cell1 = row.insertCell(-1);
	innerHTMLStr = "<div style='width:202px;'>&nbsp<label style='color:#000; font-size:12px;'><b>Target : </b>"+search+"<br/><br/>&nbsp&nbsp<b>Author : </b>"+id+"<br/><br/>&nbsp&nbsp<b>Title   : </b>"+title+"<br/><br/>";
	if(dataKind_arr == 'GeoPhoto' || dataKind_arr == 'GeoVideo'){
		innerHTMLStr += "&nbsp&nbsp<b>Date : </b>"+udate+"</label></div>";
	}
	txt_cell1.innerHTML = innerHTMLStr;
	
	var hr_row = target.insertRow(-1);
	var hr_cell = hr_row.insertCell(-1);
	hr_row.setAttribute('style', 'height:1px');
	hr_cell.setAttribute('colspan', '2');
}

//XML 유무에 따라 썸네일 아이콘 추가
function loadXML(file_url, data_kind){
	var url_buf = file_url.split(".");
	var xml_file_name = url_buf[0] + '.xml';
	var file_check =0;
	$.ajax({
		type: "GET",
		url: '<c:url value="upload/'+ data_kind + '/'+ xml_file_name +'"/>',
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

//검색 목록 마커 설정
function SearchResultMarker(lati_arr, longi_arr, file_url_arr, thumbnail_url_arr, idx_arr, dataKind_arr, origin_url_arr, id_arr) {

	var loca = [];
	for(var i=0; i < file_url_arr.length; i++)
	{	
		if(lati_arr[i] != null && lati_arr[i] != 'null' && lati_arr[i] != 0 && longi_arr[i] != null && longi_arr[i] != '' && longi_arr[i] != 0){
			var temp = new Array();
			temp[0] = lati_arr[i];
			temp[1] = longi_arr[i];
			if(dataKind_arr[i] == 'GeoPhoto'){
				temp[2] = file_url_arr[i];
			}else if(dataKind_arr[i] == 'GeoVideo'){
				temp[2] = thumbnail_url_arr[i];
			}
			temp[3] = idx_arr[i];
			temp[4] = dataKind_arr[i];
			temp[5] = file_url_arr[i];
			temp[6] = origin_url_arr[i];
			temp[7] = id_arr[i];
			
			loca.push(temp);
		}
	}
	
	LocationData = loca;
	
	typeShape = "forSearch";
	initialize();
}

//테이블 초기화
function clearSearchTable() {
	$('#search_content_list_table tr').remove();
}

</script>

<table border=0 class='ui-widget' id='search_content_list_table'>
</table>