<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="utf-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<html>
<head>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<meta http-equiv="content-type" content="text/html; charset=utf-8"/>

<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?key=AIzaSyAth-_FyQxRomNh2JkI_MvAWXRJuLOEXNI&v=3.exp&sensor=false&libraries=places,geometry"></script>
<script type='text/javascript'>

/* --------------------- 내부 함수 --------------------*/
var map;
var markerArr = new Array();
var markerFileList = null;
var preBounds; //메인화면 크기 저장

var marker_latlng, view_marker_latlng;

var fov; //화각
var view_value; //촬영 거리

var direction_latlng;

var draw_angle_arr = new Array();
var draw_direction_arr = new Array();
var blackMarker = new Array();
var gpx_draw_direction = new Array();

function initialize() {
	markerArr = new Array();
	markerFileList = null;
	
	//set map option
	var myOptions = { mapTypeId: google.maps.MapTypeId.ROADMAP, streetViewControl:false, scaleControl:false };
	//create map
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	if(typeShape == "marker") {	//main marker
		takeMarkerData(typeShape);
	}
	else if(typeShape == "forSearch") {	//searh page marker
		google.maps.event.addDomListener(window, 'load', gridMap(LocationData));	
	}
}

/* --------------------- 초기 설정 함수 --------------------*/

//촬영 지점 설정
function setCenterA(lat, lng) {
	if(lat>0 && lng>0) {
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
	var infowindow = new google.maps.InfoWindow();
	var latlng = new google.maps.LatLng(p[0], p[1]);
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

	var marker = new google.maps.Marker({
        position: latlng,
        map: map,
        title: jpgStr,				// jpg file name
        id: p[3]+'_'+p[4]+'_'+p[7]+'_'+p[8] + '_'+ p[9],			//p[3]: index, p[4]: kind(GeoPhoto, GeoVideo), p[7]: use_id, p[8]: project make user id, p[9]: project marker icon
        label: {
        	text: p[2]+'/'+p[5],	//p[2]: file , p[5]: origin file name
        	fontSize: '0px'
        },
        icon: tmpMarkerIcon
    });
    
	if(type != 'click'){
		markerArr.push(marker);
	}
	
	if(type != 'load'){	//marker click setting 
		marker.setIcon('http://maps.google.com/mapfiles/ms/icons/yellow-dot.png');
		marker.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
	}
 
    google.maps.event.addListener(marker, 'click', function() {
		var kindStr = this.id.split("_")[1];
		if(kindStr == 'GeoPhoto'){
			imageViewer(this.title, this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
		}else if(kindStr == 'GeoVideo'){
			videoViewer(this.label.text.split('/')[0], this.label.text.split('/')[1], this.id.split("_")[2], this.id.split("_")[0], this.id.split("_")[3]);
		}
    });
    
    google.maps.event.addListener(marker, 'mouseover', function() {
    	var kindStr = this.id.split("_")[1];
    	var contentStr = "<img class='round' src='<c:url value='/upload/"+ kindStr +"/"+this.title+"'/>' width='200' height='200' style='border:2px solid #888888'/>";
		infowindow = new google.maps.InfoWindow({
   			content: contentStr,
   			maxWidth: 204
  		});
    	infowindow.open(map, this);
		$('.gm-style-iw').next('div').remove();
    });
    
    google.maps.event.addListener(marker, 'mouseout', function() {
    	infowindow.close();
    });
    
    google.maps.event.addListener(marker, 'rightclick', function() {
    });
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
			
			origin_url_arr.push(data[i].ORIGINNAME);	//origin file
			
			dataKind_arr.push(data[i].DATAKIND); //데이터 타입
			
			projectUserId_arr.push(data[i].projectUserId); //project user id
			
			projectMarkerIcon_arr.push(data[i].PROJECTMARKERICON); //project marker icon
		}
	}
// 	markerFileList = file_url_arr;
	
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
	google.maps.event.addDomListener(window, 'load', gridMap(LocationData));

}

function gridMap(LocationData) {
    var bounds = new google.maps.LatLngBounds();
    var infowindow = new google.maps.InfoWindow();

    if(LocationData == null || LocationData.length <= 0){	//base map setting
    	if(dMarkerLat == null || dMarkerLat == ""){
    		dMarkerLat = 37.5663889;
    	}
    	if(dMarkerLng == null || dMarkerLng == ""){
    		dMarkerLng = 126.9997222;
    	}
    	var marker_latlng = new google.maps.LatLng(dMarkerLat, dMarkerLng);
    	map.setCenter(marker_latlng);
    	map.setZoom(10);
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
        
        var latlng = new google.maps.LatLng(p[0], p[1]);
        bounds.extend(latlng);
        
        fnMakeMarker(p, 'load');
        markerFileList.push(p[2]);
    }

    map.fitBounds(bounds);
    preBounds = bounds;
}

//get image exif data
function loadExif(file_name) {
	var encode_file_name = encodeURIComponent('/upload/GeoPhoto/'+file_name);
	
	$.ajax({
		type: 'POST',
		url: '<c:url value="/geoExif.do"/>',
		data: 'file_name='+encode_file_name+'&type=load',
		success: function(data) {
			var response = data.trim();
			exifSetting(response);
		}
	});
}

//set image exif data
function exifSetting(data) {
	var line_buf_arr = data.split("\<LineSeparator\>");
	var line_data_buf_arr;
	var direction_str = '';
	var lon_str = '';
	var lat_str = '';
	var focal_str = '';
	
	//GPS Direction
	line_data_buf_arr = line_buf_arr[14].split("\<Separator\>");
	if(line_data_buf_arr[1].charAt(0)=="'" && line_data_buf_arr[1].charAt(line_data_buf_arr[1].length-1)=="'") line_data_buf_arr[1] = line_data_buf_arr[1].substring(1, line_data_buf_arr[1].length-1);
	
	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) direction_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
	else direction_str = line_data_buf_arr[1];
	
	//GPS Longitude
	line_data_buf_arr = line_buf_arr[15].split("\<Separator\>");
	lon_str = line_data_buf_arr[1];
	
	//GPS Latitude
	line_data_buf_arr = line_buf_arr[16].split("\<Separator\>");
	lat_str = line_data_buf_arr[1];
	
	//Focal Length
	line_data_buf_arr = line_buf_arr[7].split("\<Separator\>");
	if(line_data_buf_arr[1].indexOf('\(')!=-1 && line_data_buf_arr[1].indexOf('\)')!=-1) focal_str = line_data_buf_arr[1].substring(line_data_buf_arr[1].indexOf('\(')+1, line_data_buf_arr[1].indexOf('\)'));
	else focal_str = line_data_buf_arr[1];
	
	if(focal_str != null && focal_str != ''){
		focal_str = focal_str.replace(/'/g, '');
	}
	
	//맵설정
	reloadMap(lat_str, lon_str, direction_str, focal_str);
}

function reloadMap(lat_str, lon_str, direction_str, focal_str) {
	if(lat_str != null && lat_str != '' && lon_str != null && lon_str != ''){
		var lat = parseFloat(lat_str);
		var lng = parseFloat(lon_str);

		if(lat>0 && lng>0){
			setCenterA(lat, lng);
			setAngle(direction_str, focal_str);
		}
	}
}

var oldMarkerData = new Array(); //이전 center marker
//이미지 클릭시 맵 center change
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
// 		alert('좌표 정보가 없습니다. viewer로 이동합니다.');
		jAlert('No coordinate information. Go to viewer','Info');
		if(kindStr == 'GeoPhoto'){
			if(projectImage == 1){
				imageViewer(tempArr[2],  tempArr[7], tempArr[3], tempArr[8]);
			}else{
				window.open('<c:url value="/upload/GeoPhoto/'+tempArr[2]+'"/>', 'openImage', 'width=760, height=560');
			}
		}else if(kindStr == 'GeoVideo'){
			if(projectVideo == 1){
				videoViewer(tempArr[2], tempArr[5], tempArr[7], tempArr[3], tempArr[8]);	//file_url, origin_url, id, idx
			}else{
				window.open('<c:url value="/upload/GeoVideo/'+tempArr[2]+'"/>', 'openImage', 'width=760, height=550');
			}
		}
		return;
	}
	
	$.each(markerArr, function(idx, val){
		var tmpMarkerIcon = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
		var tmpMarkerIconClk = 'http://maps.google.com/mapfiles/ms/icons/yellow-dot.png';
		var tmpVal;
		
		if(val.id != null && val.id != null && val.id != undefined){
			tmpVal = val.id.split('_');
		}
		if(tmpVal[4] != null && tmpVal[4] != '' && tmpVal[4] != undefined && tmpVal[4] != 'null'){
			var tmpSrc = tmpVal[4].replace('&ubsp','_');
			tmpMarkerIcon = {
				url: '<c:url value="images/geoImg/map/markerIcon/'+ tmpSrc +'"/>',
				scaledSize: new google.maps.Size(25, 25)
			};
		}
		
		if(tempArr[9] == undefined || tempArr[9] == 'null'){
			tempArr[9] = '';
		}
		
		if(val.id == tempArr[3]+'_'+tempArr[4]+'_'+tempArr[7]+'_'+tempArr[8] +'_'+ tempArr[9]){
			val.setIcon(tmpMarkerIconClk);
			val.setZIndex(google.maps.Marker.MAX_ZINDEX + 1);
			cnt = 1;
		}

		if(oldMarkerData != null && oldMarkerData.length > 0 && val.id == oldMarkerData[3]+'_'+oldMarkerData[4]+'_'+oldMarkerData[7]+'_'+oldMarkerData[8] +'_'+ oldMarkerData[9]){
			val.setIcon(tmpMarkerIcon);
			val.setZIndex(google.maps.Marker.MAX_ZINDEX);
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
	var file_name = buf + '.gpx';
	var lat_arr = new Array(); 
	var lng_arr = new Array();
	
	$.ajax({
		type: "GET",
		url: 'http://'+ location.host + '/GeoCMS//upload/GeoVideo/'+ file_name,
		dataType: "xml",
		cache: false,
		success: function(xml) {
			$(xml).find('trkpt').each(function(index) {
				var lat_str = $(this).attr('lat');
				var lng_str = $(this).attr('lon');
				lat_arr.push(parseFloat(lat_str));
				lng_arr.push(parseFloat(lng_str));
			});
			gps_size = lat_arr.length;
			setGPSData(lat_arr, lng_arr);
		},
		error: function(xhr, status, error) {
		}
	});
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
	else {
// 		jAlert('GPS 파일의 Latitude 와 Longitude 가 맞지 않습니다.', '정보');
		jAlert('Latitude and Longitude of the GPS file do not match.', 'Info');
	}
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
// 	var bounds = new google.maps.LatLngBounds();
// 	$.each(poly_arr, function(idx, val){
// 		bounds.extend(val);
// 	});
// 	map.fitBounds(bounds);
}

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
						url: base_url + '/GeoVideo/geoVideo/video_viewer.do?&file_url='+file_url+'&user_id='+id+'&idx='+idx+'&loginId='+loginId+'&loginType='+loginType+'&loginToken='+loginToken+'&b_contentTabArr='+b_contentTabArr+'&projectUserId='+projectUserId,
						title: 'Video Viewer',
						width: 1127,
						height: 650,
						buttons: {},
						autoOpen:false
					});
					$dialog.dialog('open');
				}else{
					window.open('<c:url value="/upload/GeoVideo/'+file_url+'"/>', 'openImage', 'width=760, height=550');
				}
			}
		}
	});
}

// var polyBounds = null;
function mapPolygonView(obj){
	//googlemap polygon
	if(editMode == 1) return;
	
	if($(obj).attr('checked')){
		$.each(markerFileList,function(idx, val){
			if(val != null){
				if(val.indexOf('ogg.ogg') > -1){
					loadGPS(val);
				}else{
					loadExif(val);
				}
			}
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
		draw_angle_arr  = new Array();
		draw_direction_arr  = new Array();
		blackMarker  = new Array();
		gpx_draw_direction  = new Array();
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

</script>
</head>

<body style='margin:0px; padding:0px;'>
	<div class="viewModeCls">
		<input type="checkbox" id="polygonView" onclick="mapPolygonView(this);" style="vertical-align: middle ;"/>
		<label style="margin-top: 3px; display: inline-block;">View Mode</label>
	</div>
	<div class="morkerModeCls1" id="morkerModeOpen" onclick="defaultMarkerSet('open');" style="display: none; height: 30px;width: 130px;position: absolute;left: 100px;top: 10px;z-index: 9;background-color: #ffffff;text-align: center;cursor: pointer;">
		<div style="margin-top: 3px; display: inline-block;">Set default location</div>
	</div>
<!-- 	<div class="morkerModeCls2" id="morkerModeSave" onclick="defaultMarkerSet('save');" style="display: none; height: 30px;width: 140px;position: absolute;left: 100px;top: 10px;z-index: 9;background-color: #ffffff;text-align: center;cursor: pointer;"> -->
<!-- 		<div style="margin-top: 3px; display: inline-block;">Save default location</div> -->
<!-- 	</div> -->
	<div class="morkerModeCls2" id="morkerModeCenCle" onclick="defaultMarkerSet('cencle');" style="display: none; height: 30px;width: 200px;position: absolute;left: 105px;top: 10px;z-index: 9;background-color: #ffffff;text-align: center;cursor: pointer;">
		<div style="margin-top: 3px; display: inline-block;">Reset default location settings</div>
	</div>
	<div class="morkerModeCls2" style="display: none; height: 30px;width: 350px;position: absolute;left: 320px;top: 10px;z-index: 9;text-align: center;cursor: pointer;">
		<input type="text" id="searchDefaultPlace" style="margin-top: 3px; display: inline-block; width: 100%;" placeholder="Enter location">
	</div>
	
	<div id="map_canvas" style="width:100%; height:100%; min-width: 1080px;"></div>
</body>
</html>
