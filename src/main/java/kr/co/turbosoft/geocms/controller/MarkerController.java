package kr.co.turbosoft.geocms.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class MarkerController {
	@RequestMapping(value = "/getMarkerIcon.do", method = RequestMethod.GET)
	public void getMarkerIcon(HttpServletRequest request, HttpServletResponse response) throws IOException {
		request.setCharacterEncoding("utf-8");
		List<String> fileNameList = new ArrayList<String>();
		
		String file_dir = request.getSession().getServletContext().getRealPath("/")+ "\\images\\geoImg\\map\\markerIcon"; // 저장주소
		File dirFile=new File(file_dir);
		
		if(dirFile.exists()){
			File []fileList=dirFile.listFiles();
			if(fileList != null){
				for(File tempFile : fileList) {
				  if(tempFile.isFile()) {
				    String tempPath=tempFile.getParent();
				    String tempFileName=tempFile.getName();
				    fileNameList.add(tempFileName);
				    System.out.println("Path="+tempPath);
				    System.out.println("FileName="+tempFileName);
				  }
				}
			}
		}else{
			dirFile.mkdirs(); 
		}
		
		String result = "";
		result = Arrays.toString(fileNameList.toArray()); 
		if(result != null && result.length() > 0){
			result = result.substring(1, result.length()-1);
		}
		System.out.println(result);
		
		//setContentType 을 먼저 설정하고 getWriter		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		out.print(result);
	}
}
