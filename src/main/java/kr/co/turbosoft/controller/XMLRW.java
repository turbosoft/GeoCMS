package kr.co.turbosoft.geocms.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Authenticator;
import java.net.HttpURLConnection;
import java.net.PasswordAuthentication;
import java.net.URL;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.nio.charset.Charset;
import java.util.ArrayList;

import org.apache.commons.io.FileUtils;
import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;
import org.apache.sanselan.common.IImageMetadata;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class XMLRW {
	private String fileSavePathStr;
	private String serverUrlStr;
	private String serverIdStr;
	private String serverPassStr;
	private String serverPortNumStr;
	private String serverPathStr;
	
	public void geoXmlRWCon(String fileSavePathStr, String serverUrlStr, String serverIdStr, String serverPassStr, String serverPortNumStr, String serverPathStr) {
		this.fileSavePathStr = fileSavePathStr;
        this.serverUrlStr = serverUrlStr;
        this.serverIdStr = serverIdStr;
        this.serverPassStr = serverPassStr;
        this.serverPortNumStr = serverPortNumStr;
        this.serverPathStr = serverPathStr;
    }
	
	public String write(String file_dir, String file_name, String xml_data, String uploadType) {
		
		FTPClient ftp = null; // FTP Client 객체 
		FileInputStream fis = null; // File Input Stream 
		int reply = 0;
		String result = "";
		
		try{
			if(file_dir != null && !"".equals(file_dir)){
				ftp = new FTPClient(); // FTP Client 객체 생성 
				ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
				ftp.setConnectTimeout(3000);
				ftp.connect(serverUrlStr, Integer.parseInt(serverPortNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
				
				reply = ftp.getReplyCode();//
				if(!FTPReply.isPositiveCompletion(reply)) {
					ftp.disconnect();
					return "error";
			    }
				
				if(!ftp.login(serverIdStr, serverPassStr)) {
					ftp.logout();
//					result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
					result = "Failed to save XML. Please contact the administrator";
			    }
				
				ftp.setFileType(FTP.BINARY_FILE_TYPE);
				ftp.enterLocalPassiveMode();
		
			    ftp.changeWorkingDirectory(serverPathStr+"/"+uploadType); // 작업 디렉토리 변경
			    reply = ftp.getReplyCode();
			    if (reply == 550) {
			    	ftp.makeDirectory(serverPathStr+"/"+uploadType);
			    	reply = ftp.getReplyCode();
			    	if (reply == 550) {
//			    		result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
			    		result = "Failed to save XML. Please contact the administrator";
			    	}
			    	ftp.changeWorkingDirectory(serverPathStr+"/"+uploadType); // 작업 디렉토리 변경
			    	reply = ftp.getReplyCode();
			    	if (reply == 550) {
//			    		result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
			    		result = "Failed to save XML. Please contact the administrator";
			    	}
			    }
			}
		    
		    try{
		    	File xml_file_dir = new File(fileSavePathStr + "/"+ uploadType);
		    	if(!xml_file_dir.exists()){
		    		xml_file_dir.mkdir();
		    	}
		    	
		    	File xml_file = new File(fileSavePathStr + "/"+ uploadType +"/" + file_name);
		    	PrintWriter printWriter = null;
				try {
					printWriter = new PrintWriter(xml_file, "utf-8");
					printWriter.println(xml_data);
					printWriter.flush();
					
					boolean isSuccess = false;
					fis = new FileInputStream(xml_file);
					if(file_dir != null && !"".equals(file_dir)){
						isSuccess = ftp.storeFile(file_name, fis);
					}else{
						isSuccess = true;
					}
				
				    if(isSuccess) {
				    	result = "XML_SAVE_SUCCESS";
				    	System.out.println(file_name + "파일 FTP 업로드 성공");
				    }
				}catch(Exception e) { 
					e.printStackTrace();
//					result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
					result = "Failed to save XML. Please contact the administrator";
				}finally{
					if(file_dir != null && !"".equals(file_dir)){
						if(xml_file.exists()){
							xml_file.delete();
						}
					}
				}
			} catch(Exception ie) {
				ie.printStackTrace(); 
//				result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
				result = "Failed to save XML. Please contact the administrator";
			} finally {
				if(fis != null) {
					try {
						fis.close();
					} catch(IOException ie) {
						ie.printStackTrace();
//						result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
						result = "Failed to save XML. Please contact the administrator";
					}
				}
			}
	    
		}catch(Exception e){
			e.printStackTrace();
//			result = "XML 저장에 실패하였습니다. 관리자에게 문의하여 주세요.";
			result = "Failed to save XML. Please contact the administrator";
		}
		
		return result;
	}
	
	public String getXmlData(String file_dir, String file_name, String upload_type) {
		String result = "";
		File xml_file_dir = new File(fileSavePathStr + File.separator+ upload_type);
    	if(!xml_file_dir.exists()){
    		xml_file_dir.mkdir();
    	}
		String fullFile = fileSavePathStr + File.separator + upload_type +File.separator+ file_name;
    	
    	if(file_dir != null && !"".equals(file_dir)){
    		try {			   
    			URL gamelan = new URL(file_dir);
    			Authenticator.setDefault(new Authenticator()
    			{
    			  @Override
    			  protected PasswordAuthentication getPasswordAuthentication()
    			  {
    			    return new PasswordAuthentication(serverIdStr, serverPassStr.toCharArray());
    			  }
    			});
    			HttpURLConnection urlConnection = (HttpURLConnection)gamelan.openConnection();
                urlConnection.connect();
              
                System.out.println("urlConnection.getResponseCode() : "+ urlConnection.getResponseCode() + " : "+ HttpURLConnection.HTTP_OK);
                if(urlConnection.getResponseCode() == HttpURLConnection.HTTP_OK){
                	BufferedReader in = new BufferedReader(new InputStreamReader(urlConnection.getInputStream(), Charset.forName("UTF-8")));

                    String inputLine;
                    while ((inputLine = in.readLine()) != null){
                    	System.out.println(inputLine);
                    	result += inputLine;
                    }
                    in.close();
                }
                
    		} catch (Exception e) {
    			e.printStackTrace();
    		}
    	}else{
    		BufferedReader in;
			try {
				File tmpFile = new File(fullFile);
				if(tmpFile.exists()){
//					in = new BufferedReader(new FileReader(tmpFile));
					in = new BufferedReader(new InputStreamReader(new FileInputStream(tmpFile),"UTF8"));
					String inputLine;
					while ((inputLine = in.readLine()) != null){
						System.out.println(inputLine);
						result += inputLine;
					}
		            in.close();
				}
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
    	}
		
		return result;
	}
}
