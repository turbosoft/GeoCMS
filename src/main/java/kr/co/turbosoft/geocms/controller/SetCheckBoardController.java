package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class SetCheckBoardController {
	@RequestMapping(value = "/geoSetChkBoard.do", method = RequestMethod.POST)
	public void geoSetChkBoard(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		//setContentType 을 먼저 설정하고 getWriter		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		System.out.println("SetCheckProjectBoard");
		out.print("SetCheckProjectBoard");
	}
}
