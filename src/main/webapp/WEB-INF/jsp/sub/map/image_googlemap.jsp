<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>

<!-- <script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?sensor=false&key=AIzaSyAZ4i-9lnjP3m46b2oqg4BlVxDmDfhExvU"></script> -->
<!-- <script type="text/javascript" src="http://map.vworld.kr/js/vworldMapInit.js.do?version=2.0&apiKey=58C34064-4482-3303-B68E-100D063F8B0A"></script> -->
<script src="http://www.openlayers.org/api/2.13/OpenLayers.js" type="text/javascript"></script>
<!-- <script type="text/javascript" src="http://map.vworld.kr/js/apis.do?type=Base&apiKey=CB879C1A-DF83-3EE8-9C5C-9CA5D742B680&domain=http://turbosoft1.iptime.org:2125/GeoCMS"></script> -->
<script type="text/javascript" src="http://map.vworld.kr/js/vworldMapInit.js.do?&apiKey=CB879C1A-DF83-3EE8-9C5C-9CA5D742B680"></script>

 
<script type='text/javascript'>
var apiMap = null//2D map
vworld.showMode = false;//브이월드 배경지도 설정 컨트롤 유무(true:배경지도를 컨트롤 할수 있는 버튼 생성/false:버튼 해제) 
var popup = null; //팝업 변수선언

var markerArr = new Array();
var markerFileList = null;

function initialize() {
	markerArr = new Array();
	markerFileList = null;
	
// 	$('#vmap').empty();
	if(apiMap != null){
		$.each($('.olAlphaImg'), function(idx, val){
			var tmpParentId = $(this).parent().attr('id');
			this.remove();
			$('#'+tmpParentId).remove();
		});
		if(typeShape == "marker") {	//main marker
			takeMarkerData(typeShape);
		}
		else if(typeShape == "forSearch") {	//searh page marker
			google.maps.event.addDomListener(window, 'load', gridMap(LocationData));	
		}
	}else{
		/**
		 * - rootDiv, mapType, mapFunc, 3D initCall, 3D failCall
		 * - 브이월드 5가지 파라미터를 셋팅하여 지도 호출
		 */
		vworld.init("vmap", "map-first", 
		    function() {        
		        apiMap = this.vmap;//브이월드맵 apiMap에 셋팅 
		        apiMap.setBaseLayer(apiMap.vworldBaseMap);//기본맵 설정 
		        apiMap.setControlsType({"simpleMap":true}); //간단한 화면    
		        apiMap.addVWORLDControl("zoomBar");
	 	        apiMap.setCenterAndZoom(14243425.793355, 4342305.8698004, 8);//화면중심점과 레벨로 이동 (초기 화면중심점과 레벨)
				if(typeShape == "marker") {	//main marker
					takeMarkerData(typeShape);
				}
				else if(typeShape == "forSearch") {	//searh page marker
					google.maps.event.addDomListener(window, 'load', gridMap(LocationData));	
				}
		    }
		);
	}
}

//마커 데이터 가져오기
function takeMarkerData(typeShape) {
	var tmpPageNum = '&nbsp';
	var tmpContentNum = '&nbsp';
	var tmpTabName = editMode == 1?tempTabName:nowTabName;
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpIdx = '&nbsp';
	
	if(tmpLoginId == null || tmpLoginId == '' ||  tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' ||  tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	if(b_url == 'cms/getBorder/'){
		gridMap(null);
		return;
	}

	var Url			= baseRoot() + b_url;
	var param		= typeShape + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + tmpPageNum + "/" + tmpContentNum + "/" + tmpTabName + "/" + tmpIdx;
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "get"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			var response = data.Data;
			markDataMake(response);
		}
	});
}

//mark load
function markDataMake(data){
	var id_arr = new Array();
	var title_arr = new Array();
	var content_arr = new Array();
	var file_url_arr = new Array();
	var udate_arr = new Array();
	var idx_arr = new Array();
	var lati_arr = new Array();
	var longi_arr = new Array();
	var origin_url_arr = new Array();
	var thumbnail_url_arr = new Array();
	var dataKind_arr = new Array();
	var projectUserId_arr = new Array();
	var projectMarkerIcon_arr = new Array();
	
	if(data != null && data.length > 0){
		for(var i=0; i<data.length; i++) 
		{
			id_arr.push(data[i].ID); //id 저장
			
			title_arr.push(data[i].TITLE); //title 저장
			
			content_arr.push(data[i].CONTENT); //content 저장
			
			file_url_arr.push(data[i].FILENAME); // file
			
			udate_arr.push(data[i].U_DATE); //찍은날짜
			
			idx_arr.push(data[i].IDX);
			
			lati_arr.push(data[i].LATITUDE); // 위도
			
			longi_arr.push(data[i].LONGITUDE); //경도
			
			thumbnail_url_arr.push(data[i].THUMBNAIL);	//thumb file
			
			origin_url_arr.push(data[i].ORIGNNAME);	//origin file
			
			dataKind_arr.push(data[i].DATAKIND); //데이터 타입
			
			projectUserId_arr.push(data[i].projectUserId); //project user id
			
			projectMarkerIcon_arr.push(data[i].PROJECTMARKERICON); //project marker icon
		}
	}
	
	var loca = [];
	for(var i=0; i < file_url_arr.length; i++)
	{	
		if(lati_arr[i] != null && lati_arr[i] != 'null' && lati_arr[i] != 0 && longi_arr[i] != null && longi_arr[i] != '' && longi_arr[i] != 0){
			var temp = new Array();
			temp[0] = lati_arr[i];
			temp[1] = longi_arr[i];
			temp[2] = file_url_arr[i];
			temp[3] = idx_arr[i];
			temp[4] = dataKind_arr[i];
			temp[5] = origin_url_arr[i];
			temp[6] = thumbnail_url_arr[i];
			temp[7] = id_arr[i];
			temp[8] = projectUserId_arr[i];
			if(projectMarkerIcon_arr[i] != null){
				projectMarkerIcon_arr[i] = projectMarkerIcon_arr[i].replace('_','&ubsp');
			}
			temp[9] = projectMarkerIcon_arr[i];
			
			loca.push(temp);
		}
	}

	LocationData = loca;
	vworldMapCall(LocationData);
}

function vworldMapCall(LocationData){
	if(LocationData == null || LocationData.length <= 0){	//base map setting
		apiMap.setCenterAndZoom(14243425.793355, 4342305.8698004, 8);//화면중심점과 레벨로 이동 (초기 화면중심점과 레벨)
    	return;
    }
	
	markerArr = new Array();
    markerFileList = new Array();
    
    for (var i in LocationData)
    {
        var p = LocationData[i];
        if(p[0] == 0 && p[1] == 0){
        	continue;
        }
        
//         var latlng = new google.maps.LatLng(p[0], p[1]);
//         bounds.extend(latlng);
        fnMakeMarker(p, 'load');
        markerFileList.push(p[2]);
    }
}

//make marker
function fnMakeMarker(p, type){ //lat, lon, filename, idx, kind, origin , thumbnail , id, projectUserId, projectMarkerIcon  
	var point = apiMap.getTransformXY(p[1], p[0], "EPSG:4326","EPSG:900913");
	
// 	alert('point : ' + JSON.stringify(point) + "  :  " + JSON.stringify(p));
	var jpgStr = p[2];
	if(p[4] == 'GeoVideo'){
		jpgStr = p[6];
	}
	
	var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
	if(p[9] != null && p[9] != '' && p[9] != undefined && p[9] != 'null'){
		var tmpSrc = p[9].replace('&ubsp','_');
		tmpMarkerIcon = {
			url: '<c:url value="images/geoImg/map/markerIcon/'+ tmpSrc +'"/>',
			scaledSize: new google.maps.Size(25, 25)
		};
	}else{
		p[9] = '';
	}

	var kindStr = p[4];
// 	var contentStr = "<img class='round' src='<c:url value='/upload/"+ p[4] +"/"+jpgStr+"'/>' width='200' height='200' hspace='10' vspace='10' style='border:2px solid #888888'/>";
// 	contentStr += '<br><label>KakaoTalk_20161121_174514428.jpg</label>';
	var marker = new vworld.Marker(point.x, point.y, '',"");
	marker.setIconImage('http://maps.google.com/mapfiles/ms/icons/red-dot.png');
	
	// 마커의 z-Index 설정
    marker.setZindex(3);
	
    marker.id = p[3]+'_'+p[4]+'_'+p[7]+'_'+p[8] + '_'+ p[9];
    marker.mtitle = jpgStr;
    marker.mtitle2 = p[2]+'/'+p[5];
    marker.lon = p[1];
    marker.lat = p[0];
    
    marker.events.register('click', marker, function(event){
    	var kindStr = this.id.split("_")[1];
		if(kindStr == 'GeoPhoto'){
			imageViewer(this.mtitle, this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
		}else if(kindStr == 'GeoVideo'){
			videoViewer(this.mtitle2.split('/')[0], this.mtitle2.split('/')[1], this.id.split("_")[2], this.id.split("_")[0]);
		}
    });
    
    marker.events.register('mouseover', marker, function(event){
//     	alert('3');
    	var kindStr = this.id.split("_")[1];
    	var contentStr = "<img class='round' src='<c:url value='/upload/"+ kindStr +"/"+this.mtitle+"'/>' width='200' height='200' hspace='10' vspace='10' style='border:2px solid #888888'/>";
//     	 this.popup = this.createPopup(this.closeBox);
//     	 this.popup.setSize(new OpenLayers.Size(300,170));/**팝업사이즈**/
//     	 this.popup.calculateNewPx = function(px) {
// 	    	 var newPx = px;
// 	    	 this.anchor.offset.x = 5;
// 	    	 this.anchor.offset.y = -280;
// 	    	 newPx = px.offset(this.anchor.offset);
// 	    	 return newPx;
//     	 };
//     	 giMap.addPopup(this.popup);/**map에 팝업 등록**/
//     	 this.popup.show();/**팝업 맵에 보여줌**/
		
// 		this.popup = this.createPopup(this.closeBox);
// 		this.popup.setSize(new OpenLayers.Size(300,170));/**팝업사이즈**/
// 		apiMap.addPopup(this.popup);
// 		this.popup.show();/**팝업 맵에 보여줌**/
                    
//                     this.popup = contentStr;
//                     alert(this.popup );
//                     apiMap.addPopup(this.popup);
                   
//                     this.popup.show();/**팝업 맵에 보여줌**/
//                  alert('cc');   
                 popup = new OpenLayers.Popup("chicken",
                   new OpenLayers.LonLat(127.325858333333330, 36.630458333333340),
                   new OpenLayers.Size(200,200),
                   "example popup",
                   true);
alert(JSON.stringify(popup));
    	apiMap.addPopup(popup);
    	
    	// 		infowindow = new google.maps.InfoWindow({
//    			content: contentStr,
//    		 	size: new google.maps.Size(100,100) 
//   		});
//     	infowindow.open(map, this);
// 		$('.gm-style-iw').next('div').remove();
    });
    
    marker.events.register('mouseout', marker, function(event){
//     	apiMap.removePopup(markerPopup);
    });
    
    apiMap.addMarker(marker);
    
  //마커 아이콘 크기변경
    var mkIvt = marker.events.element.id.toString();
    mkIvt += '_innerImage';
    var markerImg = document.getElementById(mkIvt);
    markerImg.style.width = "25px";
    markerImg.style.height = "25px";
	
	if(type != 'click'){
		markerArr.push(marker);
	}

	if(type != 'load'){	//marker click setting 
		marker.setIconImage('http://maps.google.com/mapfiles/ms/icons/yellow-dot.png');
		marker.setZindex(10);
	}
}

/* --------------------- 내부 함수 --------------------*/
// var map;
// var markerArr = new Array();
// var markerFileList = null;
// // var markerCnt = 5;				//로딩 된 마커 개수	
// // var map_type;	
// var preBounds; //메인화면 크기 저장

// var marker_latlng, view_marker_latlng;

// var fov; //화각
// var view_value; //촬영 거리

// var direction_latlng;

// var draw_angle_arr = new Array();
// var draw_direction_arr = new Array();

// function initialize() {
// 	markerArr = new Array();
// 	markerFileList = null;
	
// 	//set map option
// 	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
// 	//create map
// 	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
// 	if(typeShape == "marker") {	//main marker
// 		takeMarkerData(typeShape);
// 	}
// 	else if(typeShape == "forSearch") {	//searh page marker
// 		google.maps.event.addDomListener(window, 'load', gridMap(LocationData));	
// 	}
// }

// /* --------------------- 초기 설정 함수 --------------------*/

// //촬영 지점 설정
// function setCenterA(lat, lng) {
// // 	map_type = type;
// 	if(lat>0 && lng>0) {
// 		marker_latlng = new google.maps.LatLng(lat, lng); map.setZoom(16);
// 	}
// 	map.setCenter(marker_latlng);
// }

// //촬영 각도와 거리를 계산하여 지도에 표현
// function setAngle(direction_str, focal_str) {
// 	var direction = parseInt(direction_str);
// 	var focal = parseFloat(focal_str);
	
// 	fov = getFOV(focal);
// 	view_value = getViewLength(0.3); //km 단위
	
// 	if(direction>0 && focal>0) {
// 		setViewPoint(marker_latlng, view_value, direction);
// 		createViewPolygon(view_value, direction, fov);
// 		createViewPolyline(marker_latlng, direction_latlng);
// 		createViewMarker(direction_latlng);
// 	}
// }
// //화각 구하기
// getFOV = function(focal_length) {
// 	//var diagonalLength = Math.sqrt(Math.pow(36, 2) + Math.pow(24, 2));
// 	//var diagonalLength = Math.sqrt(Math.pow(3.626, 2) + Math.pow(2.709, 2));
// 	var fov = (2 * Math.atan(3.626 / (2 * focal_length))) * 180 / Math.PI;
	
// 	return fov;
// };
// //촬영 거리 구하기
// getViewLength = function(focus) {
// 	return focus;
// };

// //촬영 각도 및 거리에 맞추어 좌표 설정
// function setViewPoint(point, km, direction) {
// 	var rad = (km * 1000) / 1609.344;
// 	var d2r = Math.PI / 180;
// 	var circleLatLngs = new Array();
// 	var circleLat = (rad / 3963.189) / d2r;
// 	var circleLng = circleLat / Math.cos(point.lat() * d2r);
	
// 	var theta = direction * d2r;
// 	var vertexLat = point.lat() + (circleLat * Math.cos(theta));
// 	var vertexLng = point.lng() + (circleLng * Math.sin(theta));
// 	direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
// }
// //촬영 범위를 폴리곤으로 표현
// function createViewPolygon(km, direction, angle) {
// 	direction = parseInt(direction);
// 	var angle_val = angle / 2;
// 	var min_direction = direction - angle_val;
// 	if(min_direction<0) min_direction = min_direction + 360;
// 	var max_direction = direction + angle_val;
// 	if(max_direction>360) max_direction = Math.abs(360 - max_direction);
	
// 	var rad = (km * 1000) / 1609.344;
// 	var d2r = Math.PI / 180;
// 	var circleLatLngs = new Array();
// 	var circleLat = (rad / 3963.189) / d2r;
// 	var circleLng = circleLat / Math.cos(marker_latlng.lat() * d2r);
// 	circleLatLngs.push(marker_latlng);
	
// 	var theta, vertexLat, vertexLng, vertextLatLng;
// 	if(min_direction<max_direction) {
// 		for(var i=min_direction; i<max_direction; i++) {
// 			theta = i * d2r;
// 			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
// 			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
// 			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
// 			if(i==0) { circleLatLngs.push(marker_latlng); }
// 			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
// 			circleLatLngs.push(vertextLatLng);
// 		}
// 	}
// 	else {
// 		for(var i=min_direction; i<361; i++) {
// 			theta = i * d2r;
// 			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
// 			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
// 			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
// 			if(i==min_direction) { circleLatLngs.push(marker_latlng); }
// 			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
// 			circleLatLngs.push(vertextLatLng);
// 		}
// 		for(var i=0; i<max_direction; i++) {
// 			theta = i * d2r;
// 			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
// 			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
// 			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
// 			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
// 			circleLatLngs.push(vertextLatLng);
// 		}
// 	}
	
// // 	if(draw_angle!=null) draw_angle.setMap(null);
	
// 	var draw_angle = new google.maps.Polygon({
// 		paths: circleLatLngs,
// 		strokeColor: "#FF0000",
// 		strokeOpacity: 0.8,
// 		strokeWeight: 2,
// 		fillColor: "#FF0000",
// 		fillOpacity: 0.3
// 	});
// 	draw_angle_arr.push(draw_angle);
// 	draw_angle.setMap(map);
// }
// //촬영 위치와 촬영 범위 위치를 선으로 연결
// function createViewPolyline(point1, point2) {
// 	var direction_arr = [point1, point2];
	
// // 	if(draw_direction!=null) draw_direction.setMap(null);
	
// 	var draw_direction = new google.maps.Polyline({
// 		path: direction_arr,
// 		strokeColor: "#0000FF",
// 		strokeOpacity: 1.0,
// 		strokeWeight: 2
// 	});
// 	draw_direction_arr.push(draw_direction);
// 	draw_direction.setMap(map);
// }

// var nowPolyBoundsNum = 0;
// //촬영 범위 좌표 설정
// function createViewMarker(point) {
// 	var marker_image = '<c:url value="images/map/view_marker.png"/>';
	
// // 	if(view_marker==null) {
// 		var drag = false;
// // 		if(map_type==2) drag = true;
// 		var view_marker = new google.maps.Marker({
// 			position: point,
// 			map: map,
// 			title: "View",
// 			icon: marker_image,
// 			draggable: drag
// 		});
// // 	}
// // 	else {
// // 		view_marker.setPosition(point);
// // 	}
// // 	if(map_type==2) {
// // 		google.maps.event.addListener(view_marker, 'dragend', function() {
// // 			dragEvent(1);
// // 		});
// // 		google.maps.event.addListener(marker, 'dragend', function() {
// // 			dragEvent(2);
// // 		});
// // 	}

// 	if(markerFileList != null && markerFileList.length > 0){
// 		if(polyBounds != null ){
// // 			var latlng = new google.maps.LatLng(view_marker.getPosition().lat(), view_marker.getPosition().lng());
// // 			polyBounds.extend(latlng);
// 			if(nowPolyBoundsNum == (markerFileList.length -1)){
// 				map.fitBounds(polyBounds);
// 				map.setZoom(map.getZoom()+1);
// 				nowPolyBoundsNum = -1;
// 			}		
// 		}
// 	}
// 	nowPolyBoundsNum++;
// }
// //마커 드래그 이벤트
// // function dragEvent(type) {
// // 	draw_direction.setPath([marker.getPosition(), view_marker.getPosition()]);
// // 	if(type==2) { marker_latlng = new google.maps.LatLng(marker.getPosition().lat(), marker.getPosition().lng()); }
// // 	var km = draw_direction.inKm();
// // 	var degree = draw_direction.Bearing();
// // 	createViewPolygon(km, degree, fov);
	
// // 	parent.setExifData(marker.getPosition().lat(), marker.getPosition().lng(), parseInt(degree));
// // }

// /* ---------------------------- 구글맵 확장 기능 --------------------------------- */
// google.maps.LatLng.prototype.kmTo = function(a){
// 	var e = Math, ra = e.PI/180;
// 	var b = this.lat() * ra, c = a.lat() * ra, d = b - c; 
// 	var g = this.lng() * ra - a.lng() * ra;
// 	var f = 2 * e.asin(e.sqrt(e.pow(e.sin(d/2), 2) + e.cos(b) * e.cos(c) * e.pow(e.sin(g/2), 2)));
// 	return f * 6378.137; 
// }; 
// google.maps.Polyline.prototype.inKm = function(n){ 
// 	var a = this.getPath(n), len = a.getLength(), dist = 0; 
// 	for(var i=0; i<len-1; i++){ 
// 		dist += a.getAt(i).kmTo(a.getAt(i+1)); 
// 	}
// 	return dist;
// };

// google.maps.Polyline.prototype.Bearing = function(d){
// 	var path = this.getPath(d), len = path.getLength();
// 	var from = path.getAt(0);
// 	var to = path.getAt(len-1);
// 	if (from.equals(to)) {
// 		return 0;
// 	}
// 	var lat1 = from.latRadians();
// 	var lon1 = from.lngRadians();
// 	var lat2 = to.latRadians();
// 	var lon2 = to.lngRadians();
	
// 	var angle = - Math.atan2( Math.sin( lon1 - lon2 ) * Math.cos( lat2 ), Math.cos( lat1 ) * Math.sin( lat2 ) - Math.sin( lat1 ) * Math.cos( lat2 ) * Math.cos( lon1 - lon2 ) );
// 	if ( angle < 0.0 ) angle  += Math.PI * 2.0;
// 	if ( angle > Math.PI ) angle -= Math.PI * 2.0; 
	
// 	angle = parseFloat(angle.toDeg());
// 	if(-180<=angle && angle<0) angle += 360;
// 	return angle;
// };

// google.maps.LatLng.prototype.latRadians = function() {
// 	return this.lat() * Math.PI/180;
// };

// google.maps.LatLng.prototype.lngRadians = function() {
// 	return this.lng() * Math.PI/180;
// };

// Number.prototype.toDeg = function() {
// 	return this * 180 / Math.PI;
// };

// /*******************************function**************************************/
// //make marker
// function fnMakeMarker(p, type){
// 	var infowindow = new google.maps.InfoWindow();
// 	var latlng = new google.maps.LatLng(p[0], p[1]);
// 	var jpgStr = p[2];
// 	if(p[4] == 'GeoVideo'){
// 		jpgStr = p[6];
// 	}
	
// 	var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
// 	if(p[9] != null && p[9] != '' && p[9] != undefined && p[9] != 'null'){
// 		var tmpSrc = p[9].replace('&ubsp','_');
// 		tmpMarkerIcon = {
// 			url: '<c:url value="images/geoImg/map/markerIcon/'+ tmpSrc +'"/>',
// 			scaledSize: new google.maps.Size(25, 25)
// 		};
// 	}else{
// 		p[9] = '';
// 	}

// 	var marker = new google.maps.Marker({
//         position: latlng,
//         map: map,
//         title: jpgStr,				// jpg file name
//         id: p[3]+'_'+p[4]+'_'+p[7]+'_'+p[8] + '_'+ p[9],			//p[3]: index, p[4]: kind(GeoPhoto, GeoVideo), p[7]: use_id, p[8]: project make user id, p[9]: project marker icon
//         label: {
//         	text: p[2]+'/'+p[5],	//p[2]: file , p[5]: origin file name
//         	fontSize: '0px'
//         },
//         icon: tmpMarkerIcon
// //         icon:'http://maps.google.com/mapfiles/ms/icons/red-dot.png'
//     });
    
// 	if(type != 'click'){
// 		markerArr.push(marker);
// 	}
	
// 	if(type != 'load'){	//marker click setting 
// 		marker.setIcon('http://maps.google.com/mapfiles/ms/icons/yellow-dot.png');
// 		marker.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
// 	}
 
//     google.maps.event.addListener(marker, 'click', function() {
// 		var kindStr = this.id.split("_")[1];
// 		if(kindStr == 'GeoPhoto'){
// 			imageViewer(this.title, this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
// 		}else if(kindStr == 'GeoVideo'){
// 			videoViewer(this.label.text.split('/')[0], this.label.text.split('/')[1], this.id.split("_")[2], this.id.split("_")[0]);
// 		}
//     });
    
//     google.maps.event.addListener(marker, 'mouseover', function() {
//     	var kindStr = this.id.split("_")[1];
//     	var contentStr = "<img class='round' src='<c:url value='/upload/"+ kindStr +"/"+this.title+"'/>' width='200' height='200' hspace='10' vspace='10' style='border:2px solid #888888'/>";
// //     	var contentStr = "<img class='round' src='http://"+location.host + "/"+ kindStr +"/upload/"+this.title+"' width='200' height='200' hspace='10' vspace='10' style='border:2px solid #888888'/>";
// 		infowindow = new google.maps.InfoWindow({
//    			content: contentStr,
//    		 	size: new google.maps.Size(100,100) 
//   		});
//     	infowindow.open(map, this);
// 		$('.gm-style-iw').next('div').remove();
//     });
    
//     google.maps.event.addListener(marker, 'mouseout', function() {
//     	infowindow.close();
//     });
    
//     google.maps.event.addListener(marker, 'rightclick', function() {
//     	alert(this);
//     });
// }

// //마커 데이터 가져오기
// function takeMarkerData(typeShape) {
// // 	callRequest('takeMarkerData', b_url, 'type='+typeShape+'&contentNum='+markerCnt, "");
// 	var tmpPageNum = '&nbsp';
// 	var tmpContentNum = '&nbsp';
// 	var tmpTabName = editMode == 1?tempTabName:nowTabName;
// 	var tmpLoginId = loginId;
// 	var tmpLoginToken = loginToken;
// 	var tmpIdx = '&nbsp';
	
// 	if(tmpLoginId == null || tmpLoginId == '' ||  tmpLoginId == 'null'){
// 		tmpLoginId = '&nbsp';
// 	}
// 	if(tmpLoginToken == null || tmpLoginToken == '' ||  tmpLoginToken == 'null'){
// 		tmpLoginToken = '&nbsp';
// 	}
// 	if(b_url == 'cms/getBorder/'){
// 		gridMap(null);
// 		return;
// 	}

// 	var Url			= baseRoot() + b_url;
// 	var param		= typeShape + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + tmpPageNum + "/" + tmpContentNum + "/" + tmpTabName + "/" + tmpIdx;
// 	var callBack	= "?callback=?";
	
// 	$.ajax({
// 		type	: "get"
// 		, url	: Url + param + callBack
// 		, dataType	: "jsonp"
// 		, async	: false
// 		, cache	: false
// 		, success: function(data) {
// 			var response = data.Data;
// 			markDataMake(response);
// 		}
// 	});
// }

// //mark load
// function markDataMake(data){
// 	var id_arr = new Array();
// 	var title_arr = new Array();
// 	var content_arr = new Array();
// 	var file_url_arr = new Array();
// 	var udate_arr = new Array();
// 	var idx_arr = new Array();
// 	var lati_arr = new Array();
// 	var longi_arr = new Array();
// 	var origin_url_arr = new Array();
// 	var thumbnail_url_arr = new Array();
// 	var dataKind_arr = new Array();
// 	var projectUserId_arr = new Array();
// 	var projectMarkerIcon_arr = new Array();
	
// 	if(data != null && data.length > 0){
// 		for(var i=0; i<data.length; i++) 
// 		{
// 			id_arr.push(data[i].ID); //id 저장
			
// 			title_arr.push(data[i].TITLE); //title 저장
			
// 			content_arr.push(data[i].CONTENT); //content 저장
			
// 			file_url_arr.push(data[i].FILENAME); // file
			
// 			udate_arr.push(data[i].U_DATE); //찍은날짜
			
// 			idx_arr.push(data[i].IDX);
			
// 			lati_arr.push(data[i].LATITUDE); // 위도
			
// 			longi_arr.push(data[i].LONGITUDE); //경도
			
// 			thumbnail_url_arr.push(data[i].THUMBNAIL);	//thumb file
			
// 			origin_url_arr.push(data[i].ORIGNNAME);	//origin file
			
// 			dataKind_arr.push(data[i].DATAKIND); //데이터 타입
			
// 			projectUserId_arr.push(data[i].projectUserId); //project user id
			
// 			projectMarkerIcon_arr.push(data[i].PROJECTMARKERICON); //project marker icon
// 		}
// 	}
// // 	markerFileList = file_url_arr;
	
// 	var loca = [];
	
// 	for(var i=0; i < file_url_arr.length; i++)
// 	{	
// 		if(lati_arr[i] != null && lati_arr[i] != 'null' && lati_arr[i] != 0 && longi_arr[i] != null && longi_arr[i] != '' && longi_arr[i] != 0){
// 			var temp = new Array();
// 			temp[0] = lati_arr[i];
// 			temp[1] = longi_arr[i];
// 			temp[2] = file_url_arr[i];
// 			temp[3] = idx_arr[i];
// 			temp[4] = dataKind_arr[i];
// 			temp[5] = origin_url_arr[i];
// 			temp[6] = thumbnail_url_arr[i];
// 			temp[7] = id_arr[i];
// 			temp[8] = projectUserId_arr[i];
// 			if(projectMarkerIcon_arr[i] != null){
// 				projectMarkerIcon_arr[i] = projectMarkerIcon_arr[i].replace('_','&ubsp');
// 			}
// 			temp[9] = projectMarkerIcon_arr[i];
			
// 			loca.push(temp);
// 		}
// 	}

// 	LocationData = loca;
// 	google.maps.event.addDomListener(window, 'load', gridMap(LocationData));

// // 	map = 
// //         new google.maps.Map(document.getElementById('map_canvas'));
// //     var bounds = new google.maps.LatLngBounds();
// //     map.fitBounds(bounds);
// //     preBounds = bounds;
    
// //     map.setCenter(new google.maps.LatLng(lat, lon));
// //     map.fitBounds(preBounds);
// }

// function gridMap(LocationData) {
// // 	map = 
// //         new google.maps.Map(document.getElementById('map_canvas'));
//     var bounds = new google.maps.LatLngBounds();
//     var infowindow = new google.maps.InfoWindow();

//     if(LocationData == null || LocationData.length <= 0){	//base map setting
//     	var marker_latlng = new google.maps.LatLng(37.5663889, 126.9997222);
//     	map.setCenter(marker_latlng);
//     	map.setZoom(10);
//     	return;
//     }

//     markerArr = new Array();
//     markerFileList = new Array();
//     for (var i in LocationData)
//     {
//         var p = LocationData[i];
//         if(p[0] == 0 && p[1] == 0){
//         	continue;
//         }
        
//         var latlng = new google.maps.LatLng(p[0], p[1]);
//         bounds.extend(latlng);
        
//         fnMakeMarker(p, 'load');
//         markerFileList.push(p[2]);
//     }

//     map.fitBounds(bounds);
//     preBounds = bounds;
// }

// //get image exif data
// function loadExif(file_name) {
// // 	var replace_url = 'http://'+location.host +'/GeoPhoto/';
// 	var encode_file_name = encodeURIComponent('/upload/GeoPhoto/'+file_name);

// 	$.ajax({
// 		type: 'POST',
// 		url: '<c:url value="/geoExif.do"/>',
// // 		url: replace_url+'geoExif.do',
// 		data: 'file_name='+encode_file_name+'&type=load',
// 		success: function(data) {
// 			var response = data.trim();
// 			exifSetting(response);
// 		}
// 	});
// }

// //set image exif data
// function exifSetting(data) {
// 	var line_buf_arr = data.split("\<LineSeparator\>");
// 	var line_data_buf_arr;
// 	var direction_str = '';
// 	var lon_str = '';
// 	var lat_str = '';
// 	var focal_str = '';
	
// 	//GPS Direction
// 	line_data_buf_arr = line_buf_arr[14].split("\<Separator\>");
// 	if(line_data_buf_arr[1].charAt(0)=="'" && line_data_buf_arr[1].charAt(line_data_buf_arr[1].length-1)=="'") line_data_buf_arr[1] = line_data_buf_arr[1].substring(1, line_data_buf_arr[1].length-1);
	
// 	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) direction_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
// 	else direction_str = line_data_buf_arr[1];
	
// 	//GPS Longitude
// 	line_data_buf_arr = line_buf_arr[15].split("\<Separator\>");
// 	lon_str = line_data_buf_arr[1];
	
// 	//GPS Latitude
// 	line_data_buf_arr = line_buf_arr[16].split("\<Separator\>");
// 	lat_str = line_data_buf_arr[1];
	
// 	//Focal Length
// 	line_data_buf_arr = line_buf_arr[7].split("\<Separator\>");
// 	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) focal_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
// 	else focal_str = line_data_buf_arr[1];
	
// 	//맵설정
// 	reloadMap(lat_str, lon_str, direction_str, focal_str);
// }

// function reloadMap(lat_str, lon_str, direction_str, focal_str) {
// 	if(lat_str != null && lat_str != '' && lon_str != null && lon_str != ''){
// 		var lat = parseFloat(lat_str);
// 		var lng = parseFloat(lon_str);

// 		if(lat>0 && lng>0){
// 			setCenterA(lat, lng);
// 			setAngle(direction_str, focal_str);
// 		}
// 	}
// }

// //이미지 클릭시 맵 center change
function mapCenterChange(objArr){		//tempObj: lat, lon, file, idx, dataKind, origin, thumbnail, id
	var tempArr = objArr.split(",");
	var cnt = 0;
	var lat = tempArr[0];
	var lon = tempArr[1];
	
	if(proEdit == 1){
		moveContentAdd(objArr);
		return;
	}
	//좌표정보 없을 시 viewer 팝업
	if(lat == null || lat == '' || lat == 'null' || lat == 0 || lon == null || lon == '' || lon == 'null'|| lon == 0){
		var kindStr = tempArr[4];
		alert('좌표 정보가 없습니다. viewer로 이동합니다.');
		if(kindStr == 'GeoPhoto'){
			if(projectImage == 1){
				imageViewer(tempArr[2],  tempArr[7], tempArr[3], tempArr[8]);
			}else{
				window.open('<c:url value="/upload/GeoPhoto/'+tempArr[2]+'"/>', 'openImage', 'width=760, height=560');
			}
		}else if(kindStr == 'GeoVideo'){
			if(projectVideo == 1){
				videoViewer(tempArr[2], tempArr[5], tempArr[7], tempArr[3]);	//file_url, origin_url, id, idx
			}else{
				window.open('<c:url value="/upload/GeoVideo/'+tempArr[2]+'"/>', 'openImage', 'width=760, height=550');
			}
		}
		return;
	}
	
	$.each(markerArr, function(idx, val){
		var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
		var tmpMarkerIconClk = 'http://maps.google.com/mapfiles/ms/icons/yellow-dot.png';
// 		if(tempArr[9] != null && tempArr[9] != '' && tempArr[9] != undefined && tempArr[9] != 'null'){
// 			var tmpSrc = tempArr[9].replace('&ubsp','_');
// 			tmpMarkerIcon = {
// 				url: '<c:url value="images/geoImg/map/markerIcon/'+ tmpSrc +'"/>',
// 				scaledSize: new google.maps.Size(25, 25)
// 			};
// 			tmpMarkerIconClk = tmpMarkerIcon;
// 		}else{
// 			tempArr[9] = '';
// 		}

		if(tempArr[9] == undefined){
			tempArr[9] = '';
		}
		
		var rotate = this.events.element.id.toString();
		rotate = rotate + '_innerImage';
		if(val.id == tempArr[3]+'_'+tempArr[4]+'_'+tempArr[7]+'_'+tempArr[8] +'_'+ tempArr[9]){
			$('#'+rotate).attr('src',tmpMarkerIconClk);
			val.setZindex(10);
// 			val.setIcon(tmpMarkerIconClk);
// 			val.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
			cnt = 1;
		}else{
			$('#'+rotate).attr('src',tmpMarkerIcon);
			val.setZindex(3);
// 			val.setIcon(tmpMarkerIcon);
// 			val.setZIndex(google.maps.Marker.MAX_ZINDEX);
		}
	});
	
// 	markerArr = markerArr.slice(0, markerCnt);
	
	//만약 선택 항목의 마커가 로드되어 있지 않으면 새로 그려준다.
	if(cnt == 0){
		fnMakeMarker(tempArr, 'click');
	}
	
	if(tempArr[4] == 'GeoVideo'){
		loadGPS(tempArr[2]);	//선택한 타입이 비디오인 경우 GPS 파일 로드 후 지도에 그려주기
	}else{
// 		map.fitBounds(preBounds);
// 		apiMap.setBounds(preBounds);
	}
// 	apiMap.setCenterAndZoom(lon, lat, 8);//화면중심점과 레벨로 이동 (초기 화면중심점과 레벨)
// 	apiMap.setCenterAndZoom(14243425.793355, 4342305.8698004, 8);//화면중심점과 레벨로 이동 (초기 화면중심점과 레벨)
// 	map.setCenter(new google.maps.LatLng(lat, lon));
}

// var gps_size;	//gps size;
// //gps 정보 load
// function loadGPS(fileName) {
// 	var buf = fileName.split('.')[0];
// 	var file_name = buf + '.gpx';
// 	var lat_arr = new Array(); 
// 	var lng_arr = new Array();
// 	$.ajax({
// 		type: "GET",
// 		url: 'http://'+ location.host + '/GeoVideo/upload/'+ file_name,
// 		dataType: "xml",
// 		cache: false,
// 		success: function(xml) {
// 			$(xml).find('trkpt').each(function(index) {
// 				var lat_str = $(this).attr('lat');
// 				var lng_str = $(this).attr('lon');
// 				lat_arr.push(parseFloat(lat_str));
// 				lng_arr.push(parseFloat(lng_str));
// 			});
// 			gps_size = lat_arr.length;
// 			setGPSData(lat_arr, lng_arr);
// 		},
// 		error: function(xhr, status, error) {
// 		}
// 	});
// }

// //파일 바인드
// var poly_arr;
// function setGPSData(lat_arr, lng_arr) {
// 	poly_arr = new Array();
// 	if(lat_arr.length == lng_arr.length) {
// 		for(var i=0; i<lat_arr.length; i++) {
// 			poly_arr.push(new google.maps.LatLng(lat_arr[i], lng_arr[i]));
// 		}
// 	}
// 	else { jAlert('GPS 파일의 Latitude 와 Longitude 가 맞지 않습니다.', '정보'); }
// 	setDirection(poly_arr);
// }

// //이동 거리를 표현 (polyline)
// function setDirection(poly_arr) {
// 	var draw_direction = new google.maps.Polyline({
// 		path: poly_arr,
// 		strokeColor: "#FF0000",
// 		strokeOpacity: 0.8,
// 		strokeWeight: 2
// 	});
// 	draw_direction.setMap(map);
	
// 	var bounds = new google.maps.LatLngBounds();
// 	$.each(poly_arr, function(idx, val){
// 		bounds.extend(val);
// 	});
// 	map.fitBounds(bounds);
// }

//마커클릭 시 이미지 뷰어 
function imageViewer(file_url, user_id, idx, projectUserId) {   // 여기서 들어오는 file_url정보 ex)  upload/20140605_120541.jpg
	if(editMode == 1) return;
	var base_url = 'http://'+location.host;
	var conv_file_url = encodeURIComponent(file_url); // conv_file_url = upload%2F20140605_120541.jpg
	
	if(projectImage == 1){
		var $dialog = jQuery.FrameDialog.create({ //객체정보를 로드
			url: base_url + '/GeoPhoto/geoPhoto/image_viewer.do?file_url='+conv_file_url+'&user_id='+user_id +'&idx='+ idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&b_contentTabArr='+b_contentTabArr+'&projectUserId='+projectUserId,
//	 		url: base_url + '/GeoPhoto/sub/viewer/image_viewer.jsp?base_url='+base_url+'&file_url='+conv_file_url+'&user_id='+user_id +'&idx='+ idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&b_contentTabArr='+b_contentTabArr,
			title: 'Image Viewer',
			width:1127,  
			height:650, 
			buttons: {},
			autoOpen:false
		});
		$dialog.dialog('open');
	}else{
		window.open('<c:url value="/upload/GeoPhoto/'+conv_file_url+'"/>', 'openImage', 'width=1170, height=860');
	}
}

//비디오 뷰어 동작
function videoViewer(file_url, origin_url, id, idx) {
	if(editMode == 1) return;
	var base_url = 'http://'+location.host;
	var conv_origin_url = encodeURIComponent(origin_url);

	$.ajax({
		type	: "POST"
		, url	: '<c:url value="/geoVideoEncodingCheck.do"/>?origin_url='+conv_origin_url
		, dataType	: "json"
		, async	: false
		, cache	: false
		, success: function(response) {
			if(response =='true') {
				jAlert('인코딩 중 입니다...', '정보');
			}else {
				if(projectVideo == 1){
					var $dialog = jQuery.FrameDialog.create({
						url: base_url + '/GeoVideo/geoVideo/video_viewer.do?&file_url='+file_url+'&user_id='+id+'&idx='+idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&b_contentTabArr='+b_contentTabArr,
						title: 'Video Viewer',
						width: 1127,
						height: 650,
						buttons: {},
						autoOpen:false
					});
					$dialog.dialog('open');
				}else{
					window.open('<c:url value="/upload/GeoVideo/'+tempArr[2]+'"/>', 'openImage', 'width=760, height=550');
				}
			}
		}
	});
}
// var polyBounds = null;
// function mapPolygonView(obj){
// 	//googlemap polygon
// // 	alert(JSON.stringify(markerFileList));
// // 	polyBounds = new google.maps.LatLngBounds();
// 	if(editMode == 1) return;
	
// 	if($(obj).attr('checked')){
// 		polyBounds = map.getBounds();
// 		$.each(markerFileList,function(idx, val){
// 			loadExif(val);
// 		});
// 	}else{
// 		$.each(draw_angle_arr,function(idx, val){
// 			val.setMap(null);
// 		});
// 		$.each(draw_direction_arr,function(idx, val){
// 			val.setMap(null);
// 		});
// 	}
// // 	map.fitBounds(preBounds);
// }

// function contentMarker(response){
// 	markerArr = new Array();
// 	markerFileList = null;
	
// 	//set map option
// 	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
// 	//create map
// 	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
// 	markDataMake(response);
// }

</script>
</head>

<body style='margin:0px; padding:0px;'>
	 <div id="vmap" style="width:100%; height:100%;"></div>
<script>
	
// 	var mapController;
    
// 	 vw.MapControllerOption = {
//  			container : "vmap",
//  			mapMode: "2d-map",
//  			basemapType: vw.ol3.BasemapType.graphic,
//  			controlDensity:  vw.ol3.DensityType.basic,
// 				interactionDensity: vw.ol3.DensityType.basic,
// 				controlsAutoArrange: true,
// 				homePosition: vw.ol3.CameraPosition,
// 				initPosition: vw.ol3.CameraPosition,
//  		};
		
// 		mapController = new vw.MapController(vw.MapControllerOption); 
        
			 
	</script>
	<!-- 지도가 들어갈 영역 시작 -->
<!-- 	 <div id="map" style="width:100%; height:100%;"></div> -->
<!--     <div > -->
<!--         <button type="button" onclick="deleteLayerByName('VHYBRID');" name="rpg_1" >레이어삭제하기</button> -->
<!--     </div>  -->
<!-- <div id="vMap" style="width:100%;height:650px;left:0px;top:0px"></div> -->
<!-- 지도가 들어갈 영역 끝 -->
	
<!-- 	<div class="viewModeCls"> -->
<!-- 		<input type="checkbox" id="polygonView" onclick="mapPolygonView(this);" style="vertical-align: middle ;"/> -->
<!-- 		<label style="margin-top: 3px; display: inline-block;">View Mode</label> -->
<!-- 	</div> -->
<!-- 	<div id="map_canvas" style="width:100%; height:100%;"></div> -->
</body>
</html>
