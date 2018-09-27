package kr.co.turbosoft.geocms.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.security.GeneralSecurityException;
import java.security.NoSuchAlgorithmException;
import java.util.Properties;

import javax.activation.DataHandler;
import javax.activation.DataSource;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.Multipart;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeBodyPart;
import javax.mail.internet.MimeMessage;
import javax.mail.internet.MimeMultipart;
import javax.mail.util.ByteArrayDataSource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import kr.co.turbosoft.geocms.util.KeyManager;

import org.apache.commons.codec.binary.Base64;
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
		response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS, DELETE");
        response.setHeader("Access-Control-Max-Age", "3600");
        response.setHeader("Access-Control-Allow-Headers", "x-requested-with");
        response.setHeader("Access-Control-Allow-Origin", "*");
		
		String text = request.getParameter("text");
		String textType = request.getParameter("textType");
		String searchEmail = request.getParameter("searchEmail");
		String thisType = request.getParameter("thisType");
		String result = "success";

	    String msgBody = "";
	    if(thisType != null && thisType != "" && "checkEmail".equals(thisType)){
//	    	msgBody = "인증 번호 는 "+ text +" 입니다.";
	    	msgBody = "The authentication number is "+ text +" .";
	    }else{
//	    	msgBody = "요청하신 "+ textType +"는 "+ text +" 입니다.";
	    	msgBody = "The requested "+ textType +" is "+ text +" .";
	    }
	    
	    String imgData_type = request.getParameter("imgData_type");
	    String imgData_email = request.getParameter("imgData_email");
	    String imgData_url = request.getParameter("imgData_url");
	    String imgData_idx = request.getParameter("imgData_idx");
	    String chk_url = request.getParameter("chk_url");
	    String chk_capture = request.getParameter("chk_capture");
	    String imgData = request.getParameter("imgData");
	    
	    Multipart mp = new MimeMultipart();
	    
	    if(imgData_type != null && imgData_type != "" && "Y".equals(imgData_type)){
	    	try{
	        	searchEmail = imgData_email;
	        	
	        	String sendHtml = "";
	        	
	        	if(chk_url != null && "Y".equals(chk_url)){
//	        		sendHtml = "요청하신 url 주소는 <a href='"+ imgData_url +"&idx="+ imgData_idx + "&link=Y'>링크로 가기</a>";
	        		sendHtml = "The url address you requested is <a href='"+ imgData_url +"&idx="+ imgData_idx + "&link=Y'>Go to link</a>";
	        	}
	        
	        	MimeBodyPart messageBodyPart = new MimeBodyPart();
	            messageBodyPart.setContent(sendHtml, "text/html;charset=utf-8" );
	            mp.addBodyPart(messageBodyPart);
	            
	        	if(chk_capture != null && "Y".equals(chk_capture)){
	        		
	        		imgData = imgData.split(",")[1];
	        		System.out.println(imgData);
		            byte[] files = Base64.decodeBase64(imgData);
		            ByteArrayDataSource dSource = new ByteArrayDataSource(files, "image/png");
		            messageBodyPart = new MimeBodyPart();
		            DataSource fds = dSource;
		            messageBodyPart.setDataHandler( new DataHandler(fds));
		            messageBodyPart.setHeader( "Content-ID","<img1>" );
		            
		            String imgDataOrign = request.getParameter("imgDataOrign");
		            
		            mp.addBodyPart(messageBodyPart);
		            String tmpFileDir = request.getSession().getServletContext().getRealPath("/");
		            tmpFileDir = tmpFileDir.substring(0, tmpFileDir.lastIndexOf("GeoCMS")) + "GeoPhoto"+ File.separator + "mailPhoto";
		            File file = new File(tmpFileDir+ "/" + imgDataOrign);
		            if(file.exists()){file.delete();}
	        	}
	        	
	        }catch(Exception e){
	        	e.printStackTrace();
	        }
	    }
	    
	    try {
	    	Properties props = System.getProperties();
	    	props.put("mail.smtp.host", "smtp.gmail.com");
	    	props.put("mail.smtp.port", "587");
	    	props.put("mail.smtp.starttls.enable", "true");
	    	props.put("mail.smtp.auth", "true");
	    	
	    	Authenticator auth = new PopupAuthenticator();
	    	
	    	// session
	    	Session session = Session.getDefaultInstance(props, auth);
 	        Message msg = new MimeMessage(session);
 	        
 	        //sender
 	        KeyManager km = new KeyManager();
 	       try {
				emailAddress = km.decrypt(emailAddress);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
 	       
 	        InternetAddress from = new InternetAddress() ;
	        from = new InternetAddress(emailAddress);
	        msg.setFrom(from);
	        
	        //reciver
	        InternetAddress to = new InternetAddress(searchEmail);
 	        msg.setRecipient(Message.RecipientType.TO, to);
 	        
	        msg.setSubject("GeoCMS Message");
	        if(imgData_type != null && imgData_type != "" && "Y".equals(imgData_type)){
	        	msg.setContent(mp);
	        }else{
	        	msg.setContent(msgBody, "text/html;charset=utf-8" );
	        }
	        Transport.send(msg);
	    	
	    } catch (Exception e) {
	        e.printStackTrace();
	        result = "System error.";
	    }
	    
	    //setContentType 을 먼저 설정하고 getWriter
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		out.print(result);
	}
	
	private class PopupAuthenticator extends Authenticator {
        public PasswordAuthentication getPasswordAuthentication() {
        	KeyManager km = new KeyManager();
        	try {
				emailPass = km.decrypt(emailPass);
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
        	
        	String address = emailAddress;
        	String pass = emailPass;
            return new PasswordAuthentication(address, pass);
        }
    }
}
