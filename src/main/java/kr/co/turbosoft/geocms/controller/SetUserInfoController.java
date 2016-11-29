package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class SetUserInfoController {
	@RequestMapping(value = "/geoSetUserInfo.do", method = RequestMethod.POST)
	public void geoSetUserInfo(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		String typeVal = request.getParameter("typeVal");
		String loginId = request.getParameter("loginId");
		String loginToken = request.getParameter("loginToken");
		String loginType = request.getParameter("loginType");
		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		
		if(typeVal != null){
			if(typeVal.equals("login")){
				if(loginId != null && loginToken != null){
					HttpSession session = request.getSession();
					session.setAttribute("loginId", loginId);
					session.setAttribute("loginToken", loginToken);
					session.setAttribute("loginType", loginType);
					session.setMaxInactiveInterval(60 * 60 * 24); 
					out.print("100");
				}else{
					out.print("login error");
				}
			}else if(typeVal.equals("logout")){
				HttpSession session = request.getSession(false);
				if(session != null){
					session.invalidate();
				}
			}
		}
	}
}
