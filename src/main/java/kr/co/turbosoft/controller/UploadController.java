package kr.co.turbosoft.geocms.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import kr.co.turbosoft.geocms.util.ContentsSave;

@Controller
public class UploadController {
	
	@RequestMapping(value = "/geoUpload.do", method = RequestMethod.POST)
	public void geoUpload(HttpServletRequest request, HttpServletResponse response) throws IOException {
		
		request.setCharacterEncoding("utf-8");
		
		String uploadType = request.getParameter("uploadType");
		int gpxSave = 0;
		String lat = "";
		String lon = "";
		String saveFileName = "";
		
		//파일 정보 저장 변수
		ArrayList<String> files = new ArrayList<String>();
		ArrayList<String> filesName = new ArrayList<String>();
		String fileSavePathStr = request.getSession().getServletContext().getRealPath("/");
		fileSavePathStr = fileSavePathStr.substring(0,fileSavePathStr.length()-1)+"_Gateway/upload";

		//파일 업로드
		boolean isMultipart = ServletFileUpload.isMultipartContent(request); // 멀티파트인지 체크

		System.out.println("isMultipart : "+isMultipart);

		try {
			if(isMultipart) {
				int uploadMaxSize = 2*1024*1024*1024; //2GB
				File tempDir = new File(fileSavePathStr+File.separator+"tmp");
				File uploadDir = new File(fileSavePathStr+File.separator+"upload");
				 
				if(!tempDir.exists()) tempDir.mkdir();
				if(!uploadDir.exists()) uploadDir.mkdir();
				
				uploadDir = new File(fileSavePathStr+File.separator+"upload"+File.separator+uploadType);
				if(!uploadDir.exists()) uploadDir.mkdir();
				 
				DiskFileItemFactory factory = new DiskFileItemFactory(uploadMaxSize, tempDir);
				ServletFileUpload upload = new ServletFileUpload(factory);
				upload.setSizeMax(uploadMaxSize);
				List items = upload.parseRequest(request);
				Iterator iter = items.iterator();
				while(iter.hasNext()) {
					FileItem item = (FileItem)iter.next();
					if(!item.isFormField()) {
						String fieldName = item.getFieldName();
						String fileName = item.getName();
						String contentType = item.getContentType();
						boolean isInMemory = item.isInMemory();
						long sizeInBytes = item.getSize();
						System.out.println("FieldName : "+fieldName);
						System.out.println("FileName : "+fileName);
						System.out.println("ContentType : "+contentType);
						System.out.println("IsInMemory : "+isInMemory);
						System.out.println("SizeInBytes : "+sizeInBytes);
				   
						String uploadFilePath = uploadDir+File.separator+fileName;
						String newUploadFilePath = uploadFilePath;
						int fileIndex = 1;
						File uploadFile;
						
						if("GeoVideo".equals(uploadType)){
							newUploadFilePath = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."))+"_mp4.mp4";
							
							if(saveFileName != null && saveFileName != ""){
								String[] tmp = uploadFilePath.split("GeoVideo\\\\");
								newUploadFilePath = tmp[0] + "GeoVideo\\"+ saveFileName + "_mp4.gpx";
								uploadFile = new File(newUploadFilePath);
							}else{
								String tmp1 = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."))+"_mp4.mp4";
								String prefix = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."));
								while((uploadFile = new File(tmp1)).exists()) {
									String suffix = "_mp4.mp4";
									tmp1 = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									uploadFile = new File(tmp1);
								}
								String tmp2 = tmp1.substring(0, tmp1.lastIndexOf("."))+".gpx";
								while((uploadFile = new File(tmp2)).exists()) {
									String suffix = "_mp4.gpx";
									tmp2 = prefix+"("+fileIndex+")"+suffix;
									fileIndex++;
									uploadFile = new File(tmp2);
								}
								
								
								String tempPath = uploadFile.getPath();
								newUploadFilePath = tempPath.substring(0, tempPath.lastIndexOf("."))+".mp4";
								
								saveFileName = tempPath.substring(tempPath.lastIndexOf("\\")+1, tempPath.lastIndexOf("_mp4"));
							}
							
							System.out.println("uploadFile : "+newUploadFilePath);
							
							if(uploadFilePath.indexOf("gpx") > 0){
								item.write(uploadFile);
								//
								File fXmlFile = new File(newUploadFilePath);
								DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
								DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
								Document doc = dBuilder.parse(fXmlFile);
								doc.getDocumentElement().normalize();
								System.out.println("Root element :" + doc.getDocumentElement().getNodeName());
								NodeList nList = doc.getElementsByTagName("trkpt");
								System.out.println("----------------------------");
								Element eElement = (Element)nList.item(0);
								lat = eElement.getAttribute("lat");
								lon = eElement.getAttribute("lon");
								gpxSave++;
							}else{
								String tmpPathStr = newUploadFilePath.substring(0, newUploadFilePath.lastIndexOf(".")).replace("_mp4", "");
								files.add(tmpPathStr + uploadFilePath.substring(uploadFilePath.lastIndexOf(".")));
								uploadFile = new File(tmpPathStr + uploadFilePath.substring(uploadFilePath.lastIndexOf(".")));
								item.write(uploadFile);
							}
						}else{
							while((uploadFile = new File(newUploadFilePath)).exists()) {
								String prefix = uploadFilePath.substring(0, uploadFilePath.lastIndexOf("."));
								String suffix = uploadFilePath.substring(uploadFilePath.lastIndexOf("."));
								newUploadFilePath = prefix+"("+fileIndex+")"+suffix;
								fileIndex++;
								uploadFile = new File(newUploadFilePath);
							}
							filesName.add(newUploadFilePath);
							System.out.println("uploadFile : "+newUploadFilePath);
							
							files.add(newUploadFilePath);
							
							item.write(uploadFile);
						}
					}
				}
			}
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		String reseultData = "";
		
		if(uploadType != null){
			if("GeoCMS".equals(uploadType)){
				String filesStr = "";
				String filePathStr = "";
				for(int i=0;i<filesName.size();i++){
					String tmpFname = filesName.get(i);
					if(tmpFname != null && tmpFname != ""){
						filesStr += tmpFname.split("GeoCMS\\\\")[1] + ",";
						if(i==0){
							filePathStr = files.get(i);
							filePathStr = filePathStr.split("GeoCMS\\\\")[0];
						}
					}
				}
				
				if(filesStr != null && !"".equals(filesStr) && !"null".equals(filesStr)){
					filesStr += "path:" + filePathStr;
				}
				reseultData = filesStr;
			}else if("GeoPhoto".equals(uploadType)){
				ContentsSave contentsSave = new ContentsSave();
				reseultData += contentsSave.saveImageContent(files);
			}else if("GeoVideo".equals(uploadType)){
				reseultData += "lat:"+lat + ",lon:"+lon; 
				reseultData += ",files:"+files.get(0);
			}
		}
		
		response.setContentType("text/html;charset=utf-8");
		PrintWriter out = response.getWriter();
		System.out.println(reseultData);
		out.print(reseultData);
	}
}
