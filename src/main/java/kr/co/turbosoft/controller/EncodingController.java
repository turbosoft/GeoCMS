package kr.co.turbosoft.geocms.controller;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import kr.co.turbosoft.geocms.util.ImageExtract;
import kr.co.turbosoft.geocms.util.VideoEncoding;

@Controller
public class EncodingController {
	@RequestMapping(value = "/geoEncoding.do", method = RequestMethod.POST)
	public void geoEncoding(HttpServletRequest request, HttpServletResponse response) throws IOException {
		String file_name = request.getParameter("filename");
		//이미지 추출
		ImageExtract imageExtract = new ImageExtract();
		imageExtract.ImageExtractor(file_name);
		
		//자동 인코딩 (1차 : ogg)
		VideoEncoding videoEncoding = new VideoEncoding();
		videoEncoding.convertToOgg(file_name);
	}
}
