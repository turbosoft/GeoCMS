package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;
import java.util.Properties;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class UserSendMailController {
	@Value("#{props['email.address']}")
	private String emailAddress;
	
	@Value("#{props['email.pass']}")
	private String emailPass;
	
	@RequestMapping(value = "/geoUserSendMail.do", method = RequestMethod.POST)
	public void geoUserSendMail(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		request.setCharacterEncoding("utf-8");
		String text = request.getParameter("text");
		String textType = request.getParameter("textType");
		String searchEmail = request.getParameter("searchEmail");
		String thisType = request.getParameter("thisType"); 
		String result = "success";

	        String msgBody = "";
	        if(thisType != null && thisType != "" && "checkEmail".equals(thisType)){
	        	msgBody = "The authentication number is "+ text +" .";
	        }else{
	        	msgBody = "The requested  "+ textType +" is "+ text +" .";
	        }

	        try {
	        	Properties props = System.getProperties();
	        	props.put("mail.smtp.host", "smtp.gmail.com");
	        	props.put("mail.smtp.port", "587");
	        	props.put("mail.smtp.starttls.enable", "true");
	        	props.put("mail.smtp.auth", "true");
	        	
	        	Authenticator auth = new PopupAuthenticator();
	        	
	        	//session 생성 및  MimeMessage생성
	        	Session session = Session.getDefaultInstance(props, auth);
 	            Message msg = new MimeMessage(session);
 	            
 	            //편지보낸시간
 	            msg.setSentDate(new Date());
 	            InternetAddress from = new InternetAddress() ;
 	            from = new InternetAddress(emailAddress);
 	            // 이메일 발신자
 	            msg.setFrom(from);
 	            
 	            // 이메일 수신자
 	            InternetAddress to = new InternetAddress(searchEmail);
 	            msg.setRecipient(Message.RecipientType.TO, to);
 	            
	            msg.setSubject("GeoCMS Message");
	            msg.setText(msgBody);
	            Transport.send(msg);
	        	
	        } catch (Exception e) {
	        	e.printStackTrace();
	        	result = "System error. Please check the error message.";
			}
	        
	      //setContentType 을 먼저 설정하고 getWriter
			response.setContentType("text/html;charset=utf-8");
			PrintWriter out = response.getWriter();
			out.print(result);
	}
	
	private class PopupAuthenticator extends Authenticator {
        public PasswordAuthentication getPasswordAuthentication() {
        	String address = emailAddress;
        	String pass = emailPass;
            return new PasswordAuthentication(address, pass);
        }
    }
}
