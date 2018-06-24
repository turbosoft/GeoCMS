package kr.co.turbosoft.geocms.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import kr.co.turbosoft.geocms.util.XMLRW;

@Controller
public class XMLController {
	
	@RequestMapping(value = "/geoXml.do", method = RequestMethod.POST)
	public void geoXml(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		request.setCharacterEncoding("utf-8");
		System.out.println("GeoCMS req file name : " + request.getParameter("file_name"));
		String type = request.getParameter("type");
		String[] buf = request.getParameter("file_name").split("\\/");
		String upload_type = buf[0];
		String file_name = buf[1];
		String xml_data = request.getParameter("xml_data");
		String file_encode = "";
		if(file_name != null && !"".equals(file_name)){
//			file_name = file_name.substring(0, file_name.lastIndexOf(".")) + ".xml";
			file_encode = URLEncoder.encode(file_name,"utf-8");
		}
		/* ecliplse */
//		String fileSavePathStr = request.getSession().getServletContext().getRealPath("/");
//		fileSavePathStr = fileSavePathStr.substring(0,fileSavePathStr.length()-1)+"_Gateway/upload";
		
		/*tomcat*/
//		String fileSavePathStr = request.getSession().getServletContext().getRealPath("/");
//		fileSavePathStr = fileSavePathStr.substring(0, fileSavePathStr.indexOf(File.separator+"webapps"));
//		fileSavePathStr = fileSavePathStr + File.separator+"webapps" + File.separator + "GeoCMS_Gateway/upload";
		
		String serverTypeStr = request.getParameter("serverType");
		String serverUrlSrt = request.getParameter("serverUrl");
		String serverViewPortStr = request.getParameter("serverViewPort");
		String serverPathStr = request.getParameter("serverPath");
		String serverPortStr = request.getParameter("serverPort");
		String serverIdStr = request.getParameter("serverId");
		String serverPassStr = request.getParameter("serverPass");
		
		String file_dir = "";
		if(serverTypeStr != null && "URL".equals(serverTypeStr)){
			file_dir = "http://"+ serverUrlSrt +":"+ serverViewPortStr +"/shares/"+serverPathStr +"/"+ upload_type +"/"+file_encode;
		}
		
		String fileSavePathStr = request.getSession().getServletContext().getRealPath("/");
		fileSavePathStr = fileSavePathStr.substring(0,fileSavePathStr.length()-1) + File.separator + serverPathStr;
		
		File upDir = new File(fileSavePathStr);
		if(!upDir.exists()){
			upDir.mkdir();
		}
		System.out.println(xml_data);
		
		String result = "";
		XMLRW xmlRW = new XMLRW();
		xmlRW.geoXmlRWCon(fileSavePathStr, serverUrlSrt, serverIdStr, serverPassStr, serverPortStr, serverPathStr);
		
		if(type != null){
			if("load".equals(type)){
				result = xmlRW.getXmlData(file_dir, file_name, upload_type);
			}else if("save".equals(type)){
				result = xmlRW.write(file_dir, file_name, xml_data, upload_type);
			}
		}
		System.out.println(result);
		//setContentType 을 먼저 설정하고 getWriter		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		out.print(result);
	}
}
