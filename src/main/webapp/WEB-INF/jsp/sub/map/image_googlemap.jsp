<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>

<%
 response.setHeader("Cache-Control","no-cache");
 response.setHeader("Pragma","no-cache");
 response.setDateHeader("Expires",0);
%>

<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>

<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key=AIzaSyAth-_FyQxRomNh2JkI_MvAWXRJuLOEXNI&v=3.exp&sensor=false&libraries=places,geometry&language=en&region=ER"></script>
<script type='text/javascript'>

/* --------------------- 내부 함수 --------------------*/
var map;
var markerArr = new Array();
var markerFileList = null;
// var markerCnt = 5;				//로딩 된 마커 개수	
// var map_type;	
var preBounds; //메인화면 크기 저장

var marker_latlng, view_marker_latlng;

var fov; //화각
var view_value; //촬영 거리

var direction_latlng;

var draw_angle_arr = new Array();
var draw_direction_arr = new Array();
var blackMarker = new Array();
var gpx_draw_direction = new Array();
var circle_arr = new Array();
var draw_sequence_arr = new Array();
var rectangleSequence = null;

var oldMarkerData = new Array(); //이전 center marker
var infowindow = null;

function initialize() {
	markerArr = new Array();
	markerFileList = null;
	
	//set map option
	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
	//create map
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	infowindow = new google.maps.InfoWindow();
	
	if(typeShape == "marker") {	//main marker
		takeMarkerData(typeShape);
	}
	else if(typeShape == "editMap") {	//searh page marker
		google.maps.event.addDomListener(window, 'load', gridMap(LocationData));	
	}else if(typeShape == "mainMarker") {	//main marker
		takeMainMarkerData(typeShape);
	}
}

/* --------------------- 초기 설정 함수 --------------------*/

//촬영 지점 설정
function setCenterA(lat, lng) {
	if(lat!=0 && lng!=0) {
		marker_latlng = new google.maps.LatLng(lat, lng);
	}
}

//촬영 각도와 거리를 계산하여 지도에 표현
function setAngle(direction_str, focal_str) {
	var direction = parseInt(direction_str);
	var focal = parseFloat(focal_str);
	
	fov = getFOV(focal);
	view_value = getViewLength(0.1); //km 단위
	
	if(direction>0 && focal>0) {
		setViewPoint(marker_latlng, view_value, direction);
		createViewPolygon(view_value, direction, fov);
		createViewPolyline(marker_latlng, direction_latlng);
		createViewMarker(direction_latlng);
	}
}
//화각 구하기
getFOV = function(focal_length) {
	//var diagonalLength = Math.sqrt(Math.pow(36, 2) + Math.pow(24, 2));
	//var diagonalLength = Math.sqrt(Math.pow(3.626, 2) + Math.pow(2.709, 2));
	var fov = (2 * Math.atan(3.626 / (2 * focal_length))) * 180 / Math.PI;
	
	return fov;
};

//촬영 거리 구하기
getViewLength = function(focus) {
	return focus;
};

//촬영 각도 및 거리에 맞추어 좌표 설정
function setViewPoint(point, km, direction) {
	var rad = (km * 1000) / 1609.344;
	var d2r = Math.PI / 180;
	var circleLatLngs = new Array();
	var circleLat = (rad / 3963.189) / d2r;
	var circleLng = circleLat / Math.cos(point.lat() * d2r);
	
	var theta = direction * d2r;
	var vertexLat = point.lat() + (circleLat * Math.cos(theta));
	var vertexLng = point.lng() + (circleLng * Math.sin(theta));
	direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
}

//촬영 범위를 폴리곤으로 표현
function createViewPolygon(km, direction, angle) {
	direction = parseInt(direction);
	var angle_val = angle / 2;
	var min_direction = direction - angle_val;
	if(min_direction<0) min_direction = min_direction + 360;
	var max_direction = direction + angle_val;
	if(max_direction>360) max_direction = Math.abs(360 - max_direction);
	
	var rad = (km * 1000) / 1609.344;
	var d2r = Math.PI / 180;
	var circleLatLngs = new Array();
	var circleLat = (rad / 3963.189) / d2r;
	var circleLng = circleLat / Math.cos(marker_latlng.lat() * d2r);
	circleLatLngs.push(marker_latlng);
	
	var theta, vertexLat, vertexLng, vertextLatLng;
	if(min_direction<max_direction) {
		for(var i=min_direction; i<max_direction; i++) {
			theta = i * d2r;
			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
			if(i==0) { circleLatLngs.push(marker_latlng); }
			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
			circleLatLngs.push(vertextLatLng);
		}
	}
	else {
		for(var i=min_direction; i<361; i++) {
			theta = i * d2r;
			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
			if(i==min_direction) { circleLatLngs.push(marker_latlng); }
			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
			circleLatLngs.push(vertextLatLng);
		}
		for(var i=0; i<max_direction; i++) {
			theta = i * d2r;
			vertexLat = marker_latlng.lat() + (circleLat * Math.cos(theta));
			vertexLng = marker_latlng.lng() + (circleLng * Math.sin(theta));
			vertextLatLng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng));
			if(i==direction) { direction_latlng = new google.maps.LatLng(parseFloat(vertexLat), parseFloat(vertexLng)); }
			circleLatLngs.push(vertextLatLng);
		}
	}
	
	var draw_angle = new google.maps.Polygon({
		paths: circleLatLngs,
		strokeColor: "#FF0000",
		strokeOpacity: 0.8,
		strokeWeight: 2,
		fillColor: "#FF0000",
		fillOpacity: 0.3
	});
	draw_angle_arr.push(draw_angle);
	draw_angle.setMap(map);
}

//촬영 위치와 촬영 범위 위치를 선으로 연결
function createViewPolyline(point1, point2) {
	var direction_arr = [point1, point2];
	
	var draw_direction = new google.maps.Polyline({
		path: direction_arr,
		strokeColor: "#0000FF",
		strokeOpacity: 1.0,
		strokeWeight: 2
	});
	draw_direction_arr.push(draw_direction);
	draw_direction.setMap(map);
}

//촬영 범위 좌표 설정
function createViewMarker(point) {
	var marker_image = '<c:url value="images/geoImg/map/view_marker.png"/>';
	
	var drag = false;
	var view_marker = new google.maps.Marker({
		position: point,
		map: map,
		title: "View",
		icon: marker_image,
		draggable: drag
	});
	blackMarker.push(view_marker);
}


/**
 * 반경 그리기
 * @param : xy 좌표, 반경사이즈
 */
function drawCircleOnMap(lat_str, lng_str, radius){ //반경중앙좌표, 반경(단위: m)
 	var lat = parseFloat(lat_str);
	var lng = parseFloat(lng_str);
	
    var circle = new google.maps.Circle({
        strokeColor: '#07aca5', //원 바깥 선 색
        strokeOpacity: 0.8, // 바깥 선 투명도
        strokeWeight: 1, //바깥 선 두께
        fillColor: '#07aca5', //선안의 색
        fillOpacity: 0.2,// 토명도
        center: {lat: lat, lng: lng}, //위치 좌표
        radius: Number(radius) // 반경, 단위: m
    });
    
    circle_arr.push(circle);
    circle.setMap(map);// 반경을 추가할 map에 set
    
}

//촬영 위치와 촬영 범위 위치를 선으로 연결
function drawSequenceLine(point1, point2) {
	var drawLineArr = [point1, point2];
	
	var draw_sequence = new google.maps.Polyline({
		path: direction_arr,
		strokeColor: "#0000FF",
		strokeOpacity: 1.0,
		strokeWeight: 2
	});
	draw_sequence_arr.push(draw_sequence);
	draw_sequence.setMap(map);
}

/* ---------------------------- 구글맵 확장 기능 --------------------------------- */
google.maps.LatLng.prototype.kmTo = function(a){
	var e = Math, ra = e.PI/180;
	var b = this.lat() * ra, c = a.lat() * ra, d = b - c; 
	var g = this.lng() * ra - a.lng() * ra;
	var f = 2 * e.asin(e.sqrt(e.pow(e.sin(d/2), 2) + e.cos(b) * e.cos(c) * e.pow(e.sin(g/2), 2)));
	return f * 6378.137; 
}; 
google.maps.Polyline.prototype.inKm = function(n){ 
	var a = this.getPath(n), len = a.getLength(), dist = 0; 
	for(var i=0; i<len-1; i++){ 
		dist += a.getAt(i).kmTo(a.getAt(i+1)); 
	}
	return dist;
};

google.maps.Polyline.prototype.Bearing = function(d){
	var path = this.getPath(d), len = path.getLength();
	var from = path.getAt(0);
	var to = path.getAt(len-1);
	if (from.equals(to)) {
		return 0;
	}
	var lat1 = from.latRadians();
	var lon1 = from.lngRadians();
	var lat2 = to.latRadians();
	var lon2 = to.lngRadians();
	
	var angle = - Math.atan2( Math.sin( lon1 - lon2 ) * Math.cos( lat2 ), Math.cos( lat1 ) * Math.sin( lat2 ) - Math.sin( lat1 ) * Math.cos( lat2 ) * Math.cos( lon1 - lon2 ) );
	if ( angle < 0.0 ) angle  += Math.PI * 2.0;
	if ( angle > Math.PI ) angle -= Math.PI * 2.0; 
	
	angle = parseFloat(angle.toDeg());
	if(-180<=angle && angle<0) angle += 360;
	return angle;
};

google.maps.LatLng.prototype.latRadians = function() {
	return this.lat() * Math.PI/180;
};

google.maps.LatLng.prototype.lngRadians = function() {
	return this.lng() * Math.PI/180;
};

Number.prototype.toDeg = function() {
	return this * 180 / Math.PI;
};

/*******************************function**************************************/
//make marker
function fnMakeMarker(p, type){
// 	var infowindow = new google.maps.InfoWindow();
	var latlng = new google.maps.LatLng(p[0], p[1]);
	var jpgStr = p[2];

	if(p[4] == 'GeoVideo'){
		jpgStr = p[6];
	}
	var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';

	if(p[8] == null || p[8] == '' || p[8] == 'null' || p[8] == undefined){
		p[8] = '';
	}
	
	if(typeShape == 'mainMarker'){
		var marker = new google.maps.Marker({
	        position: latlng,
	        map: map,
	        title: p[12],				// jpg file name
	        id: p[11],			//p[11]: projectidx
	        icon: tmpMarkerIcon
	    });
	}else{
		var marker = new google.maps.Marker({
	        position: latlng,
	        map: map,
	        title: jpgStr,				// jpg file name
	        id: p[3]+'_'+p[4]+'_'+p[7]+'_'+p[8],			//p[3]: index, p[4]: kind(GeoPhoto, GeoVideo), p[7]: use_id, p[8]: project make user id
	        label: {
	        	text: p[2]+'/'+p[5],	//p[2]: file , p[5]: origin file name
	        	fontSize: '0px'
	        },
	        icon: tmpMarkerIcon
	    });
	}
	
	if(type != 'click'){
		markerArr.push(marker);
	}
	
    google.maps.event.addListener(marker, 'click', function() {
    	if(nowClickLine != 0){
    		return;
    	}
    	if(typeShape == 'mainMarker'){
    		return;
    	}
    	
		var kindStr = this.id.split("_")[1];
		if(kindStr == 'GeoPhoto'){
			imageViewer(this.title, this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
		}else if(kindStr == 'GeoVideo'){
			videoViewer(this.label.text.split('/')[0], this.label.text.split('/')[1], this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
		}
    });
    
    google.maps.event.addListener(marker, 'mouseover', function() {
    	if(editMode == 1){
    		return;
    	}
    	if(nowClickLine != 0){
    		return;
    	}
    	
    	var tmpBoundX = event.clientX;
    	var tmpBoundY = event.clientY; 
    	
    	if(infowindow){
    		if(Math.abs(tmpBoundX - infoViewBoundX) > 30 || Math.abs(tmpBoundY - infoViewBoundY) > 30){
    			infowindow.close();
    		}else{
    			return;
    		}
    	}
    	
    	var kindStr = this.id.split("_")[1];
        
        var tmpThumbFileName = this.title.split('.');
    	var tmpThumbFileName1 = tmpThumbFileName[0] +'_thumbnail_600.png';
    	if(kindStr == 'GeoVideo'){
    		tmpThumbFileName1 = this.title;
    	}
    	
        var contentStr = "<img class='round' src='" + ftpBaseUrl() + "/" + kindStr +"/"+tmpThumbFileName1+"' width='200' height='200' style='border:2px solid #888888'/>";
    	infowindow = new google.maps.InfoWindow({
       		content: contentStr,
       		maxWidth: 204
      	});
        infowindow.open(map, this);
        infoViewBoundX = event.clientX;
        infoViewBoundY = event.clientY;

    	$.each($('.gm-style-iw'),function(){
			$(this).next('div').remove();
			$(this).parent().addClass('infoview_main_map');
			$(this).prev('div').children().eq(1).addClass('infoview_main_map_second');
			$(this).prev('div').children().eq(2).children().addClass('infoview_main_map_child');
			$(this).prev('div').children().last().addClass('infoview_main_map_last');
		});
    });
    
    google.maps.event.addListener(marker, 'mouseout', function() {
    	if(nowClickLine != 0){
    		return;
    	}
//     	infowindow.close();

    	var tmpBoundX = event.clientX;
    	var tmpBoundY = event.clientY; 
    	
    	if(infowindow){
    		if(Math.abs(tmpBoundX - infoViewBoundX) > 5 || Math.abs(tmpBoundY - infoViewBoundY) > 5){
    			infowindow.close();
    			infoViewBoundX = 0;
    	        infoViewBoundY = 0;
    		}else{
    			return;
    		}
    	}
    });
    
    google.maps.event.addListener(marker, 'rightclick', function() {
    });
    
    google.maps.event.addListener(map, "mousedown", function(event){
    	if(event.target != null){
    		return;
    	}
    	
        if(nowClickLine == 1){
        	if(rectangleSequence != null)
        	rectangleSequence.setMap(null);
        	
        	 var sTmpLat = event.latLng.lat();
             var sTmpLon = event.latLng.lng();
             
             
          rectangleSequence = new google.maps.Rectangle({
	          strokeColor: '#FF0000',
	          strokeOpacity: 0.8,
	          strokeWeight: 2,
	          fillColor: '#FF0000',
	          fillOpacity: 0.35,
	          editable: false,
	          draggable: false,
	          bounds: {
	            north: sTmpLat,
	            south: sTmpLat,
	            east: sTmpLon,
	            west: sTmpLon
	          }
	        });
          rectangleSequence.setMap(map);
          nowClickLine = 2;
        }
    });
    
    google.maps.event.addListener(map, "mouseup", function(event){
    	if(event.target != null){
    		return;
    	}
    	
    	if(nowClickLine == 3){
        	var sTmpLat = event.latLng.lat();
	        var sTmpLon = event.latLng.lng();
	        
			var tmpLatLon = rectangleSequence.getBounds().getNorthEast();
	        var oTmpLat = tmpLatLon.lat();
	       	var oTmpLon = tmpLatLon.lng();
	         
	       	if(rectangleSequence != null)
	        	rectangleSequence.setMap(null);
	       	var minLat = sTmpLat > oTmpLat? oTmpLat:sTmpLat;
	       	var maxLat = sTmpLat > oTmpLat? sTmpLat:oTmpLat;
	       	var minLon = sTmpLon > oTmpLon? oTmpLon:sTmpLon;
	       	var maxLon = sTmpLon > oTmpLon? sTmpLon:oTmpLon;
	       	
	       	
	      rectangleSequence = new google.maps.Rectangle({
		          strokeColor: '#FF0000',
		          strokeOpacity: 0.8,
		          strokeWeight: 2,
		          fillColor: '#FF0000',
		          fillOpacity: 0.35,
		          editable: true,
		          draggable: true,
		          bounds: {
		        	  north: minLat,
			            south: maxLat,
			            east: maxLon,
			            west: minLon
		          }
		        });
	      rectangleSequence.setMap(map);
	      nowClickLine = 1;
        }
    });
    
    google.maps.event.addListener(map, "mousemove", function(){
    	var tmpBoundX = event.clientX;
    	var tmpBoundY = event.clientY;
    	console.log('tmpBoundX : ' + tmpBoundX + " infoViewBoundX   : " + infoViewBoundX + '  tmpBoundY : '+ tmpBoundY + '  infoViewBoundY : '+ infoViewBoundY);
    	 
    	if(infowindow){
    		if(Math.abs(tmpBoundX - infoViewBoundX) > 30 || Math.abs(tmpBoundY - infoViewBoundY) > 30){
    			infowindow.close();
    			infoViewBoundX = 0;
    	        infoViewBoundY = 0;
    		}else{
    			return;
    		}
    	}
    	
        if(nowClickLine == 2){
             nowClickLine = 3;
        }
    });
}

var infoViewBoundX = 0;
var infoViewBoundY = 0;

//마커 데이터 가져오기
function takeMarkerData(typeShape) {
	var tmpPageNum = '&nbsp';
	var tmpContentNum = '&nbsp';
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpIdx = '&nbsp';
	
	if(tmpLoginId == null || tmpLoginId == '' ||  tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' ||  tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	
	var Url			= baseRoot() + b_url;
	var param		= typeShape + "/" + tmpLoginToken + "/" + tmpLoginId + "/" + tmpPageNum + "/" + tmpContentNum + "/"+ b_nowProjectIdx +"/" + tmpIdx;
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
	var seqNum_arr = new Array();
	var droneType_arr = new Array();
	var projectIdx_arr = new Array();
	var projectName_arr = new Array();
	
	if(data != null && data.length > 0){
		for(var i=0; i<data.length; i++) 
		{
			id_arr.push(data[i].id); //id 저장
			
			title_arr.push(data[i].title); //title 저장
			
			content_arr.push(data[i].content); //content 저장
			
			file_url_arr.push(data[i].filename); // file
			
			udate_arr.push(data[i].u_date); //찍은날짜
			
			idx_arr.push(data[i].idx);
			
			lati_arr.push(data[i].latitude); // 위도
			
			longi_arr.push(data[i].longitude); //경도
			
			thumbnail_url_arr.push(data[i].thumbnail);	//thumb file
			
			origin_url_arr.push(data[i].originname);	//origin file
			
			dataKind_arr.push(data[i].datakind); //데이터 타입
			
			projectUserId_arr.push(data[i].projectUserId); //project user id
			
			seqNum_arr.push(data[i].seqnum); //seq num
			
			droneType_arr.push(data[i].dronetype); //drone type
			
			projectIdx_arr.push(data[i].projectidx); //project idx
			
			projectName_arr.push(data[i].projectname); //project name
		}
	}
	
	var loca = [];
	
	var tmpProjectIdx = 0;
	var locaArr = new Array();
	var locaMap = null;
	var locaChildArr = [];

	for(var i=0; i < projectIdx_arr.length; i++)
	{	
		if(lati_arr[i] != null && lati_arr[i] != 'null' && lati_arr[i] != 0 && longi_arr[i] != null && longi_arr[i] != '' && longi_arr[i] != 0){
		    if(tmpProjectIdx == 0)
		    {
		    	tmpProjectIdx = projectIdx_arr[i];
		    	locaMap = newMap();
		    	locaMap.put('projectIdx',tmpProjectIdx);
		    }
		    else if(tmpProjectIdx != projectIdx_arr[i])
		    {
		    	locaMap.put('data',locaChildArr);
		    	locaChildArr = [];
		    	locaArr.push(locaMap);
		    	tmpProjectIdx = projectIdx_arr[i];
		    	locaMap = newMap();
		    	locaMap.put('projectIdx',tmpProjectIdx);
			}
		    
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
			temp[9] = seqNum_arr[i];
			temp[10] = droneType_arr[i];
			temp[11] = projectIdx_arr[i];
			temp[12] = projectName_arr[i];
			loca.push(temp);
			locaChildArr.push(temp);
		}
	}
	if(locaChildArr != null && locaChildArr.length > 0){
		locaMap.put('data',locaChildArr);
		locaArr.push(locaMap);
	}
	
	LocationData = loca;
	markerFileList = locaArr;
	google.maps.event.addDomListener(window, 'load', gridMap(LocationData));

}

function gridMap(LocationData) {
    var bounds = new google.maps.LatLngBounds();
//     var infowindow = new google.maps.InfoWindow();
    if(LocationData == null || LocationData.length <= 0){	//base map setting
    	if(dMarkerLat == null || dMarkerLat == ""){
    		dMarkerLat = 37.5663889;
    	}
    	if(dMarkerLng == null || dMarkerLng == ""){
    		dMarkerLng = 126.9997222;
    	}
    
    	var marker_latlng = new google.maps.LatLng(dMarkerLat, dMarkerLng);
    	map.setCenter(marker_latlng);
    	map.setZoom(setObj.mapZoom);
    	return;
    }

    markerArr = new Array();
    for (var i in LocationData)
    {
    	var p = LocationData[i];
        if(p[0] == 0 && p[1] == 0){
        	continue;
        }
        
        var latlng = new google.maps.LatLng(p[0], p[1]);
        bounds.extend(latlng);
        
        fnMakeMarker(p, 'load');
    }

    map.fitBounds(bounds);
    preBounds = bounds;
}

//get image exif data
function loadExif(rObj) {
	if(rObj != null && rObj != ''){
		if(rObj[10] != null && rObj[10] == 'Y'){
			reloadMap(rObj[0], rObj[1], "", "", rObj[10]);
		}else{
			
			var tmp_serverType = dataReplaceFun(b_serverType);
			var tmp_serverUrl = dataReplaceFun(b_serverUrl);
			var tmp_serverViewPort = dataReplaceFun(b_serverViewPort);
			var tmp_serverPath = dataReplaceFun(b_serverPath);
			
			var encode_file_name = encodeURIComponent('GeoPhoto/'+rObj[2]);
			getServer(encode_file_name,'EXIF', rObj);
		}
	}
}

//set image exif data
function exifSetting(data, rLatStr, rLonStr, rDroneStr) {
	var line_buf_arr = data.split("\<LineSeparator\>");
	var line_data_buf_arr;
	var direction_str = '';
// 	var lon_str = '';
// 	var lat_str = '';
	var focal_str = '';
	
	//GPS Direction
	line_data_buf_arr = line_buf_arr[14].split("\<Separator\>");
	if(line_data_buf_arr[1].charAt(0)=="'" && line_data_buf_arr[1].charAt(line_data_buf_arr[1].length-1)=="'") line_data_buf_arr[1] = line_data_buf_arr[1].substring(1, line_data_buf_arr[1].length-1);
	
	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) direction_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
	else direction_str = line_data_buf_arr[1];
	
	//GPS Longitude
// 	line_data_buf_arr = line_buf_arr[15].split("\<Separator\>");
// 	lon_str = line_data_buf_arr[1];
	
	//GPS Latitude
// 	line_data_buf_arr = line_buf_arr[16].split("\<Separator\>");
// 	lat_str = line_data_buf_arr[1];
	
	//Focal Length
	line_data_buf_arr = line_buf_arr[7].split("\<Separator\>");
	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) focal_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
	else focal_str = line_data_buf_arr[1];
	
	if(focal_str != null && focal_str != ''){
		focal_str = focal_str.replace(/'/g, '');
	}
	
	//맵설정
	reloadMap(rLatStr, rLonStr, direction_str, focal_str, rDroneStr);
}

function reloadMap(lat_str, lon_str, direction_str, focal_str, rDrone_str) {
	if(lat_str != null && lat_str != '' && lon_str != null && lon_str != ''){
		var lat = parseFloat(lat_str);
		var lng = parseFloat(lon_str);

		if(lat>0 && lng>0){
			setCenterA(lat, lng);
			if(rDrone_str != null && rDrone_str != "" && rDrone_str == "Y"){
				drawCircleOnMap(lat_str, lon_str, 10);
			}else{
				setAngle(direction_str, focal_str);
			}
		}
	}
}
 
//이미지 클릭시 맵 center change
function mapCenterChange(objArr){		//tempObj: lat, lon, file, idx, dataKind, origin, thumbnail, id
	var tempArr = objArr.split(",");
	var cnt = 0;
	var lat = tempArr[0];
	var lon = tempArr[1];
	
	$('.editAnno').each(function(idx,val){
		$(val).removeClass('editAnno');
		$(val).css('border','2px solid #888888');
	});
	
	if(proEdit == 1){
		moveContentAdd(objArr);
		return;
	}

	//좌표정보 없을 시 viewer 팝업
	if(lat == null || lat == '' || lat == 'null' || lat == 0 || lon == null || lon == '' || lon == 'null'|| lon == 0){
		var kindStr = tempArr[4];
// 		jAlert('좌표 정보가 없습니다. viewer로 이동합니다.', '정보', function(){
		jAlert('No coordinate information. Go to viewer','Info', function(){ 
			if(kindStr == 'GeoPhoto'){
				if(projectImage == 1){
					imageViewer(tempArr[2],  tempArr[7], tempArr[3], tempArr[8]);
				}else{
					window.open(ftpBaseUrl() +'/GeoPhoto/'+tempArr[2], 'openImage', 'width=760, height=560');
				}
			}else if(kindStr == 'GeoVideo'){
				if(projectVideo == 1){
					videoViewer(tempArr[2], tempArr[5], tempArr[7], tempArr[3], tempArr[8]);	//file_url, origin_url, id, idx
				}else{
					window.open(ftpBaseUrl()+ '/GeoVideo/' + tempArr[2], 'openImage', 'width=760, height=560');
				}
			}
		});
		return;
	}

	$('#Pro_'+ tempArr[4] +'_'+ tempArr[3]+ ' img').addClass('editAnno');
	$('#Pro_'+ tempArr[4] +'_'+ tempArr[3]+ ' img').css('border','2px solid red');
	
	if(tempArr[8] == null || tempArr[8] == 'null' || tempArr[8] == undefined){
		tempArr[8] = '';
	}
	var objId = tempArr[3]+'_'+tempArr[4]+'_'+tempArr[7]+'_'+tempArr[8];

	$.each(markerArr, function(idx, val){
		var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
		var tmpMarkerIconClk = 'http://maps.google.com/mapfiles/ms/icons/yellow-dot.png';
		var tmpVal;
		
		if(val.id != null && val.id != null && val.id != undefined){
			tmpVal = val.id.split('_');
		}
		
		if(tempArr[9] == undefined || tempArr[9] == 'null'){
			tempArr[9] = '';
		}
		
		if(oldMarkerData != null && oldMarkerData.length > 0 && val.id.trim() == oldMarkerData[3]+'_'+oldMarkerData[4]+'_'+oldMarkerData[7]+'_'+oldMarkerData[8]){
			val.setIcon(tmpMarkerIcon);
			val.setZIndex(google.maps.Marker.MAX_ZINDEX);
		}
		
		if(val.id == objId){
			val.setIcon(tmpMarkerIconClk);
			val.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
			cnt = 1;
		}
		
	});
	
	//만약 선택 항목의 마커가 로드되어 있지 않으면 새로 그려준다.
	if(cnt == 0){
		fnMakeMarker(tempArr, 'click');
	}

	if(tempArr[4] == 'GeoVideo'){
		loadGPS(tempArr[2]);	//선택한 타입이 비디오인 경우 GPS 파일 로드 후 지도에 그려주기
	}else{
		map.fitBounds(preBounds);
	}
	
	oldMarkerData = tempArr;
	map.setCenter(new google.maps.LatLng(lat, lon));
}

var gps_size;	//gps size;
//gps 정보 load
function loadGPS(fileName) {
	var buf = fileName.split('.')[0];
	buf = buf.replace("_mp4",'');
	var file_name = buf + '_modify.txt';
	file_name = "GeoVideo/" + file_name;
	
	getServer(file_name, 'GPX', "");
}

//파일 바인드
var poly_arr;
function setGPSData(lat_arr, lng_arr) {
	poly_arr = new Array();
	if(lat_arr.length == lng_arr.length) {
		for(var i=0; i<lat_arr.length; i++) {
			poly_arr.push(new google.maps.LatLng(lat_arr[i], lng_arr[i]));
		}
	}
// 	else { jAlert('GPS 파일의 Latitude 와 Longitude 가 맞지 않습니다.', '정보'); }
	else { jAlert('Latitude and Longitude of the GPS file do not match.', 'Info'); }
	setDirection(poly_arr);
}

//이동 거리를 표현 (polyline)
function setDirection(poly_arr) {
	var draw_direction = new google.maps.Polyline({
		path: poly_arr,
		strokeColor: "#FF0000",
		strokeOpacity: 0.8,
		strokeWeight: 2
	});
	draw_direction.setMap(map);
	gpx_draw_direction.push(draw_direction);

}

//마커클릭 시 이미지 뷰어 
function imageViewer(file_url, user_id, idx, projectUserId) {   // 여기서 들어오는 file_url정보 ex)  upload/20140605_120541.jpg
	if(editMode == 1) return;
	var base_url = 'http://'+location.host;
	var conv_file_url = encodeURIComponent(file_url); // conv_file_url = upload%2F20140605_120541.jpg
	
	if(projectImage == 1){
		var $dialog = jQuery.FrameDialog.create({ //객체정보를 로드
			url: base_url + '/GeoPhoto/geoPhoto/image_viewer.do?file_url='+conv_file_url+'&user_id='+user_id +'&idx='+ idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&projectUserId='+projectUserId,
			title: 'Image Viewer',
			width:1127,  
// 			height:850, 
			height:810, 
			buttons: {},
			autoOpen:false
		});
		$dialog.dialog('open');
	}else{
		window.open(ftpBaseUrl() +'/GeoPhoto/'+ conv_file_url, 'openImage', 'width=1170, height=860');
	}
}

//비디오 뷰어 동작
function videoViewer(file_url, origin_url, id, idx, projectUserId) {
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
// 				jAlert('인코딩 중 입니다...', '정보');
				jAlert('Encoding is in progress...', 'Info');
			}else {
				if(projectVideo == 1){
					var $dialog = jQuery.FrameDialog.create({
						url: base_url + '/GeoVideo/geoVideo/video_viewer.do?&file_url='+file_url+'&user_id='+id+'&idx='+idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&projectUserId='+projectUserId,
						title: 'Video Viewer',
						width: 1127,
// 						height: 850,
						height:810, 
						position: 'right',
						buttons: {},
						autoOpen:false
					});
					$dialog.dialog('open');
				}else{
					window.open(ftpBaseUrl()+ '/GeoVideo/' + file_url, 'openImage', 'width=760, height=550');
				}
			}
		}
	});
}

function mapPolygonView(obj){
	//googlemap polygon
	if(editMode == 1) return;
	
	if($(obj).attr('checked')){
	
		$.each(markerFileList,function(idx, val){
			var tmpMarkList = val.value.k_data;
			$.each(tmpMarkList,function(idxs, vals){
				if(vals != null){
					loadExif(vals);
					if(vals[4] != null && vals[4] == 'GeoVideo'){
						loadGPS(vals[2]);
					}
				}
			});
			createViewSeqLine(tmpMarkList, idx);
		});
		
	}else{
		$.each(draw_angle_arr,function(idx, val){
			val.setMap(null);
		});
		$.each(draw_direction_arr,function(idx, val){
			val.setMap(null);
		});
		$.each(blackMarker, function(idx, val){
			val.setMap(null);
		});
		$.each(gpx_draw_direction, function(idx, val){
			val.setMap(null);
		});
		$.each(circle_arr, function(idx, val){
			val.setMap(null);
		});
		$.each(draw_sequence_arr, function(idx, val){
			val.setMap(null);
		});
		$.each(draw_seqLine_arr, function(idx, val){
			val.setMap(null);
		});
		draw_angle_arr  = new Array();
		draw_direction_arr  = new Array();
		blackMarker  = new Array();
		gpx_draw_direction  = new Array();
		circle_arr = new Array();
		draw_sequence_arr = new Array();
		draw_seqLine_arr = new Array();
	}
}

var draw_seqLine_arr = new Array();
//촬영 위치와 촬영 범위 위치를 선으로 연결
function createViewSeqLine(seqMarkList, colNum) {
// 	var seqLatLng_arr = new Array();
	colNum = (parseInt(colNum)+1)/10;
	var seqColor = "#" + Math.round(colNum*0xffffff).toString(16);
	var lineSymbol = {path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW};
	if(seqMarkList != null && seqMarkList.length > 1){
		
		for(var i=0; i<seqMarkList.length-1; i++){
			
			var seqLatLng_arr = new Array();
			var tmpLatLng = new Object();
			tmpLatLng.lat = seqMarkList[i][0];
			tmpLatLng.lng = seqMarkList[i][1];	
			seqLatLng_arr.push(tmpLatLng);
			
			tmpLatLng = new Object();
			tmpLatLng.lat = seqMarkList[i+1][0];
			tmpLatLng.lng = seqMarkList[i+1][1];	
			seqLatLng_arr.push(tmpLatLng);
			
			var draw_seqLine = new google.maps.Polyline({
				path: seqLatLng_arr,
				icons: [{
		            icon: lineSymbol,
		            offset: '100%'
		          }],
				strokeColor: seqColor,
				strokeOpacity: 1.0,
				strokeWeight: 2
			});
			draw_seqLine_arr.push(draw_seqLine);
			draw_seqLine.setMap(map);
		}
	}
}

function contentMarker(response){
	markerArr = new Array();
	markerFileList = null;
	
	//set map option
	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
	//create map
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	markDataMake(response);
}

var nowClickLine = 0;
function makeSequenceOpen(){
	if(markerProArr != null && markerProArr.length == 1){
		nowClickLine = 1;
		$('#copyReqStart').css('display','none');
		$('#copyReqExit').css('display','block');
		$('.copyReqClass').css('display','block');
	}else{
// 		jAlert("한 개의 프로젝트를 선택 하셔야 복사가 가능합니다.", '정보');
		jAlert("You can copy only one project at a time.", 'Info');
	}
}

function makeSequenceColse(){
	nowClickLine = 0;
	if(rectangleSequence != null){
		rectangleSequence.setMap(null);
	}
	rectangleSequence = null;
	$('#copyReqStart').css('display','block');
	$('#copyReqExit').css('display','none');
	$('.copyReqClass').css('display','none');
}

var copySeq_arr = new Array();
function makeSequenceData(copyType){
	
	if(rectangleSequence == null){
// 		jAlert('복사할 영역을 선택해 주세요.','정보');
		jAlert('Please select an area to copy.','Info');
		return;
	}

	var ne = rectangleSequence.getBounds().getNorthEast();
	var sw = rectangleSequence.getBounds().getSouthWest();
	var nTmpLat = ne.lat();
   	var nTmpLon = ne.lng();
   	var sTmpLat = sw.lat();
   	var sTmpLon = sw.lng();
	var copySeq_obj = new Object();
	copySeq_arr = new Array();
	
   	if(nowClickLine == 1 && nTmpLat != sTmpLat && nTmpLon != sTmpLon){
   		var minLat = nTmpLat> sTmpLat ? sTmpLat : nTmpLat;
   		var maxLat = nTmpLat> sTmpLat ? nTmpLat : sTmpLat;
   		var minLon = nTmpLon> sTmpLon ? sTmpLon : nTmpLon;
   		var maxLon = nTmpLon> sTmpLon ? nTmpLon : sTmpLon;
   		
   		for(var i=0; i<LocationData.length; i++){
   			var tmpLoca = LocationData[i];
   			if(copyType == 'In'){
   				if((tmpLoca[0] >= minLat) && (tmpLoca[0] <= maxLat) && (tmpLoca[1] <= maxLon) && (tmpLoca[1] >= minLon)){
   					copySeq_obj = new Object();
   					copySeq_obj.idx = tmpLoca[3];
   					copySeq_obj.dataKind = tmpLoca[4];
   	   	   			copySeq_arr.push(copySeq_obj);
   	   	   		}
   	   		}
   			else{
   	   			if((tmpLoca[0] > maxLat) || (tmpLoca[0] < minLat) || (tmpLoca[1] > maxLon) || (tmpLoca[1] < minLon)){
   	   				copySeq_obj = new Object();
					copySeq_obj.idx = tmpLoca[3];
					copySeq_obj.dataKind = tmpLoca[4];
  	   				copySeq_arr.push(copySeq_obj);
	   	   		}
   	   		}
   		}
   		if(copySeq_arr == null || (copySeq_arr != null && copySeq_arr.length < 1)){
//    			jAlert('복사할 영역을 선택해 주세요.','정보');
   			jAlert('Please select an area to copy.','Info');
   		}else{
   			copyGetTabList();
   		}
   	}else{
//		jAlert('복사할 영역을 선택해 주세요.','정보');
		jAlert('Please select an area to copy.','Info');
   	}
}

function closeCopyPoject(){
	$('#copyPojectAddDig').dialog('close');
}
//project copy
function copySareInit(){
	$('#shareAdd').val('');
	$('#shareRemove').val('');
	$('#editYes').val('');
	$('#editNo').val('');
	$('#clonSharUser').empty();
}

//open shareUser list
function copyGetShareUser(){
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

//tab select
function copyGetTabList() {
	$('#copyPojectAddDig').dialog('open');
	$('#copyProjectNameTxt').val('');
}

function addCopyPoject(){
	
	var copyProjectNameTxt = $('#copyProjectNameTxt').val();
	
	if(copyProjectNameTxt == null || copyProjectNameTxt == ''){
// 		jAlert('프로젝트 명을 입력해 주세요.', '정보');
		jAlert('Please enter project name.', 'Info');
		return;
	}
	
	if(copyProjectNameTxt != null && copyProjectNameTxt.indexOf('\'') > -1){
// 		jAlert('프로젝트 명에 특수문자 \' 는 사용할 수 없습니다.', '정보');
		jAlert('Can not use special character \' in project name.', 'Info');
		return;
	}
	
	copyProjectNameTxt = dataReplaceFun(copyProjectNameTxt);

	var Url			= baseRoot() + "cms/copyProject/";
	var param		= loginToken + "/"+ loginId + "/" + copyProjectNameTxt + "/" + markerProArr[0] +"/"+ JSON.stringify(copySeq_arr);
	var callBack	= "?callback=?";
	
	$.ajax({
		type	: "GET"
		, url	: Url + param + callBack
		, dataType	: "jsonp"
		, async	: false
		, cache	: false
		, success: function(data) {
			if(data.Code == "100" && data.Data != null){
// 				jAlert(data.Message, '정보', function(res){
				jAlert(data.Message, 'Info', function(res){
					closeCopyPoject();
					makeSequenceColse();
					viewMyProjects(null);
				});
			}
		}
	});
}
	
	
//마커 데이터 가져오기
function takeMainMarkerData(typeShape) {
	var tmpPageNum = '&nbsp';
	var tmpContentNum = '&nbsp';
	var tmpLoginId = loginId;
	var tmpLoginToken = loginToken;
	var tmpIdx = '&nbsp';
	
	if(tmpLoginId == null || tmpLoginId == '' ||  tmpLoginId == 'null'){
		tmpLoginId = '&nbsp';
	}
	if(tmpLoginToken == null || tmpLoginToken == '' ||  tmpLoginToken == 'null'){
		tmpLoginToken = '&nbsp';
	}
	var tmpOrderType = '&nbsp';
	
	var Url			= baseRoot() + 'cms/getMainProjectList/';
	var param		= "marker/" + tmpLoginToken + "/" + tmpLoginId + "/" + tmpPageNum + "/" + tmpContentNum + "/" + tmpIdx + "/"+ tmpOrderType;
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

</script>
</head>

<body style='margin:0px; padding:0px;'>
	<div class="viewModeCls" style="display: none;">
		<input type="checkbox" id="polygonView" onclick="mapPolygonView(this);" style="vertical-align: middle ;"/>
		<label style="margin-top: 3px; display: inline-block;">View Mode</label>
		
		<!-- projectName dialog -->
		<div id="copyPojectAddDig">
			<table style="width: 100%;">
				<tr>
					<td style="width:100px;">Project Name</td>
					<td><input type="text" id="copyProjectNameTxt" style="width:100%;" /></td>
				</tr>
				<tr style="text-align: center;">
					<td colspan="2">
						<input type="button" id="saveBtn" value="Save" onclick="addCopyPoject();"/>
						<input type="button" value="Cancel" onclick="closeCopyPoject();"/>
					</td>
				</tr>
			</table>
		</div>
	</div>
<!-- 	<div onclick="makeSequenceOpen();return false;" id="copyReqStart" class="copyCssClass" style="display: none;">복사할 영역 선택 하기</div> -->
<!-- 	<div onclick="makeSequenceColse();return false;" id="copyReqExit" class="copyCssClass" style="display: none;" >복사 취소</div> -->
<!-- 	<div onclick="makeSequenceData('In');return false;" id="copyReqNewIn" class="copyReqClass copyCssClass" style="display: none;" >선택 영역으로 생성</div> -->
<!-- 	<div onclick="makeSequenceData('Out');return false;" id="copyReqNewOut" class="copyReqClass copyCssClass" style="display: none;" >선택 영역 밖으로 생성</div> -->
	<div onclick="makeSequenceOpen();return false;" id="copyReqStart" class="copyCssClass" style="display: none;">Selecting the area to copy</div>
	<div onclick="makeSequenceColse();return false;" id="copyReqExit" class="copyCssClass" style="display: none;" >Cancel copy</div>
	<div onclick="makeSequenceData('In');return false;" id="copyReqNewIn" class="copyReqClass copyCssClass" style="display: none;" >Create as selection</div>
	<div onclick="makeSequenceData('Out');return false;" id="copyReqNewOut" class="copyReqClass copyCssClass" style="display: none;" >Create out of selection</div>
	
	<!-- center setting -->
	<div class="morkerModeCls1" id="morkerModeOpen" onclick="defaultMarkerSet('open');" style="display: none; height: 30px;width: 130px;position: absolute;left: 100px;top: 10px;z-index: 9;background-color: #ffffff;text-align: center;cursor: pointer;">
		<div style="margin-top: 3px; display: inline-block;">Set default location</div>
	</div>
	<div class="morkerModeCls2" id="morkerModeCenCle" onclick="defaultMarkerSet('cencle');" style="display: none; height: 30px;width: 200px;position: absolute;left: 105px;top: 10px;z-index: 9;background-color: #ffffff;text-align: center;cursor: pointer;">
		<div style="margin-top: 3px; display: inline-block;">Reset default location settings</div>
	</div>
	<div class="morkerModeCls2" style="display: none; height: 30px;width: 350px;position: absolute;left: 320px;top: 10px;z-index: 9;text-align: center;cursor: pointer;">
		<input type="text" id="searchDefaultPlace" style="margin-top: 3px; display: inline-block; width: 100%;" placeholder="Enter location">
	</div>
		
	<div id="map_canvas" style="width:100%; height:100%; min-width: 1080px;"></div>
</body>
</html>
