package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
import java.io.PrintWriter;
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
		Properties props = new Properties();
		String result = "success";

	        String msgBody = "";
	        if(thisType != null && thisType != "" && "checkEmail".equals(thisType)){
	        	msgBody = "인증 번호는 "+ text +" 입니다.";
	        }else{
	        	msgBody = "요청하신  "+ textType +"는 "+ text +" 입니다.";
	        }

	        try {
	        	Authenticator auth = new PopupAuthenticator();
	        	
	        	props.put("mail.smtp.host", "smtp.gmail.com");
	        	props.put("mail.smtp.port", "587");
	        	props.put("mail.smtp.starttls.enable", "true");
	        	props.put("mail.smtp.auth", "true");
	        	
	        	Session session = Session.getDefaultInstance(props, auth);
 	            Message msg = new MimeMessage(session);
	            msg.addRecipient(Message.RecipientType.TO,
	                             new InternetAddress(searchEmail));
	            msg.setSubject("GeoCMS Message");
	            msg.setText(msgBody);
	            Transport.send(msg);
	        	
	        } catch (AddressException e) {
	            e.printStackTrace();
	            result = "시스템 오류입니다. 오류메시지를 확인해 주세요.";
	        } catch (MessagingException e) {
	        	e.printStackTrace();
	        	result = "시스템 오류입니다. 오류메시지를 확인해 주세요.";
	        } catch (Exception e) {
	        	e.printStackTrace();
	        	result = "시스템 오류입니다. 오류메시지를 확인해 주세요.";
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
