package kr.co.turbosoft.geocms.controller;

import java.io.IOException;
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

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import kr.co.turbosoft.geocms.controller.UserSendMailController.PopupAuthenticator;

@Controller
public class UserSendMailController {
	@RequestMapping(value = "/geoUserSendMail.do", method = RequestMethod.POST)
	public void geoUserSendMail(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		request.setCharacterEncoding("utf-8");
		String text = request.getParameter("text");
		String textType = request.getParameter("textType");
		String searchEmail = request.getParameter("searchEmail");
		String thisType = request.getParameter("thisType"); 
		 Properties props = new Properties();

	        String msgBody = "";
	        if(thisType != null && thisType != "" && "checkEmail".equals(thisType)){
	        	msgBody = "인증 번호 는 "+ text +" 입니다.";
	        }else{
	        	msgBody = "요청하신 "+ textType +"는 "+ text +" 입니다.";
	        }

	        try {
	        	Authenticator auth = new PopupAuthenticator();
//	        	props.put("mail.transport.protocol", "smtp");
//	        	props.put("mail.smtp.host", "localhost");
//	        	props.put("mail.smtp.port", "25");
//	        	props.put("mail.smtp.auth", "true");
	        	
	        	props.put("mail.smtp.host", "smtp.gmail.com");
	        	props.put("mail.smtp.port", "587");
	        	props.put("mail.smtp.starttls.enable", "true");
	        	props.put("mail.smtp.auth", "true");
//	        	props.setProperty("mail.smtp.socketFactory.class", "javax.net.ssl.SSLSocketFactory");
	        	
	        	Session session = Session.getDefaultInstance(props, auth);
 	            Message msg = new MimeMessage(session);
//	            msg.setFrom(new InternetAddress("turbo@example.com"));
	            msg.addRecipient(Message.RecipientType.TO,
	                             new InternetAddress(searchEmail));
	            msg.setSubject("GeoCMS Message");
	            msg.setText(msgBody);
	            Transport.send(msg);
	        	
//	        	 String host = "smtp.gmail.com";
//	             String username = "ssong2yang@gmail.com";
//	             String password = "qufwkfl1";
//	              
//	             // 메일 내용
//	             String recipient = "song2yang@gmail.com";
//	             String subject = "지메일을 사용한 발송 테스트입니다.";
//	             String body = "내용 무";
//	              
//	             //properties 설정
//	             Properties props = new Properties();
//	             props.put("mail.smtps.auth", "true");
//	             // 메일 세션
//	             Session session = Session.getDefaultInstance(props);
//	             MimeMessage msg = new MimeMessage(session);
//	      
//	             // 메일 관련
//	             msg.setSubject(subject);
//	             msg.setText(body);
//	             msg.setFrom(new InternetAddress(username));
//	             msg.addRecipient(Message.RecipientType.TO, new InternetAddress(recipient));
//	      
//	             // 발송 처리
//	             Transport transport = session.getTransport("smtps");
//	             transport.connect(host, username, password);
//	             transport.sendMessage(msg, msg.getAllRecipients());
//	             transport.close();

	        } catch (AddressException e) {
	            e.printStackTrace();
	        } catch (MessagingException e) {
	        	 e.printStackTrace();
	        }
	}
	
	static class PopupAuthenticator extends Authenticator {
        public PasswordAuthentication getPasswordAuthentication() {
            return new PasswordAuthentication("GeoCMSmarster@gmail.com", "turbosoft2015");
        }
    }
}
