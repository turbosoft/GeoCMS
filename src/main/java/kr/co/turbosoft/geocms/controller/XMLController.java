package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import kr.co.turbosoft.geocms.util.XMLRW;

@Controller
public class XMLController {
	@RequestMapping(value = "/geoXml.do", method = RequestMethod.POST)
	public void geoXml(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		request.setCharacterEncoding("utf-8");
		
		String[] buf = request.getParameter("file_name").split("\\/");
		String file_path = buf[1] + "\\" + buf[2];
		String file_name = buf[3];
		String xml_data = request.getParameter("xml_data");
		
		System.out.println(xml_data);
		
		String file_dir = request.getSession().getServletContext().getRealPath("/")+ file_path + "\\"; // 저장주소
		
		String result = "";
		XMLRW xmlRW = new XMLRW();
		result = xmlRW.write(file_dir, file_name, xml_data);
		System.out.println(result);
		
		//setContentType 을 먼저 설정하고 getWriter		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		out.print(result);
	}
}
