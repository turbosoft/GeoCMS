package kr.co.turbosoft.util;

import java.awt.Graphics;
import java.awt.Image;
import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.imageio.ImageIO;

import net.coobird.thumbnailator.Thumbnails;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.io.FileUtils;
import org.apache.commons.net.ftp.FTP;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPReply;
import org.apache.taglibs.standard.extra.spath.Path;

import com.oreilly.servlet.multipart.DefaultFileRenamePolicy;
import com.oreilly.servlet.multipart.FilePart;
import com.oreilly.servlet.multipart.FileRenamePolicy;

import kr.co.turbosoft.dao.DataDao;
import kr.co.turbosoft.util.ImageExtract;
import kr.co.turbosoft.util.VideoEncoding;

public class SaveController extends Thread{
	private DataDao dataDao = null;
	private List<Map<String,String>> fileList;
	private List<String> saveFiles;
	
	private String loginId;
	private String logKey;
	
	private String serverUrlStr;
	private String userIdStr;
	private String userPassStr;
	private String portNumStr;
	private String saveFilePathStr;
	private String fileType;
	
	
	public void setDataAPI(DataDao dataDao){
		this.dataDao = dataDao;
	}
	
	public SaveController(String loginId, String logKey, List<Map<String,String>> fileList, List<String> saveFiles,
			String serverUrlStr, String userIdStr, String userPassStr, String portNumStr, String saveFilePathStr, String fileType) {
		this.loginId = loginId;
		this.logKey = logKey;
		
        this.fileList = fileList;
        this.saveFiles = saveFiles;
        this.serverUrlStr = serverUrlStr;
        this.userIdStr = userIdStr;
        this.userPassStr = userPassStr;
        this.portNumStr = portNumStr;
        this.saveFilePathStr = saveFilePathStr;
        this.fileType = fileType;
    }
	
	@Override
	public void run() {
        System.out.println("thread run.");
		
        FTPClient ftp = null; // FTP Client 객체 
		FileInputStream fis = null; // File Input Stream 
		int reply = 0;
		
		List<String> resIdx = new ArrayList<String>();
		HashMap<String, Object> objParam = new HashMap<String, Object>();
		Map<String, String> fileMap = new HashMap<String, String>();
		HashMap<String, String> paramMap = new HashMap<String, String>();
		HashMap<String, String> param2 = new HashMap<String, String>();
		
		for(int k=0;k<fileList.size();k++){
			fileMap = new HashMap<String, String>();
			fileMap = fileList.get(k);
			if(fileMap != null && fileMap.get("idx") != null){
				resIdx.add(fileMap.get("idx"));
			}
		}
		objParam.put("fileIdxs", resIdx);
		
		try{
			ftp = new FTPClient(); // FTP Client 객체 생성 
			ftp.setControlEncoding("UTF-8"); // 문자 코드를 UTF-8로 인코딩 
			ftp.connect(serverUrlStr, Integer.parseInt(portNumStr)); // 서버접속 " "안에 서버 주소 입력 또는 "서버주소", 포트번호 
			
			reply = ftp.getReplyCode();//
			if(!FTPReply.isPositiveCompletion(reply)) {
				ftp.disconnect();
				objParam.put("status", "ERROR");
				dataDao.updateImageStatus(objParam);
				
				if(fileType != null && "imageFile".equals(fileType)){
					param2.clear();
					param2.put("loginId", loginId);
					param2.put("idx", String.valueOf(logKey));
					param2.put("status", "ERROR");
					dataDao.updateLog(param2);
			    }
				return;
		    }
			
			if(!ftp.login(userIdStr, userPassStr)) {
				ftp.logout();
				objParam.put("status", "ERROR");
				dataDao.updateImageStatus(objParam);
				
				if(fileType != null && "imageFile".equals(fileType)){
					param2.clear();
					param2.put("loginId", loginId);
					param2.put("idx", String.valueOf(logKey));
					param2.put("status", "ERROR");
					dataDao.updateLog(param2);
			    }
				return;
		    }
			
			ftp.setFileType(FTP.BINARY_FILE_TYPE);
		    ftp.enterLocalPassiveMode();

		    ftp.changeWorkingDirectory(saveFilePathStr +"/GeoPhoto"); // 작업 디렉토리 변경
		    reply = ftp.getReplyCode();
		    if (reply == 550) {
		    	ftp.makeDirectory(saveFilePathStr +"/GeoPhoto");
		    	ftp.changeWorkingDirectory(saveFilePathStr +"/GeoPhoto"); // 작업 디렉토리 변경
		    }
		}catch(Exception e){
			e.printStackTrace();
			objParam.put("status", "ERROR");
			dataDao.updateImageStatus(objParam);
			
			if(fileType != null && "imageFile".equals(fileType)){
				param2.clear();
				param2.put("loginId", loginId);
				param2.put("idx", String.valueOf(logKey));
				param2.put("status", "ERROR");
				dataDao.updateLog(param2);
		    }
			return;
		}
		//--------------------------------------------------------------------------------------------
	    
		List<File> removeFile = new ArrayList<File>();
		String tmpFtfFileName = "";
		boolean isSuccess = false;
		ContentsSave contentsSave = new ContentsSave();
		String filePathStr = "";
		String reseultData = "";
		String[] reseultDataArr = null;
		String datalongitude = "";
		String datalatitude = "";
		
		String idxArrStr = "";
		String[] idxArr = null;
		String savefullStr = "";
		
		for(int k=0;k<fileList.size();k++){
			tmpFtfFileName = "";
			filePathStr = "";
			reseultData = "";
			reseultDataArr = null;
			datalongitude = "";
			datalatitude = "";
			idxArrStr = "";
			idxArr = null;
			fileMap = new HashMap<String, String>();
			fis = null;
			savefullStr = saveFiles.get(k);
			removeFile = new ArrayList<File>();
			
			if(savefullStr != null && !"".equals(savefullStr) && fileList.get(k) != null && !"".equals(fileList.get(k))) {
				try {
					fileMap = fileList.get(k);
					if(fileMap != null && fileMap.get("file") != null && fileMap.get("file") != ""){
						filePathStr = fileMap.get("file");
						tmpFtfFileName = filePathStr.substring(filePathStr.lastIndexOf("/")+1, filePathStr.length());
						
						removeFile.add(new File(savefullStr));
						fis = new FileInputStream(savefullStr);
						isSuccess = ftp.storeFile(tmpFtfFileName, fis);
						
						if(isSuccess) {
							paramMap = new HashMap<String, String>();
							if(fileType != null && !"".equals(fileType)){
								if("imageFile".equals(fileType)){
									//썸네일 이미지
									int thumbnail_width1 = 110;
									int thumbnail_height1 = 110;
									
									int thumbnail_width2 = 600;
									int thumbnail_height2 = 442;
									
									String tmpPreThumb = tmpFtfFileName.substring(0, tmpFtfFileName.lastIndexOf("."));
									String tmpPrefix = savefullStr.substring(0, savefullStr.lastIndexOf("."));
									File thumb_file_name1 = new File(tmpPrefix+"_thumbnail.png");
									File thumb_file_name2 = new File(tmpPrefix+"_thumbnail_600.png");
									
									BufferedImage sourceImage = ImageIO.read(new File(savefullStr));
									Image scaledImage = sourceImage.getScaledInstance(thumbnail_width1,thumbnail_height1, Image.SCALE_DEFAULT);
						        	BufferedImage newImage11 = new BufferedImage(thumbnail_width1, thumbnail_height1, BufferedImage.TYPE_INT_RGB);
						        	Graphics g11 = newImage11.getGraphics();
						        	g11.drawImage(scaledImage, 0, 0, null);
						        	g11.dispose();
						        	ImageIO.write(newImage11, "jpg", thumb_file_name1);
						        	
						        	Image scaledImage2 = sourceImage.getScaledInstance(thumbnail_width2,thumbnail_height2, Image.SCALE_DEFAULT);
						        	BufferedImage newImage22 = new BufferedImage(thumbnail_width2, thumbnail_height2, BufferedImage.TYPE_INT_RGB);
						        	Graphics g22 = newImage22.getGraphics();
						        	g22.drawImage(scaledImage2, 0, 0, null);
						        	g22.dispose();
						        	ImageIO.write(newImage11, "jpg", thumb_file_name2);
							        
									removeFile.add(thumb_file_name1);
									removeFile.add(thumb_file_name2);
									
									fis = new FileInputStream(thumb_file_name1);
									isSuccess = ftp.storeFile(tmpPreThumb+"_thumbnail.png", fis);
									fis = new FileInputStream(thumb_file_name2);
									isSuccess = ftp.storeFile(tmpPreThumb+"_thumbnail_600.png", fis);
									
									//좌표파일
									paramMap.put("idx", fileMap.get("idx"));
									reseultData = contentsSave.saveImageContent(savefullStr);
									if(reseultData != null && !"".equals(reseultData)){
										reseultDataArr = reseultData.split(",");
										
										datalongitude = reseultDataArr[0];
										datalatitude = reseultDataArr[1];
										paramMap.put("longitude", datalongitude);
										paramMap.put("latitude", datalatitude);
									}
									paramMap.put("status", "COMPLETE");
									dataDao.updateImage(paramMap);
								    System.out.println(tmpFtfFileName + "파일 FTP 업로드 성공");
								}else if("worldFile".equals(fileType)){
									idxArrStr = fileMap.get("idx");
									if(idxArrStr != null && !"".equals(idxArrStr)){
										idxArr = idxArrStr.split(",");
										if(idxArr != null && idxArr.length > 0){
											reseultData = contentsSave.saveFileContent(savefullStr);
											if(reseultData != null && !"".equals(reseultData)){
												reseultDataArr = reseultData.split(",");
												
												datalongitude = reseultDataArr[0];
												datalatitude = reseultDataArr[1];
												paramMap.put("longitude", datalongitude);
												paramMap.put("latitude", datalatitude);
											}
											paramMap.put("status", "COMPLETE");
											
											for(int m=0; m<idxArr.length; m++){
												paramMap.put("idx", idxArr[m]);
												dataDao.updateImage(paramMap);
											    System.out.println(tmpFtfFileName + "파일 FTP 업로드 성공");
											}
										}
									}
								}
							}
				       }
					}
					
			    } catch(Exception ie) {
			       ie.printStackTrace();
			       if(fileType != null && "imageFile".equals(fileType)){
			    	   param2.clear();
					   param2.put("loginId", loginId);
					   param2.put("idx", String.valueOf(logKey));
					   param2.put("status", "ERROR");
					   dataDao.updateLog(param2);
			       }
					
			       objParam.clear();
			       for(int m=k;m<fileList.size();m++){
						fileMap = new HashMap<String, String>();
						fileMap = fileList.get(m);
						if(fileMap != null && fileMap.get("idx") != null){
							resIdx.add(fileMap.get("idx"));
						}
					}
					objParam.put("fileIdxs", resIdx);
					objParam.put("status", "ERROR");
					dataDao.updateImageStatus(objParam);
			    } finally {
			       if(fis != null) {
			          try {
			             fis.close();
			          } catch(IOException ie) {
			        	  ie.printStackTrace();
			        	  if(fileType != null && "imageFile".equals(fileType)){
					    	   param2.clear();
							   param2.put("loginId", loginId);
							   param2.put("idx", String.valueOf(logKey));
							   param2.put("status", "ERROR");
							   dataDao.updateLog(param2);
					       }
						   
			        	  for(int m=k;m<fileList.size();m++){
								fileMap = new HashMap<String, String>();
								fileMap = fileList.get(m);
								if(fileMap != null && fileMap.get("idx") != null){
									resIdx.add(fileMap.get("idx"));
								}
							}
							objParam.put("fileIdxs", resIdx);
							objParam.put("status", "ERROR");
							dataDao.updateImageStatus(objParam);
			          }finally{
			        	  if(removeFile != null && removeFile.size() > 0){
			        		 for(int fi=0; fi<removeFile.size(); fi++){
			        			 if(removeFile.get(fi) != null && removeFile.get(fi).exists()){
			        				 removeFile.get(fi).delete();
			        			 }
			        		 }
			      		  }
			          }
			       }
			       
			       if(removeFile != null && removeFile.size() > 0){
		        		 for(int fi=0; fi<removeFile.size(); fi++){
		        			 if(removeFile.get(fi) != null && removeFile.get(fi).exists()){
		        				 removeFile.get(fi).delete();
		        			 }
		        		 }
		      		}
			    }
			}
		}// end for
		if(fileType != null && "imageFile".equals(fileType)){
			param2.clear();
			param2.put("loginId", loginId);
			param2.put("idx", String.valueOf(logKey));
			param2.put("status", "COMPLETE");
			dataDao.updateLog(param2);
	    }
    }
}
