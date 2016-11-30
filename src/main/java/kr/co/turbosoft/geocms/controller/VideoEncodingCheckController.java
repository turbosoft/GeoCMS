package kr.co.turbosoft.geocms.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class VideoEncodingCheckController {
	@RequestMapping(value = "/geoVideoEncodingCheck.do", method = RequestMethod.POST)
	public void geoVideoEncodingCheck(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		String origin_url = request.getParameter("origin_url");
		
		String base_path = request.getSession().getServletContext().getRealPath("/");
		
		String origin_file_name = origin_url;
		
		String full_path = base_path.replace("\\", "\\\\");
		full_path += "upload/GeoVideo/";
		
		File file = new File(full_path);
		File[] file_list = file.listFiles();
		boolean file_find = false;
		if(file_list != null){
			for(int i=0; i<file_list.length; i++) {
				System.out.println(file_list[i].getName());
				if(file_list[i].getName().equals(origin_file_name)) file_find = true;
			}
		}
		//setContentType 을 먼저 설정하고 getWriter		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		System.out.println(file_find);
		if(file_find) out.print("true");
		else out.print("false");
	}
}
