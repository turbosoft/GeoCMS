<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<!-- jQuery & jQuery UI -->
<link type="text/css" href="<c:url value='/lib/jquery/css/smoothness/jquery-ui-1.8.11.custom.css'/>" rel="Stylesheet" />
<script type="text/javascript" src="<c:url value='/lib/jquery/js/jquery-1.5.1.min.js'/>"></script>
<script type="text/javascript" src="<c:url value='/lib/jquery/js/jquery-ui-1.8.11.custom.min.js'/>"></script>

<!-- jAlert -->
<link type="text/css" href="<c:url value='/lib/jalert/jquery.alerts.css'/>" rel="Stylesheet" />
<script type="text/javascript" src="<c:url value='/lib/jalert/jquery.alerts.js'/>"></script>

<!-- cookie -->
<%-- <script type="text/javascript" src="<c:url value='/lib/cookie/jquery.cookie.js'/>"></script> --%>

<!-- panorama -->
<!-- <script type="text/javascript" src="http://localhost:8087/lib/panorama/jquery.panorama.js"></script> -->

<!-- framedialog -->
<script type="text/javascript" src="<c:url value='/lib/framedialog/jquery.framedialog.js'/>"></script>

<!-- uploadify -->
<link type="text/css" href="<c:url value='/lib/uploadify/uploadify.css'/>" rel="Stylesheet" />
<script type="text/javascript" src="<c:url value='/lib/uploadify/jquery.uploadify.v2.1.4.js'/>"></script>
<script type="text/javascript" src="<c:url value='/lib/uploadify/swfobject.js'/>"></script>
<script type="text/javascript" src="http://cdnjs.cloudflare.com/ajax/libs/json3/3.3.2/json3.min.js"></script>


<!-- cluetip -->
<link type="text/css" href="<c:url value='/lib/cluetip/jquery.cluetip.css'/>" rel="Stylesheet" />
<script type="text/javascript" src="<c:url value='/lib/cluetip/jquery.cluetip.js'/>"></script>
<script type="text/javascript" src="<c:url value='/lib/cluetip/jquery.hoverIntent.js'/>"></script>
<script type="text/javascript" src="<c:url value='/lib/cluetip/jquery.bgiframe.min.js'/>"></script>

<!-- icolorpicker -->
<script type="text/javascript" src="<c:url value='/lib/icolorpicker/iColorPicker.js'/>"></script>

<!-- contextmenu -->
<script type="text/javascript" src="<c:url value='/lib/contextmenu/jquery.contextmenu.r2.js'/>"></script>

<!-- css -->
<link type="text/css" href="<c:url value='/css/content_common.css'/>" rel="Stylesheet"/>


<script type="text/javascript">
/*
 * Path잡기
 */
// var getContextPath = function() {
// 	var offset=location.href.indexOf(location.host)+location.host.length;
// 	var ctxPath=location.href.substring(offset,location.href.indexOf('/',offset+1));
// 	//return ctxPath;
// 	return location.protocol + '//' + location.host;
// };

var baseRoot = function(){
// 	var br = "http://"+ location.host + "/GeoCMS_Gateway/";
	var br = "http://"+ location.host + "/GeoCMS_Gateway/";
// 	var br = "https://bblphr.com/PHRGateway/";
	//var br = "http://turbosoft2.iptime.org:8001/PHRGateway/";
	return br;
};
</script>